# Consolidation Plan — Phase 1C Tranche 2
## Tổng Tài Product Design Bible — Implementation Roadmap

**Date:** 2026-07-13  
**Status:** Audit Complete — Ready for Implementation  
**Effort Estimate:** 24 minutes (Priority 1 + 2 fixes)

---

## Overview

This document provides **step-by-step guidance** for consolidating the 48-document Product Design Bible into production-ready form. Based on the comprehensive audit (PHASE-1C-TRANCHE-2-AUDIT-REPORT.md), this plan prioritizes and sequences all required modifications.

### Key Findings Summary
- ✅ **No docs to remove:** All 48 documents serve distinct purposes
- ✅ **No docs to merge:** All overlaps are intentional cross-references
- ⚠️ **4 docs to modify:** Minor fixes + enhancements
- ✅ **1 doc to add:** README section for tech team

---

## Implementation Roadmap

### Phase 1: Priority 1 Fixes (10 minutes) — BLOCKING HANDOFF

Must complete before handing off to tech team.

#### Fix 1.1: Correct Screen Reference Number

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/SCREEN-CONSUMER.md`

**Problem:**  
Line 81 references "Customer Detail (SC-11)" but SC-11 is SCREEN-REPORTS.md, not Consumer Detail.

**Solution:**
```
LOCATION: Line 81
CURRENT TEXT: "Customer Detail (SC-11)"
CHANGE TO: "Customer Detail (SC-17)"

CONTEXT (lines 75-85):
| Tap | Destination | Action |
|---|---|---|
| Customer Header | Edit | Edit customer info (name, contact, segment) |
| Purchase History | Order Detail | Show order details + items + timeline |
| Segment Tag | Segment | Show segment definition + members |
| LTV Card | Customer Value | Show LTV breakdown + contribution + lifetime value |
| Call/Email | Communication | Open communication (call/email/SMS) |
| "View Full Profile" | Customer Detail (SC-17) | Show complete customer profile + full history |
```

**Verification:**
- [ ] Locate line 81 in SCREEN-CONSUMER.md
- [ ] Change "SC-11" to "SC-17"
- [ ] Verify SCREEN-CONSUMER-DETAIL.md exists
- [ ] Confirm no other references to this screen use wrong SC number

**Effort:** 1 minute

---

### Phase 2: Priority 2 Fixes (20 minutes) — STRONGLY RECOMMENDED

Should complete before tech review (prevents confusion during handoff).

#### Fix 2.1: Remove Duplicate Color Table & Add Cross-Reference

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/DESIGN-SYSTEM-DRAFT.md`

**Problem:**  
Lines 15-32 contain a duplicate 10-row domain color palette that appears in DESIGN-TOKENS.md. Creates maintenance burden if colors are updated.

**Current Content (Lines 15-32):**
```
## Color System — Domain-Driven

### Domain Colors

| Module | Color | Hex | Usage |
|---|---|---|---|
| Producer | Green | #10B981 | Sourcing, supplier discovery, arbitrage |
| Inventory | Orange | #F59E0B | Products, stock, warehouse, SKU |
| Consumer | Blue | #3B82F6 | Customers, orders, communications |
| Finance | Purple | #8B5CF6 | Revenue, expenses, profit, accounting |
| Reports | Teal | #14B8A6 | Analytics, insights, KPIs, trends |
| AI Copilot | Gold | #F59E0B | AI recommendations, insights, commands |
| Notifications | Red | #EF4444 | Alerts, warnings, urgent items |
| Success | Green | #10B981 | Confirmations, positive actions |
| Warning | Orange | #F59E0B | Cautions, reviews needed |
| Neutral | Gray | #6B7280 | Disabled, secondary, metadata |
```

**Solution:**
1. **Delete lines 15-32** (the entire color table)
2. **Replace with this reference:**

```markdown
## Color System — Domain-Driven

### Domain Colors

See **DESIGN-TOKENS.md § Color System** for the complete, authoritative domain color palette 
(Producer=Green #10B981, Inventory=Orange #F59E0B, Consumer=Blue #3B82F6, Finance=Purple #8B5CF6, 
Reports=Teal #14B8A6, etc.).

This section provides guidance on applying tokens; DESIGN-TOKENS.md is the source of truth.
```

