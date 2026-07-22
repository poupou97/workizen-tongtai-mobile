# Technology Planning Index — Tổng Tài Phase 1B

## Overview

This folder contains the technology planning and architecture documentation for **Tổng Tài** (Phase 1B — Technology Planning & Fit-Gap).

**Status:** 📋 DRAFT for Team Review  
**Phase:** 1B — Technology Planning  
**Owner:** Architecture Team  
**Date Created:** 2026-07-13  
**Date Last Updated:** 2026-07-13

---

## Documents in This Folder

### 1. **FIT-GAP-PREPARATION.md** ⭐
**Purpose:** Evaluate which Hub components can be reused for Tổng Tài  
**Length:** 1,500 words (EN + VI)  
**Key Content:**
- Current Hub capabilities
- Tổng Tài requirements
- 5 Evaluation Dimensions (Storage, AI, UI, Auth, Data Models)
- Capability Assessment Matrix
- Reuse vs. Build New decisions
- Technology Stack Alignment

**Audience:** Architecture, Tech Lead, QA  
**When to Read:** Start here to understand what we already have vs. what we need to build

**Key Finding:** ~70% reuse potential in infrastructure, 0% in business data models

---

### 2. **SHARED-CORE-PLAN.md** 🔧
**Purpose:** Define how to refactor Hub code to create reusable packages  
**Length:** 1,200 words (EN + VI)  
**Key Content:**
- Vision: One codebase, two products
- 4-phase refactoring plan (Phase 1B-3)
- Package structure & responsibilities
- Dependency rules & isolation
- Testing strategy
- Effort estimates
- Risk mitigation

**Audience:** Developer Lead, Architects, QA  
**When to Read:** Read after Fit-Gap to understand implementation roadmap

**Deliverables by Phase:**
- **Phase 1B (Weeks 1-3):** Extract 5 core packages (storage, AI, UI, utils, models)
- **Phase 1C (Weeks 4-5):** Separate Hub-specific and Tổng-Tài-specific code
- **Phase 2 (Post-MVP):** Shared services (sync, backup, notifications)
- **Phase 3+ (Future):** Plugin architecture

---

### 3. **ANDROID-IOS-IDENTITY-PLAN.md** 📱
**Purpose:** Define package name, bundle ID, icons, app name  
**Length:** 1,000 words (EN + VI)  
**Key Content:**
- Android package name: `com.workizen.tongtai` (recommended)
- iOS bundle ID: `com.workizen.tongtai` (same)
- App names (Vietnamese, English, Market)
- Icon specifications (sizes, colors)
- Splash screen design
- Code signing setup
- Version numbering scheme
- Store listing metadata
- Checklist for launch

**Audience:** Platform/Mobile Team, QA, Product  
**When to Read:** Before starting Tổng Tài development (iOS 1 or 2 weeks in)

**Decisions Made:**
- ✅ Separate app (not a flavor of Hub)
- ✅ Clear "tongtai" branding (distinct from Hub)
- ✅ Bilingual (Vietnamese primary, English secondary)

---

