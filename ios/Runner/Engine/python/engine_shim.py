"""yt-dlp inside the app process (iOS can't start subprocesses).

The Swift host (`IosMediaEngine.swift`) calls these functions through the embedded
CPython; `_mdengine` is the native module it registers. Arguments are the same
lists `YtDlpArgsBuilder` builds for Android and macOS, run through yt-dlp's own
CLI entry point, so stdout lines (`[MD]` progress, `[Merger]`, ...) are the
same on every platform. See docs/engine/ios_engine.md.
"""

import errno
import importlib
import io
import json
import os
import subprocess
import sys
import threading
import zipimport

import _mdengine

_ERROR_TAIL = 4000


class JobCancelled(BaseException):
    """Raised in a job's thread by `cancel`. A BaseException, so yt-dlp's
    `except Exception` blocks can't swallow it."""


_local = threading.local()
_lock = threading.Lock()
_threads = {}  # job id -> thread ident
_cancelled = set()
_zips = {'bundled': None, 'update': None}


# -- stdout / stderr per thread ------------------------------------------------


class _Capture:
    """Collects a job's output: emits complete lines for [job_id], else buffers."""

    def __init__(self, job_id=None):
        self._job_id = job_id
        self._parts = []
        self._partial = ''

    def write(self, text):
        if self._job_id is None:
            self._parts.append(text)
            return
        *lines, self._partial = (self._partial + text).split('\n')
        for line in lines:
            _emit(self._job_id, line)

    def close(self):
        if self._job_id is not None and self._partial:
            _emit(self._job_id, self._partial)
        self._partial = ''

    def value(self):
        return ''.join(self._parts)


def _emit(job_id, line):
    line = line.rstrip('\r')
    if line:
        _mdengine.emit(job_id, line.encode('utf-8', 'replace').decode('utf-8'))


class _ThreadStream(io.TextIOBase):
    """sys.stdout / sys.stderr: each job thread writes to its own capture, so
    two parallel downloads never mix their lines."""

    def __init__(self, name, fallback):
        super().__init__()
        self._name = name
        self._fallback = fallback

    @property
    def encoding(self):
        return 'utf-8'

    def writable(self):
        return True

    def isatty(self):
        return False

    def write(self, text):
        capture = getattr(_local, self._name, None)
        if capture is not None:
            capture.write(text)
        elif self._fallback is not None:
            self._fallback.write(text)
        return len(text)

    def flush(self):
        if getattr(_local, self._name, None) is None and self._fallback is not None:
            self._fallback.flush()


sys.stdout = _ThreadStream('out', sys.__stdout__)
sys.stderr = _ThreadStream('err', sys.__stderr__)


# -- ffmpeg / ffprobe in-process -----------------------------------------------


def _probe_stdout(argv, output, printed):
    text = printed if printed.strip() else output
    if 'json' in argv:
        start, end = text.find('{'), text.rfind('}')
        if start != -1 and end > start:
            return text[start:end + 1]
    return text


class _InProcessPopen:
    """Stands in for yt-dlp's `Popen`: `ffmpeg` / `ffprobe` run through the
    linked FFmpegKit; anything else fails like a missing program would."""

    def __init__(self, args, *_, stdin=None, stdout=None, stderr=None, text=False,
                 universal_newlines=False, encoding=None, errors=None, **__):
        argv = [os.fsdecode(a) for a in args] if isinstance(args, (list, tuple)) else []
        tool = os.path.basename(argv[0]) if argv else ''
        if tool not in ('ffmpeg', 'ffprobe'):
            raise OSError(errno.ENOTSUP, f'{sys.platform} does not support processes.')
        self.args = args
        self.pid = None
        self.stdin = io.BytesIO()
        self._text = bool(text or universal_newlines or encoding or errors)

        job_id = getattr(_local, 'job_id', None) or ''
        code, output, printed = _mdengine.ffmpeg(job_id, argv[1:], tool == 'ffprobe')
        if job_id and job_id in _cancelled:
            raise JobCancelled()
        self.returncode = code

        out = output if tool == 'ffmpeg' else _probe_stdout(argv, output, printed)
        err = output if output.strip() else f'{tool} exited with code {code}\n'
        if stderr == subprocess.STDOUT:
            out, err = output, None
        self._stdout = self._wrap(out) if stdout == subprocess.PIPE else None
        self._stderr = self._wrap(err) if stderr == subprocess.PIPE else None
        self.stdout = io.StringIO(self._stdout) if self._text and self._stdout is not None else None
        self.stderr = None

    def _wrap(self, value):
        if value is None:
            return None
        return value if self._text else value.encode('utf-8', 'replace')

    def communicate(self, input=None, timeout=None):
        return self._stdout, self._stderr

    def communicate_or_kill(self, *args, **kwargs):
        return self.communicate()

    def wait(self, timeout=None):
        return self.returncode

    def poll(self):
        return self.returncode

    def kill(self, *args, **kwargs):
        pass

    terminate = kill
    send_signal = kill

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        return False

    @classmethod
    def run(cls, *args, timeout=None, input=None, **kwargs):
        with cls(*args, **kwargs) as proc:
            default = '' if proc._text else b''
            stdout, stderr = proc.communicate_or_kill(input=input, timeout=timeout)
            return stdout or default, stderr or default, proc.returncode


