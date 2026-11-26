package com.gss.mediadownloader.engine

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Runs yt-dlp (through youtubedl-android) and ffmpeg. Arguments come from Dart
 * (YtDlpArgsBuilder / FfmpegCommandBuilder); this class only runs them and
 * forwards each stdout line. See docs/engine/android_engine.md.
 */
class MediaEngine(context: Context) : MediaEngineHostApi, EngineEventsStreamHandler() {
    private val appContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val ffmpegProcesses = ConcurrentHashMap<String, Process>()
    private val cancelledJobs = ConcurrentHashMap.newKeySet<String>()

    @Volatile
    private var sink: PigeonEventSink<EngineEventMsg>? = null

    @Volatile
    private var encoders: List<String>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<EngineEventMsg>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    override suspend fun init(): EngineInfoMsg = withContext(Dispatchers.IO) {
        YoutubeDL.getInstance().init(appContext)
        FFmpeg.getInstance().init(appContext)
        val found = encoders ?: readEncoders().also { encoders = it }
        EngineInfoMsg(ytDlpVersion = YoutubeDL.getInstance().versionName(appContext) ?: "", encoders = found)
    }

    override suspend fun probe(args: List<String>): String = withContext(Dispatchers.IO) {
        YoutubeDL.getInstance().execute(request(args)).out
    }

    override fun startDownload(jobId: String, args: List<String>) {
        scope.launch {
            try {
                YoutubeDL.getInstance().execute(request(args), jobId) { _, _, line -> emit(jobId, EngineEventKind.LINE, line) }
                emit(jobId, EngineEventKind.DONE, "")
            } catch (_: YoutubeDL.CanceledException) {
                emit(jobId, EngineEventKind.CANCELLED, "")
            } catch (error: Exception) {
                val kind = if (cancelledJobs.remove(jobId)) EngineEventKind.CANCELLED else EngineEventKind.ERROR
                emit(jobId, kind, error.message ?: error.toString())
            }
        }
    }

    override fun startFfmpeg(jobId: String, args: List<String>) {
        scope.launch {
            try {
                val process = ffmpegProcess(ffmpegBinary(), args)
                ffmpegProcesses[jobId] = process
                // stderr is drained on its own thread so a full pipe never blocks ffmpeg.
                val stderr = StringBuilder()
                val errReader = Thread { process.errorStream.bufferedReader().forEachLine { stderr.appendLine(it) } }
                errReader.start()
                process.inputStream.bufferedReader().forEachLine { emit(jobId, EngineEventKind.LINE, it) }
                val exitCode = process.waitFor()
                errReader.join()
                ffmpegProcesses.remove(jobId)
                when {
                    cancelledJobs.remove(jobId) -> emit(jobId, EngineEventKind.CANCELLED, "")
                    exitCode == 0 -> emit(jobId, EngineEventKind.DONE, "")
                    else -> emit(jobId, EngineEventKind.ERROR, stderr.toString().takeLast(4000))
                }
            } catch (error: Exception) {
                ffmpegProcesses.remove(jobId)
                emit(jobId, EngineEventKind.ERROR, error.message ?: error.toString())
            }
        }
    }

    override fun cancel(jobId: String): Boolean {
        ffmpegProcesses[jobId]?.let {
            cancelledJobs.add(jobId)
            it.destroy()
            return true
        }
        val stopped = YoutubeDL.getInstance().destroyProcessById(jobId)
        if (stopped) cancelledJobs.add(jobId)
        return stopped
    }

    override suspend fun updateYtDlp(): String = withContext(Dispatchers.IO) {
        YoutubeDL.getInstance().updateYoutubeDL(appContext, YoutubeDL.UpdateChannel.STABLE)
        YoutubeDL.getInstance().versionName(appContext) ?: ""
    }

    private fun request(args: List<String>) = YoutubeDLRequest(emptyList()).addCommands(args)

    private fun emit(jobId: String, kind: EngineEventKind, payload: String) {
        val event = EngineEventMsg(jobId = jobId, kind = kind, payload = payload)
        mainHandler.post { sink?.success(event) }
    }

    private fun readEncoders(): List<String> = try {
        val process = ffmpegProcess(ffmpegBinary(), listOf("-hide_banner", "-encoders"))
        val output = process.inputStream.bufferedReader().readText()
        process.waitFor()
        // Lines look like " V....D libx264  libx264 H.264 ...": keep video encoder names.
        output.lines()
            .map { it.trim() }
            .filter { it.length > 7 && it[0] == 'V' && it[6] == ' ' }
            .map { it.substring(7).trim().substringBefore(' ') }
    } catch (_: Exception) {
        emptyList()
    }

    private fun ffmpegBinary() = File(appContext.applicationInfo.nativeLibraryDir, "libffmpeg.so")

    private fun ffmpegProcess(binary: File, args: List<String>): Process {
        // Same layout youtubedl-android's FFmpeg.init unpacks to.
        val libDir = File(appContext.noBackupFilesDir, "youtubedl-android/packages/ffmpeg/usr/lib")
        val builder = ProcessBuilder(listOf(binary.absolutePath) + args)
        builder.environment()["LD_LIBRARY_PATH"] = libDir.absolutePath
        builder.environment()["TMPDIR"] = appContext.cacheDir.absolutePath
        return builder.start()
    }
}
