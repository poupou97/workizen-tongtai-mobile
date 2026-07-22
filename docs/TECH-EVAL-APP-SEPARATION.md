# App Separation Validation — Phase 1C Technical Evaluation

**Period:** Jul 20–26, 2026  
**Owner:** Tech Lead / Build Engineer  
**Status:** Checklist for Phase 1C app isolation & build independence

---

## 🎯 Purpose

Validate that Hub and Tổng Tài can coexist in a single repo, build independently, and have zero cross-product dependencies. Ensures the folder structure and CI/CD setup support parallel development.

---

## 1. Folder Structure Validation

### Shared Core Layer
- [ ] Directory exists: `mobile/shared/core/`
- [ ] Subdirectories present:
  - [ ] `mobile/shared/core/storage/` (SQLite + Drift)
  - [ ] `mobile/shared/core/ai/` (xAI/OpenRouter client)
  - [ ] `mobile/shared/core/ui/` (components + theme)
  - [ ] `mobile/shared/core/navigation/` (router + nav framework)
  - [ ] `mobile/shared/core/utils/` (common utilities)
- [ ] Shared layer has NO product-specific code
- [ ] Shared layer README documents what can be reused
- [ ] Test: `grep -r "hub\|tongtai" mobile/shared/core/ | wc -l` → 0 matches

### Hub Product Layer
- [ ] Directory exists: `mobile/hub/`
- [ ] Subdirectories present:
  - [ ] `lib/` (Dart source)
  - [ ] `lib/main_hub.dart` (entry point)
  - [ ] `lib/features/` (Hub-specific features)
  - [ ] `lib/screens/` (Hub-specific screens)
  - [ ] `test/` (Hub unit tests)
  - [ ] `integration_test/` (Hub E2E tests)
- [ ] Hub has NO imports from `tongtai/`
- [ ] Test: `grep -r "from.*tongtai\|import.*tongtai" mobile/hub/ | wc -l` → 0 matches

### Tổng Tài Product Layer
- [ ] Directory exists: `mobile/tongtai/`
- [ ] Subdirectories present:
  - [ ] `lib/` (Dart source)
  - [ ] `lib/main_tongtai.dart` (entry point)
  - [ ] `lib/features/` (Tổng Tài-specific features)
  - [ ] `lib/screens/` (Tổng Tài-specific screens)
  - [ ] `lib/models/` (Tổng Tài 15-entity data model)
  - [ ] `test/` (Tổng Tài unit tests)
  - [ ] `integration_test/` (Tổng Tài E2E tests)
- [ ] Tổng Tài has NO imports from `hub/`
- [ ] Test: `grep -r "from.*hub\|import.*hub" mobile/tongtai/ | wc -l` → 0 matches

### Risk Assessment
- [ ] ✅ Folder structure clean / ⚠️ Needs cleanup / 🚨 Blocker found
- **Blocker action:** Refactor cross-product imports before Phase 2

---

## 2. Dependency Isolation

### Import Restrictions (Automated)

#### Hub ← Tongtai (Must Be Blocked)
- [ ] Linter rule added to `analysis_options.yaml`:
  ```yaml
  linter:
    rules:
      - avoid_relative_import_anywhere
  # Custom: mobile/hub/ cannot import from mobile/tongtai/
  ```
- [ ] CI check: `flutter analyze` flags any `tongtai` imports in `hub/`
- [ ] Test: Add a dummy import of `tongtai` in `hub/` → CI must fail

#### Tongtai ← Hub (Must Be Blocked)
- [ ] Same linter rule applies to `tongtai/`
- [ ] CI check: `flutter analyze` flags any `hub` imports in `tongtai/`
- [ ] Test: Add a dummy import of `hub` in `tongtai/` → CI must fail

### Shared Core ← Hub/Tongtai (Must Not Happen)
- [ ] Linter rule: `mobile/shared/core/` cannot import from `hub/` or `tongtai/`
- [ ] CI check enforces this
- [ ] Test: Add a dummy import of `hub` in `shared/core/` → CI must fail

### Pubspec Dependencies
- [ ] Hub's `pubspec.yaml` lists dependencies
  - [ ] References `path: ../shared/core/` for core libs
  - [ ] No reference to `tongtai`
