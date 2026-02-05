import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart'
    as core;
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart'
    as plugin;

/// Maps flutter_device_info_plus model → core DeviceInformation
class DeviceInfoMapper {
  static core.DeviceInformation toCore(plugin.DeviceInformation pluginInfo) {
    final osVersion = parseOsVersion(pluginInfo.systemVersion);

    return core.DeviceInformation(
      osVersion: osVersion,
      cpuArchitecture: pluginInfo.processorInfo.architecture,
      cpuCores: pluginInfo.processorInfo.coreCount,
      cpuMaxFrequencyMhz: pluginInfo.processorInfo.maxFrequency,
      availableRamGb: pluginInfo.memoryInfo.availablePhysicalMemoryMB / 1024.0,
      availableStorageGb: pluginInfo.memoryInfo.availableStorageSpaceGB
          .toDouble(),
    );
  }

  static double parseOsVersion(String raw) {
    // Handles: "14", "14.0", "14.0.0", "Android 14", "14 (QPR2)" etc.
    final text = raw.trim();

    // Extract first numeric version like 14, 14.0, 14.0.0
    final match = RegExp(r'(\d+)(?:\.(\d+))?(?:\.(\d+))?').firstMatch(text);
    if (match == null) return 0;

    final major = int.tryParse(match.group(1) ?? '') ?? 0;
    final minor = int.tryParse(match.group(2) ?? '') ?? 0;
    final patch = int.tryParse(match.group(3) ?? '') ?? 0;

    // Convert to a comparable double, preserving minor/patch ordering
    // Example: 14.0.0 -> 14.0000, 14.1.2 -> 14.0102
    return major + (minor / 100.0) + (patch / 10000.0);
  }
}
