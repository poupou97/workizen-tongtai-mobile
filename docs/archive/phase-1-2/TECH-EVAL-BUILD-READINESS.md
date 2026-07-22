# Build Readiness Validation — Phase 1C Technical Evaluation

**Period:** Jul 20–26, 2026  
**Owner:** Build Engineer / QA  
**Status:** Checklist for Phase 1C build & deployment readiness

---

## 🎯 Purpose

Validate that the BUILD-AND-RUN-GUIDE (or equivalent documentation) works end-to-end. Ensures any developer can clone, build, and run both Hub and Tổng Tài on a fresh machine without hitting undocumented prerequisites.

---

## 1. Prerequisites Validation

### System Requirements Check
- [ ] Flutter 3.22+ installed?
  ```bash
  flutter --version
  ```
  - Expected output: `Flutter 3.22.x` or later
- [ ] Dart 3.4+ installed?
  ```bash
  dart --version
  ```
  - Expected output: `Dart SDK version 3.4.x` or later
- [ ] Android SDK 24+ available?
  ```bash
  flutter doctor
  ```
  - Expected: ✅ Android toolchain – Android SDK installed
- [ ] 50GB+ free disk space available?
  ```bash
  df -h
  ```
  - Verify: `/` has at least 50GB free
- [ ] Git 2.37+ available?
  ```bash
  git --version
  ```
  - Expected: `git version 2.37.x` or later

### IDE/Editor Setup (Optional but Recommended)
- [ ] VS Code installed (optional)?
  - [ ] Flutter/Dart extensions installed?
- [ ] Android Studio installed (optional)?
  - [ ] Flutter SDK plugin installed?
- [ ] Xcode installed (for iOS builds, if needed)?

### Platform-Specific Setup

#### Android Setup
- [ ] JAVA_HOME set correctly?
  ```bash
  echo $JAVA_HOME
  ```
- [ ] ANDROID_HOME set correctly?
  ```bash
  echo $ANDROID_HOME
  ```
- [ ] Android emulator configured or real device available?
  ```bash
  flutter devices
  ```
  - Expected: At least one device listed (emulator or physical)

#### iOS Setup (Optional)
- [ ] CocoaPods installed?
  ```bash
  pod --version
  ```

### Risk Assessment
- [ ] ✅ All prerequisites met / ⚠️ Some missing / 🚨 Blocker found
- **Blocker action:** Document missing prerequisites in BUILD-AND-RUN-GUIDE

---

## 2. Quick Start Procedure (Test Each Step)

### 1. Clone Repository
- [ ] Command: `git clone https://github.com/poupou97/workizen-ai-personal-wallet.git`
  - [ ] Succeeds without errors
  - [ ] Folder structure created: `workizen-ai-personal-wallet/`
- [ ] Navigate to repo: `cd workizen-ai-personal-wallet`

### 2. Verify Git Status
- [ ] Command: `git status`
  - [ ] Shows: `On branch main`
  - [ ] Shows: `Your branch is up to date with 'origin/main'.`
- [ ] No untracked files reported (except `.claude/`, etc.)

### 3. Pull Latest Code
- [ ] Command: `git pull`
  - [ ] Succeeds without errors
  - [ ] Latest commits fetched

### 4. Create Secrets File
- [ ] Check if secrets file needs creation:
  ```bash
  ls -la dev-secrets/
  ```
- [ ] If `tongtai.env` missing:
  ```bash
  mkdir -p dev-secrets
  cat > dev-secrets/tongtai.env << EOF
  # Add required secrets here (API keys, etc.)
  OPENROUTER_API_KEY=sk-or-v1-...
  EOF
  ```
  - [ ] File created successfully
  - [ ] File is in `.gitignore` (not committed)

### 5. Install Dependencies
- [ ] Command: `flutter pub get`
  - [ ] Succeeds without errors
  - [ ] All packages downloaded
  - [ ] Build-runner runs (for generated code)
  ```bash
  flutter pub run build_runner build
  ```
  - [ ] Succeeds without errors
  - [ ] Generated files created (`.g.dart`, `.config.dart`, etc.)

### 6. Verify Project Structure
- [ ] Check folder structure:
  ```bash
  ls -la mobile/
  ```
  - [ ] Folders present: `hub/`, `tongtai/`, `shared/`
- [ ] Check entry points:
  ```bash
  ls -la mobile/hub/lib/main_hub.dart
  ls -la mobile/tongtai/lib/main_tongtai.dart
  ```
  - [ ] Both exist

### 7. Launch Tổng Tài (Debug Mode)
- [ ] Emulator/device connected and ready?
  ```bash
  flutter devices
  ```
- [ ] Command: `flutter run -t lib/main_tongtai.dart`
  - [ ] Compilation succeeds
  - [ ] App launches on emulator/device
  - [ ] App shows "Tổng Tài" branding (not "Workizen Hub")
  - [ ] No white screen or crash
- [ ] Verify app is running:
  - [ ] Navigation works (tabs functional)
  - [ ] Can perform basic action (e.g., open search)

### 8. Test Hot Reload
- [ ] With app running, press `r` in terminal
  - [ ] Hot reload succeeds
  - [ ] App reflects change (e.g., color change)
  - [ ] No "Restarting app" required

