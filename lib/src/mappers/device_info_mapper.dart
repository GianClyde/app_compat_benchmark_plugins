import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart'
    as core;
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart'
    as plugin;

/// Maps flutter_device_info_plus model → core DeviceInformation
class DeviceInfoMapper {
  static core.DeviceInformation toCore(plugin.DeviceInformation pluginInfo) {
    final osVersion = _parseOsVersion(pluginInfo.systemVersion);

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

  static double _parseOsVersion(String raw) {
    final parts = raw.trim().split('.');
    if (parts.isEmpty) return 0;

    final major = double.tryParse(parts[0]) ?? 0;
    final minor = parts.length > 1 ? double.tryParse(parts[1]) ?? 0 : 0;

    return double.parse('$major.$minor');
  }
}