- [ ] Tổng Tài's `pubspec.yaml` lists dependencies
  - [ ] References `path: ../shared/core/` for core libs
  - [ ] No reference to `hub`
- [ ] Shared Core's `pubspec.yaml` lists dependencies
  - [ ] No reference to `hub` or `tongtai`
- [ ] Test: Run `flutter pub get` for Hub → succeeds, no tongtai deps pulled

### Transitive Dependency Check
- [ ] `flutter pub get` for Hub doesn't pull tongtai dependencies
- [ ] `flutter pub get` for Tổng Tài doesn't pull hub dependencies
- [ ] Test: Compare `pubspec.lock` before/after: only expected deps differ

### Risk Assessment
- [ ] ✅ All imports clean / ⚠️ Needs CI enforcement / 🚨 Blockers found
- **Blocker action:** Add linter rules to `analysis_options.yaml` + CI check

---

## 3. Build Targets Validation

### Hub Build Target
- [ ] Entry point exists: `mobile/hub/lib/main_hub.dart`
- [ ] `main_hub.dart` does NOT reference `tongtai` package
- [ ] Build command: `flutter run -t lib/main_hub.dart` on emulator/device
  - [ ] App launches successfully
  - [ ] App branded as Hub (not Tổng Tài)
  - [ ] All Hub features (document scan, chat, etc.) work
- [ ] Release build: `flutter build apk -t lib/main_hub.dart --release`
  - [ ] APK generated without errors
  - [ ] APK size reasonable (< 200MB)
  - [ ] Test: Install on real device, app runs
- [ ] Test on device: Confirm app identifies as "Workizen Hub"

### Tổng Tài Build Target
- [ ] Entry point exists: `mobile/tongtai/lib/main_tongtai.dart`
- [ ] `main_tongtai.dart` does NOT reference `hub` package
- [ ] Build command: `flutter run -t lib/main_tongtai.dart` on emulator/device
  - [ ] App launches successfully
  - [ ] App branded as Tổng Tài (not Hub)
  - [ ] All Tổng Tài features (entity list, search, etc.) work
- [ ] Release build: `flutter build apk -t lib/main_tongtai.dart --release`
  - [ ] APK generated without errors
  - [ ] APK size reasonable (< 200MB)
  - [ ] Test: Install on real device, app runs
- [ ] Test on device: Confirm app identifies as "Tổng Tài"

### Both Builds on Same Machine
- [ ] Clean build for Hub from scratch:
  ```bash
  rm -rf build/
  flutter clean
  flutter pub get
  flutter build apk -t lib/main_hub.dart --release
  ```
  - [ ] Succeeds without errors
- [ ] Clean build for Tổng Tài from scratch:
  ```bash
  rm -rf build/
  flutter clean
  flutter pub get
  flutter build apk -t lib/main_tongtai.dart --release
  ```
  - [ ] Succeeds without errors
- [ ] Both APKs are different (different branding, features, etc.)

### Risk Assessment
- [ ] ✅ Both build independently / ⚠️ Build issues / 🚨 Blockers found
- **Blocker action:** Debug build errors + fix entry points/imports

---

## 4. Test Suite Isolation

### Hub Unit Tests
- [ ] Test command: `flutter test --tags=hub test/`
  - [ ] All tests pass
  - [ ] No tongtai imports in test files
- [ ] Test directory structure:
  - [ ] `mobile/hub/test/` contains only Hub unit tests
  - [ ] No Hub tests reference tongtai code
- [ ] Test count: [Hub has __ unit tests]

### Tổng Tài Unit Tests
- [ ] Test command: `flutter test --tags=tongtai test/`
  - [ ] All tests pass
  - [ ] No hub imports in test files
- [ ] Test directory structure:
  - [ ] `mobile/tongtai/test/` contains only Tổng Tài unit tests
  - [ ] No Tổng Tài tests reference hub code
- [ ] Test count: [Tổng Tài has __ unit tests]

### Shared Core Unit Tests
- [ ] Test command: `flutter test mobile/shared/core/test/`
  - [ ] All tests pass
  - [ ] Tests verify shared components work for both products
- [ ] Test coverage: ✅ > 70% / ⚠️ 50-70% / 🚨 < 50%

### Integration Tests (E2E)

