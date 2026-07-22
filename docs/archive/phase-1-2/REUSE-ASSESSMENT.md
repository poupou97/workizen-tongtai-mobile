# Reuse Assessment — Tổng Tài from Hub

## English

**Purpose:** Deep dive into what Workizen Hub code can be reused by Tổng Tài, with detailed layer-by-layer analysis.

**Last Updated:** 2026-07-13  
**Status:** Ready for WTM-40/41 prototype validation

---

## Hub Codebase Overview

**Hub Repository:** `workizen-ai-personal-wallet/mobile/`  
**Size:** ~150k lines of Dart code (full app + tests)  
**Structure:**
```
mobile/
├── lib/
│   ├── app/                    # App shell, routing, localization
│   ├── features/
│   │   ├── chat/              # Chat feature (not reusable)
│   │   ├── document/          # Document management (not reusable)
│   │   ├── scanner/           # QR/document scanner (reuse?)
│   │   └── search/            # Local FTS5 search (REUSABLE)
│   ├── core/
│   │   ├── ai/                # xAI + OpenRouter client (REUSABLE ✅)
│   │   ├── data/              # Drift database, entities (REUSABLE with refactor)
│   │   ├── navigation/        # Bottom nav, routing (REUSABLE ✅)
│   │   ├── theme/             # Colors, typography, tokens (REUSABLE ✅)
│   │   └── utils/             # Helpers, extensions (REUSABLE ✅)
│   ├── shared/
│   │   ├── components/        # Card, button, dialog components (REUSABLE ✅)
│   │   ├── styles/            # Fonts, spacing, shadows (REUSABLE ✅)
│   │   └── widgets/           # Reusable UI widgets (REUSABLE ✅)
│   └── pubspec.yaml
├── test/                       # Unit + widget tests
└── integration_test/          # E2E tests
```

**Key Dependencies:**
- `drift` (SQLite ORM, local persistence)
- `flutter_secure_storage` (API keys, sensitive data)
- `riverpod` (state management)
- `go_router` (navigation)
- `http` + custom wrapper (API clients)
- `sqflite` (SQLite driver)
- `flutter_localization` (i18n)

---

## Reuse Matrix: Tổng Tài vs Hub

| Layer | Component | Hub Size | Reusable? | Effort | Notes |
|---|---|---|---|---|---|
| **UI** | Card component | 500 LOC | ✅ 80% | 1 week | Adapt visual style (business cards vs doc cards) |
| **UI** | Button, Dialog, Snackbar | 1.5k LOC | ✅ 100% | 0 | Direct copy, same design |
| **UI** | Bottom Nav framework | 800 LOC | ✅ 90% | 2 days | Adapt tab labels (Producer/Inventory/Consumer/Chat) |
| **UI** | Chart component | 1k LOC | ✅ 100% | 0 | Direct copy, use for reports |
| **UI** | Input fields, forms | 1.2k LOC | ✅ 95% | 3 days | Minor text validation tweaks |
| **Storage** | Drift schema | 3k LOC | ⚠️ 30% | 2 weeks | Hub schema (Document/Message) incompatible, refactor for business data (Producer/Inventory/Consumer) |
| **Storage** | Drift database layer | 2k LOC | ✅ 90% | 1 week | Abstract generic CRUD, reuse pattern |
| **AI** | xAI + OpenRouter client | 1.5k LOC | ✅ 100% | 0 | Direct copy, same prompts + routing logic |
| **AI** | Prompt templates | 3k LOC | ⚠️ 40% | 1 week | Hub prompts document-centric, refactor for business context |
| **Nav** | Go Router setup | 800 LOC | ✅ 90% | 3 days | Adapt routes (no /document, add /producer, /opportunity) |
| **Nav** | Deep linking | 600 LOC | ✅ 100% | 0 | Pattern reusable, configure URLs |
| **Theme** | Design tokens (colors, spacing) | 2k LOC | ✅ 100% | 1 day | Direct copy, minor color tweaks for business branding |
| **Theme** | Typography | 1k LOC | ✅ 100% | 0 | Direct copy (Lora headers, Outfit body) |
| **Auth** | Keycloak integration | 2k LOC | ❌ 0% | 0 | Not used (Tổng Tài MVP local-only, no auth) |
| **Auth** | Local UUID generation | 200 LOC | ✅ 100% | 0 | Direct copy |
| **Utils** | Extensions, helpers | 1.5k LOC | ✅ 85% | 3 days | Some Hub-specific, most generic |
| **Search** | FTS5 implementation | 1.5k LOC | ✅ 95% | 1 week | Adapt indexing for business data (supplier names, SKUs) |
| **Search** | Query parser | 800 LOC | ✅ 100% | 0 | Direct copy |
| **Testing** | Unit test patterns | 5k LOC | ✅ 90% | ongoing | Reuse test structure, write new tests for Tổng Tài features |
| **Testing** | E2E test framework | 2k LOC | ✅ 90% | 1 week | Adapt for business journey tests |
| **TOTAL REUSABLE** | | **~35k LOC** | **✅ 75%** | **~3-4 weeks** | Leaves **~115k LOC** new for Tổng Tài-specific features |