**Verification:**
- [ ] Open DESIGN-SYSTEM-DRAFT.md
- [ ] Navigate to lines 15-32
- [ ] Delete the entire 10-row table
- [ ] Add the reference text above
- [ ] Verify DESIGN-TOKENS.md contains the authoritative table
- [ ] Confirm no downstream references break

**Effort:** 5 minutes

---

#### Fix 2.2: Add Explicit Screen Code (SC) Assignments for Detail & Related Screens

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/BUSINESS-CAPABILITY-MODEL.md`

**Problem:**  
- SC-6 through SC-14 are officially assigned to primary screens
- SC-15, SC-16, SC-17 are used in SCREEN-*.md files but not officially defined in BUSINESS-CAPABILITY-MODEL.md
- Causes ambiguity during tech handoff

**Solution:**

1. **Locate the end of the primary screen assignments** (look for "SC-14" in BUSINESS-CAPABILITY-MODEL.md)

2. **Add this new section after SC-14:**

```markdown
### Related Screens — Detail & Navigation Views

These screens provide detailed information or secondary navigation:

| Screen Code | File | Purpose | Invoked From |
|---|---|---|---|
| **SC-15** | SCREEN-PRODUCER-DETAIL.md | Supplier profile, ratings, products, reviews | SC-7 (Producer) → Tap supplier card |
| **SC-16** | SCREEN-INVENTORY-DETAIL.md | Product details, pricing, stock, history | SC-8 (Inventory) → Tap product card |
| **SC-17** | SCREEN-CONSUMER-DETAIL.md | Customer profile, order history, LTV, segments | SC-9 (Consumer) → Tap customer card |
| **SC-18** | SCREEN-MORE.md | Secondary navigation, settings, integrations | Bottom nav → "More" tab |
| **SC-19** | SCREEN-FLOW.md | Navigation patterns & flow diagrams (not a user-facing screen) | Reference only |
```

3. **Update all references** in BUSINESS-CAPABILITY-MODEL.md to use "SC-15", "SC-16", "SC-17" instead of inferred numbers

4. **Verify consistency:** Check that all SCREEN-*.md files that reference these details use correct SC numbers

**Verification:**
- [ ] Open BUSINESS-CAPABILITY-MODEL.md
- [ ] Find line containing "SC-14"
- [ ] Add new "Related Screens" section after it
- [ ] Verify all detail screen files exist
- [ ] Cross-check SCREEN-PRODUCER.md, SCREEN-INVENTORY.md, SCREEN-CONSUMER.md reference correct SC numbers
- [ ] Confirm SCREEN-MORE.md and SCREEN-FLOW.md are accounted for

**Effort:** 8 minutes

**Related Verification:** After this fix, re-verify SCREEN-CONSUMER.md line 81 now reads "SC-17" (already fixed in Phase 1)

---

### Phase 3: Priority 3 Enhancements (10 minutes) — NICE-TO-HAVE

Optional improvements for clarity; not blocking handoff.

#### Enhancement 3.1: Add Clarification to BUSINESS-CAPABILITY-MODEL.md

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/BUSINESS-CAPABILITY-MODEL.md`

**Problem:**  
BUSINESS-CAPABILITY-MODEL.md mentions alternative UI names for modules (e.g., "Sourcing Hub" instead of "Producer") but doesn't clarify these are UI-only alternatives, not documentation terms.

**Solution:**

1. **Locate the Producer capability section** (line ~14)

2. **Add this clarification note:**

```markdown
> **Note:** Alternative names shown here (e.g., "Sourcing Hub", "Customer Intelligence Ecosystem") 
> are UI labels acceptable for mobile app screens. In technical documentation, always use the 
> official names from **TERMINOLOGY.md**: Producer, Inventory, Consumer, Finance, Reports, etc.
```

**Placement:** After each module definition that lists alternatives (Producer, Consumer, Finance)