#### Hub Integration Tests
- [ ] Test file: `mobile/hub/integration_test/hub_flow_test.dart`
- [ ] Test command:
  ```bash
  flutter drive \
    --target=integration_test/hub_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
- [ ] Test scenario: Scan document → chat → export (mock)
  - [ ] Succeeds on emulator
  - [ ] Succeeds on real device (S24 or equivalent)
- [ ] No tongtai imports in test code

#### Tổng Tài Integration Tests
- [ ] Test file: `mobile/tongtai/integration_test/tongtai_flow_test.dart`
- [ ] Test command:
  ```bash
  flutter drive \
    --target=integration_test/tongtai_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
- [ ] Test scenario: Browse entities → search → view detail
  - [ ] Succeeds on emulator
  - [ ] Succeeds on real device (S24 or equivalent)
- [ ] No hub imports in test code

### Risk Assessment
- [ ] ✅ All tests isolated + passing / ⚠️ Some test issues / 🚨 Blockers found
- **Blocker action:** Fix cross-product test dependencies

---

## 5. CI/CD Pipeline Validation

### GitHub Actions / CI Configuration

#### Lint Stage (Per Product)
- [ ] CI runs: `flutter analyze` for Hub
  - [ ] Checks: no tongtai imports
  - [ ] Checks: no other violations
  - [ ] Passes
- [ ] CI runs: `flutter analyze` for Tổng Tài
  - [ ] Checks: no hub imports
  - [ ] Checks: no other violations
  - [ ] Passes
- [ ] CI runs: `flutter analyze` for shared/core
  - [ ] Checks: no product-specific imports
  - [ ] Passes

#### Format Stage (Per Product)
- [ ] CI runs: `dart format --line-length 100` for Hub
  - [ ] No formatting errors
- [ ] CI runs: `dart format --line-length 100` for Tổng Tài
  - [ ] No formatting errors
- [ ] CI runs: `dart format --line-length 100` for shared/core
  - [ ] No formatting errors

#### Test Stage (Per Product)
- [ ] CI runs: `flutter test --tags=hub` for Hub
  - [ ] All unit tests pass
  - [ ] Coverage > 70% (or target percentage)
- [ ] CI runs: `flutter test --tags=tongtai` for Tổng Tài
  - [ ] All unit tests pass
  - [ ] Coverage > 70% (or target percentage)
- [ ] CI runs: `flutter test` for shared/core
  - [ ] All shared tests pass
  - [ ] Coverage > 80%

#### Build Stage (Per Product)
- [ ] CI builds: `flutter build apk -t lib/main_hub.dart --release`
  - [ ] Succeeds
  - [ ] APK artifact uploaded
- [ ] CI builds: `flutter build apk -t lib/main_tongtai.dart --release`
  - [ ] Succeeds
  - [ ] APK artifact uploaded
- [ ] CI builds: `flutter build appbundle -t lib/main_hub.dart --release`
  - [ ] Succeeds
  - [ ] AAB artifact uploaded
- [ ] CI builds: `flutter build appbundle -t lib/main_tongtai.dart --release`
  - [ ] Succeeds
  - [ ] AAB artifact uploaded

### Risk Assessment
- [ ] ✅ CI pipeline clean / ⚠️ CI issues / 🚨 Blockers found
- **Blocker action:** Debug CI configuration + fix build/test steps

---

## 6. Future Split Readiness

### Code Structure for Eventual Repo Split

#### Shared Core Pub Package
- [ ] Shared code could be extracted to independent Dart package?
  - [ ] `mobile/shared/core/` has minimal dependencies
  - [ ] No Flutter-specific code in core storage/AI (only in ui/navigation)
  - [ ] Clean API boundary (exports clear interfaces)
- [ ] Pubspec ready for publication:
  - [ ] Proper `name:`, `version:`, `description:` fields
  - [ ] Homepage + repository URLs documented

#### Hub Pub Package (Future)
- [ ] Hub code structured for independent package?
  - [ ] Features are modules (can be yanked independently)
  - [ ] No circular dependencies
  - [ ] Clear entry point (`main_hub.dart`)

