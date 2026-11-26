package com.example.media_downloader.background

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Starts, updates and stops [DownloadService] for Dart. */
class BackgroundWork(context: Context, messenger: BinaryMessenger) : BackgroundWorkHostApi {
    private val appContext = context.applicationContext
    private val flutterApi = BackgroundWorkFlutterApi(messenger)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        DownloadService.onCancel = { jobId ->
            mainHandler.post {
                scope.launch { runCatching { flutterApi.cancelRequested(jobId) } }
            }
        }
    }

    override fun update(work: BackgroundWorkMsg) {
        DownloadService.current = work
        if (DownloadService.running) {
            DownloadService.refresh(appContext, work)
            return
        }
        try {
            ContextCompat.startForegroundService(appContext, Intent(appContext, DownloadService::class.java))
        } catch (_: IllegalStateException) {
            // Android 12+ refuses to start it from the background; downloads still
            // run while the process lives, only without the notification.
        }
    }

    override fun stop() {
        DownloadService.current = null
        appContext.stopService(Intent(appContext, DownloadService::class.java))
    }
}