---

## Reusable Packages Identified

### ✅ High Reuse (100% Direct Copy)

1. **UI Components** (Button, Dialog, Snackbar, Input)
   - Location: `lib/shared/components/`
   - Reuse: Direct copy to `tongtai_mobile/lib/shared/components/`
   - Effort: 0 (just copy files)
   - Risk: Low (UI framework is stable)

2. **AI Integration Client** (xAI + OpenRouter)
   - Location: `lib/core/ai/`
   - Reuse: Direct copy, same provider logic + routing
   - Effort: 0 (just copy files)
   - Risk: Low (API client is stable)
   - Note: Prompt templates can be reused as-is, then specialized for business context

3. **Navigation Framework** (Go Router setup)
   - Location: `lib/core/navigation/`
   - Reuse: Copy pattern, modify routes for Tổng Tài screens
   - Effort: 3 days (route configuration)
   - Risk: Low (routing pattern proven on Hub)

4. **Design Tokens** (Colors, spacing, typography)
   - Location: `lib/core/theme/`
   - Reuse: Direct copy, minor color tweaks
   - Effort: 1 day (design review, color palette customization)
   - Risk: Low (tokens stable)

5. **Test Infrastructure** (Unit test patterns, widget testing)
   - Location: `test/`, `integration_test/`
   - Reuse: Copy test structure, write new feature tests
   - Effort: Ongoing (per feature)
   - Risk: Low (testing pattern proven)

### ⚠️ Partial Reuse (50-90%)

1. **Storage Layer** (Drift database)
   - Location: `lib/core/data/`
   - Reuse: Pattern + architecture, NOT schema
   - Effort: 2 weeks (redesign schema for business data)
   - Hub Schema: Document (PDF metadata), Message (chat history), Page (OCR text)
   - Tổng Tài Schema: Producer (supplier), Inventory (product/SKU), Consumer (customer), Journey (business goal), Opportunity (discovered opportunity)
   - Risk: Medium (schema versioning, migration complexity)
   - Mitigation: Abstract Drift layer (generic repository pattern), define new entities

2. **Search Engine** (FTS5)
   - Location: `lib/core/search/`
   - Reuse: FTS5 indexing pattern, query parsing
   - Effort: 1 week (adapt indices for business terms)
   - Hub Index: Document text, message content
   - Tổng Tài Index: Supplier names, product SKUs, customer names, opportunity titles
   - Risk: Medium (index schema redesign)

3. **Prompt Templates** (AI guidance)
   - Location: `lib/core/ai/prompts/`
   - Reuse: Routing logic, LLM abstraction
   - Effort: 1 week (specialize prompts for business use cases)
   - Hub Prompts: Document analysis, chat assistance
   - Tổng Tài Prompts: Opportunity discovery, supplier scoring, customer segmentation, journey planning
   - Risk: Low (logic reusable, content specialized)

