package com.gss.mediatool.background

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground service (`dataSync`) that keeps the process alive while
 * downloads run, with one notification: the active job's title, percent and
 * a Cancel action. Dart starts, updates and stops it through
 * [BackgroundWork]. See docs/engine/android_engine.md#running-in-the-background.
 */
class DownloadService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CANCEL -> intent.getStringExtra(EXTRA_JOB_ID)?.let { jobId -> onCancel?.invoke(jobId) }
            else -> {
                val work = current
                if (work == null) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                ensureChannel(this)
                ServiceCompat.startForeground(
                    this,
                    NOTIFICATION_ID,
                    buildNotification(this, work),
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC else 0,
                )
                running = true
            }
        }
        // Dart restarts the service if work is still active; never revive it on its own.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        super.onDestroy()
    }

    // The system stops dataSync services after their daily limit (Android 15+).
    override fun onTimeout(startId: Int, fgsType: Int) {
        stopSelf()
    }

    companion object {
        private const val CHANNEL_ID = "downloads"
        private const val NOTIFICATION_ID = 7001
        private const val ACTION_CANCEL = "com.gss.mediatool.CANCEL_JOB"
        private const val EXTRA_JOB_ID = "jobId"

        @Volatile
        var current: BackgroundWorkMsg? = null

        @Volatile
        var running = false

        /** Set by [BackgroundWork]: forwards the notification's Cancel to Dart. */
        @Volatile
        var onCancel: ((String) -> Unit)? = null

        /** Re-posts the notification of a running service. */
        fun refresh(context: Context, work: BackgroundWorkMsg) {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            ensureChannel(context)
            manager.notify(NOTIFICATION_ID, buildNotification(context, work))
        }

        private fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                return
            }
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(CHANNEL_ID, "Downloads", NotificationManager.IMPORTANCE_LOW).apply {
                        description = "Progress of running downloads"
                        setShowBadge(false)
                    },
                )
            }
        }

        private fun buildNotification(context: Context, work: BackgroundWorkMsg): Notification {
            val openApp = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
                PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            }
            val cancel = PendingIntent.getService(
                context,
                1,
                Intent(context, DownloadService::class.java).setAction(ACTION_CANCEL).putExtra(EXTRA_JOB_ID, work.jobId),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val percent = work.percent?.toInt()
            val others = (work.activeCount - 1).toInt()
            val text = listOfNotNull(
                percent?.let { "$it%" },
                if (others > 0) "+$others more" else null,
            ).joinToString(" · ")
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(work.title)
                .setContentText(text.ifEmpty { "Downloading…" })
                .setProgress(100, percent ?: 0, percent == null)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_PROGRESS)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .setContentIntent(openApp)
                .addAction(0, "Cancel", cancel)
                .build()
        }
    }
}
