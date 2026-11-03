import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/camera_service.dart';
import 'camera_screen.dart';
import 'preview_screen.dart';

/// Main landing interface providing the entry point to access the camera,
/// review permission status, and inspect the most recently captured photo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _capturedImage;
  int _imageSizeBytes = 0;
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final CameraService service = CameraService.instance;
    if (!service.isInitialized) {
      await service.initializeCameras();
    }
  }

  Future<void> _handleLaunchCamera() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final CameraService service = CameraService.instance;
    if (!service.isInitialized) {
      await service.initializeCameras();
    }

    // Check camera permission
    final PermissionStatus status = await service.checkCameraPermission();

    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
        _showPermanentlyDeniedDialog();
      }
      return;
    }

    if (!status.isGranted && !status.isLimited) {
      final PermissionStatus requestStatus =
          await service.requestCameraPermission();

      if (requestStatus.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _isCheckingPermission = false;
          });
          _showPermanentlyDeniedDialog();
        }
        return;
      }

      if (!requestStatus.isGranted && !requestStatus.isLimited) {
        if (mounted) {
          setState(() {
            _isCheckingPermission = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to capture photos.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingPermission = false;
      });
    }

    if (!mounted) return;

    // Navigate to Camera Screen
    final dynamic result = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute<XFile?>(
        builder: (context) => const CameraScreen(),
      ),
    );

    if (result != null && result is XFile) {
      int size = 0;
      try {
        size = await result.length();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _capturedImage = result;
        _imageSizeBytes = size;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured and saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPermanentlyDeniedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access has been permanently denied. Please enable camera permission in your system application settings to take photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _clearCapturedImage() {
    setState(() {
      _capturedImage = null;
      _imageSizeBytes = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo preview cleared.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _inspectPhoto() {
    if (_capturedImage == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PreviewScreen(
          imageFile: _capturedImage!,
          canRetake: false,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildThumbnail() {
    if (_capturedImage == null) return const SizedBox.shrink();

    if (kIsWeb) {
      return Image.network(
        _capturedImage!.path,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(_capturedImage!.path),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final CameraService service = CameraService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Camera API'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Information banner
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'System Overview',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This application implements the Flutter Camera API with lifecycle handling, multi-sensor switching, and full-resolution photo capture.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Detected Cameras:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            service.hasCameras
                                ? '${service.cameras.length} Sensor(s) Found'
                                : 'Searching hardware...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: service.hasCameras
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Captured Image section
              Text(
                'Captured Photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (_capturedImage == null)
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No photo captured yet',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Open Camera" below to capture your first photo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _inspectPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 240,
                              width: double.infinity,
                              color: Colors.black,
                              child: _buildThumbnail(),
                            ),
                            Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to expand',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capturedImage!.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Size: ${_formatFileSize(_imageSizeBytes)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _inspectPhoto,
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('View Full'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  onPressed: _clearCapturedImage,
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.redAccent,
                                  tooltip: 'Clear Photo',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Action button to launch camera
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _isCheckingPermission ? null : _handleLaunchCamera,
                  icon: _isCheckingPermission
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.photo_camera),
                  label: Text(
                    _isCheckingPermission
                        ? 'Verifying Permissions...'
                        : 'Open Camera',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
