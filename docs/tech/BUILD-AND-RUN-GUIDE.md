# Build & Run Guide: Tổng Tài Development

## Hướng Dẫn Xây Dựng & Chạy: Phát Triển Tổng Tài

> **Step-by-step instructions to build and run Tổng Tài locally on Android and iOS.**

**Status:** 📋 DRAFT for Review  
**Phase:** 1B — Technology Planning  
**Owner:** Developer Team  
**Date:** 2026-07-13

---

## English — Build & Run Guide

### Prerequisites

#### System Requirements

**macOS (for iOS development):**
- macOS 12+ (Big Sur or newer)
- Xcode 14+ (with iOS 15+ SDK)
- CocoaPods
- Minimum 50GB free disk space

**Windows/Linux/macOS (for Android development):**
- Android Studio 2021.2+
- Android SDK 24+ (API level 24, minimum)
- SDK Platform API level 34+
- Android Emulator or physical device
- 20GB free disk space

**All Platforms:**
- Flutter 3.22+
  ```bash
  flutter --version  # Should show 3.22.0 or later
  ```
- Dart 3.4+
  ```bash
  dart --version    # Should show 3.4.0 or later
  ```
- Git 2.37+
  ```bash
  git --version
  ```

#### IDE Setup

**Recommended: VS Code or Android Studio**

**VS Code:**
1. Install Dart extension
2. Install Flutter extension
3. Install GitLens (optional, for Git history)

**Android Studio:**
1. Built-in Flutter/Dart plugins
2. Built-in Android development tools

#### Environment Variables

**Set Flutter path:**
```bash
# Add to ~/.bash_profile or ~/.zshrc
export PATH="$PATH:/path/to/flutter/bin"
export PATH="$PATH:/path/to/android-sdk/cmdline-tools/latest/bin"
```

**Verify setup:**
```bash
flutter doctor
# Output should show:
#   ✓ Flutter (Channel stable, X.XX.X)
#   ✓ Android toolchain
#   ✓ Xcode (for iOS)
#   ✓ CocoaPods
```

---

### Clone Repository

```bash
# Clone the Hub repo (which includes Tổng Tài)
git clone https://github.com/workizen/workizen-ai-personal-wallet.git
cd workizen-ai-personal-wallet

# Verify you're on main
git checkout main
git pull
```

---

### Setup Local Secrets

**Tổng Tài requires API keys for AI providers.**

#### Create secrets file

```bash
mkdir -p dev-secrets
touch dev-secrets/tongtai.env
```

#### Add API keys

```bash
# dev-secrets/tongtai.env
XAI_API_KEY=sk-...  # Get from xAI (https://console.x.ai)
OPENROUTER_API_KEY=sk-...  # Get from OpenRouter (https://openrouter.io)
```

**⚠️ NEVER commit this file!**

```bash
# Verify .gitignore covers it
cat .gitignore | grep dev-secrets
# Should output: dev-secrets/
```

---

### Flutter Setup

#### Get Dependencies

```bash
cd mobile/
flutter pub get
```

**Expected output:**
```
Running "flutter pub get" in mobile...
Resolving dependencies...
Got dependencies in X.XXs.
```

#### Generate Drift Database (if needed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Run Tổng Tài (Development)

#### On Android Emulator

```bash
# Start emulator (if not running)
emulator -avd Pixel_6_API_34  # or your configured emulator

# Run Tổng Tài
flutter run -t lib/main_tongtai.dart

# Output:
# Launching lib/main_tongtai.dart on Pixel_6_API_34...
# Application finished with exit code 0.
```

**Troubleshooting:**

| Issue | Solution |
|---|---|
| No emulator found | `emulator -list-avds` to see available emulators, or create one in Android Studio |
| Gradle build failed | `flutter clean && flutter pub get` |
| Port already in use | Kill process: `lsof -i :5037 \| grep -v COMMAND \| awk '{print $2}' \| xargs kill -9` |

#### On iOS Simulator

```bash
# Start simulator
open -a Simulator

# Run Tổng Tài
flutter run -t lib/main_tongtai.dart

# Output:
# Launching lib/main_tongtai.dart on iPhone 15...
# Application finished with exit code 0.
```

**Troubleshooting:**

| Issue | Solution |
|---|---|
| Simulator not found | `open -a Simulator` or use `xcrun simctl list` |
| Pod install failed | `cd ios && pod repo update && pod install && cd ..` |
| Device locked | Unlock simulator or set auto-lock to "Never" in Settings |

#### On Physical Device (Android)

```bash
# Enable USB debugging on your device
# Settings → Developer Options → USB Debugging (toggle ON)

# Connect device via USB
# Verify connection
adb devices

# Run Tổng Tài
flutter run -t lib/main_tongtai.dart
```

#### On Physical Device (iOS)

```bash
# Connect iPhone via USB
# Trust the computer on your iPhone
# (Settings → General → Trust [Your Computer])

# Run Tổng Tài
flutter run -t lib/main_tongtai.dart
```