### 4. **APP-SEPARATION-PLAN.md** 🚫
**Purpose:** Define folder structure & isolation rules  
**Length:** 1,000 words (EN + VI)  
**Key Content:**
- Folder structure (shared/, hub/, tongtai/, app/)
- Dependency rules (what can import what)
- Code review isolation checklist
- Build isolation (separate binaries)
- CI/CD enforcement (automatic lint checks)
- Refactoring path to separate repos (Phase 2+)
- Best practices (DO/DON'T)
- Testing isolation

**Audience:** Developer Lead, Code Reviewers, CI/CD  
**When to Read:** Before first code review (during Phase 1C)

**Golden Rules:**
- ❌ NO hub ↔ tongtai cross-imports
- ❌ NO product code in shared/
- ✅ Use `flutter run -t lib/main_tongtai.dart` (separate builds)
- ✅ Enforce via CI (automatic rejection of violations)

---

### 5. **BUILD-AND-RUN-GUIDE.md** 🏃
**Purpose:** Developer instructions to build & run Tổng Tài locally  
**Length:** 800 words (EN + VI)  
**Key Content:**
- System requirements (Flutter, Dart, SDK versions)
- Environment setup (paths, variables)
- Clone & secrets setup
- Development workflow (run, test, debug)
- Release builds (APK, AAB, IPA)
- Testing (unit, integration, E2E)
- Debugging & profiling
- Common troubleshooting
- Typical day workflow

**Audience:** Developers, QA, CI/CD  
**When to Read:** First day of development

**Quick Start:**
```bash
flutter run -t lib/main_tongtai.dart  # Debug
flutter build apk -t lib/main_tongtai.dart --release  # Release APK
flutter build appbundle -t lib/main_tongtai.dart --release  # Release AAB
flutter test --tags=tongtai  # Tests
```

---

## Reading Sequence

**For Architects/Tech Leads:**
1. FIT-GAP-PREPARATION (understand what to reuse)
2. SHARED-CORE-PLAN (understand refactoring phases)
3. APP-SEPARATION-PLAN (understand isolation rules)

**For Developers (joining Tổng Tài):**
1. FIT-GAP-PREPARATION (5 min skim)
2. SHARED-CORE-PLAN (folder structure only)
3. BUILD-AND-RUN-GUIDE (get it running)
4. APP-SEPARATION-PLAN (code review rules)

**For QA/Testers:**
1. BUILD-AND-RUN-GUIDE (how to build)
2. APP-SEPARATION-PLAN (what NOT to do)
3. ANDROID-IOS-IDENTITY-PLAN (app identity)

**For Product/PM:**
1. FIT-GAP-PREPARATION (what's reused vs. new)
2. ANDROID-IOS-IDENTITY-PLAN (app branding)

---

## Key Decisions (Ready for Founder Review)

| Decision | Status | Details |
|---|---|---|
| **Separate app (not flavor)** | ✅ PROPOSED | Tổng Tài is a distinct app on Play Store & App Store |
| **Package name** | ✅ RECOMMENDED | `com.workizen.tongtai` (instead of `com.workizen.business`) |
| **Bundle ID** | ✅ RECOMMENDED | `com.workizen.tongtai` (matches Android) |
| **Shared codebase** | ✅ PROPOSED | Both products in `mobile/` folder with `shared/core/` packages |
| **App separation** | ✅ PROPOSED | `hub/`, `tongtai/` folders with strict dependency rules |
| **Refactor in phases** | ✅ PROPOSED | Phase 1B (3wks) → 1C (1wk) → Phase 2 (post-MVP) |
| **CI enforcement** | ✅ PROPOSED | Automatic lint checks to prevent cross-product imports |

---

## What Comes Next (Phase 1B-1C Execution)

### Immediate (Week 1)
- [ ] Founder review & approve all 5 tech docs
- [ ] Create Jira stories (WTM-39-43)
- [ ] Publish Confluence page (if Tổng Tài Confluence space exists)
- [ ] Create `lib/main_tongtai.dart` entry point
- [ ] Create initial `tongtai/` folder structure

### Phase 1B (Weeks 1-3)
- [ ] Extract `shared/core/storage/`
- [ ] Extract `shared/core/ai/`
- [ ] Extract `shared/core/ui/`
- [ ] Extract `shared/core/utils/`
- [ ] Extract `shared/core/models/`
- [ ] Write integration tests for each package
- [ ] Verify Hub still builds

### Phase 1C (Weeks 4-5)
- [ ] Separate Hub-specific code to `hub/`
- [ ] Create Tổng Tài business entity models in `tongtai/models/`
- [ ] Set up build targets for both products
- [ ] Build both products independently (APK, AAB)
- [ ] Publish CI checks for cross-product imports

### Phase 1C+ (Beyond MVP)
- [ ] Tổng Tài feature development
- [ ] Opportunity detection engine
- [ ] Business analytics & reports
- [ ] AI business copilot
- [ ] Closed beta testing

---

## Jira Stories to Create

These are proposed; creator should adjust scope/priority:

| Story | Title | Effort | Phase | Priority |
|---|---|---|---|---|
| **WTM-39** | Define Fit-Gap Analysis (Hub vs Tổng Tài) | 3 days | 1B | P0 |
| **WTM-40** | Plan Shared Core Package Refactoring | 3 days | 1B | P1 |
| **WTM-41** | Implement App Separation (Folder Structure) | 2 weeks | 1C | P1 |
| **WTM-42** | Define Package Identity & App Icons | 2 days | 1B | P0 |
| **WTM-43** | Create Build & Run Guide (Dev Onboarding) | 2 days | 1B | P0 |

**Epic:** Tổng Tài Technology Foundation (Phase 1B-1C)

---

## Confluence Page Structure (Proposed)

**Space:** Tổng Tài (or WorkizenTo, pending Confluence setup)  
**Page:** Technology & Architecture

**Content:**
- Overview (this index)
- Links to 5 tech docs above
- Tech stack summary (Flutter, Dart, SQLite, xAI)
- Architecture diagram (folder structure)
- Build process overview
- Isolation rules (visual)
- Roadmap (Phase 1B → 1C → 2)
- FAQ (common Q&A)

---

## Success Criteria

✅ **All 5 tech docs complete and bilingual (EN+VI)**  
✅ **Fit-gap matrix filled (reuse decisions made)**  
✅ **Shared core packages identified + planned**  
✅ **App separation rules documented**  
✅ **Build guide tested (team can build locally)**  
✅ **Jira stories created (WTM-39-43)**  
✅ **Confluence page published**  
✅ **Founder reviews & approves**  

---

## Contact & Questions

- **Architecture Questions:** Ask in Jira (WTM project)
- **Build Issues:** See BUILD-AND-RUN-GUIDE.md → Troubleshooting
- **Isolation Violations:** See APP-SEPARATION-PLAN.md → Code Review Checklist
- **Fit-Gap Clarification:** See FIT-GAP-PREPARATION.md → Capability Assessment Matrix

---

**Document Version:** 1.0 (Draft)  
**Status:** 📋 Awaiting Founder Review  
**Last Updated:** 2026-07-13 18:30 UTC  
**Next Milestone:** Founder Approval + Jira Story Creation
