import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/camera_service.dart';
import 'preview_screen.dart';

/// Camera capture view providing full preview, camera sensor switching,
/// flash control, lifecycle resilience, and error state recovery.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _selectedCameraIndex = 0;

  bool _isInitializing = true;
  bool _isTakingPicture = false;
  String? _errorMessage;

  FlashMode _currentFlashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // Do nothing if controller is not present or not initialized.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free camera hardware when app is paused/backgrounded.
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-acquire camera hardware on resume.
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _setupCameras() async {
    final CameraService service = CameraService.instance;
    if (!service.isInitialized || !service.hasCameras) {
      await service.initializeCameras();
    }

    _cameras = service.cameras;

    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'No camera hardware detected on this device. If using an emulator, please enable virtual camera in AVD settings.';
        });
      }
      return;
    }

    // Default to the first back camera or the first available sensor.
    int initialIndex = 0;
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        initialIndex = i;
        break;
      }
    }

    _selectedCameraIndex = initialIndex;
    await _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController? oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }

    final CameraController newController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    if (mounted) {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
    }

    try {
      await newController.initialize();
      try {
        await newController.setFlashMode(_currentFlashMode);
      } catch (_) {
        // Flash mode may not be supported on all front sensors.
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } on CameraException catch (e) {
      _handleCameraException(e);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  void _handleCameraException(CameraException e) {
    String message = 'An unexpected camera error occurred: ${e.code}';
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        message = 'Camera permission was denied. Please grant permission in App Settings.';
        break;
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        message = 'Audio permission was denied.';
        break;
      default:
        message = 'Camera initialization failed (${e.code}): ${e.description ?? 'Unknown reason'}';
        break;
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _errorMessage = message;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1 || _isTakingPicture || _isInitializing) {
      return;
    }

    final int nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _selectedCameraIndex = nextIndex;
    });

    await _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlashMode() async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await controller.setFlashMode(nextMode);
      if (mounted) {
        setState(() {
          _currentFlashMode = nextMode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash mode set to ${_flashModeToString(nextMode)}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash mode not supported on current camera sensor.'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _flashModeToString(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'On';
      case FlashMode.off:
        return 'Off';
      case FlashMode.torch:
        return 'Torch';
    }
  }

  IconData _flashModeIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  Future<void> _takePicture() async {
    final CameraController? controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile photo = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _isTakingPicture = false;
      });

      // Navigate to the preview screen
      final dynamic result = await Navigator.of(context).push<XFile?>(
        MaterialPageRoute<XFile?>(
          builder: (context) => PreviewScreen(imageFile: photo),
        ),
      );

      // If the user tapped 'Keep Photo', return the file to the caller
      if (result != null && result is XFile && mounted) {
        Navigator.of(context).pop(result);
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: ${e.code} - ${e.description}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error during capture: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildCameraPreview() {
    final CameraController? controller = _controller;

    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Initialization Error',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_errorMessage!.contains('permission')) {
                        openAppSettings();
                      } else {
                        _setupCameras();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(_errorMessage!.contains('permission')
                        ? 'Open Settings'
                        : 'Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera is not ready.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ClipRect(
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentLensName = _cameras.isNotEmpty &&
            _selectedCameraIndex < _cameras.length
        ? (_cameras[_selectedCameraIndex].lensDirection ==
                CameraLensDirection.front
            ? 'Front Camera'
            : 'Rear Camera')
        : 'Camera';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full camera viewfinder area
            Positioned.fill(
              child: _buildCameraPreview(),
            ),

            // Top control bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        currentLensName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _flashModeIcon(_currentFlashMode),
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlashMode,
                      tooltip: 'Toggle Flash',
                    ),
                  ],
                ),
              ),
            ),

            // Bottom control bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Switch camera button
                    IconButton(
                      iconSize: 32,
                      icon: Icon(
                        Icons.flip_camera_ios,
                        color: _cameras.length > 1
                            ? Colors.white
                            : Colors.white24,
                      ),
                      onPressed: _cameras.length > 1 ? _switchCamera : null,
                      tooltip: 'Switch Camera',
                    ),

                    // Shutter Capture Button
                    GestureDetector(
                      onTap: (_isInitializing || _isTakingPicture)
                          ? null
                          : _takePicture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: _isTakingPicture
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Spacer/alignment placeholder
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
