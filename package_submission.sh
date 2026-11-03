#!/bin/bash
# ==============================================================================
# Script: package_submission.sh
# Purpose: Packages the Flutter Camera API project into ZIP/RAR archives
#          for academic assignment submission.
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

OUTPUT_NAME="camera_api_submission"
SCREENSHOTS_DIR="screenshots"

echo "=========================================="
echo "Flutter Camera API Submission Packager"
echo "=========================================="

# Ensure screenshots directory exists
if [ ! -d "$SCREENSHOTS_DIR" ]; then
    echo "[INFO] Creating $SCREENSHOTS_DIR directory..."
    mkdir -p "$SCREENSHOTS_DIR"
fi

# Check for screenshots
SCREENSHOT_COUNT=$(find "$SCREENSHOTS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | wc -l)
echo "[INFO] Found $SCREENSHOT_COUNT screenshot(s) in $SCREENSHOTS_DIR/"

if [ "$SCREENSHOT_COUNT" -eq 0 ]; then
    echo "[WARNING] No screenshots found in $SCREENSHOTS_DIR/."
    echo "[WARNING] Please capture run screenshots before submitting to ensure full grade points."
fi

# Clean build artifacts to keep archive size small
echo "[INFO] Cleaning build cache..."
flutter clean > /dev/null 2>&1 || true

# Target files for submission
SUBMISSION_ITEMS=(
    "lib/"
    "test/"
    "screenshots/"
    "pubspec.yaml"
    "README.md"
    "android/app/build.gradle.kts"
    "android/app/src/main/AndroidManifest.xml"
    "ios/Runner/Info.plist"
)

# Package into ZIP
echo "[INFO] Creating ZIP archive: ${OUTPUT_NAME}.zip..."
if command -v zip >/dev/null 2>&1; then
    zip -r "${OUTPUT_NAME}.zip" "${SUBMISSION_ITEMS[@]}"
    echo "[SUCCESS] Created ${OUTPUT_NAME}.zip via zip utility"
elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import zipfile, os
items = ['lib', 'test', 'screenshots', 'pubspec.yaml', 'README.md', 'android/app/build.gradle.kts', 'android/app/src/main/AndroidManifest.xml', 'ios/Runner/Info.plist']
with zipfile.ZipFile('${OUTPUT_NAME}.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for item in items:
        if os.path.isdir(item):
            for root, _, files in os.walk(item):
                for f in files:
                    full = os.path.join(root, f)
                    z.write(full, full)
        elif os.path.exists(item):
            z.write(item, item)
"
    echo "[SUCCESS] Created ${OUTPUT_NAME}.zip via Python zipfile module"
else
    echo "[ERROR] Neither 'zip' nor 'python3' was found to build the ZIP archive."
fi

# Package into RAR if rar command is available
if command -v rar >/dev/null 2>&1; then
    echo "[INFO] Creating RAR archive: ${OUTPUT_NAME}.rar..."
    rar a -r "${OUTPUT_NAME}.rar" "${SUBMISSION_ITEMS[@]}"
    echo "[SUCCESS] Created ${OUTPUT_NAME}.rar"
fi

echo "=========================================="
echo "Packaging complete."
echo "=========================================="