#### Tổng Tài Pub Package (Future)
- [ ] Tổng Tài code structured for independent package?
  - [ ] Features are modules (can be yanked independently)
  - [ ] No circular dependencies
  - [ ] Clear entry point (`main_tongtai.dart`)

### Circular Dependency Check
- [ ] Run `dart pub get` + inspect dependency graph
  - [ ] No cycles between shared/core → hub → tongtai
  - [ ] Shared can be published independently
- [ ] Test: Extract shared/core to separate directory, both products still build

### Risk Assessment
- [ ] ✅ Structure ready for split / ⚠️ Needs refactor / 🚨 Circular deps found
- **Blocker action:** Resolve circular dependencies before Phase 2 lock

---

## 7. Overall Go/No-Go Decision

### All 6 Areas Passed?
- [ ] Folder Structure: ✅ / ⚠️ / 🚨
- [ ] Dependency Isolation: ✅ / ⚠️ / 🚨
- [ ] Build Targets: ✅ / ⚠️ / 🚨
- [ ] Test Suite Isolation: ✅ / ⚠️ / 🚨
- [ ] CI/CD Pipeline: ✅ / ⚠️ / 🚨
- [ ] Split Readiness: ✅ / ⚠️ / 🚨

### Recommendation
- [ ] **GO** — All areas passed; both apps can coexist + build independently
- [ ] **GO with conditions** — Minor structural issues; not blocking Phase 2
  - Conditions: [list here]
- [ ] **HOLD** — Needs refactoring; escalate to Founder
  - Blockers: [list here]

### Sign-Off
- **Tech Lead:** _________________ **Date:** _______
- **Build Engineer:** _________________ **Date:** _______

---

---

# Xác Minh Tách Ứng Dụng — Đánh Giá Kỹ Thuật Phase 1C

**Kỳ:** 20–26 Tháng 7, 2026  
**Chủ Trì:** Tech Lead / Build Engineer  
**Trạng Thái:** Bảng kiểm để cô lập ứng dụng & độc lập xây dựng

---

## 🎯 Mục Đích

Xác minh rằng Hub và Tổng Tài có thể cùng tồn tại trong một kho duy nhất, xây dựng độc lập và có phụ thuộc qua sản phẩm bằng không. Đảm bảo cấu trúc thư mục và thiết lập CI/CD hỗ trợ phát triển song song.

---

## 1. Xác Minh Cấu Trúc Thư Mục

### Tầng Chia Sẻ Cốt Lõi
- [ ] Thư mục tồn tại: `mobile/shared/core/`
- [ ] Thư mục con có mặt:
  - [ ] `mobile/shared/core/storage/` (SQLite + Drift)
  - [ ] `mobile/shared/core/ai/` (xAI/OpenRouter client)
  - [ ] `mobile/shared/core/ui/` (thành phần + chủ đề)
  - [ ] `mobile/shared/core/navigation/` (router + khung nav)
  - [ ] `mobile/shared/core/utils/` (tiện ích chung)
- [ ] Tầng chia sẻ KHÔNG có mã cụ thể sản phẩm
- [ ] README tầng chia sẻ ghi lại những gì có thể được tái sử dụng
- [ ] Kiểm tra: `grep -r "hub\|tongtai" mobile/shared/core/ | wc -l` → 0 trận đấu

### Tầng Sản Phẩm Hub
- [ ] Thư mục tồn tại: `mobile/hub/`
- [ ] Thư mục con có mặt:
  - [ ] `lib/` (Nguồn Dart)
  - [ ] `lib/main_hub.dart` (điểm vào)
  - [ ] `lib/features/` (tính năng cụ thể Hub)
  - [ ] `lib/screens/` (màn hình cụ thể Hub)
  - [ ] `test/` (kiểm tra đơn vị Hub)
  - [ ] `integration_test/` (kiểm tra E2E Hub)
- [ ] Hub KHÔNG nhập từ `tongtai/`
- [ ] Kiểm tra: `grep -r "from.*tongtai\|import.*tongtai" mobile/hub/ | wc -l` → 0 trận đấu