### 9. Stop App
- [ ] Press `q` in terminal to quit
  - [ ] App closes gracefully
  - [ ] No orphaned processes

### Risk Assessment
- [ ] ✅ All steps successful / ⚠️ Some steps failed / 🚨 Blocker found
- **Blocker action:** Document errors in BUILD-AND-RUN-GUIDE, fix issues

---

## 3. Build Targets Validation

### Hub Debug Build
- [ ] Command: `flutter run -t lib/main_hub.dart --debug`
  - [ ] Compilation succeeds
  - [ ] App launches
  - [ ] Verified: "Workizen Hub" branding appears
  - [ ] All Hub features accessible (document scan, chat, etc.)

### Tổng Tài Debug Build
- [ ] Command: `flutter run -t lib/main_tongtai.dart --debug`
  - [ ] Compilation succeeds
  - [ ] App launches
  - [ ] Verified: "Tổng Tài" branding appears
  - [ ] All Tổng Tài features accessible (entity list, search, etc.)

### Hub Release APK
- [ ] Command:
  ```bash
  flutter build apk -t lib/main_hub.dart --release
  ```
  - [ ] Build succeeds without errors
  - [ ] APK generated at: `build/app/outputs/flutter-apk/app-release.apk`
  - [ ] File size reasonable: [__ MB] (< 200MB)
  - [ ] Test: Install on real device (if available)
    ```bash
    adb install build/app/outputs/flutter-apk/app-release.apk
    ```
    - [ ] Installation succeeds
    - [ ] App launches and functions

### Tổng Tài Release APK
- [ ] Command:
  ```bash
  flutter build apk -t lib/main_tongtai.dart --release
  ```
  - [ ] Build succeeds without errors
  - [ ] APK generated at: `build/app/outputs/flutter-apk/app-release.apk`
  - [ ] File size reasonable: [__ MB] (< 200MB)
  - [ ] Test: Install on real device (if available)
    ```bash
    adb install build/app/outputs/flutter-apk/app-release.apk
    ```
    - [ ] Installation succeeds
    - [ ] App launches and functions

### Hub Release AAB (Android App Bundle)
- [ ] Command:
  ```bash
  flutter build appbundle -t lib/main_hub.dart --release
  ```
  - [ ] Build succeeds without errors
  - [ ] AAB generated at: `build/app/outputs/bundle/release/app-release.aab`
  - [ ] File size reasonable: [__ MB]
- [ ] Verify: Check bundle in Play Console (if available)

### Tổng Tài Release AAB
- [ ] Command:
  ```bash
  flutter build appbundle -t lib/main_tongtai.dart --release
  ```
  - [ ] Build succeeds without errors
  - [ ] AAB generated at: `build/app/outputs/bundle/release/app-release.aab`
  - [ ] File size reasonable: [__ MB]

### Hub Release IPA (iOS, if applicable)
- [ ] Command (on Mac):
  ```bash
  flutter build ipa -t lib/main_hub.dart --release
  ```
  - [ ] Build succeeds without errors (or note if iOS skipped in Phase 1C)
  - [ ] IPA generated at: `build/ios/ipa/`

### Tổng Tài Release IPA (iOS, if applicable)
- [ ] Command (on Mac):
  ```bash
  flutter build ipa -t lib/main_tongtai.dart --release
  ```
  - [ ] Build succeeds without errors (or note if iOS skipped in Phase 1C)
  - [ ] IPA generated at: `build/ios/ipa/`

### Risk Assessment
- [ ] ✅ All build targets successful / ⚠️ Some build issues / 🚨 Blocker found
- **Blocker action:** Debug build errors, add troubleshooting to guide

---

## 4. Testing Commands Validation

### Unit Tests (Hub)
- [ ] Command: `flutter test --tags=hub test/`
  - [ ] All tests pass
  - [ ] Output shows pass count: [__ tests passed]
  - [ ] No failures or errors

### Unit Tests (Tổng Tài)
- [ ] Command: `flutter test --tags=tongtai test/`
  - [ ] All tests pass
  - [ ] Output shows pass count: [__ tests passed]
  - [ ] No failures or errors

### Unit Tests (Shared Core)
- [ ] Command: `flutter test mobile/shared/core/test/`
  - [ ] All tests pass
  - [ ] Output shows pass count: [__ tests passed]
  - [ ] No failures or errors

### Integration Tests (Hub, Optional for Phase 1C)
- [ ] Command:
  ```bash
  flutter drive \
    --target=integration_test/hub_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
  - [ ] Tests pass or note if skipped
  - [ ] Device/emulator logs show no crashes

### Integration Tests (Tổng Tài, Optional for Phase 1C)
- [ ] Command:
  ```bash
  flutter drive \
    --target=integration_test/tongtai_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
  - [ ] Tests pass or note if skipped
  - [ ] Device/emulator logs show no crashes

### Code Analysis (Lint)
- [ ] Command: `flutter analyze`
  - [ ] No errors reported
  - [ ] No warnings (or only acceptable warnings)
  - [ ] Output confirms: `No issues found!`

### Code Formatting Check
- [ ] Command: `dart format --line-length 100 --dry-run .`
  - [ ] Reports: no files need formatting (or list files that do)
  - [ ] If files need formatting: `dart format --line-length 100 .` to fix

