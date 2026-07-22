# App Separation Plan: Keeping Hub & Tổng Tài Isolated in One Repository

## Kế Hoạch Tách Biệt Ứng Dụng: Giữ Hub & Tổng Tài Cô Lập Trong Một Kho Lưu Trữ

> **Define folder structure and isolation rules to prevent feature bleed between Hub and Tổng Tài.**

**Status:** 📋 DRAFT for Review  
**Phase:** 1B — Technology Planning  
**Owner:** Architecture Team  
**Date:** 2026-07-13

---

## English — App Separation Plan

### Executive Summary

During MVP (Phase 1B-1C), Hub and Tổng Tài share the same Git repository and Flutter workspace for code reuse efficiency. However, they must remain isolated to prevent:

- Feature/code leakage from one product to another
- Confused ownership (who owns this screen? who maintains this service?)
- Coupling that makes future split painful
- Build bloat (Tổng Tài build includes Hub code)

**Solution:** Clear folder structure + dependency rules + CI enforcement.

---

### Folder Structure

```
mobile/
├── shared/                          ← SHARED PACKAGES (used by both products)
│   ├── core/
│   │   ├── storage/                 # SQLite, Drift
│   │   ├── ai/                      # xAI, OpenRouter
│   │   ├── ui/                      # Flutter components
│   │   ├── utils/                   # Helpers
│   │   └── models/                  # Shared models (app config, prefs)
│   ├── services/                    # Future: sync, backup, notifications
│   └── pubspec.yaml
│
├── hub/                             ← HUB PRODUCT (Hub only)
│   ├── screens/
│   │   ├── home/
│   │   ├── chat/
│   │   ├── document/
│   │   ├── output/
│   │   ├── studio/
│   │   └── settings/
│   ├── models/
│   │   ├── chat_message.dart
│   │   ├── document.dart
│   │   ├── collection.dart
│   │   ├── output.dart
│   │   └── user_preferences.dart
│   ├── services/
│   │   ├── document_service.dart
│   │   ├── chat_service.dart
│   │   ├── output_service.dart
│   │   └── ocr_service.dart
│   ├── providers/                   # Riverpod state management
│   │   ├── document_providers.dart
│   │   ├── chat_providers.dart
│   │   └── output_providers.dart
│   ├── widgets/                     # Hub-specific UI components
│   │   ├── document_card.dart
│   │   ├── chat_bubble.dart
│   │   └── output_preview.dart
│   ├── main_hub.dart               # Entry point (flutter run -t lib/main_hub.dart)
│   └── pubspec.yaml                # Depends on: shared/core, shared/services
│
├── tongtai/                         ← TỔNG TÀI PRODUCT (Tổng Tài only)
│   ├── screens/
│   │   ├── home/
│   │   ├── producer/               # Nguồn Hàng
│   │   ├── inventory/              # Tồn Kho
│   │   ├── consumer/               # Khách Hàng
│   │   ├── finance/                # Tài Chính
│   │   ├── reports/                # Báo Cáo
│   │   ├── opportunity/            # Cơ Hội
│   │   ├── copilot/                # AI Tổng Tài
│   │   ├── journey/                # Hành Trình
│   │   └── settings/
│   ├── models/
│   │   ├── producer.dart           # Supplier/source data
│   │   ├── inventory.dart          # Product/stock data
│   │   ├── consumer.dart           # Customer data
│   │   ├── order.dart              # Transaction data
│   │   ├── finance.dart            # Revenue/expense data
│   │   ├── opportunity.dart        # Opportunity data
│   │   ├── journey.dart            # Business goal data
│   │   └── metadata.dart           # App-specific config
│   ├── services/
│   │   ├── producer_service.dart
│   │   ├── inventory_service.dart
│   │   ├── consumer_service.dart
│   │   ├── finance_service.dart
│   │   ├── opportunity_service.dart
│   │   └── journey_service.dart
│   ├── providers/
│   │   ├── producer_providers.dart
│   │   ├── inventory_providers.dart
│   │   ├── consumer_providers.dart
│   │   ├── finance_providers.dart
│   │   ├── opportunity_providers.dart
│   │   └── journey_providers.dart
│   ├── widgets/                    # Tổng Tài-specific UI
│   │   ├── producer_card.dart
│   │   ├── inventory_chart.dart
│   │   ├── customer_list_item.dart
│   │   └── opportunity_badge.dart
│   ├── main_tongtai.dart          # Entry point (flutter run -t lib/main_tongtai.dart)
│   └── pubspec.yaml               # Depends on: shared/core, shared/services
│
├── app/
│   ├── main_hub.dart              # Redirect to hub/main_hub.dart
│   ├── main_tongtai.dart          # Redirect to tongtai/main_tongtai.dart
│   └── pubspec.yaml
│
└── pubspec.yaml                    ← WORKSPACE ROOT (optional, for monorepo tooling)
```