def _patch_popen():
    from yt_dlp.utils import _utils

    original = _utils.Popen
    for name, module in list(sys.modules.items()):
        if module is None or not (name == 'yt_dlp' or name.startswith('yt_dlp.')):
            continue
        try:
            if getattr(module, 'Popen', None) is original:
                module.Popen = _InProcessPopen
        except Exception:
            pass
    _utils.Popen = _InProcessPopen


# -- loading yt-dlp ------------------------------------------------------------


def _unload():
    for name in list(sys.modules):
        if name.split('.')[0] in ('yt_dlp', 'yt_dlp_ejs'):
            del sys.modules[name]
    for path in _zips.values():
        if path is None:
            continue
        while path in sys.path:
            sys.path.remove(path)
        sys.path_importer_cache.pop(path, None)
        getattr(zipimport, '_zip_directory_cache', {}).pop(path, None)
    importlib.invalidate_caches()


def _load():
    """Imports yt-dlp: the updated zipapp when it works, else the bundled one."""
    failure = None
    for key in ('update', 'bundled'):
        path = _zips[key]
        if path is None or not os.path.isfile(path):
            continue
        _unload()
        sys.path.insert(0, path)
        try:
            import yt_dlp  # noqa: F401
            from yt_dlp.version import __version__

            _patch_popen()
            return __version__
        except Exception as error:
            failure = error
    _unload()
    raise RuntimeError(f'yt-dlp could not be loaded: {failure}')


def init(bundled_zip, update_zip):
    """Loads yt-dlp. Returns its version."""
    _zips['bundled'] = bundled_zip
    _zips['update'] = update_zip
    return _load()


def reload():
    """Reloads yt-dlp after an update replaced the zipapp. Returns its version."""
    return _load()


# -- jobs ----------------------------------------------------------------------


def _run(job_id, argv, out, err):
    """Runs yt-dlp's CLI entry point and returns its exit status."""
    import yt_dlp

    with _lock:
        if job_id is not None and job_id in _cancelled:
            raise JobCancelled()
        if job_id is not None:
            _threads[job_id] = threading.get_ident()
    _local.job_id, _local.out, _local.err = job_id, out, err
    try:
        try:
            yt_dlp.main(argv)
            return 0
        except SystemExit as exit_:
            return exit_.code
    finally:
        with _lock:
            _threads.pop(job_id, None)
        _local.job_id = _local.out = _local.err = None
        # A cancel that arrived as the job ended must not hit the next call.
        _mdengine.async_raise(threading.get_ident(), None)


def _failure(status, err):
    message = err.value()
    if isinstance(status, str):
        message += status
    message = message.strip() or f'yt-dlp exited with code {status}'
    return message[-_ERROR_TAIL:]


def probe(argv_json):
    """`yt-dlp -J`: returns its stdout (the JSON)."""
    out, err = _Capture(), _Capture()
    status = _run(None, json.loads(argv_json), out, err)
    if status not in (0, None):
        raise RuntimeError(_failure(status, err))
    return out.value()


def download(job_id, argv_json):
    """Runs a download; stdout lines go to Swift as they come. Returns
    {"result": "done" | "error" | "cancelled", "message": ...} as JSON."""
    out, err = _Capture(job_id), _Capture()
    status = None
    try:
        try:
            status = _run(job_id, json.loads(argv_json), out, err)
        finally:
            out.close()
    except JobCancelled:
        pass
    with _lock:
        cancelled = job_id in _cancelled
        _cancelled.discard(job_id)
    if cancelled:
        return json.dumps({'result': 'cancelled', 'message': ''})
    if status in (0, None):
        return json.dumps({'result': 'done', 'message': ''})
    return json.dumps({'result': 'error', 'message': _failure(status, err)})


def cancel(job_id):
    """Stops [job_id]: raises JobCancelled in its thread. Returns "true" when it
    was running."""
    with _lock:
        _cancelled.add(job_id)
        ident = _threads.get(job_id)
        if ident is not None:
            _mdengine.async_raise(ident, JobCancelled)
    return 'true' if ident is not None else 'false'