---

### Build Release APK (Android)

```bash
# Build Tổng Tài APK
flutter build apk -t lib/main_tongtai.dart --release

# Output: build/app/outputs/apk/release/app-release.apk
# Size: ~40-50 MB (depending on assets)
```

**Install on device:**
```bash
adb install build/app/outputs/apk/release/app-release.apk
```

---

### Build Release AAB (Android App Bundle for Play Store)

```bash
# Build Tổng Tài AAB
flutter build appbundle -t lib/main_tongtai.dart --release

# Output: build/app/outputs/bundle/release/app-release.aab
# Size: ~30-40 MB
```

**⚠️ AAB cannot be directly installed. Use for Play Store only.**

---

### Build Release IPA (iOS App for App Store)

```bash
# Build Tổng Tài IPA
flutter build ipa -t lib/main_tongtai.dart --release

# Output: build/ios/ipa/Runner.ipa
# Size: ~60-80 MB
```

**Install on device (for testing):**
```bash
# Requires Apple Developer account
xcrun devicectl device install app build/ios/ipa/Runner.ipa
```

---

### Run Tests

#### Unit Tests

```bash
# All tests
flutter test

# Only Tổng Tài tests
flutter test --tags=tongtai

# Only shared tests
flutter test test/shared/

# Single test file
flutter test test/tongtai/models/producer_test.dart
```

#### Integration Tests (E2E)

```bash
# Start emulator or device first

# Run all integration tests
flutter drive --driver=integration_test/driver.dart \
  --target=integration_test/tongtai_flow_test.dart

# Run on specific device
flutter drive --driver=integration_test/driver.dart \
  --target=integration_test/tongtai_flow_test.dart \
  -d emulator-5554
```

---

### Debugging

#### Enable Debug Logging

```dart
// In main_tongtai.dart
void main() {
  // Enable debug mode
  debugPrintBeginFrameBanner = true;
  debugPrintEndFrameBanner = true;
  
  runApp(const TongTaiApp());
}
```

#### Use Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Or automatically open with flutter run
flutter run -t lib/main_tongtai.dart --devtools-mode=server
```

#### Hot Reload (Development Only)

```bash
# While flutter run is active, press 'r' to hot reload
# Press 'R' to hot restart
flutter run -t lib/main_tongtai.dart
# Press: r (hot reload), R (restart), q (quit)
```

#### View Device Logs

```bash
# Android Logcat
adb logcat | grep "flutter"

# iOS Console
# Open Console.app → select device → filter by "flutter"
```

---

### Troubleshooting

#### Common Issues

**Issue: "No connected devices"**
```bash
# Solution 1: Use emulator
flutter emulators
flutter emulators launch <emulator-name>

# Solution 2: Connect physical device
adb devices  # Android
xcrun xcode-select --install  # iOS
```

**Issue: "Build failed: Gradle error"**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -t lib/main_tongtai.dart
```

**Issue: "Error: Target […] not found"**
```bash
# Verify file exists
ls lib/main_tongtai.dart

# If missing, create it
touch lib/main_tongtai.dart
# Add basic content (see below)
```

**Issue: "CocoaPods error (iOS)"**
```bash
cd ios
rm Podfile.lock
pod repo update
pod install
cd ..
flutter run -t lib/main_tongtai.dart
```

**Issue: "API key not found"**
```bash
# Verify secrets file exists
cat dev-secrets/tongtai.env

# If missing, create it
mkdir -p dev-secrets
echo "XAI_API_KEY=sk-..." > dev-secrets/tongtai.env
echo "OPENROUTER_API_KEY=sk-..." >> dev-secrets/tongtai.env
```

#### Get Help

1. **Check Flutter docs:** https://flutter.dev/docs
2. **Check GitHub issues:** https://github.com/workizen/workizen-ai-personal-wallet/issues
3. **Ask in Slack:** #development

---

### Development Workflow

**Typical day:**

```bash
# 1. Start of day: sync and setup
git checkout main
git pull
flutter pub get

# 2. Create feature branch
git checkout -b feat/tongtai-producer-screen

# 3. Run Tổng Tài during development
flutter run -t lib/main_tongtai.dart

# 4. While running, use hot reload (press 'r')
# Edit lib/main_tongtai.dart, press 'r'

# 5. When ready to test, run tests
flutter test --tags=tongtai

# 6. Commit changes
git add .
git commit -m "feat(tongtai): add producer screen"

# 7. Push and create PR
git push -u origin feat/tongtai-producer-screen
```

---

### Performance Profiling

#### Memory Usage

```bash
# While running Tổng Tài, press 'M' to dump memory info
flutter run -t lib/main_tongtai.dart
# Press: M (memory), L (memory leaks), q (quit)
```

#### Frame Rate (Jank Detection)