### Risk Assessment
- [ ] ✅ All tests pass / ⚠️ Some test failures / 🚨 Blocker found
- **Blocker action:** Fix failing tests before Phase 2 lock

---

## 5. Environment-Specific Issues (Troubleshoot Any)

### macOS-Specific Issues
- [ ] No "iOS deployment target" mismatch?
  - Test: `cd mobile/ios && pod install` succeeds?
- [ ] No M1/M2 native architecture issues?
  - Test: `flutter run -t lib/main_tongtai.dart` on M1/M2 Mac succeeds?
- [ ] Path issues (spaces in paths, special characters)?

### Windows-Specific Issues
- [ ] Git Bash vs. CMD.exe compatibility?
- [ ] Android SDK path set correctly?
- [ ] No line-ending issues (CRLF vs. LF)?

### Linux-Specific Issues
- [ ] X11/Wayland issues for emulator?
- [ ] No permission issues (USB for devices)?

### Missing Dependencies
- [ ] All Pub packages downloaded without errors?
  ```bash
  flutter pub get
  flutter pub run build_runner build
  ```
- [ ] No pub cache corruption?
  ```bash
  flutter pub cache clean
  flutter pub get
  ```

### Version Conflicts
- [ ] Flutter version matches `.flutter-version` (if pinned)?
- [ ] Dart version matches Flutter's bundled version?
  ```bash
  flutter doctor -v
  ```

### Platform-Specific Build Issues
- [ ] Android: No NDK issues?
  ```bash
  flutter doctor -v | grep "Android SDK"
  ```
- [ ] iOS: No CocoaPods issues (if applicable)?
  ```bash
  pod repo update
  cd mobile/ios && pod install
  ```

### Risk Assessment
- [ ] ✅ No environmental issues / ⚠️ Some issues found / 🚨 Blocker found
- **Blocker action:** Document workarounds in BUILD-AND-RUN-GUIDE

---

## 6. Build Documentation Review

### BUILD-AND-RUN-GUIDE Verification

#### Exists & Complete?
- [ ] File location: `docs/QUICK-START.md` or `docs/tongtai/BUILD-AND-RUN-GUIDE.md`
- [ ] File is readable and well-formatted (Markdown)
- [ ] Contains sections:
  - [ ] Prerequisites (system, tools, accounts)
  - [ ] Quick start (clone, build, run)
  - [ ] Build targets (debug, release, APK, AAB, IPA)
  - [ ] Testing (unit, integration, lint)
  - [ ] Troubleshooting (common errors + solutions)
  - [ ] Bilingual (EN + VI)?

#### Prerequisites Section
- [ ] Lists all required tools with versions
  - [ ] Flutter 3.22+
  - [ ] Dart 3.4+
  - [ ] Android SDK 24+
  - [ ] Git 2.37+
  - [ ] IDE (optional recommendations)
- [ ] Clear installation instructions (links provided)
- [ ] Platform-specific (macOS, Windows, Linux, iOS)

#### Quick Start Section
- [ ] Step-by-step clone + build + run instructions
- [ ] Commands are exact (copy-paste ready)
- [ ] Expected output for each step documented
- [ ] Covers both Hub and Tổng Tài

#### Build Targets Section
- [ ] Debug build instructions
- [ ] Release APK instructions
- [ ] Release AAB instructions
- [ ] Release IPA instructions (if applicable)
- [ ] Output artifact locations documented

#### Testing Section
- [ ] Unit test command
- [ ] Integration test command
- [ ] Code analysis (lint) command
- [ ] Code formatting command
- [ ] How to interpret test results

#### Troubleshooting Section
- [ ] Common errors documented:
  - [ ] "Dart SDK not found"
  - [ ] "Android toolchain not found"
  - [ ] "Pod install fails"
  - [ ] "Build fails with permission error"
  - [ ] "App crashes on startup"
- [ ] Solutions provided for each
- [ ] Links to external resources (if needed)

#### Bilingual Support (EN + VI)
- [ ] English section present and complete
- [ ] Vietnamese section present and complete
- [ ] Terminology consistent (e.g., "Tổng Tài" vs. "Hub")

### Risk Assessment
- [ ] ✅ Guide complete & accurate / ⚠️ Needs minor updates / 🚨 Major sections missing
- **Blocker action:** Complete missing sections before Phase 2

---

## 7. Real Device Testing (Optional for Phase 1C)

### Android Device
- [ ] Samsung S24 Ultra (flagship, if available):
  - [ ] Hub app installs and runs
  - [ ] Tổng Tài app installs and runs
  - [ ] Both apps are performant (no jank)
  - [ ] Battery drain acceptable (<5% per hour idle)
- [ ] Lower-end device (Nokia 6.1 or equivalent):
  - [ ] Hub app installs and runs
  - [ ] Tổng Tài app installs and runs
  - [ ] No crash on startup
  - [ ] Scrolling/navigation is smooth (>30fps)

### iOS Device (if Phase 1C includes iOS)
- [ ] iPad (if available):
  - [ ] Hub app installs and runs
  - [ ] Tổng Tài app installs and runs
  - [ ] Layout is appropriate for tablet size
- [ ] iPhone (if available):
  - [ ] Hub app installs and runs
  - [ ] Tổng Tài app installs and runs
  - [ ] Notch/safe area respected

