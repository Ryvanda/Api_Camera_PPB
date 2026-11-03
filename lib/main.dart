import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/camera_service.dart';

Future<void> main() async {
  // Ensure Flutter engine binding is initialized before accessing native channels.
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent camera viewfinder experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Discover and cache available camera hardware early during app bootstrap.
  try {
    await CameraService.instance.initializeCameras();
  } catch (e) {
    debugPrint('[main] Camera initialization encountered an error: $e');
  }

  runApp(const CameraApiApp());
}

/// Root widget of the Camera API application.
class CameraApiApp extends StatelessWidget {
  const CameraApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandSeedColor = Color(0xFF1E88E5);

    return MaterialApp(
      title: 'Camera API',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandSeedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandSeedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