4. **Error Handling & Logging**
   - Location: `lib/core/utils/`
   - Reuse: Error types, logging infrastructure
   - Effort: 3 days (adapt error messages)
   - Risk: Low

### ❌ No Reuse (0%)

1. **Feature-Specific Code** (Chat, Document Scanner, OCR)
   - Hub chat (Riverpod state, xAI integration) ≠ Tổng Tài chat (simpler, business-focused)
   - Hub scanner (QR code, document) ≠ Tổng Tài (no scanning needed MVP)
   - Risk: Don't try to force reuse; build Tổng Tài-specific

2. **Authentication Layer** (Keycloak)
   - Location: `lib/core/auth/`
   - Reuse: None (Tổng Tài MVP is local-only, no auth)
   - Note: Can reference for future Phase 3+ Keycloak integration

3. **Cloud Sync & Backup**
   - Hub has Portal integration stubs (not production)
   - Tổng Tài MVP has no sync
   - Reuse deferred to Phase 3

---

## Shared Core Package Design (Option 2 Architecture)

### Proposed Structure

```
packages/
├── workizen_shared/
│   ├── lib/
│   │   ├── ai/                        # AI client (xAI, OpenRouter)
│   │   │   ├── client.dart           # Reuse 100%
│   │   │   ├── models.dart           # Reuse 100%
│   │   │   └── prompts.dart          # Reuse pattern, specialize per product
│   │   ├── storage/
│   │   │   ├── database.dart         # Abstract Drift layer
│   │   │   ├── repository.dart       # Generic CRUD repo
│   │   │   └── migrations.dart       # Schema versioning
│   │   ├── navigation/
│   │   │   ├── router.dart           # Go Router pattern
│   │   │   ├── deep_link.dart        # Reuse 100%
│   │   │   └── routes.dart           # Base route config (products extend)
│   │   ├── theme/
│   │   │   ├── tokens.dart           # Colors, spacing (reuse 100%)
│   │   │   ├── typography.dart       # Fonts (reuse 100%)
│   │   │   └── extensions.dart       # TextTheme, etc.
│   │   ├── components/
│   │   │   ├── card.dart             # Generic card (reuse 80%)
│   │   │   ├── button.dart           # Reuse 100%
│   │   │   ├── dialog.dart           # Reuse 100%
│   │   │   └── input.dart            # Reuse 100%
│   │   ├── search/
│   │   │   ├── fts5_engine.dart      # FTS5 pattern
│   │   │   ├── indexer.dart          # Generic indexing
│   │   │   └── query_parser.dart     # Reuse 100%
│   │   ├── utils/
│   │   │   ├── extensions.dart       # Reuse 85%
│   │   │   ├── validators.dart       # Reuse 90%
│   │   │   └── helpers.dart          # Mix of reuse + new
│   │   ├── localization/             # i18n setup (reuse pattern)
│   │   └── pubspec.yaml
│   ├── test/
│   └── README.md

apps/
├── hub_mobile/
│   ├── lib/
│   │   ├── chat/               # Hub-specific
│   │   ├── document/           # Hub-specific
│   │   └── pubspec.yaml        # depends: workizen_shared
│   └── test/
├── tongtai_mobile/
│   ├── lib/
│   │   ├── producer/           # Tổng Tài-specific
│   │   ├── inventory/          # Tổng Tài-specific
│   │   ├── consumer/           # Tổng Tài-specific
│   │   └── pubspec.yaml        # depends: workizen_shared
│   └── test/
```

### Dependency Versioning

**Option A: Path Dependency (Local Dev)**
```yaml
# tongtai_mobile/pubspec.yaml
dependencies:
  workizen_shared:
    path: ../../packages/workizen_shared
```
Pros: Easy local development, no pub.dev setup needed  
Cons: Can't version independently, tight coupling during development