### Risk Assessment
- [ ] ✅ All devices tested OK / ⚠️ Some device issues / 🚨 Crash or blocker found
- **Blocker action:** Debug device-specific issues before Phase 2

---

## 8. Overall Go/No-Go Decision

### All 7 Areas Passed?
- [ ] Prerequisites: ✅ / ⚠️ / 🚨
- [ ] Quick Start: ✅ / ⚠️ / 🚨
- [ ] Build Targets: ✅ / ⚠️ / 🚨
- [ ] Testing Commands: ✅ / ⚠️ / 🚨
- [ ] Environment Issues: ✅ / ⚠️ / 🚨
- [ ] Build Documentation: ✅ / ⚠️ / 🚨
- [ ] Real Device Testing: ✅ / ⚠️ / 🚨 (or N/A)

### Recommendation
- [ ] **GO** — Build process is solid and documented; anyone can build Tổng Tài
- [ ] **GO with conditions** — Minor doc/build issues; not blocking Phase 2
  - Conditions: [list here]
- [ ] **HOLD** — Build is broken or process is unclear; escalate to Founder
  - Blockers: [list here]

### Build Readiness Summary
| Metric | Hub | Tổng Tài | Notes |
|--------|-----|----------|-------|
| Debug build time | [__s] | [__s] | |
| Release APK size | [__MB] | [__MB] | < 200MB acceptable |
| Release AAB size | [__MB] | [__MB] | |
| Unit test pass rate | [__%] | [__%] | > 80% acceptable |
| Test execution time | [__s] | [__s] | < 30s acceptable |
| Code analysis passes | ✅ / ❌ | ✅ / ❌ | Must pass |
| Real device tested | ✅ / ⚠️ / ❌ | ✅ / ⚠️ / ❌ | |

### Sign-Off
- **Build Engineer:** _________________ **Date:** _______
- **QA/Tester:** _________________ **Date:** _______

---

---

# Xác Minh Sự Sẵn Sàng Xây Dựng — Đánh Giá Kỹ Thuật Phase 1C

**Kỳ:** 20–26 Tháng 7, 2026  
**Chủ Trì:** Build Engineer / QA  
**Trạng Thái:** Bảng kiểm cho sự sẵn sàng xây dựng & triển khai Phase 1C

---

## 🎯 Mục Đích

Xác minh rằng BUILD-AND-RUN-GUIDE (hoặc tài liệu tương đương) hoạt động từ đầu đến cuối. Đảm bảo rằng bất kỳ nhà phát triển nào cũng có thể sao chép, xây dựng và chạy cả Hub và Tổng Tài trên một máy mới mà không gặp các điều kiện tiên quyết chưa được ghi lại.

---

## 1. Xác Minh Điều Kiện Tiên Quyết

### Kiểm Tra Yêu Cầu Hệ Thống
- [ ] Flutter 3.22+ được cài đặt?
  ```bash
  flutter --version
  ```
  - Đầu ra dự kiến: `Flutter 3.22.x` hoặc mới hơn
- [ ] Dart 3.4+ được cài đặt?
  ```bash
  dart --version
  ```
  - Đầu ra dự kiến: `Dart SDK version 3.4.x` hoặc mới hơn
- [ ] Android SDK 24+ có sẵn?
  ```bash
  flutter doctor
  ```
  - Dự kiến: ✅ Android toolchain – Android SDK installed
- [ ] Có ≥50GB dung lượng đĩa trống?
  ```bash
  df -h
  ```
  - Xác minh: `/` có ít nhất 50GB trống
- [ ] Git 2.37+ có sẵn?
  ```bash
  git --version
  ```
  - Dự kiến: `git version 2.37.x` hoặc mới hơn

### Thiết Lập IDE/Trình Chỉnh Sửa (Tùy Chọn Nhưng Được Khuyến Khích)
- [ ] VS Code được cài đặt (tùy chọn)?
  - [ ] Tiện ích Flutter/Dart được cài đặt?
- [ ] Android Studio được cài đặt (tùy chọn)?
  - [ ] Tiện ích Flutter SDK được cài đặt?
- [ ] Xcode được cài đặt (để xây dựng iOS, nếu cần)?

### Thiết Lập Dành Riêng Cho Nền Tảng

#### Thiết Lập Android
- [ ] JAVA_HOME được đặt chính xác?
  ```bash
  echo $JAVA_HOME
  ```
- [ ] ANDROID_HOME được đặt chính xác?
  ```bash
  echo $ANDROID_HOME
  ```
- [ ] Bộ mô phỏng Android được cấu hình hoặc thiết bị thực sẽ khả dụng?
  ```bash
  flutter devices
  ```
  - Dự kiến: Ít nhất một thiết bị được liệt kê (bộ mô phỏng hoặc vật lý)

#### Thiết Lập iOS (Tùy Chọn)
- [ ] CocoaPods được cài đặt?
  ```bash
  pod --version
  ```

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả các điều kiện tiên quyết được đáp ứng / ⚠️ Một số bị thiếu / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Ghi lại các điều kiện tiên quyết bị thiếu trong BUILD-AND-RUN-GUIDE

---

## 2. Quy Trình Bắt Đầu Nhanh (Kiểm Tra Từng Bước)

