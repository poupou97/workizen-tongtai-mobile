# Open Decisions — Tổng Tài Phase 1B

## English

**Purpose:** Track product and technical decisions pending Founder approval that affect Phase 1B and Phase 2 execution.

**Status Update:** 10 decisions mapped, 7 require Founder decision by end of Phase 1B (Aug 28, 2026).

---

## D-1: App Separation Strategy

**Status:** ✅ **DECIDED — 2026-07-16 (Founder)** → **Option 1: Single-app + Flavors**

> **Founder decision (recorded verbatim intent):** ship MVP fast, maximize AI Hub
> platform reuse, no premature optimization. Tổng Tài remains an independent
> product in domain/UI-UX/business logic but shares the platform layer.
> **Architecture requirements:** (1) clear Platform Layer vs Product Layer
> separation; (2) Tổng Tài business logic must NOT depend directly on Hub
> feature code; (3) every new module must be extractable into its own package or
> repo later. **Roadmap:** Phase 1–2 = single-app + flavors; at ~100k+ users or
> an independent team, re-evaluate Multi-Package Monorepo; a separate repository
> only when release lifecycles must truly split.
> Full record: `ADR-TON-001-app-separation-single-app-flavors.md`.

**Question:** How should Tổng Tài be isolated from Workizen Hub in the codebase?

**Options:**

1. **Single Flutter Project, Multi-Target**
   - One `pubspec.yaml`, shared dependencies, two build flavors (hub / tongtai)
   - Pros: Shared Drift schema, reuse navigation framework, single dependency version
   - Cons: Couples release cycles, larger APK, complex feature flags
   - Estimated effort: 2-3 weeks

2. **Multi-Package Monorepo** ⭐ RECOMMENDED
   - Shared `workizen_shared/` package (SQLite, AI client, navigation, components)
   - Independent `hub_mobile/` and `tongtai_mobile/` apps
   - Dependency: both depend on `workizen_shared`
   - Pros: Independent releases, clean separation, reusable shared layer, mirrors future repo split
   - Cons: Slightly more setup, private pub.dev or path dependency management
   - Estimated effort: 1-2 weeks

3. **Separate Repositories** (Early)
   - Fork main branch now, duplicate shared code
   - Pros: Total independence, clear ownership
   - Cons: Code duplication, hard to keep Hub reuse in sync, complex cherry-picking
   - Estimated effort: High ongoing maintenance

**Recommendation:** Option 2 (Multi-Package Monorepo). Balances reuse with independence, enables future repo split, mirrors Hub's own multi-module structure.

**Business Impact:**
- Option 1: Tight coupling, must release both together
- Option 2: Independent release cadence, but must maintain shared package API compatibility
- Option 3: Full duplication, maintenance burden

**Timeline:** Decision needed by Aug 5 for Phase 2 sprint planning.

**Owner:** Founder (product decision) + PM Agent (architecture)

**Dependencies:**
- WTM-41 prototype results
- REUSE-ASSESSMENT.md identification of reusable packages
- App packaging decision (D-3)

**Notes:** Hub already uses multi-module structure (packages, core layers). Tổng Tài can adopt same pattern, proven by Hub experience.

---

## D-2: Package & Bundle Identity

**Status:** PROPOSED (3 options in ANDROID-IOS-IDENTITY-PLAN.md)

**Question:** What package/bundle identifiers should Tổng Tài use on Android and iOS?

**Options:**

1. **Semantic: `com.workizen.tongtai` / `com.workizen.tongtai`** ⭐ RECOMMENDED
   - Clear product name, matches Firebase console
   - Pros: Semantic, easy to understand, aligns with brand
   - Cons: Less future-proof if product rebrands
   - Estimated effort: 0 (decision only)

2. **Generic: `com.workizen.business` / `com.workizen.business`**
   - Future-proof if Tổng Tài rebrands to "Business OS"
   - Pros: Flexible for future pivots
   - Cons: Less clear product identity
   - Estimated effort: 0

3. **Organizational: `ai.workizen.business` / `ai.workizen.business`**
   - Matches Hub pattern (`ai.workizen.wallet`)
   - Pros: Consistent with Hub, clear org intent
   - Cons: Slightly verbose
   - Estimated effort: 0

