# Flutter Camera API Project

## 1. Overview
This project provides a production-grade Flutter application implementing device Camera hardware access, live viewfinder preview, multi-sensor switching (front and rear), flash control, and high-resolution photo capture according to academic mobile programming specifications.

The application adheres to idiomatic Flutter architecture, enforces separation of concerns across service and presentation layers, and incorporates lifecycle management to prevent native hardware resource leakage.

---

## 2. Key Features
- Dynamic camera hardware discovery and capability resolution.
- Live camera viewfinder using the official Flutter camera plugin.
- Camera switching between available rear and front lens directions.
- Flash mode toggling (Auto, On, Off).
- Immediate post-capture preview screen with metadata inspection (file name, file size, timestamp).
- User workflow options to Keep or Retake captured photos.
- App lifecycle awareness using WidgetsBindingObserver to safely release and re-acquire camera resources during app pause and resume events.
- Runtime permission verification and graceful error handling for denied access, missing hardware, or initialization exceptions.

---

## 3. Project Architecture and File Structure

```text
camera_api/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts           # Configured minSdk = 21
│   │   └── src/main/
│   │       └── AndroidManifest.xml    # CAMERA and hardware feature declarations
├── ios/
│   └── Runner/
│       └── Info.plist                 # NSCameraUsageDescription and NSMicrophoneUsageDescription
├── lib/
│   ├── main.dart                      # App bootstrap, orientation lock, Material 3 theme
│   ├── screens/
│   │   ├── camera_screen.dart         # Live camera preview, sensor switch, capture controls
│   │   ├── home_screen.dart           # Home dashboard, permission checks, photo summary card
│   │   └── preview_screen.dart        # Fullscreen photo display, metadata, Keep/Retake actions
│   └── services/
│       └── camera_service.dart        # Singleton service for camera hardware discovery & permissions
├── test/
│   ├── camera_service_test.dart       # Unit tests for CameraService
│   └── widget_test.dart               # Widget tests for HomeScreen rendering
├── pubspec.yaml                       # Dependencies: camera, permission_handler
└── README.md                          # Technical documentation and submission guide
```

---

## 4. Dependencies

The application utilizes official and community-standard plugins declared in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  camera: ^0.12.2
  permission_handler: ^13.0.2
```

---

## 5. Platform Configurations

### 5.1 Android Configuration

#### A. Permissions and Hardware Features (`android/app/src/main/AndroidManifest.xml`)
The following entries are configured inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

Setting `android:required="false"` ensures compatibility with emulators or devices without autofocus or flash hardware.

#### B. Minimum SDK Version (`android/app/build.gradle.kts`)
The camera plugin requires a minimum Android SDK level of 21:

```kotlin
defaultConfig {
    applicationId = "com.example.camera_api"
    minSdk = 21
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

---

### 5.2 iOS Configuration (`ios/Runner/Info.plist`)
Camera and microphone usage descriptions are configured in `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to take pictures.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for audio recording during video capture.</string>
```

---

## 6. Execution Instructions

### 6.1 Prerequisites
- Flutter SDK (version 3.19.0 or later, tested with Dart 3.x).
- Android SDK with platform-tools (adb) or Xcode (for macOS/iOS development).

### 6.2 Setup Steps
1. Fetch project dependencies:
   ```bash
   flutter pub get
   ```

2. Run static analysis to verify code quality:
   ```bash
   flutter analyze
   ```

3. Execute test suite:
   ```bash
   flutter test
   ```

### 6.3 Running on an Android Emulator
1. Open Android Virtual Device (AVD) Manager in Android Studio.
2. Ensure the virtual device camera is configured:
   - Edit AVD -> Advanced Settings -> Camera.
   - Set Front Camera to "Webcam0" or "Emulated".
   - Set Back Camera to "VirtualScene" or "Webcam0".
3. Launch the emulator:
   ```bash
   flutter emulators --launch <emulator_id>
   ```
4. Run the application:
   ```bash
   flutter run -d android
   ```

### 6.4 Running on a Physical Android Device
1. Enable Developer Options and USB Debugging on your device.
2. Connect the phone via USB and verify connection:
   ```bash
   adb devices
   ```
3. Run the application:
   ```bash
   flutter run -d <device_id>
   ```

---

## 7. Guidelines for Capturing Assignment Screenshots

For academic submission, capture the following 4 required verification screens:

1. **Screenshot 1: Home Screen (Initial State)**
   - Shows the application title "Flutter Camera API".
   - Shows the System Overview card displaying detected camera sensors.
   - Shows the empty state placeholder: "No photo captured yet".
   - Shows the "Open Camera" primary action button.

2. **Screenshot 2: Camera Viewfinder Screen**
   - Shows active camera preview feed.
   - Shows top control overlay with back button, current sensor badge ("Rear Camera"), and flash mode icon.
   - Shows bottom bar with switch camera icon and circular shutter button.

3. **Screenshot 3: Captured Photo Preview Screen**
   - Shows the captured photo in full view.
   - Shows capture details: image file name, file size in KB/MB.
   - Shows the "Retake" button and "Keep Photo" button.

4. **Screenshot 4: Home Screen (Post-Capture State)**
   - Shows the updated Home Screen with the newly captured photo card.
   - Displays thumbnail preview, file name, file size, "View Full" button, and delete icon button.

### How to Take Screenshots via Terminal (ADB)
```bash
# Capture and pull screenshot 1
adb shell screencap -p /sdcard/screenshot_01_home.png
adb pull /sdcard/screenshot_01_home.png ./screenshots/

# Capture and pull screenshot 2
adb shell screencap -p /sdcard/screenshot_02_camera.png
adb pull /sdcard/screenshot_02_camera.png ./screenshots/

# Capture and pull screenshot 3
adb shell screencap -p /sdcard/screenshot_03_preview.png
adb pull /sdcard/screenshot_03_preview.png ./screenshots/

# Capture and pull screenshot 4
adb shell screencap -p /sdcard/screenshot_04_home_result.png
adb pull /sdcard/screenshot_04_home_result.png ./screenshots/
```

---

## 8. Packaging and Submission Instructions

### 8.1 Create Screenshots Directory
Store all captured screenshots inside a `screenshots/` directory at the project root:
```bash
mkdir -p screenshots
```

### 8.2 Create ZIP Archive
To package the `lib/` directory, configuration files, and `screenshots/` into a standard `.zip` file:

```bash
zip -r camera_api_submission.zip \
  lib/ \
  test/ \
  screenshots/ \
  pubspec.yaml \
  README.md \
  android/app/build.gradle.kts \
  android/app/src/main/AndroidManifest.xml \
  ios/Runner/Info.plist
```

### 8.3 Create RAR Archive (Alternative)
If your academic institution explicitly requests `.rar` format:

```bash
rar a -r camera_api_submission.rar \
  lib/ \
  test/ \
  screenshots/ \
  pubspec.yaml \
  README.md \
  android/app/build.gradle.kts \
  android/app/src/main/AndroidManifest.xml \
  ios/Runner/Info.plist
```

### 8.4 Verification of Submission Archive
Verify the contents of the archive before submitting:

```bash
# For ZIP:
unzip -l camera_api_submission.zip

# For RAR:
unrar l camera_api_submission.rar
```