---

### Dependency Rules

**ALLOWED Dependencies:**

```
shared/core
  ↑ (no dependencies on anything else)

shared/services
  ↑ depends on: shared/core ONLY

hub/
  ↑ depends on: shared/core, shared/services ONLY

tongtai/
  ↑ depends on: shared/core, shared/services ONLY

app/
  ↑ depends on: hub/, tongtai/
```

**Forbidden Dependencies:**

```
❌ hub ← → tongtai
❌ hub → tongtai/models
❌ tongtai → hub/screens
❌ tongtai/services → hub/services
❌ shared/core → hub or tongtai (NEVER import product-specific code in shared/)
```

---

### Code Review Isolation Checklist

**Every PR must pass these checks:**

1. ✅ **No Hub→Tổng Tài Imports**
   ```dart
   // ❌ FORBIDDEN
   import 'package:tongtai/models/producer.dart';
   import 'package:tongtai/services/inventory_service.dart';
   ```

2. ✅ **No Tổng Tài→Hub Imports**
   ```dart
   // ❌ FORBIDDEN
   import 'package:hub/models/document.dart';
   import 'package:hub/services/ocr_service.dart';
   ```

3. ✅ **No Product-Specific Code in Shared**
   ```dart
   // ❌ FORBIDDEN (in shared/core/)
   import 'package:hub/screens/home.dart';  // Don't expose Hub code
   // ❌ FORBIDDEN (in shared/core/)
   if (Platform.isAndroid && isHubMode) { ... }  // Don't branch on product
   ```

4. ✅ **Imports Must Be from Allowed Layers**
   ```dart
   // ✅ ALLOWED (Hub can import from shared)
   import 'package:shared_core/storage/drift_schema.dart';
   import 'package:shared_core/ui/components/card.dart';
   
   // ✅ ALLOWED (Hub imports its own code)
   import 'package:hub/models/document.dart';
   import 'package:hub/screens/chat.dart';
   ```

5. ✅ **No Dart Conditionals for Product Branching**
   ```dart
   // ❌ FORBIDDEN
   if (productName == 'hub') { ... } else { ... }
   
   // Use separate main_hub.dart and main_tongtai.dart instead
   ```

---

### Build Isolation

#### Run Hub (Development)
```bash
flutter run -t lib/main_hub.dart
# Builds and runs only Hub (tongtai/ code is not compiled)
```

#### Run Tổng Tài (Development)
```bash
flutter run -t lib/main_tongtai.dart
# Builds and runs only Tổng Tài (hub/ code is not compiled)
```

#### Build Hub APK (Release)
```bash
flutter build apk -t lib/main_hub.dart --release
# Output: build/app/outputs/apk/release/app-release.apk
```

#### Build Tổng Tài APK (Release)
```bash
flutter build apk -t lib/main_tongtai.dart --release
# Output: build/app/outputs/apk/release/app-release.apk
```

#### Build Hub AAB (Play Store)
```bash
flutter build appbundle -t lib/main_hub.dart --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Build Tổng Tài AAB (Play Store)
```bash
flutter build appbundle -t lib/main_tongtai.dart --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

### CI/CD Enforcement

#### Lint Rule: No Cross-Product Imports

**Tool:** `dart pub deps`

**Script:** `.github/workflows/check-isolation.yml`

