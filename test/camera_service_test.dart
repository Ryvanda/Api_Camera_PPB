import 'package:flutter_test/flutter_test.dart';
import 'package:camera_api/services/camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraService tests', () {
    test('CameraService singleton returns same instance', () {
      final service1 = CameraService.instance;
      final service2 = CameraService.instance;
      expect(identical(service1, service2), isTrue);
    });

    test('Initial state before hardware discovery has expected defaults', () {
      final service = CameraService.instance;
      expect(service.cameras, isEmpty);
      expect(service.hasCameras, isFalse);
      expect(service.hasMultipleCameras, isFalse);
      expect(service.defaultCamera, isNull);
    });
  });
}

