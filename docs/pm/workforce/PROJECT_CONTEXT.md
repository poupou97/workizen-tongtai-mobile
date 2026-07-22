# PROJECT_CONTEXT — Per-project instance / Bối cảnh riêng của project

- **AI Workforce V1** · Bilingual EN/VI. **This copy = Hub Mobile.** Copy + edit the `<…>` fields for each new repo.

## Identity / Định danh
| Field | Value (Hub Mobile) |
|---|---|
| Product / Sản phẩm | **Workizen Hub Mobile** |
| Repo | `workizen-ai-personal-wallet` (Flutter, Android + iOS) |
| Jira project | `WH` |
| Confluence space | `FH` (dev-env) → target `WORKIZEN` |
| Architecture | one repo per product (ADR-059 / D-117) — this repo is **Mobile only** |

## Stack / Công nghệ
EN: Flutter/Dart · Riverpod · Drift (SQLite) · flutter_secure_storage. Principles: Local-First · Edge-First · BYOK · Privacy-by-Default. **Not** WorkforceOS Enterprise; **no backend** in Hub (backend lives in `workizen-portal`).
VI: Flutter/Dart · Riverpod · Drift (SQLite) · flutter_secure_storage. Nguyên tắc: Local-First · Edge-First · BYOK · Privacy-by-Default. **Không** phải WorkforceOS Enterprise; **không backend** trong Hub (backend ở `workizen-portal`).

## Source of Authority / Nguồn thẩm quyền
EN: Jira `WH` = work · Confluence = human knowledge · GitHub = code + ADR/Spec · Canonical KB = doctrine. Spec source = Git ADR (option B).
VI: Jira `WH` = việc · Confluence = tri thức người · GitHub = code + ADR/Spec · Canonical KB = doctrine. Nguồn spec = Git ADR (phương án B).

## Naming / Đặt tên
EN: Files kebab-case · ADR `ADR-NNN` (never reuse/gap) · Jira `WH-<n>` · labels `product-* area-* type-* pri-p0..3 phase-* roadmap-* decision` · feature branches only · version `1.1.0+NN` + CHANGELOG entry.
VI: File kebab-case · ADR `ADR-NNN` (không trùng/nhảy số) · Jira `WH-<n>` · label `product-* area-* type-* pri-p0..3 phase-* roadmap-* decision` · chỉ feature branch · version `1.1.0+NN` + dòng CHANGELOG.

## Current state / Trạng thái
EN: Hub app `v1.1.0+62` on `main`. Gesture nav (back-swipe + tab-swipe) default-ON. Backlog in Jira `WH`.
VI: App Hub `v1.1.0+62` trên `main`. Gesture nav (back-swipe + tab-swipe) mặc định ON. Backlog ở Jira `WH`.

## Environment / Môi trường
EN: Build `flutter build apk/appbundle/ipa`. Device S24 `R5CX62RCBNB` (adb at `~/Library/Android/sdk/platform-tools/adb`). ASC key `PC6TLRQV8Q` (iOS upload); release keystore via `android/key.properties`.
VI: Build `flutter build apk/appbundle/ipa`. Máy S24 `R5CX62RCBNB` (adb ở `~/Library/Android/sdk/platform-tools/adb`). Key ASC `PC6TLRQV8Q` (đẩy iOS); keystore release qua `android/key.properties`.