**Option B: Private Pub Package (Production)**
```yaml
# After Phase 2, publish to private pub.dev or GitHub Packages
dependencies:
  workizen_shared: ^1.0.0
```
Pros: Version control, independent releases, clear API surface  
Cons: Setup pub.dev account, version management complexity

**Recommendation:** Start with Option A (path dependency) for Phase 2, migrate to Option B after Phase 3 if multiple products depend on it.

---

## Refactoring Effort Estimate

### Shared Core Extraction (1-2 weeks, WTM-40)

1. **Create packages/workizen_shared** (1 day)
   - Set up pub package structure
   - Create pubspec.yaml with dependencies (drift, riverpod, go_router, etc.)

2. **Extract AI layer** (2 days)
   - Copy `lib/core/ai/` from Hub
   - Test with existing xAI API client
   - No changes needed

3. **Extract Navigation** (2 days)
   - Copy Go Router pattern
   - Extract generic route configuration
   - Tested with Hub routes, then clear for Tõng Tài customization

4. **Extract Theme & Components** (2 days)
   - Copy design tokens (colors, typography, spacing)
   - Copy UI components (button, dialog, card, input)
   - Minor theme tweaks for Tổng Tài branding

5. **Abstract Storage Layer** (3 days)
   - Create generic Drift database wrapper
   - Define repository pattern (abstract base class)
   - Move Hub-specific schema ASIDE (keep in Hub app, not shared)
   - Define interface for Tổng Tài schema (new entities)

6. **Extract Utils, Search, Tests** (3 days)
   - Utils (extensions, validators, helpers)
   - Search (FTS5 indexing pattern)
   - Test infrastructure + test utils

7. **Integration Testing** (2 days)
   - Verify Hub app still builds + runs after extraction
   - Verify Tõng Tài app can depend on workizen_shared
   - Test shared components in Tõng Tài context

**Total: 1-2 weeks, 2 engineers (1 refactoring Hub, 1 building Tõng Tài starter)**

### Tổng Tài App Bootstrap (1-2 weeks, WTM-41)

1. **Create tongtai_mobile app** (1 day)
   - Set up Flutter app structure
   - Add pubspec.yaml dependency on workizen_shared
   - Configure build flavors (optional)

2. **Implement Tộng Tài Schema** (2-3 days)
   - Define Drift entities: Producer, Inventory, Consumer, Journey, Opportunity
   - Create migrations (v1)
   - Write repository classes

3. **Implement Navigation** (1-2 days)
   - Define Tổng Tài routes (home, producer, inventory, consumer, chat, settings)
   - Configure Go Router
   - Test deep linking

4. **Build UI Screens (Shells)** (2-3 days)
   - Create screen shells (Home, Producer, Inventory, Consumer, Chat, Settings)
   - Use reusable components from shared (card, button, dialog)
   - Add theme customization (colors, fonts)

5. **Integrate AI & Storage** (1-2 days)
   - Wire xAI client (same as Hub)
   - Connect Drift database (new schema)
   - Test AI + storage together

6. **First Build & Test** (1 day)
   - `flutter build apk` (Android)
   - `flutter build ios` (iOS)
   - Run on emulator/device

**Total: 1-2 weeks**

---

## Risks & Mitigations

### Risk: Schema Coupling
**Problem:** Hub's Drift schema (Document, Message, Page) is tightly coupled to Hub features. Refactoring to shared layer could break Hub.

**Mitigation:**
- Keep Hub schema in Hub app (`hub_mobile/lib/data/schema.dart`), don't extract to shared
- Shared layer provides generic repository pattern + abstract database setup
- Each app (Hub, Tõng Tài) defines its own schema + entities
- Shared database wrapper is agnostic to schema

### Risk: Circular Dependencies
**Problem:** If shared package depends on feature-specific code, circular dependency possible.

