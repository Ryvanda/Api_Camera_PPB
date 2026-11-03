import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for managing camera hardware discovery,
/// permission verification, and camera device lifecycle operations.
class CameraService {
  CameraService._internal();

  /// Singleton instance of [CameraService].
  static final CameraService instance = CameraService._internal();

  List<CameraDescription> _cameras = <CameraDescription>[];
  bool _isInitialized = false;

  /// Returns the unmodifiable list of available cameras on the device.
  List<CameraDescription> get cameras => List.unmodifiable(_cameras);

  /// Whether the camera hardware list has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether at least one camera is available on the device.
  bool get hasCameras => _cameras.isNotEmpty;

  /// Whether the device provides more than one camera sensor (e.g. front and rear).
  bool get hasMultipleCameras => _cameras.length > 1;

  /// Discovers and caches available cameras on the host device.
  Future<List<CameraDescription>> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      _isInitialized = true;
      debugPrint('[CameraService] Initialized ${_cameras.length} camera(s).');
      return _cameras;
    } on CameraException catch (e) {
      debugPrint('[CameraService] Failed to fetch cameras: ${e.code} - ${e.description}');
      _cameras = <CameraDescription>[];
      _isInitialized = true;
      return _cameras;
    } catch (e) {
      debugPrint('[CameraService] Unexpected error while fetching cameras: $e');
      _cameras = <CameraDescription>[];
      _isInitialized = true;
      return _cameras;
    }
  }

  /// Checks the current camera permission status.
  Future<PermissionStatus> checkCameraPermission() async {
    return Permission.camera.status;
  }

  /// Requests camera permission from the operating system.
  Future<PermissionStatus> requestCameraPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    debugPrint('[CameraService] Camera permission status: $status');
    return status;
  }

  /// Verifies whether camera access is currently permitted.
  Future<bool> hasPermission() async {
    final PermissionStatus status = await Permission.camera.status;
    return status.isGranted || status.isLimited;
  }

  /// Returns the first rear-facing camera, or the first available camera.
  CameraDescription? get defaultCamera {
    if (_cameras.isEmpty) {
      return null;
    }
    for (final CameraDescription camera in _cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return _cameras.first;
  }

  /// Returns the next camera description in the list for switching sensors.
  CameraDescription? getNextCamera(CameraDescription current) {
    if (_cameras.length <= 1) {
      return null;
    }
    final int currentIndex = _cameras.indexOf(current);
    if (currentIndex == -1) {
      return _cameras.first;
    }
    final int nextIndex = (currentIndex + 1) % _cameras.length;
    return _cameras[nextIndex];
  }

  /// Persists a captured [XFile] to application document storage.
  Future<File> saveImageToAppStorage(XFile capturedFile) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String targetPath = '${directory.path}/IMG_$timestamp.jpg';
    final File newImage = await File(capturedFile.path).copy(targetPath);
    debugPrint('[CameraService] Saved image to app storage: $targetPath');
    return newImage;
  }
}