**Verification:**
- [ ] Find Producer, Consumer, Finance module definitions
- [ ] Add note to each
- [ ] Verify no confusion between UI labels and doc terminology

**Effort:** 3 minutes

---

#### Enhancement 3.2: Update TERMINOLOGY.md Status Footer

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/TERMINOLOGY.md`

**Problem:**  
Footer says "✅ RATIFIED by Founder" but doesn't prevent accidental modifications.

**Solution:**

Update the footer (line ~101):

```markdown
**Last Updated:** 2026-07-13  
**Maintained By:** Claude Code (Developer Agent)  
**Status:** ✅ RATIFIED BY FOUNDER — Locked. Do not modify without explicit Founder approval.
```

**Verification:**
- [ ] Open TERMINOLOGY.md
- [ ] Go to last section (footer)
- [ ] Update status line
- [ ] Confirm change is clear

**Effort:** 1 minute

---

#### Enhancement 3.3: Add Onboarding Section to README.md

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/README.md`

**Problem:**  
Tech team doesn't have clear guidance on which docs to read first. The bible has 48 documents; without a reading path, onboarding takes longer.

**Solution:**

Add this new section to README.md:

```markdown
## Onboarding for Technology Team (Phase 2)

### Critical Read Path (2 hours to full understanding)

The Product Design Bible contains 48 documents organized in 7 tiers. To understand the product 
architecture for technical evaluation, read in this order:

| Step | Document | Time | Purpose |
|---|---|---|---|
| 1 | **TERMINOLOGY.md** | 10 min | Learn all official terms (Producer, Inventory, Consumer, etc.) |
| 2 | **PRODUCT-VISION.md** | 10 min | Understand product intent: "AI-first Business Operating System" |
| 3 | **BUSINESS-CAPABILITY-MODEL.md** | 15 min | Master 8-module architecture (Producer/Inventory/Consumer/Finance/Reports/Journey/Opportunity/Copilot) |
| 4 | **PRODUCT-BOUNDARIES.md** | 10 min | Lock scope: what's in/out of MVP |
| 5-18 | **All SCREEN-*.md** (14 files) | 60 min | Dive into each screen spec (4-5 min per file; start with SCREEN-HOME.md) |
| 19 | **COMPONENT-LIBRARY.md** | 10 min | Learn reusable UI components |
| 20 | **DESIGN-TOKENS.md** | 5 min | Understand visual tokens (colors, spacing, fonts) |
| 21 | **DOMAIN-DATA-MODEL.md** | 10 min | Grasp entity relationships |
| 22 | **INTEGRATION-MAP.md** | 10 min | Review external APIs and integrations |

**Total: ~2 hours**

### Files by Purpose

**Foundation (Concepts & Terminology)**
- TERMINOLOGY.md — Single source of truth for all product terms
- PRODUCT-VISION.md — Product mission and positioning

**Architecture (Capabilities & Scope)**
- BUSINESS-CAPABILITY-MODEL.md — 8 core modules + SC references
- PRODUCT-BOUNDARIES.md — Scope definition (MVP vs future)
- DOMAIN-BOUNDARIES.md — Feature boundaries and interactions

**AI & Intelligence**
- AI-BUSINESS-COPILOT.md — AI assistant design
- AI-CAPABILITY-MATRIX.md — Where AI is used on each screen
- OPPORTUNITY-ENGINE.md — AI-discovered opportunities
- BUSINESS-JOURNEY-BIBLE.md — Goal-driven orchestration

**User Experience**
- INFORMATION-ARCHITECTURE.md — Navigation structure
- USER-JOURNEYS.md — Personas and use cases
- SCREEN-FLOW.md — Navigation flows and patterns
- All SCREEN-*.md (14 files) — Individual screen specifications

**Design System**
- DESIGN-TOKENS.md — Visual variables (colors, spacing, fonts)
- DESIGN-SYSTEM-DRAFT.md — Visual language guidance
- COMPONENT-LIBRARY.md — Reusable component specs
- COMPONENT-AUDIT.md — Component inventory and status

**Technical & Domain**
- DOMAIN-DATA-MODEL.md — Entities, relationships, constraints
- INTEGRATION-MAP.md — External APIs, webhooks, third-party services
- ANDROID-IOS-IDENTITY-PLAN.md — Platform-specific identifiers
- APP-SEPARATION-PLAN.md — Repository structure and build configuration
- BUILD-AND-RUN-GUIDE.md — Local development setup

**Roadmap & Decisions**
- ROADMAP.md — 4-phase product roadmap
- PRODUCT-BACKLOG.md — Feature backlog and prioritization
- OPEN-DECISIONS.md — 10 pending architecture/product decisions
- RISKS-AND-CONSTRAINTS.md — Known constraints and risks
- PHASE-1-REPORT.md — Design phase execution summary

**Phase 2 Preparation**
- FIT-GAP-PREPARATION.md — Technology fit-gap analysis
- REUSE-ASSESSMENT.md — Reuse potential from Workizen Hub

### For Quick Scanning (20 min)
1. TERMINOLOGY.md
2. PRODUCT-VISION.md
3. BUSINESS-CAPABILITY-MODEL.md diagram

### For Deep Dive (Full Design Review)
1. Read the Critical Path (2 hours)
2. Review OPEN-DECISIONS.md (10 items to resolve)
3. Study RISKS-AND-CONSTRAINTS.md (know the gotchas)
4. Read ROADMAP.md for Phase 2+ direction

### Questions to Answer Before Handing Off

After reading the Critical Path, be ready to answer:

1. **What are the 8 core capabilities?** (Producer, Inventory, Consumer, Finance, Reports, Business Journey, Opportunity Hub, AI Copilot)
2. **What makes this different from other business software?** (AI-first, BYOK, local-first, mobile-native)
3. **How do screens organize into tabs/nav?** (Bottom nav: Home, Producer, Inventory, Consumer, More)
4. **What does "Business Journey" mean?** (Goal-driven orchestration, not just workflow)
5. **How does the AI Copilot work?** (Context-aware recommendations, pattern detection, task executor)
6. **What data does the app need to store?** (Entities: Products, Suppliers, Customers, Opportunities, Orders, Transactions, etc.)
7. **What are the top 3 open decisions?** (See OPEN-DECISIONS.md)

---

## Product Design Bible Structure (48 Documents)

### Tier 0: Foundation (2)
TERMINOLOGY.md, PRODUCT-VISION.md

### Tier 1: Architecture (3)
BUSINESS-CAPABILITY-MODEL.md, PRODUCT-BOUNDARIES.md, DOMAIN-BOUNDARIES.md

### Tier 2: AI & Business Logic (4)
AI-BUSINESS-COPILOT.md, AI-CAPABILITY-MATRIX.md, OPPORTUNITY-ENGINE.md, BUSINESS-JOURNEY-BIBLE.md

### Tier 3: User Interaction (3)
INFORMATION-ARCHITECTURE.md, USER-JOURNEYS.md, SCREEN-FLOW.md

### Tier 4: Screen Specifications (14)
SCREEN-HOME.md, SCREEN-PRODUCER.md, SCREEN-INVENTORY.md, SCREEN-CONSUMER.md, SCREEN-FINANCE.md, SCREEN-REPORTS.md, SCREEN-BUSINESS-JOURNEY.md, SCREEN-OPPORTUNITY-HUB.md, SCREEN-AI-COPILOT.md, SCREEN-PRODUCER-DETAIL.md, SCREEN-INVENTORY-DETAIL.md, SCREEN-CONSUMER-DETAIL.md, SCREEN-MORE.md, SCREEN-FLOW.md (pattern doc)

### Tier 5: Design System (4)
DESIGN-TOKENS.md, DESIGN-SYSTEM-DRAFT.md, COMPONENT-LIBRARY.md, COMPONENT-AUDIT.md

### Tier 6: Technical & Domain (6)
DOMAIN-DATA-MODEL.md, INTEGRATION-MAP.md, ANDROID-IOS-IDENTITY-PLAN.md, APP-SEPARATION-PLAN.md, BUILD-AND-RUN-GUIDE.md, REUSE-ASSESSMENT.md

### Tier 7: Roadmap & Decisions (5)
ROADMAP.md, PRODUCT-BACKLOG.md, OPEN-DECISIONS.md, RISKS-AND-CONSTRAINTS.md, PHASE-1-REPORT.md

### Tech Subdirectory (3)
tech/INDEX.md, tech/FIT-GAP-PREPARATION.md, tech/ANDROID-IOS-IDENTITY-PLAN.md, tech/APP-SEPARATION-PLAN.md, tech/SHARED-CORE-PLAN.md

```