### Tầng Sản Phẩm Tổng Tài
- [ ] Thư mục tồn tại: `mobile/tongtai/`
- [ ] Thư mục con có mặt:
  - [ ] `lib/` (Nguồn Dart)
  - [ ] `lib/main_tongtai.dart` (điểm vào)
  - [ ] `lib/features/` (tính năng cụ thể Tổng Tài)
  - [ ] `lib/screens/` (màn hình cụ thể Tổng Tài)
  - [ ] `lib/models/` (mô hình dữ liệu 15-entity của Tổng Tài)
  - [ ] `test/` (kiểm tra đơn vị Tổng Tài)
  - [ ] `integration_test/` (kiểm tra E2E Tổng Tài)
- [ ] Tổng Tài KHÔNG nhập từ `hub/`
- [ ] Kiểm tra: `grep -r "from.*hub\|import.*hub" mobile/tongtai/ | wc -l` → 0 trận đấu

### Đánh Giá Rủi Ro
- [ ] ✅ Cấu trúc thư mục sạch sẽ / ⚠️ Cần dọn dẹp / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Tái cấu trúc các nhập qua sản phẩm trước Phase 2

---

## 2. Cô Lập Phụ Thuộc

### Giới Hạn Nhập (Tự Động)

#### Hub ← Tongtai (Phải Bị Chặn)
- [ ] Quy tắc linter được thêm vào `analysis_options.yaml`:
  ```yaml
  linter:
    rules:
      - avoid_relative_import_anywhere
  # Tùy chỉnh: mobile/hub/ không thể nhập từ mobile/tongtai/
  ```
- [ ] Kiểm tra CI: `flutter analyze` gắn cờ bất kỳ nhập `tongtai` nào trong `hub/`
- [ ] Kiểm tra: Thêm nhập giả của `tongtai` trong `hub/` → CI phải thất bại

#### Tongtai ← Hub (Phải Bị Chặn)
- [ ] Quy tắc linter giống nhau áp dụng cho `tongtai/`
- [ ] Kiểm tra CI: `flutter analyze` gắn cờ bất kỳ nhập `hub` nào trong `tongtai/`
- [ ] Kiểm tra: Thêm nhập giả của `hub` trong `tongtai/` → CI phải thất bại

### Chia Sẻ Cốt Lõi ← Hub/Tongtai (Không Được Xảy Ra)
- [ ] Quy tắc linter: `mobile/shared/core/` không thể nhập từ `hub/` hoặc `tongtai/`
- [ ] Kiểm tra CI thực thi điều này
- [ ] Kiểm tra: Thêm nhập giả của `hub` trong `shared/core/` → CI phải thất bại

### Pubspec Phụ Thuộc
- [ ] `pubspec.yaml` của Hub liệt kê các phụ thuộc
  - [ ] Tham chiếu `path: ../shared/core/` cho thư viện cốt lõi
  - [ ] Không có tham chiếu đến `tongtai`
- [ ] `pubspec.yaml` của Tổng Tài liệt kê các phụ thuộc
  - [ ] Tham chiếu `path: ../shared/core/` cho thư viện cốt lõi
  - [ ] Không có tham chiếu đến `hub`
- [ ] `pubspec.yaml` của Shared Core liệt kê các phụ thuộc
  - [ ] Không có tham chiếu đến `hub` hoặc `tongtai`
- [ ] Kiểm tra: Chạy `flutter pub get` cho Hub → thành công, không có tongtai deps được kéo

### Kiểm Tra Phụ Thuộc Bắc Cầu
- [ ] `flutter pub get` cho Hub không kéo các phụ thuộc tongtai
- [ ] `flutter pub get` cho Tổng Tài không kéo các phụ thuộc hub
- [ ] Kiểm tra: So sánh `pubspec.lock` trước/sau: chỉ các deps dự kiến khác nhau

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả nhập sạch sẽ / ⚠️ Cần thực thi CI / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Thêm quy tắc linter vào `analysis_options.yaml` + kiểm tra CI

---

## 3. Xác Minh Mục Tiêu Xây Dựng

### Mục Tiêu Xây Dựng Hub
- [ ] Điểm vào tồn tại: `mobile/hub/lib/main_hub.dart`
- [ ] `main_hub.dart` KHÔNG tham chiếu gói `tongtai`
- [ ] Lệnh xây dựng: `flutter run -t lib/main_hub.dart` trên bộ mô phỏng/thiết bị
  - [ ] Ứng dụng khởi động thành công
  - [ ] Ứng dụng được ghi nhãn là Hub (không phải Tổng Tài)
  - [ ] Tất cả các tính năng Hub (quét tài liệu, trò chuyện, v.v.) hoạt động