**Recommendation:** Option 1 (`com.workizen.tongtai`). Semantic, clear, aligns with product brand. If later rebrand needed, bundle can change (app users don't see this).

**Business Impact:**
- All options functionally equivalent; choice is branding/marketing signal
- Firebase console will mirror chosen package
- Play Store and App Store listing tied to this identifier

**Timeline:** Needed immediately for Firebase setup + Phase 2 mobile build.

**Owner:** Founder (branding)

**Dependencies:**
- Firebase project setup (WTM-45)
- Google Play Developer setup
- Apple Developer setup

**Notes:** Cannot change after first production release (store policies). Choose carefully but this is not a blocker.

---

## D-3: MVP Launch Strategy

**Status:** PROPOSED (affects Phase 2 scope)

**Question:** What is the launch path for Tổng Tài from closed beta to public release?

**Options:**

1. **Closed Beta → Open Beta → Production** (Standard)
   - Phase 2: Closed beta (50-100 testers, ~4-6 weeks)
   - Phase 3: Open beta (10,000+ testers, Google Play / App Store beta track, ~2-3 weeks)
   - Phase 4: Production release on stores
   - Pros: Phased risk, feedback loops, proven path
   - Cons: Longer overall timeline, more polish required upfront
   - Estimated effort: Standard

2. **Closed Beta → Production Fast-Track** (Aggressive)
   - Phase 2 extended (8-10 weeks closed beta with 1,000+ testers)
   - Skip open beta, go straight to production on stores
   - Pros: Faster public availability, competitive advantage
   - Cons: Higher risk (less testing), faster turnaround for bug fixes, user support load
   - Estimated effort: Same features, higher velocity

3. **Direct APK Download → Production** (Minimum Path)
   - Phase 2: Distribute APK via website + Firebase App Distribution
   - Skip stores initially, reach Android users only
   - Later (Phase 4): Submit to Play Store + App Store
   - Pros: Unblocked by store review, full control over release timing
   - Cons: Limited distribution, user discovery hard, not professional, platform fragmentation
   - Estimated effort: Lower upfront, higher long-term

**Recommendation:** Option 1 (Standard path). Hub's successful precedent shows closed-beta-first mitigates risk, feedback loop improves product-market fit, open beta builds community buzz.

**Business Impact:**
- Option 1: Professional launch, stores are single source of truth, standard user expectations
- Option 2: Faster but riskier, good if founder confident in product quality and can handle rapid feedback
- Option 3: Limited reach, later store submission complex (version numbering, review reset)

**Timeline:** Decision drives Phase 2 QA effort allocation and store submission timing. Needed by Aug 10.

**Owner:** Founder (market strategy) + QA/Deploy Agent (release logistics)

**Dependencies:**
- D-6 (payment timing decision)
- D-7 (analytics/privacy decision)
- Store accounts setup

**Notes:** Hub launched closed beta first (v1.1.0+38), proved valuable. Recommend replicating that playbook.

---

## D-4: Authentication (MVP Scope)

**Status:** TBD (needs Founder decision on privacy tradeoff)

**Question:** Should Tổng Tài require user authentication in Phase 2, or stay local-only?

**Options:**

1. **No Authentication (Local-Only)** ⭐ RECOMMENDED FOR MVP
   - Phase 1-2: No login, all data stored locally on device
   - User ID = device-generated UUID (local reference only)
   - Backup/sync added in Phase 3 (opt-in via Keycloak)
   - Pros: Privacy-first, simplest MVP, zero backend, faster ship
   - Cons: No data sync, no team features, users reinstall = data loss
   - Estimated effort: 0 (local-first already planned)

2. **Keycloak Optional** (Phase 2)
   - Offer login for sync, no enforcement
   - Backup/sync behind opt-in toggle
   - Pros: Privacy choice, early sync adoption, can measure demand
   - Cons: Complex UX (when to login?), sync edge cases, more support burden
   - Estimated effort: 2-3 weeks (Keycloak integration)

3. **Keycloak Required** (Anti-Pattern for MVP)
   - Enforce login at startup
   - Requires backend infrastructure, account recovery, etc.
   - Pros: Future-proof for teams/collab
   - Cons: Violates Local-First principle, increases churn, conflicts with BYOK philosophy
   - Estimated effort: 3-4 weeks
   - NOT RECOMMENDED for Phase 1B

**Recommendation:** Option 1 (No auth in MVP). Aligns with Tổng Tài's Local-First principle (per CLAUDE.md), accelerates Phase 2 ship date, reduces backend dependency, keeps MVP laser-focused. Sync/backup added Phase 3 as opt-in.

**Business Impact:**
- Option 1: True local-first experience, no account friction, privacy as feature
- Option 2: Hedges bets, measures sync demand, but adds complexity
- Option 3: Over-engineered for MVP, risks user churn

**Timeline:** Must decide by Aug 5 to finalize Phase 2 backend scope.

**Owner:** Founder (privacy principle)

**Dependencies:**
- D-5 (backend scope decision)
- Local-first storage (already designed in ADR-003)

**Notes:** Tổng Tài, like Hub, is founded on privacy-first. Local-only auth is not a limitation—it's a feature. Defer sync/teams to Phase 3 after PMF validation.

---

## D-5: Backend & Sync (MVP Scope)

**Status:** TBD (depends on D-4)

**Question:** Should Phase 2 MVP include any backend, or remain fully local?

**Options:**

1. **No Backend (Pure Local)** ⭐ RECOMMENDED FOR MVP
   - All compute on-device, all data on-device
   - AI calls only (xAI/OpenRouter), no sync backend
   - Backup = user exports CSV locally
   - Pros: Simplest ship, lowest cost, pure local-first, BYOK validated
   - Cons: No sync, no team collab, users responsible for backup
   - Estimated effort: 0 (all designed)
   - Cost: $0/month

2. **Light Sync Backend** (Phase 3)
   - Phase 2: Still local-only
   - Phase 3: Optional Portal sync (user exports → server stores encrypted copy)
   - Backup/recovery + cross-device restore capability
   - Pros: Opt-in convenience, server cost low initially
   - Cons: More complex UX, sync conflict handling
   - Estimated effort: 2-3 weeks (Phase 3)
   - Cost: $200-500/month initially

3. **Full Backend** (Anti-Pattern for MVP)
   - Phase 2: Enforce server persistence from day 1
   - Cloud-first data model
   - Pros: Immediate sync, cross-device support
   - Cons: Violates local-first, adds infra cost, slows ship
   - Estimated effort: 4-6 weeks
   - Cost: $1000+/month
   - NOT RECOMMENDED for MVP

**Recommendation:** Option 1 (No backend). Achieves MVP ship goal, maintains local-first principle, reduces cost and complexity. Sync in Phase 3 allows time to validate product-market fit before investing in infrastructure.

**Business Impact:**
- Option 1: Fastest to market, validates core product value, sync pain measured via support/feedback
- Option 2: Early infrastructure investment, measures sync demand without enforcing it
- Option 3: Over-built, risks not validating core business value before infrastructure cost

**Timeline:** Decision needed by Aug 5.

**Owner:** Founder (strategic scoping)

**Dependencies:**
- D-4 (auth decision)
- Phase 2 resource availability
- Business model (subscription vs ads vs enterprise)

**Notes:** Hub validated local-first works. Tổng Tài should replicate that success, defer sync investments until demand proven.

---

## D-6: Payment & Monetization (Phase 2+)

**Status:** PROPOSED (RevenueCat SDK ready, models TBD)

**Question:** Should Phase 2 include any monetization, or remain free-to-play?

**Options:**

1. **Free MVP (Monetization Phase 3)** ⭐ RECOMMENDED FOR MVP
   - Phase 2: 100% free, no restrictions
   - Phase 3: Freemium model (storage quota + advanced AI features)
   - Uses RevenueCat SDK (already integrated in Hub)
   - Pros: Max user acquisition, clear monetization strategy when ready, measured demand
   - Cons: Future paywall friction (user expectation reset), churn risk at paywall
   - Estimated effort: 0 Phase 2, 2-3 weeks Phase 3
   - Revenue: $0 Phase 2, estimated $5-20k/month Phase 3 (based on 10% conversion)

2. **Lite Freemium (Phase 2)** 
   - Free tier: 10 products, 3 suppliers, basic AI (2 queries/day)
   - Pro tier: Unlimited, advanced AI, $4.99/month or $39.99/year
   - Introduces paywall early, measures monetization
   - Pros: Revenue from day 1, tests pricing elasticity
   - Cons: May reduce user growth, distract from product refinement, quota management complexity
   - Estimated effort: 2-3 weeks Phase 2
   - Revenue: estimated $500-2k/month Phase 2, $10-30k/month Phase 3

3. **No Monetization (Long-term Ad-Supported)**
   - Phase 2-3: Free with no paywalls
   - Phase 4: Ad-supported (banner + rewarded)
   - Pros: Max growth, pure engagement, later monetization doesn't break user trust
   - Cons: Different economics, ad system complexity, lower revenue ceiling
   - Estimated effort: 1-2 weeks Phase 4

**Recommendation:** Option 1 (Free MVP). Mirrors Hub's successful playbook (free until product proven), removes friction from onboarding and feedback collection, RevenueCat already integrated and tested. Freemium added Phase 3 after PMF confirmation.

**Business Impact:**
- Option 1: Maximizes user growth, validates value before monetization, maintains goodwill
- Option 2: Faster revenue but risk of slow growth, "cheap" positioning
- Option 3: Maximum growth but late monetization uncertainty

**Timeline:** Decision needed by Aug 10 (affects Phase 2 sprint scope).

**Owner:** Founder (business model)

**Dependencies:**
- D-3 (launch strategy)
- User acquisition targets
- Team financial sustainability needs

**Notes:** Hub shipped free (v1.1.0+38 closed beta, still free at +62), proved acquisition-first is smart. Replicate for Tổng Tài.

---

## D-7: Analytics & Privacy (MVP Scope)

**Status:** PROPOSED (privacy principle clear, telemetry timing TBD)

**Question:** What data collection is acceptable in Phase 2 closed beta?

**Options:**

1. **Privacy-First: No Analytics (MVP)** ⭐ RECOMMENDED
   - Phase 2: Zero telemetry SDKs, zero crash reporting
   - Manual feedback only (in-app survey, email support)
   - Usage insight via user interviews, not data
   - Pros: Maintains privacy brand, no user friction, no privacy policy complexity, trust-first
   - Cons: Slower issue detection, less quantified metrics, higher support load
   - Estimated effort: 0
   - Cost: Support hours only

2. **Opt-In Telemetry (Privacy-Respectful)**
   - Phase 2: Crash reporting + usage analytics (Firebase Analytics with no personalized ads)
   - Clear privacy explanation, OFF by default
   - Users opt-in explicitly during onboarding
   - Pros: Better issue detection, quantified metrics, still privacy-first
   - Cons: Firebase integration complexity, privacy policy review needed, low opt-in rates (typically 5-15%)
   - Estimated effort: 1-2 weeks
   - Cost: Firebase free tier (under 1M events)

3. **Default Analytics** (Anti-Pattern for Privacy Brand)
   - Phase 2: Crash reporting + analytics enabled by default
   - Typical SaaS telemetry
   - Pros: Max data for product optimization
   - Cons: Violates privacy-first positioning, user friction, contradicts brand promise
   - Estimated effort: 1-2 weeks
   - NOT RECOMMENDED

**Recommendation:** Option 1 (Privacy-First, no analytics). Tổng Tài's brand is AI-first + privacy-first. Telemetry SDKs contradict this promise. Gather feedback via manual channels in closed beta (small user base). Revisit in Phase 3 if needed, but default should remain OFF.

**Business Impact:**
- Option 1: Strengthens privacy brand, zero regulatory risk, trust-first positioning
- Option 2: Balanced: metrics with privacy respect, but low adoption
- Option 3: Maximum metrics but brand dilution

**Timeline:** Decision needed by Aug 5.

**Owner:** Founder (brand positioning)

**Dependencies:**
- Privacy policy content
- Support process design for closed beta

**Notes:** Privacy is core Workizen principle (CLAUDE.md). Tổng Tài should not compromise on this.

---

## D-8: Localization & Language Priority

**Status:** PROPOSED (bilingual docs mandated, but app priority TBD)

**Question:** Which language is primary for Phase 2 closed beta app release?

**Options:**

1. **Vietnamese Primary, English Secondary** ⭐ RECOMMENDED
   - All UI defaults to Vietnamese (VI)
   - English available as in-app language toggle
   - Marketing/docs in Vietnamese first
   - Pros: SME target market speaks Vietnamese, clearer product vision in mother tongue, cultural fit
   - Cons: English-speaking user feedback delayed
   - Estimated effort: 0 (already designed)

2. **Bilingual Parallel**
   - Both languages equally supported from day 1
   - App defaults to device language
   - Equal marketing effort both languages
   - Pros: Wider audience, future-proof
   - Cons: Double translation effort, diluted messaging
   - Estimated effort: +1-2 weeks Phase 2

3. **English Primary** (Anti-Pattern)
   - English-first for international positioning
   - Vietnamese translation later
   - Pros: Potential global expansion signal
   - Cons: Misses home market, lost cultural resonance, small SME audience speaks English
   - Estimated effort: Higher later-stage translation cost

**Recommendation:** Option 1 (Vietnamese Primary). Tổng Tài targets Vietnamese SMEs. Product vision clearest in Vietnamese business terminology. English available as toggle for international users/docs. Hub precedent: Vietnamese product, English available (Debrief, My Voice with VN terms).

**Business Impact:**
- Option 1: Market fit, cultural resonance, strong home-market positioning
- Option 2: Slower decisions (translation load), weaker initial messaging
- Option 3: Misses core audience

**Timeline:** Needed by Aug 10 for Phase 2 sprint copy planning.

**Owner:** Founder (market positioning) + Designer (UX copy)

**Dependencies:**
- TERMINOLOGY.md finalization (Vietnamese business terms)
- Translation workflow setup
- Marketing narrative

**Notes:** Workizen's strength is Vietnam knowledge. Lead with that, not international dilution.

---

## D-9: Primary AI Model & Provider Strategy

**Status:** PROPOSED (xAI/OpenRouter tested, Provider primary decision TBD)

**Question:** Which AI model/provider should Tổng Tài use by default, and what's the fallback strategy?

**Options:**

1. **xAI Primary + OpenRouter Fallback** ⭐ RECOMMENDED
   - Primary: xAI (Grok) — strong reasoning, cost-effective, founder relationship ✅
   - Fallback: OpenRouter free tier (if xAI unavailable or quota exceeded)
   - User can BYOK (bring any xAI/OpenRouter API key) or use app-embedded key
   - Pros: Preferred provider, tested integration, cost-effective, clear fallback
   - Cons: Dependent on xAI availability, provider pricing changes
   - Estimated effort: 0 (Hub already has this)

2. **Multi-Provider Agnostic** (Complex)
   - Offer xAI + OpenRouter + local Ollama + user BYOK at equal weight
   - User selects provider at setup
   - Pros: Maximum resilience, user choice
   - Cons: Complex UX, testing burden, lower quality bar per provider
   - Estimated effort: 2-3 weeks (provider routing logic)

3. **OpenRouter Exclusive** (Suboptimal)
   - Convenience, but loses xAI relationship
   - Pros: Simpler integration (one provider)
   - Cons: Slower reasoning for business AI, higher cost
   - Estimated effort: 0
   - NOT RECOMMENDED

**Recommendation:** Option 1 (xAI primary + OpenRouter fallback). Proven hub pattern, founder connection, strong reasoning for business use cases (Opportunity Engine needs nuanced analysis). User can always bring own key. Fallback ensures availability.

**Business Impact:**
- Option 1: Optimal user experience + cost, validates xAI partnership
- Option 2: Maximum resilience but diminishes Tổng Tài's core AI personality
- Option 3: Cost/availability tradeoff

**Timeline:** Needed by Aug 5 for Phase 2 feature contracts.

**Owner:** Founder (provider relationship)

**Dependencies:**
- xAI API availability + pricing confirmation
- OpenRouter free tier status
- BYOK key management UX

**Notes:** Hub's model selection proven: xAI first, fallback on OpenRouter. Tổng Tài should replicate.

---

## D-10: Data Export & Business Intelligence Features

**Status:** TBD (Phase 2 vs Phase 3 timing)

**Question:** Should Phase 2 MVP include data export (CSV/Excel) and BI reporting, or defer to Phase 3?

**Options:**

1. **Phase 3 Deferral** ⭐ RECOMMENDED FOR MVP
   - Phase 2: Focused on core CRUD + AI Opportunity Engine
   - Phase 3: Add export + BI reports (custom dashboards, trend analysis)
   - Pros: Faster Phase 2 ship, focus on core value (business journey), export less critical than AI
   - Cons: User requests for export in closed beta, complexity adds Phase 3
   - Estimated effort: 0 Phase 2, 1-2 weeks Phase 3

2. **Basic CSV Export (Phase 2)**
   - Phase 2: Add "Export as CSV" on Producer / Inventory / Consumer lists
   - Users can download their data anytime
   - Pros: Data portability, satisfies user demand, trust-building
   - Cons: Adds scope, 1 week engineering, low usage likely in closed beta
   - Estimated effort: 1 week Phase 2

3. **Full BI Suite (Phase 2)** (Over-Scoped)
   - Custom dashboards, forecasting, trend analysis
   - Requires data warehouse / query engine
   - Pros: Differentiator, comprehensive offering
   - Cons: Massive scope, delays ship, not core to MVP
   - Estimated effort: 3-4 weeks Phase 2
   - NOT RECOMMENDED for MVP

**Recommendation:** Option 1 (Phase 3 deferral). MVP laser focus: get Opportunity Engine + core business journey working. Export is nice-to-have, BI is Phase 3+ when data patterns are clear. Hub's approach: core features first, reporting layers later.

**Business Impact:**
- Option 1: Faster MVP, focus on core AI value, technical debt minimal
- Option 2: User peace-of-mind (data portability), slight scope creep
- Option 3: Over-engineered for MVP, risk of incomplete BI

**Timeline:** Decision needed by Aug 10.

**Owner:** Founder (MVP prioritization) + PM Agent (user research)

**Dependencies:**
- Phase 2 resource constraints
- User feedback from competitive research

**Notes:** Hub's export/reporting added gradually. Tổng Tài should follow same pattern.

---

## Summary Table

| Decision | Status | Timeline | Owner | Recommendation |
|---|---|---|---|---|
| D-1: App Separation | ✅ DECIDED 2026-07-16 | — | Founder | **Single-app + Flavors** (re-eval monorepo at ~100k users) |
| D-2: Package ID | PROPOSED | Immediate | Founder | `com.workizen.tongtai` |
| D-3: MVP Launch Path | PROPOSED | Aug 10 | Founder + QA | Closed Beta → Open → Prod |
| D-4: Auth (MVP) | TBD | Aug 5 | Founder | Local-Only (no auth) |
| D-5: Backend (MVP) | TBD | Aug 5 | Founder | No Backend (pure local) |
| D-6: Monetization | PROPOSED | Aug 10 | Founder | Free MVP, freemium Phase 3 |
| D-7: Analytics | PROPOSED | Aug 5 | Founder | Privacy-First (no telemetry) |
| D-8: Language Priority | PROPOSED | Aug 10 | Founder + Design | Vietnamese Primary |
| D-9: AI Model | PROPOSED | Aug 5 | Founder | xAI Primary + OpenRouter |
| D-10: Export/BI | TBD | Aug 10 | Founder + PM | Defer to Phase 3 |

---

---

## Tiếng Việt

**Mục Đích:** Theo dõi các quyết định sản phẩm và kỹ thuật đang chờ phê duyệt từ Founder, ảnh hưởng đến thực hiện Phase 1B và Phase 2.

**Cập Nhật Trạng Thái:** 10 quyết định đã được ánh xạ, 7 quyết định yêu cầu phê duyệt từ Founder trước hết ngày Phase 1B (28 Tháng Tám, 2026).

### D-1: Chiến Lược Tách Ứng Dụng

**Trạng Thái:** ✅ **ĐÃ QUYẾT — 16/07/2026 (Founder)** → **Tùy chọn 1: Single-app + Flavors**

> **Quyết định Founder:** ưu tiên ship MVP nhanh, tái sử dụng tối đa nền tảng AI
> Hub, không tối ưu sớm. Tổng Tài vẫn là sản phẩm độc lập về domain/UI-UX/
> business logic nhưng dùng chung platform layer. **Yêu cầu kiến trúc:** (1) tách
> rõ Platform Layer / Product Layer; (2) business logic Tổng Tài KHÔNG phụ thuộc
> trực tiếp code feature của Hub; (3) mọi module mới phải tách được thành
> package/repo riêng trong tương lai. **Lộ trình:** Phase 1–2 = single-app +
> flavors; ~100k+ users hoặc có team độc lập → đánh giá Multi-Package Monorepo;
> repo riêng chỉ khi thật sự cần tách vòng đời phát hành.
> Hồ sơ đầy đủ: `ADR-TON-001-app-separation-single-app-flavors.md`.

**Câu Hỏi:** Tổng Tài nên được tách biệt khỏi Workizen Hub trong codebase như thế nào?

**Các Tùy Chọn:**

1. **Single Flutter Project, Multi-Target**
   - Một `pubspec.yaml`, dependencies chia sẻ, hai build flavors (hub / tongtai)
   - Ưu điểm: Chia sẻ Drift schema, tái sử dụng navigation framework
   - Nhược điểm: Liên kết release cycles, APK lớn hơn

2. **Multi-Package Monorepo** ⭐ RECOMMENDED
   - Shared `workizen_shared/` package (SQLite, AI client, components)
   - Ứng dụng độc lập `hub_mobile/` và `tongtai_mobile/`
   - Ưu điểm: Rele độc lập, tách biệt rõ ràng, phản ánh tách repo tương lai
   - Nhược điểm: Setup phức tạp hơn, quản lý pub.dev

3. **Separate Repositories** (Sớm)
   - Fork branch chính, sao chép code chia sẻ
   - Ưu điểm: Độc lập hoàn toàn
   - Nhược điểm: Trùng lặp code, khó đồng bộ

**Khuyến Nghị:** Option 2. Cân bằng tái sử dụng với độc lập, cho phép tách repo tương lai.

**Dòng Thời Gian:** Cần quyết định trước 5 Tháng 8 để lập kế hoạch sprint Phase 2.

**Chủ Sở Hữu:** Founder (quyết định sản phẩm) + PM Agent

---

### D-2: Danh Tính Gói & Bundle

**Trạng Thái:** PROPOSED

**Câu Hỏi:** Tổng Tài nên sử dụng những danh tính package/bundle nào trên Android và iOS?

**Các Tùy Chọn:**

1. **Semantic: `com.workizen.tongtai`** ⭐ RECOMMENDED
   - Rõ ràng, khớp với tên sản phẩm
   - Ưu điểm: Dễ hiểu, phù hợp với thương hiệu
   - Nhược điểm: Ít linh hoạt nếu rebranding

2. **Generic: `com.workizen.business`**
   - Linh hoạt hơn nếu pivot sau này
   - Ưu điểm: Có thể thích ứng tương lai
   - Nhược điểm: Ít rõ ràng về danh tính sản phẩm

3. **Tổ Chức: `ai.workizen.business`**
   - Khớp với Hub (`ai.workizen.wallet`)
   - Ưu điểm: Nhất quán
   - Nhược điểm: Dài hơn

**Khuyến Nghị:** Option 1. Rõ ràng, có ý nghĩa, khớp với thương hiệu sản phẩm.

**Dòng Thời Gian:** Cần ngay để cài đặt Firebase.

**Chủ Sở Hữu:** Founder (branding)

---

### D-3: Chiến Lược Khởi Động MVP

**Trạng Thái:** PROPOSED

**Câu Hỏi:** Đường dẫn khởi động cho Tổng Tài từ closed beta đến phát hành công khai là gì?

**Các Tùy Chọn:**

1. **Closed Beta → Open Beta → Production** ⭐ RECOMMENDED
   - Phase 2: Closed beta (50-100 người kiểm thử)
   - Phase 3: Open beta (10,000+ người kiểm thử)
   - Phase 4: Phát hành production
   - Ưu điểm: Quản lý rủi ro từng giai đoạn, vòng lặp phản hồi

2. **Closed Beta → Production Fast-Track**
   - Phase 2 mở rộng (8-10 tuần)
   - Bỏ qua open beta
   - Ưu điểm: Nhanh hơn, cạnh tranh
   - Nhược điểm: Rủi ro cao hơn

3. **Direct APK → Production**
   - Phát hành APK trực tiếp
   - Bỏ qua cửa hàng ban đầu
   - Ưu điểm: Không bị chặn bởi review cửa hàng
   - Nhược điểm: Phạm vi hạn chế

**Khuyến Nghị:** Option 1. Hub đã chứng minh closed-beta-first giảm rủi ro, cải thiện product-market fit.

**Dòng Thời Gian:** Cần trước 10 Tháng 8.

**Chủ Sở Hữu:** Founder (chiến lược thị trường) + QA/Deploy Agent

---

### D-4: Xác Thực (MVP Scope)

**Trạng Thái:** TBD

**Câu Hỏi:** Tổng Tài có nên yêu cầu xác thực người dùng trong Phase 2, hay vẫn chỉ cục bộ?

**Các Tùy Chọn:**

1. **Không Xác Thực (Local-Only)** ⭐ RECOMMENDED
   - Phase 1-2: Không cần đăng nhập
   - Tất cả dữ liệu lưu trữ cục bộ trên thiết bị
   - ID người dùng = UUID do thiết bị tạo
   - Ưu điểm: Privacy-first, đơn giản nhất, không backend
   - Nhược điểm: Không đồng bộ, không team features

2. **Keycloak Optional** (Phase 2+)
   - Đề nghị đăng nhập cho đồng bộ
   - Không bắt buộc
   - Ưu điểm: Privacy choice, đo lường nhu cầu
   - Nhược điểm: UX phức tạp

3. **Keycloak Bắt Buộc** (Anti-Pattern)
   - Yêu cầu đăng nhập
   - Nhược điểm: Violate Local-First principle

**Khuyến Nghị:** Option 1. Phù hợp với nguyên tắc Local-First, tăng tốc độ ship Phase 2.

**Dòng Thời Gian:** Cần trước 5 Tháng 8.

**Chủ Sở Hữu:** Founder (privacy principle)

---

### Bảng Tóm Tắt

| Quyết Định | Trạng Thái | Dòng Thời Gian | Chủ Sở Hữu | Khuyến Nghị |
|---|---|---|---|---|
| D-1: Tách Ứng Dụng | ✅ ĐÃ QUYẾT 16/07/2026 | — | Founder | **Single-app + Flavors** (đánh giá lại monorepo ở ~100k users) |
| D-2: ID Gói | PROPOSED | Ngay lập tức | Founder | `com.workizen.tongtai` |
| D-3: Đường Dẫn MVP | PROPOSED | 10 Tháng 8 | Founder + QA | Closed → Open → Prod |
| D-4: Xác Thực (MVP) | TBD | 5 Tháng 8 | Founder | Local-Only |
| D-5: Backend (MVP) | TBD | 5 Tháng 8 | Founder | No Backend |
| D-6: Tiền Tệ | PROPOSED | 10 Tháng 8 | Founder | Free MVP, Freemium Phase 3 |
| D-7: Phân Tích | PROPOSED | 5 Tháng 8 | Founder | Privacy-First |
| D-8: Ưu Tiên Ngôn Ngữ | PROPOSED | 10 Tháng 8 | Founder + Design | Vietnamese Primary |
| D-9: Model AI | PROPOSED | 5 Tháng 8 | Founder | xAI Primary + OpenRouter |
| D-10: Export/BI | TBD | 10 Tháng 8 | Founder + PM | Defer Phase 3 |

---

**Last Updated:** 2026-07-13  
**Status:** 🔄 Ready for Founder Review
