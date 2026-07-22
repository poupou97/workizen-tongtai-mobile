# Risks, Constraints & Mitigations — Tổng Tài

## English

**Purpose:** Identify and track product, technical, and organizational risks that could impact Tổng Tài delivery. Also document known constraints that shape scope and execution.

**Last Updated:** 2026-07-13  
**Status:** 🔄 Phase 1B In Progress

---

## Risk Matrix

```
           Low Prob   Med Prob   High Prob
HIGH       R-7        R-2, R-6   R-1, R-3, R-5
MEDIUM     R-8, R-9   R-4, R-10  R-11
LOW        R-12       R-13       (none)

Total: 13 Risks Identified
Active: 11
Mitigated: 2 ✅
Resolved: 0
```

---

## Critical Risks (Severity 🔴 HIGH, Impact > 4 weeks)

### R-1: Scope Creep — Founder Feature Adds Beyond MVP

**Severity:** 🔴 Critical  
**Probability:** High (historical pattern on Hub: MVP → features → scope spiral)  
**Description:** Founder enthusiasm for Tổng Tài could lead to adding features beyond Phase 2 MVP scope (e.g., multi-user, advanced finance forecasting, integrations). Each new feature = 1-2 weeks delay.

**Impact:**
- Phase 2 timeline slips 2-4 weeks (target Oct 15 → Nov 15)
- Developer team overworked, quality suffers
- Beta launch delayed, market window narrows
- Phase 3 (production) at risk

**Probability Drivers:**
- Founder driven by ambitious product vision (feature-rich)
- Competitive pressure ("other apps have X feature")
- User feedback during closed beta ("please add Y")

**Mitigation:**
- **Gate mechanism:** Founder approval required for ANY scope addition (contract v2 D-118)
- **Clear MVP definition:** OPEN-DECISIONS.md + PRODUCT-BOUNDARIES.md frozen at Phase 1B end
- **Backlog discipline:** New features → backlog with clear "Phase 3+" label, not Phase 2
- **Weekly scope review:** PM Agent flags any creep in sprint planning
- **Buffer time:** Reserve 1-2 weeks of phase 2 for "unknown unknowns"
- **Decision framework:** Feature request → Founder → YES (prioritize another out) or DEFER to Phase 3

**Contingency:**
- If creep detected mid-sprint, descope Phase 2 features (e.g., move Advanced Finance or Forecasting to Phase 3)
- Defer "nice-to-haves" immediately
- Trade time for quality only if critical issue found

**Owner:** Founder (decision) + PM Agent (monitoring)  
**Status:** Active — high vigilance needed  
**Monitoring:** Weekly sprint review, scope checklist

**Historical Context:**
Hub experienced 20% scope creep in Phase 1 (Chat, Scanner vs original note-taking focus). Lesson: enforce gates strictly, Founder buys in to trade-offs.

---

### R-3: AI Model Availability & Cost Volatility

**Severity:** 🔴 Critical  
**Probability:** High (xAI Beta API, pricing can change; OpenRouter is free but unreliable)  
**Description:** Tổng Tài's core AI features (Opportunity Engine, Copilot) depend on xAI Grok API. If xAI becomes unavailable, rate-limited, or pricing increases sharply, Tổng Tài loses competitive advantage or must pivot to lower-quality models.

**Impact:**
- Phase 2: App ships with degraded AI quality (falls back to OpenRouter free tier, which is slower)
- User experience suffers (recommendations less useful, chat responses slower)
- Opportunity Engine less compelling (core feature compromised)
- Revenue impact (freemium pricing sensitivity, churn if AI quality perceived as low)

**Probability Drivers:**
- xAI is in beta (API subject to change)
- OpenRouter free tier has rate limits (5req/min for free models)
- Grok pricing unknown (xAI business model TBD)

**Mitigation:**
- **Multi-provider strategy:** xAI primary, OpenRouter fallback, local Ollama tertiary (already designed in D-9)
- **Graceful degradation:** If xAI unavailable, automatically fall back to OpenRouter (tested in Phase 1C)
- **User BYOK option:** Users can bring their own xAI or OpenRouter keys (bypasses cost entirely)
- **Quota management:** Track API costs per beta user, alert if spend anomalies
- **Vendor lock-in assessment:** Design Opportunity Engine to work across models (abstracted prompt routing)
- **SLA monitoring:** Daily uptime checks for xAI + OpenRouter, alert if either below 99%
- **Pricing model flexibility:** Prepared to adjust freemium tiers if xAI costs rise

**Contingency:**
- If xAI becomes prohibitively expensive (>$100/mo for 1K users), default to OpenRouter + BYOK
- If OpenRouter free tier exhausted, offer paid tier to users or reduce Opportunity Engine frequency
- Last resort: local Ollama integration (mistral-7b or similar) for text-only features