- [ ] Xây dựng phát hành: `flutter build apk -t lib/main_hub.dart --release`
  - [ ] APK được tạo ra không có lỗi
  - [ ] Kích thước APK hợp lý (< 200MB)
  - [ ] Kiểm tra: Cài đặt trên thiết bị thực, ứng dụng chạy
- [ ] Kiểm tra trên thiết bị: Xác nhận ứng dụng xác định là "Workizen Hub"

### Mục Tiêu Xây Dựng Tổng Tài
- [ ] Điểm vào tồn tại: `mobile/tongtai/lib/main_tongtai.dart`
- [ ] `main_tongtai.dart` KHÔNG tham chiếu gói `hub`
- [ ] Lệnh xây dựng: `flutter run -t lib/main_tongtai.dart` trên bộ mô phỏng/thiết bị
  - [ ] Ứng dụng khởi động thành công
  - [ ] Ứng dụng được ghi nhãn là Tổng Tài (không phải Hub)
  - [ ] Tất cả các tính năng Tổng Tài (danh sách thực thể, tìm kiếm, v.v.) hoạt động
- [ ] Xây dựng phát hành: `flutter build apk -t lib/main_tongtai.dart --release`
  - [ ] APK được tạo ra không có lỗi
  - [ ] Kích thước APK hợp lý (< 200MB)
  - [ ] Kiểm tra: Cài đặt trên thiết bị thực, ứng dụng chạy
- [ ] Kiểm tra trên thiết bị: Xác nhận ứng dụng xác định là "Tổng Tài"

### Cả Hai Xây Dựng trên Cùng Một Máy
- [ ] Xây dựng sạch cho Hub từ đầu:
  ```bash
  rm -rf build/
  flutter clean
  flutter pub get
  flutter build apk -t lib/main_hub.dart --release
  ```
  - [ ] Thành công không có lỗi
- [ ] Xây dựng sạch cho Tổng Tài từ đầu:
  ```bash
  rm -rf build/
  flutter clean
  flutter pub get
  flutter build apk -t lib/main_tongtai.dart --release
  ```
  - [ ] Thành công không có lỗi
- [ ] Cả hai APK đều khác nhau (thương hiệu khác, tính năng khác, v.v.)

### Đánh Giá Rủi Ro
- [ ] ✅ Xây dựng độc lập / ⚠️ Vấn đề xây dựng / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Gỡ lỗi xây dựng + sửa điểm vào/nhập

---

## 4. Cô Lập Bộ Kiểm Tra

### Kiểm Tra Đơn Vị Hub
- [ ] Lệnh kiểm tra: `flutter test --tags=hub test/`
  - [ ] Tất cả các bài kiểm tra vượt qua
  - [ ] Không có nhập tongtai trong các tệp kiểm tra
- [ ] Cấu trúc thư mục kiểm tra:
  - [ ] `mobile/hub/test/` chứa chỉ các bài kiểm tra đơn vị Hub
  - [ ] Không có bài kiểm tra Hub tham chiếu mã tongtai
- [ ] Số lượng bài kiểm tra: [Hub có __ bài kiểm tra đơn vị]

### Kiểm Tra Đơn Vị Tổng Tài
- [ ] Lệnh kiểm tra: `flutter test --tags=tongtai test/`
  - [ ] Tất cả các bài kiểm tra vượt qua
  - [ ] Không có nhập hub trong các tệp kiểm tra
- [ ] Cấu trúc thư mục kiểm tra:
  - [ ] `mobile/tongtai/test/` chứa chỉ các bài kiểm tra đơn vị Tổng Tài
  - [ ] Không có bài kiểm tra Tổng Tài tham chiếu mã hub
- [ ] Số lượng bài kiểm tra: [Tổng Tài có __ bài kiểm tra đơn vị]

### Kiểm Tra Đơn Vị Chia Sẻ Cốt Lõi
- [ ] Lệnh kiểm tra: `flutter test mobile/shared/core/test/`
  - [ ] Tất cả các bài kiểm tra vượt qua
  - [ ] Các bài kiểm tra xác minh các thành phần chia sẻ hoạt động cho cả hai sản phẩm