### 1. Sao Chép Kho Dữ Liệu
- [ ] Lệnh: `git clone https://github.com/poupou97/workizen-ai-personal-wallet.git`
  - [ ] Thành công không có lỗi
  - [ ] Cấu trúc thư mục được tạo: `workizen-ai-personal-wallet/`
- [ ] Điều hướng đến kho dữ liệu: `cd workizen-ai-personal-wallet`

### 2. Xác Minh Trạng Thái Git
- [ ] Lệnh: `git status`
  - [ ] Hiển thị: `On branch main`
  - [ ] Hiển thị: `Your branch is up to date with 'origin/main'.`
- [ ] Không có tệp chưa được theo dõi được báo cáo (ngoại trừ `.claude/`, v.v.)

### 3. Kéo Mã Mới Nhất
- [ ] Lệnh: `git pull`
  - [ ] Thành công không có lỗi
  - [ ] Các commit mới nhất được tìm nạp

### 4. Tạo Tệp Bí Mật
- [ ] Kiểm tra xem tệp bí mật có cần tạo không:
  ```bash
  ls -la dev-secrets/
  ```
- [ ] Nếu `tongtai.env` bị thiếu:
  ```bash
  mkdir -p dev-secrets
  cat > dev-secrets/tongtai.env << EOF
  # Thêm các bí mật bắt buộc ở đây (khóa API, v.v.)
  OPENROUTER_API_KEY=sk-or-v1-...
  EOF
  ```
  - [ ] Tệp được tạo thành công
  - [ ] Tệp nằm trong `.gitignore` (không cam kết)

### 5. Cài Đặt Phụ Thuộc
- [ ] Lệnh: `flutter pub get`
  - [ ] Thành công không có lỗi
  - [ ] Tất cả các gói được tải xuống
  - [ ] Build-runner chạy (cho mã được tạo)
  ```bash
  flutter pub run build_runner build
  ```
  - [ ] Thành công không có lỗi
  - [ ] Các tệp được tạo được tạo ra (`.g.dart`, `.config.dart`, v.v.)

### 6. Xác Minh Cấu Trúc Dự Án
- [ ] Kiểm tra cấu trúc thư mục:
  ```bash
  ls -la mobile/
  ```
  - [ ] Thư mục có mặt: `hub/`, `tongtai/`, `shared/`
- [ ] Kiểm tra điểm vào:
  ```bash
  ls -la mobile/hub/lib/main_hub.dart
  ls -la mobile/tongtai/lib/main_tongtai.dart
  ```
  - [ ] Cả hai tồn tại

### 7. Chạy Tổng Tài (Chế Độ Gỡ Lỗi)
- [ ] Bộ mô phỏng/thiết bị được kết nối và sẵn sàng?
  ```bash
  flutter devices
  ```
- [ ] Lệnh: `flutter run -t lib/main_tongtai.dart`
  - [ ] Biên dịch thành công
  - [ ] Ứng dụng khởi động trên bộ mô phỏng/thiết bị
  - [ ] Ứng dụng hiển thị thương hiệu "Tổng Tài" (không phải "Workizen Hub")
  - [ ] Không có màn hình trắng hoặc sự cố
- [ ] Xác minh ứng dụng đang chạy:
  - [ ] Điều hướng hoạt động (tab hoạt động)
  - [ ] Có thể thực hiện hành động cơ bản (ví dụ: tìm kiếm mở)

### 8. Kiểm Tra Tải Lại Nóng
- [ ] Với ứng dụng đang chạy, nhấn `r` trong terminal
  - [ ] Tải lại nóng thành công
  - [ ] Ứng dụng phản ánh sự thay đổi (ví dụ: thay đổi màu)
  - [ ] Không cần "Khởi động lại ứng dụng"

### 9. Dừng Ứng Dụng
- [ ] Nhấn `q` trong terminal để thoát
  - [ ] Ứng dụng đóng một cách duyên dáng
  - [ ] Không có quy trình trẻ em

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả các bước thành công / ⚠️ Một số bước không thành công / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Ghi lại lỗi trong BUILD-AND-RUN-GUIDE, sửa các vấn đề

---

## 3. Xác Minh Mục Tiêu Xây Dựng

### Hub Debug Build
- [ ] Lệnh: `flutter run -t lib/main_hub.dart --debug`
  - [ ] Biên dịch thành công
  - [ ] Ứng dụng khởi động
  - [ ] Xác minh: "Workizen Hub" thương hiệu xuất hiện
  - [ ] Tất cả các tính năng Hub có thể truy cập (quét tài liệu, trò chuyện, v.v.)

### Tổng Tài Debug Build
- [ ] Lệnh: `flutter run -t lib/main_tongtai.dart --debug`
  - [ ] Biên dịch thành công
  - [ ] Ứng dụng khởi động
  - [ ] Xác minh: "Tổng Tài" thương hiệu xuất hiện
  - [ ] Tất cả các tính năng Tổng Tài có thể truy cập (danh sách thực thể, tìm kiếm, v.v.)

