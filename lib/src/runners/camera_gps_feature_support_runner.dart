import 'dart:io';

import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraGpsFeatureSupportRunner implements FeatureSupportRunner {
  const CameraGpsFeatureSupportRunner();

  @override
  Future<FeatureSuppResult> check(FeatureStepType step) async {
    switch (step) {
      case FeatureStepType.camera:
        return _checkCamera();
      case FeatureStepType.gps:
        return _checkLocation();
    }
  }

  Future<FeatureSuppResult> _checkCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return const FeatureSuppResult(
          stepType: FeatureStepType.camera,
          status: FeatureStatus.unsupported,
          message: "No camera found",
          incompatible: true,
        );
      }

      final permission = await Permission.camera.status;
      if (!permission.isGranted) {
        return const FeatureSuppResult(
          stepType: FeatureStepType.camera,
          status: FeatureStatus.permissionDenied,
          message: "Camera permission denied / not granted",
          incompatible: true,
        );
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.dispose();

      return const FeatureSuppResult(
        stepType: FeatureStepType.camera,
        status: FeatureStatus.ready,
        message: "Camera ready and supported",
      );
    } catch (e) {
      return FeatureSuppResult(
        stepType: FeatureStepType.camera,
        status: FeatureStatus.runtimeFailed,
        message: e.toString(),
        incompatible: true,
      );
    }
  }

  Future<FeatureSuppResult> _checkLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const FeatureSuppResult(
          stepType: FeatureStepType.gps,
          status: FeatureStatus.serviceDisabled,
          message: "Location service is disabled",
          incompatible: true,
        );
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const FeatureSuppResult(
          stepType: FeatureStepType.gps,
          status: FeatureStatus.permissionDenied,
          message: "Location permission denied / not granted",
          incompatible: true,
        );
      }

      final LocationSettings settings;
      if (Platform.isAndroid) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 3),
        );
      } else if (Platform.isIOS) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 3),
        );
      } else {
        settings = const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 3),
        );
      }

      await Geolocator.getCurrentPosition(locationSettings: settings);

      return const FeatureSuppResult(
        stepType: FeatureStepType.gps,
        status: FeatureStatus.ready,
        message: "Location ready and supported",
      );
    } catch (e) {
      return FeatureSuppResult(
        stepType: FeatureStepType.gps,
        status: FeatureStatus.runtimeFailed,
        message: e.toString(),
        incompatible: true,
      );
    }
  }
}
