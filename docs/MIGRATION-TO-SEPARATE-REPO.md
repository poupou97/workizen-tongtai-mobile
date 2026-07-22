# Migration to Separate Repository — Tổng Tài

## English

**Purpose:** Plan the migration of Tổng Tài from a folder in Hub repository to a dedicated `workizen-tongtai-mobile` repository after Phase 3 (Public Beta).

**Timeline:** Phase 3 completion (Late Nov 2026) → Repo split (Early Dec 2026)  
**Owner:** Founder (decision), Developer Agent (execution)  
**Status:** Planning (Phase 4 preparation)

---

## Current State (Phase 1-2)

### Repository Structure Today

```
workizen-ai-personal-wallet/                    (Hub repo)
├── docs/
│   ├── tongtai/                                (Tõng Tài design docs)
│   └── (Hub docs)
├── mobile/
│   ├── lib/
│   │   ├── hub/                                (Hub app)
│   │   │   ├── chat/
│   │   │   ├── document/
│   │   │   └── ...
│   │   ├── tongtai/                            (Tõng Tài app) ← TO BE MOVED
│   │   │   ├── producer/
│   │   │   ├── inventory/
│   │   │   ├── consumer/
│   │   │   ├── journey/
│   │   │   ├── opportunity/
│   │   │   └── ...
│   │   ├── shared/                             (Shared between both apps)
│   │   │   ├── components/
│   │   │   ├── theme/
│   │   │   ├── ai/
│   │   │   └── ...
│   │   └── pubspec.yaml                        (One for both apps)
│   ├── android/
│   ├── ios/
│   ├── test/
│   └── .flutter_settings
├── .git/
└── CLAUDE.md

```

**Issue:** Single pubspec.yaml manages both Hub + Tõng Tài, build flavors distinguish apps. This works for MVP (Phase 1-2) but creates release cycle coupling.

---

## Future State (Phase 4+)

### Target Separation (Post-Phase 3)

```
workizen-ai-personal-wallet/                    (Hub repo, now SINGLE-PRODUCT)
├── docs/
│   ├── ...
├── mobile/
│   ├── lib/
│   │   ├── hub/                                (Hub ONLY)
│   │   │   ├── chat/
│   │   │   ├── document/
│   │   │   └── ...
│   │   ├── shared/                             (Extracted to package)
│   │   │   └── [empty, all in workizen_shared]
│   │   └── pubspec.yaml                        (Hub only)
│   ├── android/
│   ├── ios/
│   ├── test/
│   └── .flutter_settings
├── .git/
└── CLAUDE.md

workizen-tongtai-mobile/ (NEW REPO, INDEPENDENT)
├── docs/
│   ├── ...
├── mobile/
│   ├── lib/
│   │   ├── producer/                           (Tõng Tài ONLY)
│   │   ├── inventory/
│   │   ├── consumer/
│   │   ├── journey/
│   │   ├── opportunity/
│   │   ├── shared/                             (References workizen_shared package)
│   │   └── pubspec.yaml                        (Tõng Tài only, depends on workizen_shared)
│   ├── android/
│   ├── ios/
│   ├── test/
│   └── .flutter_settings
├── .git/ (separate from Hub)
├── .workforce.json                             (Jira project config)
└── CLAUDE.md

packages/workizen_shared (SHARED PKG, BOTH REPOS DEPEND ON IT)
├── lib/
│   ├── ai/
│   ├── storage/
│   ├── components/
│   ├── theme/
│   ├── navigation/
│   ├── search/
│   └── utils/
├── pubspec.yaml                                (version: 1.0.0+)
└── .git/ (separate, or in monorepo if using workspaces)
```

---

## Migration Phases

### Phase 0: Planning (Late Nov 2026, 1 week)
- Finalize shared package API (workizen_shared 1.0.0)
- Decide: host workizen_shared in separate repo or monorepo?
- Create workizen-tongtai-mobile repo (git init, GitHub setup)
- Plan cutover (when to split, how to handle in-flight work)

### Phase 1: Extract & Publish Shared Package (Early Dec 2026, 1-2 weeks)