### Hub Release APK
- [ ] Lệnh:
  ```bash
  flutter build apk -t lib/main_hub.dart --release
  ```
  - [ ] Xây dựng thành công không có lỗi
  - [ ] APK được tạo ra tại: `build/app/outputs/flutter-apk/app-release.apk`
  - [ ] Kích thước tệp hợp lý: [__ MB] (< 200MB)
  - [ ] Kiểm tra: Cài đặt trên thiết bị thực (nếu có)
    ```bash
    adb install build/app/outputs/flutter-apk/app-release.apk
    ```
    - [ ] Cài đặt thành công
    - [ ] Ứng dụng khởi động và hoạt động

### Tổng Tài Release APK
- [ ] Lệnh:
  ```bash
  flutter build apk -t lib/main_tongtai.dart --release
  ```
  - [ ] Xây dựng thành công không có lỗi
  - [ ] APK được tạo ra tại: `build/app/outputs/flutter-apk/app-release.apk`
  - [ ] Kích thước tệp hợp lý: [__ MB] (< 200MB)
  - [ ] Kiểm tra: Cài đặt trên thiết bị thực (nếu có)
    ```bash
    adb install build/app/outputs/flutter-apk/app-release.apk
    ```
    - [ ] Cài đặt thành công
    - [ ] Ứng dụng khởi động và hoạt động

### Hub Release AAB (Android App Bundle)
- [ ] Lệnh:
  ```bash
  flutter build appbundle -t lib/main_hub.dart --release
  ```
  - [ ] Xây dựng thành công không có lỗi
  - [ ] AAB được tạo ra tại: `build/app/outputs/bundle/release/app-release.aab`
  - [ ] Kích thước tệp hợp lý: [__ MB]

### Tổng Tài Release AAB
- [ ] Lệnh:
  ```bash
  flutter build appbundle -t lib/main_tongtai.dart --release
  ```
  - [ ] Xây dựng thành công không có lỗi
  - [ ] AAB được tạo ra tại: `build/app/outputs/bundle/release/app-release.aab`
  - [ ] Kích thước tệp hợp lý: [__ MB]

### Hub Release IPA (iOS, nếu áp dụng)
- [ ] Lệnh (trên Mac):
  ```bash
  flutter build ipa -t lib/main_hub.dart --release
  ```
  - [ ] Xây dựng thành công không có lỗi (hoặc ghi chú nếu iOS bị bỏ qua trong Phase 1C)
  - [ ] IPA được tạo ra tại: `build/ios/ipa/`

### Tổng Tài Release IPA (iOS, nếu áp dụng)
- [ ] Lệnh (trên Mac):
  ```bash
  flutter build ipa -t lib/main_tongtai.dart --release
  ```
  - [ ] Xây dựng thành công không có lỗi (hoặc ghi chú nếu iOS bị bỏ qua trong Phase 1C)
  - [ ] IPA được tạo ra tại: `build/ios/ipa/`

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả mục tiêu xây dựng thành công / ⚠️ Một số vấn đề xây dựng / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Gỡ lỗi lỗi xây dựng, thêm khắc phục sự cố vào hướng dẫn

---

## 4. Xác Minh Lệnh Kiểm Tra

### Kiểm Tra Đơn Vị (Hub)
- [ ] Lệnh: `flutter test --tags=hub test/`
  - [ ] Tất cả các bài kiểm tra vượt qua
  - [ ] Đầu ra hiển thị số lượng vượt qua: [__ bài kiểm tra đã vượt qua]
  - [ ] Không có lỗi hoặc lỗi

### Kiểm Tra Đơn Vị (Tổng Tài)
- [ ] Lệnh: `flutter test --tags=tongtai test/`
  - [ ] Tất cả các bài kiểm tra vượt qua
  - [ ] Đầu ra hiển thị số lượng vượt qua: [__ bài kiểm tra đã vượt qua]
  - [ ] Không có lỗi hoặc lỗi

### Kiểm Tra Đơn Vị (Chia Sẻ Cốt Lõi)
- [ ] Lệnh: `flutter test mobile/shared/core/test/`
  - [ ] Tất cả các bài kiểm tra vượt qua
  - [ ] Đầu ra hiển thị số lượng vượt qua: [__ bài kiểm tra đã vượt qua]
  - [ ] Không có lỗi hoặc lỗi

### Kiểm Tra Tích Hợp (Hub, Tùy Chọn cho Phase 1C)
- [ ] Lệnh:
  ```bash
  flutter drive \
    --target=integration_test/hub_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
  - [ ] Các bài kiểm tra vượt qua hoặc ghi chú nếu bị bỏ qua
  - [ ] Nhật ký thiết bị/bộ mô phỏng không hiển thị sự cố

### Kiểm Tra Tích Hợp (Tổng Tài, Tùy Chọn cho Phase 1C)
- [ ] Lệnh:
  ```bash
  flutter drive \
    --target=integration_test/tongtai_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
  - [ ] Các bài kiểm tra vượt qua hoặc ghi chú nếu bị bỏ qua
  - [ ] Nhật ký thiết bị/bộ mô phỏng không hiển thị sự cố

### Phân Tích Mã (Lint)
- [ ] Lệnh: `flutter analyze`
  - [ ] Không có lỗi được báo cáo
  - [ ] Không có cảnh báo (hoặc chỉ cảnh báo có thể chấp nhận được)
  - [ ] Đầu ra xác nhận: `No issues found!`