```yaml
name: Check Product Isolation

on: [pull_request]

jobs:
  isolation-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check for hub→tongtai imports
        run: |
          grep -r "import.*package:tongtai" hub/ \
            && echo "ERROR: Hub imports Tổng Tài code" && exit 1 \
            || echo "PASS: No Hub→Tổng Tài imports"
      
      - name: Check for tongtai→hub imports
        run: |
          grep -r "import.*package:hub" tongtai/ \
            && echo "ERROR: Tổng Tài imports Hub code" && exit 1 \
            || echo "PASS: No Tổng Tài→Hub imports"
      
      - name: Check for product branching in shared/
        run: |
          grep -r "isHub\|isTongTai\|productName.*==" shared/core/ \
            && echo "ERROR: Product branching in shared/" && exit 1 \
            || echo "PASS: No product branching in shared/"
```

#### Lint Rule: Both Products Build

**Script:** `.github/workflows/build.yml`

```yaml
name: Build Both Products

on: [pull_request, push]

jobs:
  build-hub:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk -t lib/main_hub.dart
  
  build-tongtai:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk -t lib/main_tongtai.dart
```

---

### Refactoring Path to Separate Repos (Phase 2+)

When Tổng Tài matures (estimated: end of 2026), you can:

1. **Extract Tổng Tài to separate repo:**
   ```bash
   git subtree split --prefix=tongtai/ -b tongtai-split
   mkdir ../workizen-tongtai
   cd ../workizen-tongtai
   git init
   git pull ../workizen-ai-personal-wallet tongtai-split
   ```

2. **Move shared packages to internal pub server:**
   ```bash
   # Publish to Artifactory or private pub.dev mirror
   dart pub publish --server=https://pub.workizen.internal
   ```

3. **Both repos depend on shared packages via pub:**
   ```yaml
   # Hub pubspec.yaml
   dependencies:
     shared_core: ^1.0.0  # From pub.workizen.internal

   # Tổng Tài pubspec.yaml
   dependencies:
     shared_core: ^1.0.0  # Same package
   ```

4. **Keep sync'd via version constraints:**
   - Both products constrain `shared_core: ^1.0` (major version stable)
   - Updates to shared/ are published as new versions
   - Teams coordinate via changelog

---

### Isolation Best Practices

#### ✅ DO:

1. **Put reusable code in `shared/core/`**
   ```dart
   // shared/core/ui/components/card.dart
   class Card extends StatelessWidget { ... }
   ```

2. **Product-specific code goes in product folder**
   ```dart
   // tongtai/screens/producer.dart
   class ProducerListScreen extends StatelessWidget { ... }
   ```

3. **Use adapters for shared functionality**
   ```dart
   // shared/core/ai/model_selector.dart (product-agnostic)
   ModelConfig selectModel(TaskType task) {
     if (task == TaskType.chat) return ModelConfig.reasoning;
     return ModelConfig.standard;
   }
   ```

4. **Export shared code from shared/pubspec.yaml**
   ```yaml
   # shared/core/pubspec.yaml
   name: shared_core
   publish_to: "none"
   ```

5. **Document product differences**
   ```dart
   // hub/main_hub.dart
   /// Hub entry point — document/chat/output centric
   void main() => runApp(const HubApp());
   
   // tongtai/main_tongtai.dart
   /// Tổng Tài entry point — business operating system
   void main() => runApp(const TongTaiApp());
   ```

#### ❌ DON'T:

1. **Don't put product-specific code in shared/**
   ```dart
   // ❌ WRONG (in shared/core/ai/)
   if (isHub) {
     // Hub-specific AI logic
   } else {
     // Tổng Tài-specific logic
   }
   ```

2. **Don't import across products**
   ```dart
   // ❌ WRONG (in tongtai/screens/)
   import 'package:hub/models/document.dart';
   ```

3. **Don't branch on platform-specific behavior in shared**
   ```dart
   // ❌ WRONG (in shared/core/)
   if (const String.fromEnvironment('PRODUCT') == 'hub') { ... }
   ```

4. **Don't duplicate code instead of extracting to shared**
   ```dart
   // ❌ WRONG (two copies of AI chat logic)
   // hub/services/chat.dart (one copy)
   // tongtai/services/chat.dart (second copy, slightly different)
   
   // ✅ CORRECT (shared implementation)
   // shared/core/ai/chat_service.dart (both use this)
   ```

