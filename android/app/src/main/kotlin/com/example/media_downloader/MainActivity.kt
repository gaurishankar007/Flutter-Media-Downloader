package com.example.media_downloader

import android.content.Intent
import com.example.media_downloader.background.BackgroundWork
import com.example.media_downloader.background.BackgroundWorkHostApi
import com.example.media_downloader.engine.EngineEventsStreamHandler
import com.example.media_downloader.engine.MediaEngine
import com.example.media_downloader.engine.MediaEngineHostApi
import com.example.media_downloader.export.FileExportHostApi
import com.example.media_downloader.export.FileExporter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var fileExporter: FileExporter? = null
    private var backgroundWork: BackgroundWork? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val engine = MediaEngine(this)
        MediaEngineHostApi.setUp(messenger, engine)
        EngineEventsStreamHandler.register(messenger, engine)
        val work = BackgroundWork(this, messenger).also { backgroundWork = it }
        BackgroundWorkHostApi.setUp(messenger, work)
        val exporter = FileExporter(this).also { fileExporter = it }
        FileExportHostApi.setUp(messenger, exporter)
        com.example.media_downloader.system.SystemMonitorHostApi.setUp(messenger, com.example.media_downloader.system.SystemMonitor(this))
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (fileExporter?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        // Without the activity the Dart side is gone too; nothing can update the notification.
        if (isFinishing) {
            backgroundWork?.stop()
        }
        super.onDestroy()
    }
}