### Kiểm Tra Định Dạng Mã
- [ ] Lệnh: `dart format --line-length 100 --dry-run .`
  - [ ] Báo cáo: không có tệp nào cần định dạng (hoặc liệt kê các tệp cần)
  - [ ] Nếu các tệp cần định dạng: `dart format --line-length 100 .` để sửa

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả các bài kiểm tra vượt qua / ⚠️ Một số lỗi kiểm tra / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Sửa các bài kiểm tra không thành công trước khi khóa Phase 2

---

## 5. Xử Lý Các Vấn Đề Dành Riêng Cho Môi Trường (Khắc Phục Bất Kỳ Vấn Đề Nào)

### Vấn Đề Dành Riêng Cho macOS
- [ ] Không có sự không khớp "iOS deployment target"?
  - Kiểm tra: `cd mobile/ios && pod install` thành công?
- [ ] Không có vấn đề kiến trúc bản địa M1/M2?
  - Kiểm tra: `flutter run -t lib/main_tongtai.dart` trên Mac M1/M2 thành công?
- [ ] Vấn đề đường dẫn (khoảng trắng trong đường dẫn, ký tự đặc biệt)?

### Vấn Đề Dành Riêng Cho Windows
- [ ] Tương thích Git Bash so với CMD.exe?
- [ ] Đường dẫn Android SDK được đặt chính xác?
- [ ] Không có vấn đề kết thúc dòng (CRLF so với LF)?

### Vấn Đề Dành Riêng Cho Linux
- [ ] Vấn đề X11/Wayland cho bộ mô phỏng?
- [ ] Không có vấn đề quyền (USB cho thiết bị)?

### Phụ Thuộc Bị Thiếu
- [ ] Tất cả các gói Pub được tải xuống không có lỗi?
  ```bash
  flutter pub get
  flutter pub run build_runner build
  ```
- [ ] Không có tham nhũng bộ đệm pub?
  ```bash
  flutter pub cache clean
  flutter pub get
  ```

### Xung Đột Phiên Bản
- [ ] Phiên bản Flutter khớp với `.flutter-version` (nếu được ghim)?
- [ ] Phiên bản Dart khớp với phiên bản được bundled của Flutter?
  ```bash
  flutter doctor -v
  ```

### Vấn Đề Xây Dựng Dành Riêng Cho Nền Tảng
- [ ] Android: Không có vấn đề NDK?
  ```bash
  flutter doctor -v | grep "Android SDK"
  ```
- [ ] iOS: Không có vấn đề CocoaPods (nếu áp dụng)?
  ```bash
  pod repo update
  cd mobile/ios && pod install
  ```

### Đánh Giá Rủi Ro
- [ ] ✅ Không có vấn đề môi trường / ⚠️ Một số vấn đề được tìm thấy / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Ghi lại giải pháp khắc phục trong BUILD-AND-RUN-GUIDE

---

## 6. Đánh Giá Tài Liệu Xây Dựng

### Xác Minh BUILD-AND-RUN-GUIDE

#### Tồn Tại & Hoàn Thành?
- [ ] Vị trí tệp: `docs/QUICK-START.md` hoặc `docs/tongtai/BUILD-AND-RUN-GUIDE.md`
- [ ] Tệp có thể đọc được và định dạng tốt (Markdown)
- [ ] Chứa các phần:
  - [ ] Điều kiện tiên quyết (hệ thống, công cụ, tài khoản)
  - [ ] Bắt đầu nhanh (sao chép, xây dựng, chạy)
  - [ ] Mục tiêu xây dựng (gỡ lỗi, phát hành, APK, AAB, IPA)
  - [ ] Kiểm tra (đơn vị, tích hợp, lint)
  - [ ] Khắc phục sự cố (lỗi phổ biến + giải pháp)
  - [ ] Đa ngôn ngữ (EN + VI)?

#### Phần Điều Kiện Tiên Quyết
- [ ] Liệt kê tất cả các công cụ bắt buộc với phiên bản
  - [ ] Flutter 3.22+
  - [ ] Dart 3.4+
  - [ ] Android SDK 24+
  - [ ] Git 2.37+
  - [ ] IDE (khuyến nghị tùy chọn)
- [ ] Hướng dẫn cài đặt rõ ràng (các liên kết được cung cấp)
- [ ] Dành riêng cho nền tảng (macOS, Windows, Linux, iOS)

#### Phần Bắt Đầu Nhanh
- [ ] Hướng dẫn từng bước sao chép + xây dựng + chạy
- [ ] Các lệnh là chính xác (sao chép và dán sẵn sàng)
- [ ] Đầu ra dự kiến cho mỗi bước được ghi lại
- [ ] Bao gồm cả Hub và Tổng Tài

#### Phần Mục Tiêu Xây Dựng
- [ ] Hướng dẫn xây dựng gỡ lỗi
- [ ] Hướng dẫn phát hành APK
- [ ] Hướng dẫn phát hành AAB
- [ ] Hướng dẫn phát hành IPA (nếu áp dụng)
- [ ] Vị trí tạo phẩm được ghi lại

#### Phần Kiểm Tra
- [ ] Lệnh bài kiểm tra đơn vị
- [ ] Lệnh bài kiểm tra tích hợp
- [ ] Lệnh phân tích mã (lint)
- [ ] Lệnh định dạng mã
- [ ] Cách diễn giải kết quả kiểm tra

