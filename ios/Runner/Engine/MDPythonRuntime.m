#import "MDPythonRuntime.h"

#import "MDFFmpeg.h"

#define PY_SSIZE_T_CLEAN
#include <Python/Python.h>

static MDLineHandler lineHandler;

#pragma mark - _mdengine: native functions the shim calls

// _mdengine.emit(job_id, line): one stdout line of a yt-dlp job.
static PyObject *md_emit(PyObject *self, PyObject *args) {
  const char *jobId;
  const char *line;
  if (!PyArg_ParseTuple(args, "ss", &jobId, &line)) {
    return NULL;
  }
  MDLineHandler handler = lineHandler;
  if (handler != nil) {
    @autoreleasepool {
      handler(@(jobId), @(line) ?: @"");
    }
  }
  Py_RETURN_NONE;
}

// _mdengine.ffmpeg(job_id, args, probe) -> (returncode, output, stdout):
// runs ffmpeg / ffprobe in-process without holding the GIL.
static PyObject *md_ffmpeg(PyObject *self, PyObject *args) {
  const char *jobId;
  PyObject *list;
  int probe;
  if (!PyArg_ParseTuple(args, "sO!p", &jobId, &PyList_Type, &list, &probe)) {
    return NULL;
  }
  @autoreleasepool {
    NSMutableArray<NSString *> *arguments = [NSMutableArray array];
    for (Py_ssize_t i = 0; i < PyList_Size(list); i++) {
      const char *item = PyUnicode_AsUTF8(PyList_GetItem(list, i));
      if (item == NULL) {
        return NULL;
      }
      [arguments addObject:@(item)];
    }
    NSString *job = strlen(jobId) > 0 ? @(jobId) : nil;
    NSString *output = nil;
    NSString *printed = nil;
    int code;
    Py_BEGIN_ALLOW_THREADS
    code = [MDFFmpeg runSyncWithArguments:arguments probe:probe jobId:job output:&output stdoutText:&printed];
    Py_END_ALLOW_THREADS
    return Py_BuildValue("iss", code, (output ?: @"").UTF8String, (printed ?: @"").UTF8String);
  }
}

// _mdengine.async_raise(thread_id, exc_type or None) -> int: raises (or
// clears) an exception in another Python thread; how a yt-dlp job is cancelled.
static PyObject *md_async_raise(PyObject *self, PyObject *args) {
  unsigned long threadId;
  PyObject *exception;
  if (!PyArg_ParseTuple(args, "kO", &threadId, &exception)) {
    return NULL;
  }
  int count = PyThreadState_SetAsyncExc(threadId, exception == Py_None ? NULL : exception);
  return PyLong_FromLong(count);
}

static PyMethodDef mdEngineMethods[] = {
    {"emit", md_emit, METH_VARARGS, NULL},
    {"ffmpeg", md_ffmpeg, METH_VARARGS, NULL},
    {"async_raise", md_async_raise, METH_VARARGS, NULL},
    {NULL, NULL, 0, NULL},
};

static struct PyModuleDef mdEngineModule = {PyModuleDef_HEAD_INIT, "_mdengine", NULL, -1, mdEngineMethods};

static PyObject *PyInit__mdengine(void) {
  return PyModule_Create(&mdEngineModule);
}

#pragma mark - Runtime

@implementation MDPythonRuntime

static BOOL attempted = NO;
static NSString *startError = nil;

+ (BOOL)isStarted {
  @synchronized(self) {
    return attempted && startError == nil;
  }
}

+ (BOOL)startWithHome:(NSString *)home
                paths:(NSArray<NSString *> *)paths
          lineHandler:(MDLineHandler)handler
                error:(NSString **)error {
  @synchronized(self) {
    if (!attempted) {
      attempted = YES;
      lineHandler = [handler copy];
      startError = [self initializeWithHome:home paths:paths];
    }
    if (startError != nil && error != NULL) {
      *error = startError;
    }
    return startError == nil;
  }
}