5. **Don't build both products in one APK**
   ```bash
   # ❌ WRONG (messy, 2x size)
   flutter build apk  # (no -t flag, builds all entry points)
   
   # ✅ CORRECT (separate APKs)
   flutter build apk -t lib/main_hub.dart
   flutter build apk -t lib/main_tongtai.dart
   ```

---

### Testing Isolation

#### Unit Tests

**Hub Tests:**
```bash
# Test only Hub
flutter test --tags=hub
```

**Tổng Tài Tests:**
```bash
# Test only Tổng Tài
flutter test --tags=tongtai
```

**Shared Tests:**
```bash
# Test shared packages (runs for both products)
flutter test test/shared/
```

#### Integration Tests

**Hub Integration:**
```bash
flutter drive \
  --driver=integration_test/driver.dart \
  --target=integration_test/hub_flow_test.dart
```

**Tổng Tài Integration:**
```bash
flutter drive \
  --driver=integration_test/driver.dart \
  --target=integration_test/tongtai_flow_test.dart
```

---

## Tiếng Việt — Kế Hoạch Tách Biệt Ứng Dụng

### Tóm Tắt Điều Hành

Trong MVP (Phase 1B-1C), Hub và Tổng Tài chia sẻ cùng một kho lưu trữ Git và không gian làm việc Flutter để tái sử dụng mã hiệu quả. Tuy nhiên, chúng phải vẫn cô lập để ngăn:

- Sự rò rỉ tính năng/mã từ sản phẩm này sang sản phẩm khác
- Quyền sở hữu không rõ ràng
- Liên kết khiến việc chia tách trong tương lai trở nên đau đớn
- Bản dựng phình to (bản dựng Tổng Tài bao gồm mã Hub)

**Giải pháp:** Cấu trúc thư mục rõ ràng + quy tắc phụ thuộc + thực thi CI.

---

### Cấu Trúc Thư Mục

[Cấu trúc như ở trên]

```
mobile/
├── shared/         ← Gói dùng chung (cả hai sản phẩm sử dụng)
├── hub/            ← Sản phẩm Hub (chỉ Hub)
├── tongtai/        ← Sản phẩm Tổng Tài (chỉ Tổng Tài)
├── app/            ← Điểm nhập ứng dụng
└── pubspec.yaml
```

---

### Quy Tắc Phụ Thuộc

**Phụ Thuộc ĐƯỢC PHÉP:**

```
shared/core → không phụ thuộc gì
shared/services → shared/core
hub/ → shared/core, shared/services
tongtai/ → shared/core, shared/services
app/ → hub/, tongtai/
```

**Phụ Thuộc BỊ CẤM:**

```
❌ hub ↔ tongtai
❌ shared/core → hub hoặc tongtai
```

---

### Danh Sách Kiểm Tra Xem Xét Mã

**Mọi PR phải vượt qua các kiểm tra này:**

1. ✅ Không có nhập Hub→Tổng Tài
2. ✅ Không có nhập Tổng Tài→Hub
3. ✅ Không có mã cụ thể sản phẩm trong Shared
4. ✅ Nhập phải từ các lớp được phép
5. ✅ Không có điều kiện Dart để phân nhánh sản phẩm

---

### Tách Biệt Bản Dựng

#### Chạy Hub
```bash
flutter run -t lib/main_hub.dart
```

#### Chạy Tổng Tài
```bash
flutter run -t lib/main_tongtai.dart
```

---

### Thực Thi CI/CD

#### Quy Tắc Lint: Không Có Nhập Chéo Sản Phẩm

Script CI tự động kiểm tra:
- Không có `import 'package:tongtai'` trong `hub/`
- Không có `import 'package:hub'` trong `tongtai/`
- Không có nhánh sản phẩm trong `shared/core/`

#### Quy Tắc Lint: Cả Hai Sản Phẩm Xây Dựng

Cả hai sản phẩm phải xây dựng thành công (không có lỗi biên dịch).

---

**Version:** 1.0 (Draft)  
**Next Review:** After folder structure is created