```dart
// In main_tongtai.dart
void main() {
  debugPrintBeginFrameBanner = true;
  debugPrintEndFrameBanner = true;  // Shows frame timing
  runApp(const TongTaiApp());
}

// Monitor in Android Studio profiler
// Or use DevTools → Performance
```

#### Battery Drain (Android)

```bash
# Use Android Profiler
# Android Studio → Tools → Android → Android Profiler
# Monitor: CPU, Memory, Network, Power
```

---

## Tiếng Việt — Hướng Dẫn Xây Dựng & Chạy

### Điều Kiện Tiên Quyết

#### Yêu Cầu Hệ Thống

**macOS (cho phát triển iOS):**
- macOS 12+ (Big Sur hoặc mới hơn)
- Xcode 14+ (với SDK iOS 15+)
- CocoaPods
- Tối thiểu 50GB dung lượng trống

**Windows/Linux/macOS (cho phát triển Android):**
- Android Studio 2021.2+
- Android SDK 24+ (API level 24, tối thiểu)
- SDK Platform API level 34+
- Android Emulator hoặc thiết bị vật lý
- 20GB dung lượng trống

**Tất cả nền tảng:**
- Flutter 3.22+
- Dart 3.4+
- Git 2.37+

---

### Sao Chép Kho Lưu Trữ

```bash
git clone https://github.com/workizen/workizen-ai-personal-wallet.git
cd workizen-ai-personal-wallet
git checkout main
git pull
```

---

### Thiết Lập Bí Mật Cục Bộ

Tổng Tài yêu cầu API key cho các nhà cung cấp AI.

```bash
mkdir -p dev-secrets
touch dev-secrets/tongtai.env

# Thêm:
# XAI_API_KEY=sk-...
# OPENROUTER_API_KEY=sk-...
```

**⚠️ KHÔNG commit tệp này!**

---

### Thiết Lập Flutter

```bash
cd mobile/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Chạy Tổng Tài

#### Trên Android Emulator

```bash
emulator -avd Pixel_6_API_34
flutter run -t lib/main_tongtai.dart
```

#### Trên iOS Simulator

```bash
open -a Simulator
flutter run -t lib/main_tongtai.dart
```

#### Trên Thiết Bị Vật Lý (Android)

```bash
# Bật USB Debugging trên thiết bị
adb devices
flutter run -t lib/main_tongtai.dart
```

#### Trên Thiết Bị Vật Lý (iOS)

```bash
# Kết nối iPhone qua USB
# Tin tưởng máy tính trên iPhone
flutter run -t lib/main_tongtai.dart
```

---

### Xây Dựng APK Release (Android)

```bash
flutter build apk -t lib/main_tongtai.dart --release
# Output: build/app/outputs/apk/release/app-release.apk
```

---

### Xây Dựng AAB (Android App Bundle cho Play Store)

```bash
flutter build appbundle -t lib/main_tongtai.dart --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

### Xây Dựng IPA (iOS App cho App Store)

```bash
flutter build ipa -t lib/main_tongtai.dart --release
# Output: build/ios/ipa/Runner.ipa
```

---

### Chạy Kiểm Thử

```bash
# Tất cả kiểm thử
flutter test

# Chỉ kiểm thử Tổng Tài
flutter test --tags=tongtai

# Kiểm thử tích hợp
flutter drive --driver=integration_test/driver.dart \
  --target=integration_test/tongtai_flow_test.dart
```

---

### Gỡ Lỗi

#### Hot Reload (Chỉ Phát Triển)

```bash
flutter run -t lib/main_tongtai.dart
# Nhấn 'r' để hot reload
# Nhấn 'R' để khởi động lại
# Nhấn 'q' để thoát
```

#### Xem Nhật Ký Thiết Bị

```bash
# Android
adb logcat | grep "flutter"

# iOS
# Mở Console.app → chọn thiết bị → lọc "flutter"
```

---

### Khắc Phục Sự Cố

| Vấn Đề | Giải Pháp |
|---|---|
| Không có thiết bị kết nối | Sử dụng bộ mô phỏng hoặc kết nối thiết bị vật lý |
| Lỗi Gradle | `flutter clean && flutter pub get` |
| Lỗi CocoaPods (iOS) | `cd ios && pod repo update && pod install && cd ..` |
| API key không tìm thấy | Tạo `dev-secrets/tongtai.env` |

---

### Quy Trình Phát Triển Điển Hình

```bash
# 1. Bắt đầu ngày
git checkout main && git pull
flutter pub get

# 2. Tạo nhánh tính năng
git checkout -b feat/tongtai-producer-screen

# 3. Chạy Tổng Tài
flutter run -t lib/main_tongtai.dart

# 4. Sử dụng hot reload (nhấn 'r')

# 5. Kiểm thử
flutter test --tags=tongtai

# 6. Commit
git commit -m "feat(tongtai): add producer screen"

# 7. Đẩy và tạo PR
git push -u origin feat/tongtai-producer-screen
```

---

**Version:** 1.0 (Draft)  
**Next Review:** After first build is successful