**Placement:** Add this new section to README.md (after the introductory section, before any existing content)

**Verification:**
- [ ] Open README.md
- [ ] Add new "Onboarding for Technology Team" section
- [ ] Ensure formatting is clean (tables, bullet points align)
- [ ] Verify file references are correct
- [ ] Test that table markdown renders properly

**Effort:** 5 minutes

---

#### Enhancement 3.4: Optional — Rename SCREEN-FLOW.md

**File:** `/Users/alexnguyen/projects/workizen-ai-personal-wallet/docs/tongtai/SCREEN-FLOW.md`

**Problem:**  
Filename "SCREEN-FLOW.md" suggests a screen specification, but content is navigation patterns/flow diagrams (not a user-facing screen).

**Solution (Optional):**

**Option A: Rename file** (if desired, for clarity)
```bash
mv SCREEN-FLOW.md NAVIGATION-PATTERNS.md
```

Then update:
- BUSINESS-CAPABILITY-MODEL.md reference: "SC-19: NAVIGATION-PATTERNS.md"
- README.md reference (if added in Enhancement 3.3)
- Any internal links pointing to SCREEN-FLOW.md

**Option B: Keep as-is** (also acceptable)
- File name stays SCREEN-FLOW.md
- Add header clarification in file: "This document describes navigation patterns and flows, not an individual screen specification."
- Keep SC-19 reference as "SCREEN-FLOW.md (navigation patterns; not a user screen)"