- [ ] Phạm vi kiểm tra: ✅ > 70% / ⚠️ 50-70% / 🚨 < 50%

### Kiểm Tra Tích Hợp (E2E)

#### Kiểm Tra Tích Hợp Hub
- [ ] Tệp kiểm tra: `mobile/hub/integration_test/hub_flow_test.dart`
- [ ] Lệnh kiểm tra:
  ```bash
  flutter drive \
    --target=integration_test/hub_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
- [ ] Kịch bản kiểm tra: Quét tài liệu → trò chuyện → xuất (giả lập)
  - [ ] Thành công trên bộ mô phỏng
  - [ ] Thành công trên thiết bị thực (S24 hoặc tương đương)
- [ ] Không có nhập tongtai trong mã kiểm tra

#### Kiểm Tra Tích Hợp Tổng Tài
- [ ] Tệp kiểm tra: `mobile/tongtai/integration_test/tongtai_flow_test.dart`
- [ ] Lệnh kiểm tra:
  ```bash
  flutter drive \
    --target=integration_test/tongtai_flow_test.dart \
    --driver=test_driver/integration_test.dart
  ```
- [ ] Kịch bản kiểm tra: Duyệt các thực thể → tìm kiếm → xem chi tiết
  - [ ] Thành công trên bộ mô phỏng
  - [ ] Thành công trên thiết bị thực (S24 hoặc tương đương)
- [ ] Không có nhập hub trong mã kiểm tra

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả các bài kiểm tra được cô lập + vượt qua / ⚠️ Một số vấn đề kiểm tra / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Sửa các phụ thuộc kiểm tra qua sản phẩm

---

## 5. Xác Minh Đường Ống CI/CD

### GitHub Actions / Cấu Hình CI

#### Giai Đoạn Lint (Trên Mỗi Sản Phẩm)
- [ ] CI chạy: `flutter analyze` cho Hub
  - [ ] Kiểm tra: không có nhập tongtai
  - [ ] Kiểm tra: không có vi phạm khác
  - [ ] Vượt qua
- [ ] CI chạy: `flutter analyze` cho Tổng Tài
  - [ ] Kiểm tra: không có nhập hub
  - [ ] Kiểm tra: không có vi phạm khác
  - [ ] Vượt qua
- [ ] CI chạy: `flutter analyze` cho shared/core
  - [ ] Kiểm tra: không có nhập cụ thể sản phẩm
  - [ ] Vượt qua

#### Giai Đoạn Định Dạng (Trên Mỗi Sản Phẩm)
- [ ] CI chạy: `dart format --line-length 100` cho Hub
  - [ ] Không có lỗi định dạng
- [ ] CI chạy: `dart format --line-length 100` cho Tổng Tài
  - [ ] Không có lỗi định dạng
- [ ] CI chạy: `dart format --line-length 100` cho shared/core
  - [ ] Không có lỗi định dạng

#### Giai Đoạn Kiểm Tra (Trên Mỗi Sản Phẩm)
- [ ] CI chạy: `flutter test --tags=hub` cho Hub
  - [ ] Tất cả các bài kiểm tra đơn vị vượt qua
  - [ ] Phạm vi > 70% (hoặc tỷ lệ phục vụ đích)
- [ ] CI chạy: `flutter test --tags=tongtai` cho Tổng Tài
  - [ ] Tất cả các bài kiểm tra đơn vị vượt qua
  - [ ] Phạm vi > 70% (hoặc tỷ lệ phục vụ đích)
- [ ] CI chạy: `flutter test` cho shared/core
  - [ ] Tất cả các bài kiểm tra chia sẻ vượt qua
  - [ ] Phạm vi > 80%

#### Giai Đoạn Xây Dựng (Trên Mỗi Sản Phẩm)
- [ ] CI xây dựng: `flutter build apk -t lib/main_hub.dart --release`
  - [ ] Thành công
  - [ ] Tạo phẩm APK được tải lên
- [ ] CI xây dựng: `flutter build apk -t lib/main_tongtai.dart --release`
  - [ ] Thành công
  - [ ] Tạo phẩm APK được tải lên
- [ ] CI xây dựng: `flutter build appbundle -t lib/main_hub.dart --release`
  - [ ] Thành công
  - [ ] Tạo phẩm AAB được tải lên
- [ ] CI xây dựng: `flutter build appbundle -t lib/main_tongtai.dart --release`
  - [ ] Thành công
  - [ ] Tạo phẩm AAB được tải lên

### Đánh Giá Rủi Ro
- [ ] ✅ Đường ống CI sạch sẽ / ⚠️ Vấn đề CI / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Gỡ lỗi cấu hình CI + sửa bước xây dựng/kiểm tra

---

## 6. Sự Sẵn Sàng Tách Trong Tương Lai

### Cấu Trúc Mã Để Tách Kho Dự Kiến

#### Gói Pub Chia Sẻ Cốt Lõi
- [ ] Mã chia sẻ có thể được trích xuất thành gói Dart độc lập?
  - [ ] `mobile/shared/core/` có phụ thuộc tối thiểu
  - [ ] Không có mã cụ thể Flutter trong bộ nhớ/AI cốt lõi (chỉ trong ui/navigation)
  - [ ] Ranh giới API sạch sẽ (xuất các giao diện rõ ràng)
- [ ] Pubspec sẵn sàng để xuất bản:
  - [ ] Các trường `name:`, `version:`, `description:` thích hợp
  - [ ] URL Trang Chủ + kho lưu trữ được tài liệu hóa

#### Gói Pub Hub (Trong Tương Lai)
- [ ] Mã Hub được cấu trúc cho gói độc lập?
  - [ ] Các tính năng là mô-đun (có thể được kéo độc lập)
  - [ ] Không có phụ thuộc vòng tròn
  - [ ] Điểm vào rõ ràng (`main_hub.dart`)

#### Gói Pub Tổng Tài (Trong Tương Lai)
- [ ] Mã Tổng Tài được cấu trúc cho gói độc lập?
  - [ ] Các tính năng là mô-đun (có thể được kéo độc lập)
  - [ ] Không có phụ thuộc vòng tròn
  - [ ] Điểm vào rõ ràng (`main_tongtai.dart`)

### Kiểm Tra Phụ Thuộc Vòng Tròn
- [ ] Chạy `dart pub get` + kiểm tra biểu đồ phụ thuộc
  - [ ] Không có chu kỳ giữa shared/core → hub → tongtai
  - [ ] Chia sẻ có thể được xuất bản độc lập
- [ ] Kiểm tra: Trích xuất shared/core vào thư mục riêng, cả hai sản phẩm vẫn xây dựng

### Đánh Giá Rủi Ro
- [ ] ✅ Cấu trúc sẵn sàng để tách / ⚠️ Cần tái cấu trúc / 🚨 Phụ thuộc vòng tròn tìm thấy
- **Hành động chặn:** Giải quyết các phụ thuộc vòng tròn trước khi khóa Phase 2

---

## 7. Quyết Định Go/No-Go Tổng Thể

### Tất Cả 6 Khu Vực Được Vượt Qua?
- [ ] Cấu Trúc Thư Mục: ✅ / ⚠️ / 🚨
- [ ] Cô Lập Phụ Thuộc: ✅ / ⚠️ / 🚨
- [ ] Mục Tiêu Xây Dựng: ✅ / ⚠️ / 🚨
- [ ] Cô Lập Bộ Kiểm Tra: ✅ / ⚠️ / 🚨
- [ ] Đường Ống CI/CD: ✅ / ⚠️ / 🚨
- [ ] Sự Sẵn Sàng Tách: ✅ / ⚠️ / 🚨

### Khuyến Cáo
- [ ] **GO** — Tất cả các khu vực đã vượt qua; cả hai ứng dụng có thể cùng tồn tại + xây dựng độc lập
- [ ] **GO với điều kiện** — Vấn đề cấu trúc nhỏ; không phải chặn đường Phase 2
  - Điều kiện: [danh sách ở đây]
- [ ] **HOLD** — Cần tái cấu trúc; báo cáo cho Founder
  - Chặn đường: [danh sách ở đây]

### Ký Tên
- **Tech Lead:** _________________ **Ngày:** _______
- **Build Engineer:** _________________ **Ngày:** _______
