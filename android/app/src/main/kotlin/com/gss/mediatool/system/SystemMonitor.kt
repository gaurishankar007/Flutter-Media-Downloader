package com.gss.mediatool.system

import android.app.ActivityManager
import android.content.Context
import android.net.TrafficStats
import android.os.SystemClock

/**
 * RAM (ActivityManager.MemoryInfo) and whole-device network traffic
 * (TrafficStats). Android hides CPU (/proc/stat) and GPU load from apps, so
 * those are never reported. Raw counters only; Dart computes rates.
 */
class SystemMonitor(context: Context) : SystemMonitorHostApi {
    private val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

    override fun capabilities(): SystemCapabilitiesMsg = SystemCapabilitiesMsg(
        memory = true,
        cpu = false,
        gpu = false,
        network = networkSupported(),
    )

    override fun sample(): SystemSampleMsg {
        val memory = ActivityManager.MemoryInfo().also(activityManager::getMemoryInfo)
        val network = networkSupported()
        return SystemSampleMsg(
            uptimeMillis = SystemClock.elapsedRealtime(),
            memoryUsedBytes = memory.totalMem - memory.availMem,
            memoryTotalBytes = memory.totalMem,
            networkRxBytes = if (network) TrafficStats.getTotalRxBytes() else null,
            networkTxBytes = if (network) TrafficStats.getTotalTxBytes() else null,
        )
    }

    private fun networkSupported(): Boolean =
        TrafficStats.getTotalRxBytes() != TrafficStats.UNSUPPORTED.toLong() &&
            TrafficStats.getTotalTxBytes() != TrafficStats.UNSUPPORTED.toLong()
}
