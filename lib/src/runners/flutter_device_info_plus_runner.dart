import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart'
    as core;
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

import '../mappers/device_info_mapper.dart';

class FlutterDeviceInfoPlusRunner implements core.DeviceInfoRunner {
  final FlutterDeviceInfoPlus _deviceInfo;

  FlutterDeviceInfoPlusRunner({FlutterDeviceInfoPlus? deviceInfo})
    : _deviceInfo = deviceInfo ?? FlutterDeviceInfoPlus();

  @override
  Future<core.DeviceInformation> getDeviceInfo() async {
    try {
      final pluginInfo = await _deviceInfo.getDeviceInfo();
      // ignore: avoid_print
      print("PLUGIN systemVersion=${pluginInfo.systemVersion}");
      return DeviceInfoMapper.toCore(pluginInfo);
    } catch (e, st) {
      // ignore: avoid_print
      print("DEVICE INFO PLUGIN FAILED: $e\n$st");
      rethrow; // keep rethrow while debugging to see origin
    }
  }
}