**Recommendation:** **Option B is preferred** — minimal changes, clarity added via note instead of rename

**Verification (if Option A chosen):**
- [ ] Rename file
- [ ] Update all references in other docs
- [ ] Update README.md references

**Effort:** 5 minutes (Option A) or 2 minutes (Option B)

---

## Consolidation Summary Table

| Document | Action | Priority | Effort | Status |
|---|---|---|---|---|
| SCREEN-CONSUMER.md | Fix SC-11 → SC-17 (line 81) | P1 | 1 min | ✅ Priority 1 |
| DESIGN-SYSTEM-DRAFT.md | Remove duplicate color table + add reference | P2 | 5 min | ✅ Priority 2 |
| BUSINESS-CAPABILITY-MODEL.md | Add SC-15/16/17/18/19 assignments | P2 | 8 min | ✅ Priority 2 |
| BUSINESS-CAPABILITY-MODEL.md | Add UI vs. doc terminology clarification | P3 | 3 min | ✅ Priority 3 |
| TERMINOLOGY.md | Update footer status: "Locked" | P3 | 1 min | ✅ Priority 3 |
| README.md | Add "Onboarding for Tech Team" section | P3 | 5 min | ✅ Priority 3 |
| SCREEN-FLOW.md | Add header clarification (Option B) | P3 | 2 min | ✅ Priority 3 (Optional) |
| **TOTAL** | **7 modifications** | — | **24 min** | **Ready** |

---

## Testing & Verification Checklist

### Before Handoff to Tech Team

- [ ] **Phase 1 Complete (P1)**
  - [ ] SCREEN-CONSUMER.md line 81 changed: SC-11 → SC-17
  - [ ] Verify file renders correctly in Git/Markdown
  
- [ ] **Phase 2 Complete (P2)**
  - [ ] DESIGN-SYSTEM-DRAFT.md: Color table removed, reference added
  - [ ] BUSINESS-CAPABILITY-MODEL.md: SC-15/16/17/18/19 sections added
  - [ ] All references across docs verified consistent
  