/// Returns nil on success, else what went wrong.
+ (NSString *)initializeWithHome:(NSString *)home paths:(NSArray<NSString *> *)paths {
  if (PyImport_AppendInittab("_mdengine", PyInit__mdengine) == -1) {
    return @"Could not register _mdengine";
  }

  PyPreConfig preConfig;
  PyPreConfig_InitIsolatedConfig(&preConfig);
  preConfig.utf8_mode = 1;
  PyStatus status = Py_PreInitialize(&preConfig);
  if (PyStatus_Exception(status)) {
    return [NSString stringWithFormat:@"Python pre-init failed: %s", status.err_msg];
  }

  PyConfig config;
  PyConfig_InitIsolatedConfig(&config);
  config.buffered_stdio = 0;
  config.write_bytecode = 0;
  // The app owns signals; Python must not install a SIGINT handler.
  config.install_signal_handlers = 0;
  status = PyConfig_SetBytesString(&config, &config.home, home.fileSystemRepresentation);
  if (!PyStatus_Exception(status)) {
    status = Py_InitializeFromConfig(&config);
  }
  PyConfig_Clear(&config);
  if (PyStatus_Exception(status)) {
    return [NSString stringWithFormat:@"Python init failed: %s", status.err_msg];
  }

  NSString *failure = nil;
  PyObject *site = PyImport_ImportModule("site");
  PyObject *addSiteDir = site != NULL ? PyObject_GetAttrString(site, "addsitedir") : NULL;
  if (addSiteDir == NULL) {
    failure = [self takeException] ?: @"Could not load site";
  } else {
    for (NSString *path in paths) {
      PyObject *result = PyObject_CallFunction(addSiteDir, "s", path.fileSystemRepresentation);
      if (result == NULL) {
        failure = [self takeException];
        break;
      }
      Py_DECREF(result);
    }
  }
  Py_XDECREF(addSiteDir);
  Py_XDECREF(site);

  // Every later call takes the GIL with PyGILState_Ensure on its own thread.
  PyEval_SaveThread();
  return failure;
}

+ (NSString *)call:(NSString *)function arguments:(NSArray<NSString *> *)arguments error:(NSString **)error {
  if (![self isStarted]) {
    if (error != NULL) {
      *error = startError ?: @"Python is not running";
    }
    return nil;
  }
  NSString *value = nil;
  NSString *failure = nil;
  PyGILState_STATE gil = PyGILState_Ensure();
  PyObject *module = PyImport_ImportModule("engine_shim");
  PyObject *callable = module != NULL ? PyObject_GetAttrString(module, function.UTF8String) : NULL;
  if (callable == NULL) {
    failure = [self takeException];
  } else {
    PyObject *tuple = PyTuple_New((Py_ssize_t)arguments.count);
    for (NSUInteger i = 0; i < arguments.count; i++) {
      PyTuple_SET_ITEM(tuple, (Py_ssize_t)i, PyUnicode_FromString(arguments[i].UTF8String));
    }
    PyObject *result = PyObject_CallObject(callable, tuple);
    Py_DECREF(tuple);
    if (result == NULL) {
      failure = [self takeException];
    } else {
      PyObject *text = PyObject_Str(result);
      const char *utf8 = text != NULL ? PyUnicode_AsUTF8(text) : NULL;
      if (utf8 != NULL) {
        value = @(utf8);
      } else {
        failure = [self takeException];
      }
      Py_XDECREF(text);
      Py_DECREF(result);
    }
  }
  Py_XDECREF(callable);
  Py_XDECREF(module);
  PyGILState_Release(gil);
  if (failure != nil && error != NULL) {
    *error = failure;
  }
  return failure == nil ? value : nil;
}

/// The pending Python exception as text (and clears it). Needs the GIL.
+ (NSString *)takeException {
  PyObject *exception = PyErr_GetRaisedException();
  if (exception == NULL) {
    return nil;
  }
  NSString *message = @"Python error";
  PyObject *text = PyObject_Str(exception);
  const char *utf8 = text != NULL ? PyUnicode_AsUTF8(text) : NULL;
  if (utf8 != NULL && strlen(utf8) > 0) {
    message = @(utf8);
  } else {
    message = @(Py_TYPE(exception)->tp_name);
  }
  PyErr_Clear();
  Py_XDECREF(text);
  Py_DECREF(exception);
  return message;
}

@end
