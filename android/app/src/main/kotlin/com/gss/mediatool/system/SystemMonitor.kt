package com.gss.mediatool.system

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.StatFs
import android.os.SystemClock

/**
 * RAM (ActivityManager.MemoryInfo), whole-device network traffic
 * (TrafficStats), storage (StatFs on the app's files dir) and battery (the
 * sticky ACTION_BATTERY_CHANGED intent; no permission). Android hides CPU
 * (/proc/stat) and GPU load from apps, so those are never reported. Raw
 * counters only; Dart computes rates.
 */
class SystemMonitor(context: Context) : SystemMonitorHostApi {
    private val appContext = context.applicationContext
    private val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

    override fun capabilities(): SystemCapabilitiesMsg = SystemCapabilitiesMsg(
        memory = true,
        cpu = false,
        gpu = false,
        network = networkSupported(),
        storage = storage().totalBytes != null,
        battery = battery().levelPercent != null,
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

    override fun storage(): SystemStorageMsg {
        val stats = runCatching { StatFs(appContext.filesDir.path) }.getOrNull()
            ?: return SystemStorageMsg()
        return SystemStorageMsg(totalBytes = stats.totalBytes, freeBytes = stats.availableBytes)
    }

    override fun battery(): SystemBatteryMsg {
        // A null receiver just reads the sticky intent; nothing stays registered.
        val intent = appContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val present = intent?.getBooleanExtra(BatteryManager.EXTRA_PRESENT, true) ?: false
        if (intent == null || !present || level < 0 || scale <= 0) {
            return SystemBatteryMsg(state = BatteryStateMsg.UNKNOWN)
        }
        val state = when (intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
            BatteryManager.BATTERY_STATUS_CHARGING -> BatteryStateMsg.CHARGING
            BatteryManager.BATTERY_STATUS_FULL -> BatteryStateMsg.FULL
            BatteryManager.BATTERY_STATUS_DISCHARGING -> BatteryStateMsg.DISCHARGING
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> BatteryStateMsg.NOT_CHARGING
            else -> BatteryStateMsg.UNKNOWN
        }
        val health = when (intent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)) {
            BatteryManager.BATTERY_HEALTH_GOOD -> BatteryHealthMsg.GOOD
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> BatteryHealthMsg.OVERHEAT
            BatteryManager.BATTERY_HEALTH_DEAD -> BatteryHealthMsg.DEAD
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> BatteryHealthMsg.OVER_VOLTAGE
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> BatteryHealthMsg.FAILURE
            BatteryManager.BATTERY_HEALTH_COLD -> BatteryHealthMsg.COLD
            else -> null
        }
        // Tenths of a degree Celsius; missing (Int.MIN_VALUE) or 0 means the device doesn't report it.
        val temperature = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
        // Android 14+; many devices still leave it out (-1). There's no public capacity-based health %.
        val cycles = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            intent.getIntExtra(BatteryManager.EXTRA_CYCLE_COUNT, -1)
        } else {
            -1
        }
        return SystemBatteryMsg(
            levelPercent = level * 100.0 / scale,
            state = state,
            temperatureCelsius = if (temperature != Int.MIN_VALUE && temperature != 0) temperature / 10.0 else null,
            health = health,
            cycleCount = if (cycles >= 0) cycles.toLong() else null,
        )
    }

    private fun networkSupported(): Boolean =
        TrafficStats.getTotalRxBytes() != TrafficStats.UNSUPPORTED.toLong() &&
            TrafficStats.getTotalTxBytes() != TrafficStats.UNSUPPORTED.toLong()
}