- [ ] **Phase 3 Complete (P3)**
  - [ ] BUSINESS-CAPABILITY-MODEL.md: UI vs. doc terminology note added
  - [ ] TERMINOLOGY.md: Footer status updated to "Locked"
  - [ ] README.md: Onboarding section added
  - [ ] SCREEN-FLOW.md: Header clarification added (if Option B chosen)

- [ ] **Cross-Document Verification**
  - [ ] All SC references (SC-6 through SC-19) are consistent
  - [ ] No broken internal links
  - [ ] All terminology uses official names from TERMINOLOGY.md
  - [ ] All screens are in Tiers 4 (primary), SC-15/16/17 (detail), SC-18 (nav)

- [ ] **Quality Checks**
  - [ ] All markdown renders correctly (no formatting breaks)
  - [ ] All tables are properly formatted
  - [ ] No typos or inconsistencies in terminology
  - [ ] File references point to actual files
  - [ ] Bilingual sections (EN + Tiếng Việt) are present and consistent

### Tech Team Handoff Acceptance Criteria

- [ ] Audit report (PHASE-1C-TRANCHE-2-AUDIT-REPORT.md) reviewed by Founder
- [ ] All Priority 1 + 2 fixes applied
- [ ] Priority 3 enhancements applied or deferred (per Founder decision)
- [ ] README.md updated with critical read path
- [ ] All 48 documents delivered to tech team
- [ ] Tech team confirms they can start Phase 2 technical evaluation

---

## Risk Mitigation

### Risk 1: Incomplete SC Assignments
**Mitigation:** Add all SC-15/16/17/18/19 in single update to BUSINESS-CAPABILITY-MODEL.md. Verify all screens exist before finalizing.

### Risk 2: Broken References During Edit
**Mitigation:** Use find-and-replace with caution. Verify each change in context before committing.

### Risk 3: Tech Team Doesn't Know Read Order
**Mitigation:** Add detailed "Onboarding" section to README.md with clear critical path + 2-hour estimate.

### Risk 4: Maintenance Burden of Duplicate Color Table
**Mitigation:** Remove duplicate; point to DESIGN-TOKENS.md as single source of truth.

---

## Success Criteria

✅ **Phase 1C Tranche 2 is COMPLETE when:**

1. All Priority 1 fixes applied (1 change)
2. All Priority 2 fixes applied (2 changes)
3. Tech team can read README.md and understand doc structure within 2 hours
4. All 48 documents are consistent with TERMINOLOGY.md
5. No broken cross-references
6. No circular dependencies
7. All 14 SCREEN-*.md files are production-ready
8. Design system is locked and documented
9. Founder approves delivery to tech team

---

## Handoff Checklist for Founder

- [ ] Review PHASE-1C-TRANCHE-2-AUDIT-REPORT.md (20 min read)
- [ ] Approve 5 minor issues identified as non-blocking
- [ ] Approve consolidation plan (this document)
- [ ] Decision: Implement Priority 3 enhancements? (Yes / No / Defer)
- [ ] Schedule tech team review (2 hours)
- [ ] Verify all 48 documents are production-ready
- [ ] Sign-off on handoff to Phase 2 Technical Evaluation

---

## Timeline

| Phase | Task | Time | Cumulative | Status |
|---|---|---|---|---|
| **P1** | Fix SC references | 10 min | 10 min | → Ready |
| **P2** | Remove duplicate colors, add SC assignments | 20 min | 30 min | → Ready |
| **P3** | Optional enhancements | 10 min | 40 min | → Optional |
| **QA** | Verify all changes + test links | 10 min | 50 min | → Ready |
| **HANDOFF** | Deliver to tech team + onboard (2 hours) | 120 min | 170 min | → Phase 2 |

**Total Implementation: 50 minutes (P1+P2+QA) or 60 minutes (all including P3)**

---

**Document Status:** Ready for Implementation  
**Next Step:** Founder approves consolidation plan → Implementation begins  
**Expected Completion:** Same day (1 hour total)