**Owner:** Founder (vendor relationship) + Developer Agent (integration, monitoring)  
**Status:** Active — monitor xAI pricing announcements weekly  
**Monitoring:** Cost tracking dashboard, API uptime alerts, model performance benchmarks

**Notes:**
Hub faces same risk (xAI dependency). Tổng Tài should adopt Hub's provider abstraction layer + fallback strategy.

---

### R-5: Team Availability & Key Person Risk

**Severity:** 🔴 Critical  
**Probability:** High (founder has limited bandwidth, key developers may unavailable)  
**Description:** Phase 2 build requires 2-3 full-time developers for 8-10 weeks. If key team members unavailable (vacation, other projects, personal reasons), delivery slips or quality decays.

**Impact:**
- Phase 2 extends from 8 weeks → 12-16 weeks (30-50% delay)
- Parallel work blocked (single developer = serial bottleneck)
- QA/polish suffers (rushed, bugs missed)
- Beta launch delayed (Oct 15 → Dec 15)
- Market window shrinks (Q4 holiday season, competitor activity)

**Probability Drivers:**
- Founder has primary job (pre-arranged, limiting availability)
- Small team size (2-3 engineers, no deep bench)
- No formal resource commitment from parent company
- Contractors/freelancers may have other clients

**Mitigation:**
- **Early commitment:** Confirm developer availability NOW (before Phase 1B end)
- **Resource plan:** Assign 2 full-time + 1 part-time (50%) for Phase 2, finalized by Aug 15
- **Contingency staffing:** Identify 1-2 on-call contractors (coders, designers) for surge capacity
- **Async-first discipline:** Document decisions, specs, requirements clearly so work doesn't block on single person
- **Knowledge distribution:** Pair developers, cross-train on data layer + UI layer so no single point of failure
- **Founder time-box:** Reserve 5-10 hrs/week for founder (reviews, decisions), not daily implementation
- **Vacation planning:** Schedule holidays OUTSIDE Phase 2 (pre-Sep 1, post-Oct 31)

**Contingency:**
- If developer unavailable mid-sprint, descope Phase 2 (e.g., skip Advanced Finance, defer to Phase 3)
- Hire contractor immediately (cost $50-100/hr, ~$8k-15k for 2 weeks)
- Extend Phase 2 timeline (accept delayed launch)
- Reduce quality bar temporarily (known bugs → Phase 3, focus on core 3 epics only)

**Owner:** Founder (resource decision) + PM Agent (scheduling, risk monitoring)  
**Status:** Active — confirmation needed by Aug 1  
**Monitoring:** Weekly standup, developer calendar blocks

**Notes:**
Hub's playbook: founder works 10 hrs/week, developer team 1.5FTE on Hub features (shared with other products). Tổng Tài should request dedicated team for Phase 2 only.

---

### R-2: Hub Reuse Complexity & Shared Core Extraction

**Severity:** 🟠 High  
**Probability:** Medium (complex refactoring, but Hub precedent exists)  
**Description:** If Option 2 (Multi-Package Monorepo) chosen for D-1, extracting a reusable `workizen_shared` package from Hub is complex. Shared code (Drift, AI client, navigation) must be abstracted carefully. If extraction takes 3-4 weeks instead of 1-2, Phase 2 start delays.

**Impact:**
- Phase 2 start slips 2-3 weeks (Sep 1 → Sep 15-22)
- Developers blocked waiting for shared package to stabilize
- Multiple refactoring iterations needed
- Risk of breaking Hub while refactoring

**Probability Drivers:**
- Hub's code architecture not originally designed for multi-product reuse
- Tight coupling between Hub-specific and generic code
- Schema versioning complexity (Drift migrations must be backward compatible)

**Mitigation:**
- **Prototype early:** WTM-40/41 prototypes for app separation + shared core extraction, due Aug 15
- **Parallel work:** Shared core team starts extraction in parallel with Tổng Tài specs (Aug 1-21)
- **Clear boundaries:** Define shared vs product-specific code BEFORE refactoring (separation of concerns)
- **Testing discipline:** Unit tests + integration tests for shared package, prevent Hub regressions
- **Versioning strategy:** Semantic versioning for shared package (1.0.0), clear upgrade path
- **Rollback plan:** Git tags for stable shared package versions, ability to pin version
- **Communication:** Daily standup between Hub maintenance + Tổng Tài teams during extraction

**Contingency:**
- If extraction > 2 weeks, switch to Option 1 (Single Flutter app, multi-flavor) as fallback
- Duplicate code initially, refactor after Phase 2 (slower but lower risk)
- Hire contractor specializing in Dart/Flutter architecture (1-2 weeks, $15-20k)