#### Phần Khắc Phục Sự Cố
- [ ] Lỗi phổ biến được ghi lại:
  - [ ] "Dart SDK không tìm thấy"
  - [ ] "Không tìm thấy Android toolchain"
  - [ ] "Cài đặt Pod không thành công"
  - [ ] "Xây dựng không thành công với lỗi quyền"
  - [ ] "Ứng dụng bị sự cố khi khởi động"
- [ ] Các giải pháp được cung cấp cho mỗi
- [ ] Liên kết đến tài nguyên bên ngoài (nếu cần)

#### Hỗ Trợ Đa Ngôn Ngữ (EN + VI)
- [ ] Phần Anh văn có mặt và hoàn thành
- [ ] Phần Tiếng Việt có mặt và hoàn thành
- [ ] Thuật ngữ nhất quán (ví dụ: "Tổng Tài" so với "Hub")

### Đánh Giá Rủi Ro
- [ ] ✅ Hướng dẫn hoàn chỉnh & chính xác / ⚠️ Cần cập nhật nhỏ / 🚨 Các phần chính bị thiếu
- **Hành động chặn:** Hoàn thành các phần bị thiếu trước Phase 2

---

## 7. Kiểm Tra Thiết Bị Thực (Tùy Chọn cho Phase 1C)

### Thiết Bị Android
- [ ] Samsung S24 Ultra (flagship, nếu có):
  - [ ] Ứng dụng Hub cài đặt và chạy
  - [ ] Ứng dụng Tổng Tài cài đặt và chạy
  - [ ] Cả hai ứng dụng có hiệu suất cao (không nhức)
  - [ ] Tiêu thụ pin chấp nhận được (<5% mỗi giờ nhàn rỗi)
- [ ] Thiết bị cấp thấp hơn (Nokia 6.1 hoặc tương đương):
  - [ ] Ứng dụng Hub cài đặt và chạy
  - [ ] Ứng dụng Tổng Tài cài đặt và chạy
  - [ ] Không sự cố khi khởi động
  - [ ] Cuộn/điều hướng mượt mà (>30fps)

### Thiết Bị iOS (nếu Phase 1C bao gồm iOS)
- [ ] iPad (nếu có):
  - [ ] Ứng dụng Hub cài đặt và chạy
  - [ ] Ứng dụng Tổng Tài cài đặt và chạy
  - [ ] Bố cục thích hợp cho kích thước máy tính bảng
- [ ] iPhone (nếu có):
  - [ ] Ứng dụng Hub cài đặt và chạy
  - [ ] Ứng dụng Tổng Tài cài đặt và chạy
  - [ ] Notch/safe area được tôn trọng

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả thiết bị được kiểm tra OK / ⚠️ Một số vấn đề thiết bị / 🚨 Sự cố hoặc chỉ ra chặn đường
- **Hành động chặn:** Gỡ lỗi các vấn đề dành riêng cho thiết bị trước Phase 2

---

## 8. Quyết Định Go/No-Go Tổng Thể

### Tất Cả 7 Khu Vực Được Vượt Qua?
- [ ] Điều Kiện Tiên Quyết: ✅ / ⚠️ / 🚨
- [ ] Bắt Đầu Nhanh: ✅ / ⚠️ / 🚨
- [ ] Mục Tiêu Xây Dựng: ✅ / ⚠️ / 🚨
- [ ] Lệnh Kiểm Tra: ✅ / ⚠️ / 🚨
- [ ] Vấn Đề Môi Trường: ✅ / ⚠️ / 🚨
- [ ] Tài Liệu Xây Dựng: ✅ / ⚠️ / 🚨
- [ ] Kiểm Tra Thiết Bị Thực: ✅ / ⚠️ / 🚨 (hoặc N/A)

### Khuyến Cáo
- [ ] **GO** — Quy trình xây dựng là bảo đảm và được ghi lại; bất kỳ ai cũng có thể xây dựng Tổng Tài
- [ ] **GO với điều kiện** — Vấn đề doc/xây dựng nhỏ; không phải chặn đường Phase 2
  - Điều kiện: [danh sách ở đây]
- [ ] **HOLD** — Xây dựng bị hỏng hoặc quy trình không rõ ràng; báo cáo cho Founder
  - Chặn đường: [danh sách ở đây]

### Tóm Tắt Sự Sẵn Sàng Xây Dựng
| Số Liệu | Hub | Tổng Tài | Ghi Chú |
|--------|-----|----------|-------|
| Thời gian xây dựng gỡ lỗi | [__s] | [__s] | |
| Kích thước APK phát hành | [__MB] | [__MB] | < 200MB chấp nhận được |
| Kích thước AAB phát hành | [__MB] | [__MB] | |
| Tỷ lệ vượt qua bài kiểm tra đơn vị | [__%] | [__%] | > 80% chấp nhận được |
| Thời gian thực hiện kiểm tra | [__s] | [__s] | < 30s chấp nhận được |
| Phân tích mã vượt qua | ✅ / ❌ | ✅ / ❌ | Phải vượt qua |
| Thiết bị thực được kiểm tra | ✅ / ⚠️ / ❌ | ✅ / ⚠️ / ❌ | |

### Ký Tên
- **Build Engineer:** _________________ **Ngày:** _______
- **QA/Tester:** _________________ **Ngày:** _______