**Step 1: Freeze Hub + Tõng Tài Repos**
- No new features to Hub or Tõng Tài during migration (optional, but safer)
- Merge pending PRs, tag stable version

**Step 2: Extract Shared Package**
- Create `packages/workizen_shared/` in Hub repo (if monorepo) or separate repo
- Copy `mobile/lib/shared/` → `packages/workizen_shared/lib/`
- Create pubspec.yaml for shared package (version 1.0.0)
- Define public API (what's exported from shared package)
- Write README for shared package
- Run tests (unit + integration)

**Step 3: Publish Shared Package**
- Option A: Private Pub.dev package (requires pub.dev account setup, paid)
- Option B: GitHub Packages (free for public repos, requires GitHub auth for private)
- Option C: Path dependency (local development only, not production)
- Recommendation: Use Option B (GitHub Packages) for Phase 4+

**Step 4: Update Hub App**
- Update `hub_mobile/pubspec.yaml` to depend on workizen_shared package (not path)
- Test Hub app builds + runs
- Commit, push, merge to Hub main

### Phase 2: Create & Migrate Tõng Tài Repo (Early Dec 2026, 1-2 weeks)

**Step 1: Initialize workizen-tongtai-mobile Repo**
```bash
cd /Users/alexnguyen/projects
git init workizen-tongtai-mobile
cd workizen-tongtai-mobile
git branch -M main
```

**Step 2: Copy Tõng Tài Codebase**
- Copy `workizen-ai-personal-wallet/mobile/` → `workizen-tongtai-mobile/mobile/`
- Copy `workizen-ai-personal-wallet/docs/tongtai/` → `workizen-tongtai-mobile/docs/`
- Remove Hub-specific code (hub/ folder, Hub-only features)
- Remove old `shared/` folder (will depend on package)
- Create new `.workforce.json` (Jira project: TONGTAI)
- Create new `CLAUDE.md` (Tõng Tài-specific)
- Create new `README.md` (Tõng Tài project)

**Step 3: Update Dependencies**
- Update `pubspec.yaml` to:
  - Remove Hub dependencies
  - Add dependency on workizen_shared package
  - Update version to 1.0.0+1 (first Tõng Tài release)

**Step 4: Test Build**
```bash
cd workizen-tongtai-mobile/mobile
flutter clean
flutter pub get
flutter build apk --flavor tongtai  # or adjust build flavor
```

**Step 5: Push to GitHub**
- Add GitHub remote
- Create GitHub repo `workizen-tongtai-mobile` (Workizen org)
- Push main branch
- Set up branch protection (main requires PR review + Founder approval)

**Step 6: Update Confluence + Jira**
- Create workizen-tongtai-mobile link in Hub docs (cross-reference)
- Update TONGTAI Jira project board (link to new repo)
- Update Team Wiki (new repo URL)

### Phase 3: Verify & Parallel Build (Dec 2026, ongoing)

**Testing:**
- Build Hub app independently (verify migration didn't break Hub)
- Build Tõng Tài app independently (verify migration didn't break Tõng Tài)
- Cross-verify shared package works for both apps
- CI/CD pipeline working (GitHub Actions for both repos)

**Parallel Development:**
- Hub and Tõng Tài teams can now develop independently
- No more build/release coupling
- Shared package updates require coordination (semantic versioning)

---

## Repository Setup

### workizen-tongtai-mobile Structure

```
workizen-tongtai-mobile/
├── .git/                                       (separate repo)
├── .gitignore
├── .github/
│   └── workflows/
│       ├── build.yml                           (CI: build APK/IPA, run tests)
│       └── release.yml                         (CI: version bump, tag, release)
├── mobile/
│   ├── lib/
│   │   ├── producer/
│   │   ├── inventory/
│   │   ├── consumer/
│   │   ├── journey/
│   │   ├── opportunity/
│   │   ├── shared/
│   │   │   └── theme.dart                      (local theme overrides, references workizen_shared)
│   │   ├── main.dart                           (entry point)
│   │   └── pubspec.yaml                        (TONGTAI ONLY)
│   ├── android/
│   ├── ios/
│   ├── test/
│   ├── integration_test/
│   └── .flutter_settings
├── docs/
│   ├── CHANGELOG.md                            (per-app version history)
│   ├── README.md                               (Tõng Tài build + run guide)
│   ├── architecture/
│   ├── adr/
│   ├── product/
│   └── (all Tõng Tài design docs)
├── .workforce.json                             (Jira: TONGTAI project)
├── CLAUDE.md                                   (Tõng Tài working agreement)
├── README.md                                   (Project overview)
└── pubspec.lock                                (Tõng Tài lock file)
```

### Configuration Files

**pubspec.yaml (Tõng Tài)**
```yaml
name: tongtai_mobile
description: Tổng Tài — AI-first Business OS for SMEs

version: 1.0.0+1

dependencies:
  flutter:
    sdk: flutter
  workizen_shared:
    git:
      url: https://github.com/Workizen/workizen-shared.git
      ref: v1.0.0
  # (no other dependencies, all reuse from workizen_shared)

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test: ...
```

**CLAUDE.md (Tõng Tài)**
```markdown
# CLAUDE.md — Tổng Tài Mobile

## Single Source of Truth
- Canonical Knowledge: workizen-knowledge-base/canonical/
- Product Spec: docs/tongtai/ (from Hub repo during design)
- Implementation: workizen-tongtai-mobile/

## Architecture
- Flutter + Dart
- Local-first, no backend (MVP)
- Shared components via workizen_shared package

## Workflow
- Jira Project: TONGTAI (separate from Hub)
- Confluence Space: workizento (shared)
- GitHub: workizen-tongtai-mobile (independent releases)

## Key Links
- Hub Repo: github.com/Workizen/workizen-ai-personal-wallet (Hub features)
- Shared Package: github.com/Workizen/workizen-shared (reusable UI, AI, storage)
- Original Design: workizen-ai-personal-wallet/docs/tongtai/
```

**.workforce.json (Tõng Tài)**
```json
{
  "cloudId": "abc123",                          (Jira Cloud ID)
  "jiraProject": "TONGTAI",                     (TONGTAI Jira project key)
  "confluenceSpace": "workizento",              (shared Confluence space)
  "repository": "workizen-tongtai-mobile",
  "branch": "main"
}
```

---

## Release & Versioning Strategy

### Version Bump Process
1. PR to `workizen-tongtai-mobile/main`
2. Founder reviews, approves (GitHub PR)
3. Merge triggers GitHub Action
4. Action bumps version in `pubspec.yaml` (e.g., 1.0.0+5 → 1.0.0+6)
5. Action adds entry to `docs/CHANGELOG.md`
6. Action builds APK/IPA, uploads to Play/App Store

### Independent Release Cycle
- Hub and Tõng Tài release on independent schedules
- Can hotfix one app without affecting the other
- Shared package updates require Both apps to test + approve

### Example Release Timeline (Phase 4)
```
Dec 15, 2026: Hub v1.2.0 released (independent)
Dec 18, 2026: Tõng Tài v1.0.0 released (first public release)
Dec 25, 2026: workizen_shared v1.1.0 released (shared package)
               Both Hub + Tõng Tài update to v1.1.0
Jan 5, 2027: Tõng Tài v1.0.1 hotfix (fast, Hub unaffected)
```

---

## Cutover Checklist

Before flipping the switch:

- [ ] Shared package extracted and tested (v1.0.0 published)
- [ ] workizen-tongtai-mobile repo created (GitHub)
- [ ] Tõng Tài code copied to new repo
- [ ] Dependencies updated (pubspec.yaml points to workizen_shared)
- [ ] Both Hub and Tõng Tài build independently (no regressions)
- [ ] CI/CD pipelines set up for both repos (GitHub Actions)
- [ ] Hub docs updated (cross-reference to Tõng Tài repo)
- [ ] Tõng Tài docs updated (cross-reference to Hub, shared package)
- [ ] Jira TONGTAI project linked (GitHub → TONGTAI issue linking)
- [ ] Confluence pages updated (.workforce.json links)
- [ ] Team trained (developers know how to work with both repos + shared package)
- [ ] Backup of current state (tag Hub main before extraction)

---

## Rollback Plan

If migration fails:

1. Revert Hub main to pre-migration tag (git reset)
2. Delete workizen-tongtai-mobile repo (if on GitHub)
3. Restore mobile/ folder to Hub (git checkout mobile/)
4. Restore pubspec.yaml (path dependency on shared, or revert to single pubspec)
5. Test Hub builds + runs
6. Analyze what went wrong, schedule retry

---

## Long-Term Considerations

### Multi-Repo Coordination

**Shared Package Versioning:**
- Hub and Tõng Tài may depend on different versions of workizen_shared
- Use semantic versioning (major.minor.patch)
- Breaking changes require both apps to update simultaneously
- Minor/patch updates can be independent

**Monorepo Alternative (Not Recommended):**
- Could use Dart monorepo tooling (but Flutter tooling doesn't support it well)
- Stick with separate repos + shared package approach

**Team Communication:**
- Weekly sync between Hub + Tõng Tài teams if coordinating shared package changes
- Async communication via GitHub issues on workizen_shared

### Future Repo Expansion

If more products (e.g., Compute, Portal mobile, Tổng Tài admin panel):

```
workizen-ai-personal-wallet/        (Hub)
workizen-tongtai-mobile/             (Tõng Tài consumer)
workizen-tongtai-admin-web/          (Tõng Tài SME admin dashboard, future)
workizen-compute-mobile/             (Compute, future)
workizen-shared/                     (Shared packages)
```

Each repo would depend on workizen_shared package (or monorepo if Dart tooling matures).

---

---

## Tiếng Việt

**Mục Đích:** Lập kế hoạch chuyển dịch Tổng Tài từ một thư mục trong Hub repository sang một repository `workizen-tongtai-mobile` chuyên dụng sau Phase 3.

**Dòng Thời Gian:** Hoàn thành Phase 3 (Cuối Tháng 11 2026) → Chia tách Repo (Đầu Tháng 12 2026)

### Trạng Thái Hiện Tại (Phase 1-2)

Tổng Tài hiện được quản lý trong Hub repo, sử dụng build flavors để phân biệt các ứng dụng.

### Trạng Thái Tương Lai (Phase 4+)

Tõng Tài được chuyển sang repository riêng (`workizen-tongtai-mobile`), độc lập phát hành.

### Các Giai Đoạn Chuyển Dịch

**Phase 0: Lập Kế Hoạch** (1 tuần)
- Hoàn thiện API gói chia sẻ (workizen_shared 1.0.0)
- Tạo workizen-tongtai-mobile repo (GitHub)
- Lập kế hoạch cắt ngang

**Phase 1: Trích Xuất & Xuất Bản Gói Chia Sẻ** (1-2 tuần)
- Tạo `packages/workizen_shared/`
- Sao chép `mobile/lib/shared/` → package
- Xuất bản workizen_shared v1.0.0
- Cập nhật Hub app để phụ thuộc vào gói

**Phase 2: Tạo & Chuyển Dịch Repo Tõng Tài** (1-2 tuần)
- Khởi tạo workizen-tongtai-mobile repo
- Sao chép mã Tõng Tài từ Hub
- Xóa mã Hub-specific
- Cập nhật dependencies (workizen_shared)
- Đẩy lên GitHub

**Phase 3: Xác Minh & Xây Dựng Song Song** (Liên Tục)
- Xây dựng Hub độc lập
- Xây dựng Tõng Tài độc lập
- Xác minh shared package hoạt động cho cả hai
- CI/CD pipeline cho cả hai repos

### Danh Sách Kiểm Tra Cắt Ngang

Trước khi chuyển đổi:

- [ ] Gói chia sẻ trích xuất & tested (v1.0.0 xuất bản)
- [ ] Repo workizen-tongtai-mobile được tạo
- [ ] Mã Tõng Tài sao chép đến repo mới
- [ ] Dependencies cập nhật
- [ ] Cả Hub và Tõng Tài xây dựng độc lập
- [ ] CI/CD pipelines thiết lập
- [ ] Tài liệu cập nhật (cross-reference)
- [ ] Đội được đào tạo

---

**Last Updated:** 2026-07-13  
**Status:** 🔄 Planning Phase