**Owner:** Developer Agent (implementation) + PM Agent (scheduling)  
**Status:** Active — prototype due Aug 15  
**Monitoring:** Prototype results, extraction timeline tracking

**Notes:**
Hub has Drift, components, AI client reusable. Tổng Tài can build on this, but abstraction needs care. Test thoroughly with sample app (not just Hub + Tổng Tài simultaneously).

---

## High Risks (Severity 🟠 HIGH, Impact 2-4 weeks)

### R-4: Data Privacy & Compliance Risk

**Severity:** 🟠 High  
**Probability:** Medium (data types change from Hub: customer data, supplier data, financial data all sensitive)  
**Description:** Tổng Tài handles new data types (customer list, supplier pricing, financial records) that are more sensitive than Hub's documents/chat. Privacy regulations (Vietnam Personal Data Protection, international GDPR/CCPA if international expansion planned) could require changes late in Phase 2.

**Impact:**
- Privacy policy review required before launch (1-2 weeks delay if major issues found)
- Encryption requirements added (data-at-rest, data-in-transit)
- User consent flows needed (privacy consent at first launch)
- Play Store / App Store rejection if privacy policy insufficient
- User trust loss if data breach or privacy violation occurs

**Probability Drivers:**
- Product's core is business data (sensitive by nature)
- Data remains local, but export feature + future sync means data could leave device
- Privacy law complexity (Vietnam + international markets)

**Mitigation:**
- **Privacy-by-design:** Data minimization, no unnecessary collection (already in CLAUDE.md principle)
- **Local-first enforcement:** All data encrypted at-rest (sqlite encryption via Drift), no cloud by default
- **Privacy policy drafting:** Start NOW (Aug 1), use lawyer for 4-hour review ($1-2k), finalize by Oct 1
- **Data classification:** Document what's sensitive (all business data is sensitive) and handling rules
- **Compliance checklist:** Created in parallel with product (not an afterthought)
- **User education:** Clear onboarding about data ownership, privacy guarantees
- **Audit logging:** Optional privacy audit trail (what data accessed when, by whom) for enterprise features later
- **GDPR/CCPA prep:** Design data export + deletion flows (required by law)

**Contingency:**
- If privacy policy issues found late (Oct 1), delay store submission 2 weeks for remediation
- Simplify data model if compliance impossible (e.g., remove customer email, keep only business name)
- Consult external privacy counsel if uncertain ($3-5k)

**Owner:** Founder (policy, legal) + PM Agent (compliance checklist)  
**Status:** Active — privacy policy drafting starts Aug 1  
**Monitoring:** Legal review calendar, compliance checklist progress

**Notes:**
Hub privacy policy approved for Keycloak, but Tổng Tài's data is riskier. Early counsel recommended.

---

### R-6: Store Approval & Content Rating Delays

**Severity:** 🟠 High  
**Probability:** Medium (Google Play is usually fast, but App Store can be slow; privacy issues can trigger rejection)  
**Description:** Google Play typically approves in 2-3 hours, but App Store can take 3-7 days. If submission rejected (privacy policy, permissions, content rating), resubmission adds 1-2 weeks. Late submission = missed holiday season.

**Impact:**
- Phase 3 production launch delayed 2-3 weeks (Nov 25 → Dec 15)
- Competitor advantage if similar product launches (market window missed)
- Marketing campaigns disrupted (planned launch date no longer valid)
- Tester expectations unmet (promised "launch in Nov")

**Probability Drivers:**
- App Store is slower than Play Store (typical 3-7 days, can be 10-14 if rejected)
- Privacy policy issues could trigger rejection (Tổng Tài handles sensitive data)
- Content rating process requires user testing (IARC form for Play, age rating for App Store)
- First-time app is more risky for rejection (not a proven publisher)

**Mitigation:**
- **Early submission:** Submit to closed testing track FIRST (Google Play, App Store), not directly to production
- **Closed beta on Play/App Store:** Publish to beta track in Phase 3 week 1 (Oct 15), get feedback on submission quality
- **Store review prep:** Legal review of privacy policy, content rating accuracy, permissions, by Sep 15
- **Content rating:** Complete IARC rating in Phase 3 (Age 12+, Business app, minimal data collection)
- **Permissions audit:** Justification for each permission (camera for QR code, contacts optional, etc.)
- **App icon & screenshots:** Professional screenshots + description (50-100 words per language)
- **Early submission:** Submit to production track by Nov 1 (4 weeks before target launch), allow 2-3 weeks for review cycles

**Contingency:**
- If App Store rejects, submit appeal with clarification (usually approved within 2-3 days)
- If critical issue found (privacy), fix + resubmit (add 1-2 weeks)
- Parallel direct APK distribution (sideload.apk link on website, unblock Android users)
- Delay iOS launch to Jan 2027 if necessary (ship Android first)