**Mitigation:**
- Shared package has NO dependencies on Hub or Tõng Tài apps
- Hub and Tõng Tài depend on shared, not vice versa
- Dependency graph: workizen_shared → [depends on nothing product-specific]
- Hub app, Tõng Tài app → [both depend on workizen_shared]

### Risk: Version Incompatibility
**Problem:** Flutter/Dart versions differ between Hub and Tõng Tài, causing dependency conflicts.

**Mitigation:**
- Shared package specifies minimum Flutter SDK version (`sdk: ">=3.0.0"`)
- Both Hub and Tõng Tài use same Flutter version during Phase 2 (coordinated)
- Test shared package with both apps regularly (CI pipeline)

### Risk: Over-Extraction
**Problem:** Extracting too much into shared layer could over-generalize, make shared package hard to maintain.

**Mitigation:**
- Shared layer focuses on proven, stable patterns (UI components, AI client, storage layer)
- Feature-specific logic stays in each app
- Shared package API is minimal, clear, well-documented
- Code review process: don't add to shared unless used by both Hub + Tõng Tài

---

## Recommended Reuse Checklist

For Phase 2 Tõng Tài Development:

- [x] **Copy AI client:** `workizen_shared/lib/ai/` → xAI + OpenRouter integration
- [x] **Copy components:** `workizen_shared/lib/components/` → Button, Dialog, Card, Input
- [x] **Copy design tokens:** `workizen_shared/lib/theme/` → Colors, typography, spacing
- [x] **Copy navigation pattern:** `workizen_shared/lib/navigation/` → Go Router setup
- [x] **Copy search pattern:** `workizen_shared/lib/search/` → FTS5 indexing
- [x] **Copy test utilities:** `workizen_shared/test/` → Mock data, test helpers
- [ ] **Reference but don't copy:** Hub schema (define own for Tõng Tài)
- [ ] **Don't reuse:** Keycloak auth layer (Tõng Tài MVP local-only)
- [ ] **Defer to Phase 3:** Cloud sync, Portal integration

---

## Success Criteria

✅ Shared core package extracted and tested  
✅ Hub app still builds + runs without regression  
✅ Tõng Tài app bootstrapped and builds successfully  
✅ Both apps use shared components consistently  
✅ No circular dependencies or version conflicts  
✅ Phase 2 development velocity = Hub velocity (proof of reuse success)  
✅ Code reuse > 75% in components, theme, AI, navigation layers  

---

---

## Tiếng Việt

**Mục Đích:** Đánh giá sâu sắc những gì mã Hub có thể tái sử dụng bởi Tổng Tài.

**Cập Nhật Lần Cuối:** 2026-07-13  
**Trạng Thái:** Sẵn Sàng Cho Prototype WTM-40/41

### Danh Sách Đánh Giá Tái Sử Dụng Khuyến Nghị

Cho Phát Triển Phase 2 Tổng Tài:

- [x] **Sao chép AI client:** xAI + OpenRouter integration
- [x] **Sao chép components:** Button, Dialog, Card, Input
- [x] **Sao chép design tokens:** Colors, typography, spacing
- [x] **Sao chép navigation pattern:** Go Router setup
- [x] **Sao chép search pattern:** FTS5 indexing
- [x] **Sao chép test utilities:** Mock data, test helpers
- [ ] **Tham khảo nhưng không sao chép:** Hub schema
- [ ] **Không tái sử dụng:** Keycloak auth layer
- [ ] **Hoãn lại đến Phase 3:** Cloud sync, Portal integration

### Tiêu Chí Thành Công

✅ Gói shared core extracted và tested  
✅ Hub app vẫn builds + runs  
✅ Tổng Tài app bootstrapped  
✅ Cả hai ứng dụng sử dụng shared components nhất quán  
✅ Không có circular dependencies  
✅ Phase 2 development velocity = Hub velocity  
✅ Code reuse > 75% trong layers chính  

---

**Last Updated:** 2026-07-13  
**Status:** 🔄 Ready for Developer Review
