package com.gss.mediatool

import android.content.Intent
import com.gss.mediatool.background.BackgroundWork
import com.gss.mediatool.background.BackgroundWorkHostApi
import com.gss.mediatool.engine.EngineEventsStreamHandler
import com.gss.mediatool.engine.MediaEngine
import com.gss.mediatool.engine.MediaEngineHostApi
import com.gss.mediatool.export.FileExportHostApi
import com.gss.mediatool.export.FileExporter
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
        com.gss.mediatool.system.SystemMonitorHostApi.setUp(messenger, com.gss.mediatool.system.SystemMonitor(this))
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