**Owner:** QA/Deploy Agent (submission, tracking)  
**Status:** Active — prep starts in Phase 3 week 1  
**Monitoring:** Store submission status dashboard, approval timelines

**Notes:**
Hub's precedent: App Store approval took 5 days, no rejections. Tổng Tài might be slower (new publisher). Plan for worst case.

---

### R-11: AI Prompt Quality & Hallucination Risk

**Severity:** 🟠 High  
**Probability:** Medium (LLMs hallucinate; business decisions based on incorrect AI recommendation could cause user harm)  
**Description:** Opportunity Engine and Business Copilot provide business advice based on AI reasoning. If AI hallucinates or gives bad recommendations ("supplier X is trustworthy" when it's not, "buy this product trend" when it's declining), user could make costly business mistakes. Trust loss + potential liability.

**Impact:**
- User makes bad decision based on AI recommendation (costly for SME, e.g., $1k+ loss)
- Negative reviews / churn ("AI told me wrong advice")
- Reputational damage (founder called out on social media)
- Potential legal liability (if advice-giving is considered professional service)

**Probability Drivers:**
- xAI Grok is powerful but not infallible (like all LLMs, makes mistakes)
- Business data is incomplete (SME doesn't provide full context)
- AI reasoning is opaque (why did it recommend this supplier?)

**Mitigation:**
- **Probabilistic language:** Copilot always phrases as suggestions, not directives ("Consider checking…" not "You must…")
- **Source attribution:** Every recommendation shows sources (which data points informed this)
- **Confidence scoring:** AI returns confidence level (70% vs 90%), UI shows lower confidence with disclaimer
- **User override:** Users can reject AI advice, manually edit recommendations
- **Guardrails:** Block obviously bad recommendations (e.g., supplier with <50 reviews, pricing >500% above average)
- **User agreement:** Terms of service clearly state AI is advisory only, user responsible for decisions
- **Logging:** Log every AI recommendation + user action (accepted/rejected/edited) for improvement
- **Feedback loop:** Collect user feedback on recommendation quality, retrain prompts
- **Transparency:** In-app explanation: "Why did I suggest this?" (show reasoning chain, sources)
- **Escalation path:** If user suspects bad recommendation, email support for human review

**Contingency:**
- If high-confidence bad recommendations detected (user feedback), disable Opportunity Engine temporarily, investigate prompt quality
- Switch to more conservative prompts (lower confidence threshold, more explicit caveats)
- Add human review step for high-value recommendations before showing to user (slower but safer)

**Owner:** Developer Agent (implementation, monitoring) + Founder (prompt tuning)  
**Status:** Active — prompt testing starts Phase 2 sprint 3  
**Monitoring:** User feedback on recommendations, error rate tracking

**Notes:**
Hub's Chat sometimes hallucinates; Tổng Tài's recommendations are more risky (business impact). Design for skepticism, not trust.

---

## Medium Risks (Severity 🟡 MEDIUM, Impact 1-2 weeks)

### R-8: Localization Quality (Vietnamese Terms & Translations)

**Severity:** 🟡 Medium  
**Probability:** Low (foundational terminology already defined, bilingual docs set pattern)  
**Description:** Vietnamese business terminology is complex (supplier types, KPIs, accounting concepts). Poor translations or inconsistent terms could confuse SME users, especially older entrepreneurs less comfortable with English.

**Impact:**
- UX confusion (terminology unclear, users unsure what feature does)
- User churn (frustration with interface, switch to competitor)
- Support load (FAQ flooded with "what does this button do" questions)
- Perception of amateur app (bad translation signals low quality)

**Mitigation:**
- **TERMINOLOGY.md:** Already created, freeze vocabulary by Phase 1B end
- **Native reviewer:** Hire Vietnamese UX writer ($500-1k) to review all copy before Phase 2 launch
- **Translation consistency:** Use CAT tool (Crowdin or similar) to enforce term consistency across app
- **User testing:** Conduct usability testing with 3-5 SME users (Vietnamese-primary) in Phase 3 early, get feedback on terminology
- **Glossary in-app:** Embed help tooltips for complex terms (tap term → definition)
- **Regional feedback:** Monitor Play Store + App Store reviews for language/translation complaints

**Contingency:**
- If terminology issues detected in Phase 3 beta, fix + push update (low risk)
- If widespread misunderstanding, pivot copy to simpler language, defer domain terminology to Phase 4

**Owner:** Designer (copy) + Native Vietnamese reviewer  
**Status:** Medium — addressed via TERMINOLOGY.md, prep for Phase 3  
**Monitoring:** Review translations in Phase 3 week 1

---

### R-9: Learning Curve for SME Users

**Severity:** 🟡 Medium  
**Probability:** Low (product designed with SME in mind, but adoption is always complex)  
**Description:** SMEs using Tổng Tài for first time may find the app overwhelming (4 main sections + AI chat + reports). If onboarding is confusing, users abandon app before seeing value.

**Impact:**
- Low DAU (daily active users) despite installs
- High churn in first week (50%+ uninstall rate)
- Negative reviews ("too complicated")
- Poor word-of-mouth (founder's network loses interest)

**Mitigation:**
- **Progressive onboarding:** Introduce features gradually (Day 1: Home + Producer, Day 2: Inventory, Day 3: Consumer, Day 4: Chat)
- **In-app tutorials:** Context-sensitive tips (tap ? icon → show tutorial for current screen)
- **Demo data:** Pre-populate app with sample suppliers, products, customers (3-5 examples), let user practice
- **Support email:** Real human support for first week (dedicated email, fast response <4hrs)
- **Welcome video:** 2-3 minute YouTube video showing core workflow (find supplier → add to inventory → get recommendations)
- **FAQ section:** Built-in FAQ in app (tap Help → common questions + answers)
- **Founder guide:** PDF/email guide for "first 30 days with Tổng Tài"

**Contingency:**
- If beta testing shows > 40% churn in first week, simplify onboarding (reduce number of features shown initially)
- Extend tutorial duration, add more walkthroughs
- Consider human-led onboarding (Founder does 30-min call with early users, walks them through)

**Owner:** Designer (onboarding UX) + PM Agent (tutorials, FAQ)  
**Status:** Medium — design by Phase 3 early  
**Monitoring:** Beta churn metrics, user feedback on onboarding

---

### R-10: API Integration Complexity (Future Shopee/TikTok)

**Severity:** 🟡 Medium  
**Probability:** Medium (Phase 4 feature, but design now affects architecture)  
**Description:** Phase 4 includes Shopee + TikTok Shop API integrations. If APIs are complex or undocumented, Phase 4 delays. However, this is PHASE 4, not MVP-blocking.

**Impact:**
- Phase 4 (Growth) delayed 4-8 weeks
- User expectation (promised integrations) unmet
- Competitive disadvantage (other apps have integrations sooner)

**Mitigation:**
- **API research now:** Document Shopee + TikTok API capabilities, limits, authentication (Phase 1B research task)
- **Design for extensibility:** API client abstraction, plugin architecture (Phase 2, don't build integration yet)
- **Partner relationship:** Reach out to Shopee + TikTok account managers NOW, discuss API access (they're faster for direct requests)
- **Phase 4 plan:** Clear scope + timeline for each integration (Shopee first, TikTok second, both Q4 2026 or Q1 2027)

**Contingency:**
- If API unavailable or restricted, defer integration to Phase 5 (lower priority)
- Implement manual data entry as workaround (users manually add Shopee orders)
- Partner with third-party integration provider (Zapier, Make) if direct API too complex

**Owner:** Developer Agent (research) + Founder (partnership)  
**Status:** Medium — research starts Phase 1B  
**Monitoring:** API documentation, partner communication log

---

## Low Risks (Severity 🟢 LOW, Impact < 1 week)

### R-7: Market Timing & Competitive Entry

**Severity:** 🟢 Low  
**Probability:** Low (business OS for SMEs is niche, slow to market)  
**Description:** Another company launches a similar AI-first business OS for Vietnamese SMEs before Tổng Tài ships (Phase 3, Nov 2026). Market share opportunity lost.

**Impact:**
- Market education burden (need to explain category)
- Differentiation more important (can't be first-mover)
- Growth slower (users already committed to competitor)

**Probability Drivers:**
- Category is emerging (AI Agents for business)
- Small team at Workizen (slower execution than VC-backed startup)
- Vietnam is target market (local competitors possible)

**Mitigation:**
- **Founder positioning:** Focus on LOCAL SME + AI-first, not just "business app"
- **Unique value prop:** Opportunity Engine (continuous discovery) is differentiator, not just CRM/accounting
- **Community building:** Start founder network outreach NOW (not wait for app launch), build audience pre-launch
- **Speed discipline:** Hit Nov 2026 target (not slip to Dec/Jan)
- **Press strategy:** Founder can write about business OS vision NOW (Medium, LinkedIn), build thought leadership before competitor launches

**Contingency:**
- If competitor launches similar product, pivot to vertical (e.g., fashion SMEs, food vendors)
- Focus on superior AI quality (Grok > competitor's generic LLM)
- Emphasize privacy (local-first > cloud-first competitor)

**Owner:** Founder (market watch, positioning)  
**Status:** Low — monitor quarterly  
**Monitoring:** Google Alerts for "AI business", "SME", "Vietnam", competitor tracking

---

### R-12: Performance & Infrastructure Scaling

**Severity:** 🟢 Low  
**Probability:** Low (local-first, scaling is gradual)  
**Description:** If Tổng Tài reaches 10,000+ users in Phase 4, xAI/OpenRouter API calls scale linearly. Infrastructure cost could exceed budget if not managed. However, this is a "good problem" (success metric), and Phase 4 is far away.

**Impact:**
- Monthly API costs could hit $500-2k (vs budgeted $100-200) if not managed
- Performance slowdowns if too many concurrent users (xAI rate limits)
- Freemium pricing model may not cover costs

**Mitigation:**
- **Cost monitoring:** Track API costs per user, set budget alerts ($2k/month hard limit)
- **Rate limiting:** Implement per-user quota (e.g., 50 AI requests/day free tier, unlimited for Pro)
- **Caching:** Cache AI responses (same question = return cached answer, don't call API again)
- **Batch processing:** Run Opportunity Engine at night (batch job, not per-user on-demand)
- **Freemium pricing:** Ensure Pro tier pricing ($4.99/mo) covers API costs for premium users (target $1-2/user/month)
- **Usage analytics:** Dashboard showing cost per feature, identify high-cost features

**Contingency:**
- If costs exceed budget, reduce Opportunity Engine frequency (weekly instead of daily)
- Implement on-device caching aggressively (reduce API calls)
- Adjust freemium pricing (increase to $9.99/mo if market will bear)

**Owner:** Developer Agent (implementation, monitoring)  
**Status:** Low — design Phase 4, implement Phase 2  
**Monitoring:** Cost dashboard (track from Phase 2 beta onwards)

---

### R-13: Design System Evolution Drift

**Severity:** 🟢 Low  
**Probability:** Low (design system documented, designer review process)  
**Description:** As app grows (Phase 2 → 4), UI evolves organically. Design system (colors, spacing, components) could drift, leading to inconsistent UI.

**Impact:**
- UI feels "rough" after a few quarters (inconsistent look/feel)
- Component library entropy (more one-off components than reusable ones)
- Designer productivity slows (no clear patterns to follow)

**Mitigation:**
- **Component library:** Built and maintained from Phase 2 onwards
- **Design system governance:** Monthly design review (designer + PM), spot-check UI for consistency
- **Version control:** Design tokens in code (not Figma only), enable automation
- **Figma → Code:** Design system Figma file as single source of truth, linked from code
- **Refactoring budget:** Reserve 10% of Phase 3+ sprints for design system debt (component consolidation, token cleanup)

**Contingency:**
- If design system drifts significantly, allocate 1-2 sprints for refactoring (Phase 4)

**Owner:** Designer (governance)  
**Status:** Low — process design Phase 2  
**Monitoring:** Design review checklist, component library audit

---

## Constraints (Known Limitations)

### C-1: No Backend Infrastructure (MVP)

**Constraint:** All Tổng Tài Phase 2 compute happens on-device. No server-side backend (except AI provider calls).

**Implication:**
- No data sync across devices (user's phone only)
- No team collaboration (single-user only)
- No user authentication (local device ID only)
- No server-side search (FTS5 local only)
- No cloud backup (user responsibility, manual export)

**Why:** MVP is local-first, validates core product value without infrastructure cost ($0 backend ops cost).

**Workaround:** Phase 3+ can add opt-in Portal sync (post-PMF validation).

**Trade-off:** Faster MVP, lower cost, but limits features. User can explicitly export/backup if desired.

---

### C-2: BYOK Required (Bring Your Own API Key)

**Constraint:** Users must provide xAI API key to use Opportunity Engine + Copilot. App does not pre-load paid API keys.

**Implication:**
- Setup friction (users must sign up for xAI, generate key, paste in app)
- Support burden (API key issues = support ticket)
- Feature gating (without key, AI features disabled)

**Why:** Privacy-first principle, reduces app cost, BYOK aligns with ecosystem trust.

**Workaround:** Offer OpenRouter free tier as fallback (easier setup, slower). App provides clear key setup instructions.

**Trade-off:** Higher UX friction vs. user privacy + cost reduction.

---

### C-3: Local-First Data (No Cloud by Default)

**Constraint:** All business data stays on-device by default. No automatic cloud sync.

**Implication:**
- User is responsible for backups (manual export to CSV)
- Data loss risk (if phone broken/lost, data gone unless backed up)
- No cross-device sync (business data tied to single phone)

**Why:** Privacy-first, BYOK principle, simplifies MVP scope.

**Workaround:** User can export to CSV, back up manually. Phase 3 adds opt-in Portal sync.

**Trade-off:** Privacy + simplicity vs. convenience + reliability.

---

### C-4: Small Team Size (2-3 Developers)

**Constraint:** Phase 2 execution estimated at 2-3 engineers + 1 designer, not larger.

**Implication:**
- Parallel work limited (must carefully prioritize which epics in parallel)
- Code reviews + QA slower (single QA person)
- Context switching high (engineers work across data + UI layers)
- Limited buffer for illness/vacation

**Why:** Founder bandwidth limited, team small.

**Workaround:** Async-first development, clear specs + architecture reduce need for synchronous discussion.

**Trade-off:** Smaller team = faster decisions, but slower build. Mitigated by clear product spec + architecture.

---

### C-5: Aggressive Timeline (Phase 1B Aug, Phase 2 Sep-Oct, Phase 3 Nov)

**Constraint:** 4-month timeline from design end (Aug 28) to production launch (Nov 25).

**Implication:**
- No room for major rework (design-build-test in parallel, not sequential)
- Scope must be strict (any creep = late launch)
- Testing must be efficient (unit + E2E in CI, not manual QA)
- Quality bar is "good enough" not "perfect"

**Why:** Market window (Q4 2026), founder availability, competitive urgency.

**Workaround:** Parallel sprints (Phase 2 sprints 2-4 run while sprint 1 in QA), early testing.

**Trade-off:** Faster timeline vs. polish. Accept known bugs, improve in Phase 3.

---

### C-6: Vietnamese Primary Market

**Constraint:** MVP targets Vietnamese SMEs first. International expansion deferred to Phase 4.

**Implication:**
- Product design optimized for Vietnam (1688, Shopee, local payment methods)
- Non-Vietnamese users secondary
- Marketing in Vietnamese only (initially)
- Compliance = Vietnam law only (GDPR/CCPA deferred)

**Why:** Founder's expertise (Vietnam market knowledge), market size (10M+ SMEs), competitive advantage.

**Workaround:** English available as language toggle, but messaging/features Vietnamese-first.

**Trade-off:** Faster product-market fit in home market vs. slower international growth initially.

---

## Risk & Constraint Summary Table

| ID | Type | Name | Severity | Prob | Timeline | Owner | Status |
|---|---|---|---|---|---|---|---|
| R-1 | Risk | Scope Creep | 🔴 | High | 8+ weeks | Founder | Active |
| R-2 | Risk | Hub Reuse | 🟠 | Med | 2-4 weeks | Dev | Active |
| R-3 | Risk | AI Availability | 🔴 | High | 8+ weeks | Founder | Active |
| R-4 | Risk | Privacy/Compliance | 🟠 | Med | 2-4 weeks | Founder | Active |
| R-5 | Risk | Team Availability | 🔴 | High | 8+ weeks | Founder | Active |
| R-6 | Risk | Store Approval | 🟠 | Med | 2-4 weeks | QA | Active |
| R-7 | Risk | Market Timing | 🟢 | Low | <1 week | Founder | Low Priority |
| R-8 | Risk | Localization | 🟡 | Low | 1-2 weeks | Designer | Medium |
| R-9 | Risk | Learning Curve | 🟡 | Low | 1-2 weeks | Designer | Medium |
| R-10 | Risk | API Integration | 🟡 | Med | 2-4 weeks | Dev | Phase 4 |
| R-11 | Risk | Prompt Quality | 🟠 | Med | 2-4 weeks | Dev | Active |
| R-12 | Risk | Infrastructure Cost | 🟢 | Low | <1 week | Dev | Phase 4 |
| R-13 | Risk | Design Drift | 🟢 | Low | <1 week | Designer | Low Priority |
| C-1 | Constraint | No Backend | N/A | N/A | 0 | PM | Fixed (MVP) |
| C-2 | Constraint | BYOK Required | N/A | N/A | 0 | PM | Fixed (MVP) |
| C-3 | Constraint | Local-First | N/A | N/A | 0 | PM | Fixed (MVP) |
| C-4 | Constraint | Small Team | N/A | N/A | 0 | Founder | Fixed |
| C-5 | Constraint | Aggressive Timeline | N/A | N/A | 0 | Founder | Fixed |
| C-6 | Constraint | Vietnam Primary | N/A | N/A | 0 | Founder | Fixed |

---

---

## Tiếng Việt

**Mục Đích:** Xác định và theo dõi các rủi ro sản phẩm, kỹ thuật và tổ chức có thể ảnh hưởng đến việc phân phối Tổng Tài. Cũng ghi lại các ràng buộc đã biết hình thành phạm vi và thực hiện.

**Cập Nhật Lần Cuối:** 2026-07-13  
**Trạng Thái:** 🔄 Phase 1B Đang Tiến Hành

### Rủi Ro Quan Trọng (Severity 🔴 CAO)

#### R-1: Scope Creep — Founder Thêm Tính Năng Beyond MVP

**Tầm Nghiêm Trọng:** 🔴 Nghiêm Trọng  
**Xác Suất:** Cao

**Mô Tả:** Sự nhiệt tình của Founder đối với Tổng Tài có thể dẫn đến thêm tính năng ngoài phạm vi Phase 2 MVP.

**Tác Động:**
- Timeline Phase 2 trượt 2-4 tuần
- Đội nhà phát triển quá tải, chất lượng giảm
- Beta launch bị trì hoãn
- Phase 3 (production) có rủi ro

**Giảm Thiểu:**
- Gate mechanism: Founder phê duyệt cho BẤT KỲ bổ sung phạm vi nào
- Định nghĩa MVP rõ ràng: OPEN-DECISIONS.md + PRODUCT-BOUNDARIES.md (đóng lại)
- Kỷ luật backlog: Tính năng mới → backlog với "Phase 3+" label rõ ràng
- Review phạm vi hàng tuần: PM Agent cảnh báo bất kỳ creep nào
- Thời gian đệm: Dành riêng 1-2 tuần cho "unknown unknowns"

---

#### R-3: Tính Khả Dụng Của Mô Hình AI & Biến Động Chi Phí

**Tầm Nghiêm Trọng:** 🔴 Nghiêm Trọng  
**Xác Suất:** Cao

**Mô Tả:** Tổng Tài phụ thuộc vào xAI Grok API. Nếu xAI không khả dụng, bị giới hạn tỷ lệ, hoặc tăng giá, Tổng Tài mất lợi thế cạnh tranh.

**Tác Động:**
- Phase 2: Ứng dụng ship với chất lượng AI giảm
- UX giảm (đề xuất ít hữu ích)
- Opportunity Engine kém hấp dẫn
- Tác động doanh thu

**Giảm Thiểu:**
- Chiến lược đa nhà cung cấp: xAI chính, OpenRouter dự phòng
- Suy giảm duyên đầu lịch sự: Nếu xAI không khả dụng, tự động quay lại OpenRouter
- Lựa chọn BYOK người dùng: Người dùng có thể mang khóa xAI hoặc OpenRouter của họ
- Quản lý hạn ngạch: Theo dõi chi phí API per user
- Đánh giá khoá nhà cung cấp: Thiết kế Opportunity Engine để hoạt động trên các mô hình

---

#### R-5: Tính Khả Dụng Của Đội & Rủi Ro Người Chính

**Tầm Nghiêm Trọng:** 🔴 Nghiêm Trọng  
**Xác Suất:** Cao

**Mô Tả:** Phase 2 build yêu cầu 2-3 developers toàn thời gian trong 8-10 tuần. Nếu thành viên đội chính không khả dụng, trang web trượt hoặc chất lượng suy giảm.

**Tác Động:**
- Phase 2 kéo dài từ 8 tuần → 12-16 tuần
- Công việc song song bị chặn
- QA/polish suy giảm
- Beta launch bị trì hoãn

**Giảm Thiểu:**
- Xác nhận sớm tính khả dụng của developer
- Kế hoạch tài nguyên: 2 toàn thời gian + 1 bán thời gian
- Nhân viên dự phòng: 1-2 nhà thầu tại cuộc họp
- Kỷ luật Async-first: Ghi lại quyết định, specs rõ ràng
- Phân phối kiến thức: Pair developers, cross-train

---

### Rủi Ro Cao (Severity 🟠)

**R-2:** Hub Reuse Complexity — Nếu Option 2 được chọn  
**R-4:** Privacy & Compliance — Dữ liệu kinh doanh nhạy cảm  
**R-6:** Store Approval — App Store có thể slow  
**R-11:** Prompt Quality — AI hallucination risk  

### Ràng Buộc (Hạn Chế Đã Biết)

| ID | Tên | Tác Động | Giải Quyết |
|---|---|---|---|
| C-1 | Không Backend (MVP) | Không đồng bộ, không team collaboration | Phase 3+ add sync |
| C-2 | BYOK Bắt Buộc | Friction setup, gánh nặng hỗ trợ | Docs tốt, OpenRouter fallback |
| C-3 | Local-First Data | Trách nhiệm backup người dùng | Export manual, Phase 3 sync |
| C-4 | Đội Nhỏ | Công việc song song hạn chế, QA slow | Async-first, specs rõ ràng |
| C-5 | Timeline Aggressive | Không có room cho rework lớn | Parallel sprints, scope strict |
| C-6 | Vietnam Primary | Expansion deferred, non-VN secondary | English toggle, focus VN first |

---

**Last Updated:** 2026-07-13  
**Status:** 🔄 Ready for Founder Review
