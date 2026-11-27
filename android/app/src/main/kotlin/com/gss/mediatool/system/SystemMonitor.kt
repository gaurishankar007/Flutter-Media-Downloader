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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * RAM (ActivityManager.MemoryInfo), whole-device network traffic
 * (TrafficStats), storage (StatFs on the app's files dir) and battery (the
 * sticky ACTION_BATTERY_CHANGED intent; no permission). Android hides CPU
 * (/proc/stat) and GPU load from apps, so those are never reported. Raw
 * counters only; Dart computes rates. Hardware facts: the SoC name, core count
 * and clusters (grouped by each core's max clock in /sys). RAM type, GPU and
 * storage details aren't readable by apps.
 */
class SystemMonitor(context: Context) : SystemMonitorHostApi {
    private val appContext = context.applicationContext
    private val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    private val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager

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
        val levelPercent = level * 100.0 / scale
        return SystemBatteryMsg(
            levelPercent = levelPercent,
            state = state,
            temperatureCelsius = if (temperature != Int.MIN_VALUE && temperature != 0) temperature / 10.0 else null,
            health = health,
            cycleCount = if (cycles >= 0) cycles.toLong() else null,
            remainingCapacityMah = remainingMah(levelPercent),
        )
    }

    override suspend fun hardware(): SystemHardwareMsg = withContext(Dispatchers.IO) {
        val cores = possibleCpuCount() ?: Runtime.getRuntime().availableProcessors()
        // kHz; some devices hide cpufreq, then there are no clusters.
        val maxFrequencies = (0 until cores).mapNotNull {
            readText("/sys/devices/system/cpu/cpu$it/cpufreq/cpuinfo_max_freq")?.toLongOrNull()
        }
        val clusters = if (maxFrequencies.size == cores) {
            maxFrequencies.groupingBy { it }.eachCount().toSortedMap(compareByDescending { it }).values.map(Int::toLong)
        } else {
            null
        }
        // ARM phone cores run one thread each, so threads equal cores.
        SystemHardwareMsg(
            cpuName = socName(),
            cpuCores = cores.toLong(),
            cpuThreads = cores.toLong(),
            cpuClusterCores = clusters?.takeIf { it.size > 1 },
            cpuMaxFrequencyMhz = maxFrequencies.maxOrNull()?.div(1000)?.takeIf { it > 0 },
        )
    }

    /// The fuel gauge's charge counter; 0 or Int.MIN_VALUE when the device doesn't report it.
    /// Android documents µAh, but some gauges (Xiaomi) report mAh: read as µAh, the whole
    /// battery would come out under 500 mAh, which no phone or tablet has.
    private fun remainingMah(levelPercent: Double): Long? {
        val raw = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER).toLong()
        if (raw <= 0) {
            return null
        }
        val fromMicro = raw / 1000L
        val impliedFullMah = fromMicro * 100 / levelPercent.coerceAtLeast(1.0)
        val mah = if (impliedFullMah < 500) raw else fromMicro
        return if (mah in 1..30_000) mah else null
    }

    /// "QTI SM8550" on Android 12+, else the board name ("mt6789").
    private fun socName(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val model = Build.SOC_MODEL.takeIf { it.isNotBlank() && it != Build.UNKNOWN }
            val maker = Build.SOC_MANUFACTURER.takeIf { it.isNotBlank() && it != Build.UNKNOWN }
            if (model != null) {
                return listOfNotNull(maker, model).joinToString(" ")
            }
        }
        return Build.HARDWARE.takeIf { it.isNotBlank() && it != Build.UNKNOWN }
    }

    /// Counts "0-7" or "0-3,4-7" from /sys/devices/system/cpu/possible (includes cores that are offline now).
    private fun possibleCpuCount(): Int? {
        val text = readText("/sys/devices/system/cpu/possible") ?: return null
        val count = text.split(',').sumOf { range ->
            val bounds = range.split('-').mapNotNull { it.trim().toIntOrNull() }
            when (bounds.size) {
                1 -> 1
                2 -> bounds[1] - bounds[0] + 1
                else -> return null
            }
        }
        return count.takeIf { it > 0 }
    }

    private fun readText(path: String): String? = runCatching { File(path).readText().trim() }.getOrNull()

    private fun networkSupported(): Boolean =
        TrafficStats.getTotalRxBytes() != TrafficStats.UNSUPPORTED.toLong() &&
            TrafficStats.getTotalTxBytes() != TrafficStats.UNSUPPORTED.toLong()
}
