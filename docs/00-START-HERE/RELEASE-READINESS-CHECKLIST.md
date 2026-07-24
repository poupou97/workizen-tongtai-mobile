# Release-Readiness Checklist — Closed Beta (WTM-118)

**Assessed:** 2026-07-24 · **Priority:** P1 (release gate prep) · **Related:**
WTM-37 (Compliance & Privacy), WTM-35 (Risk Register), WTM-119 (Localization),
WTM-117 (Data-flow), D-7/ADR-TON-005 (telemetry).

> Đây là **checklist chuẩn bị phát hành**, không phải feature. Trạng thái phản
> ánh thực tế code tại thời điểm đánh giá. / A release-readiness checklist, not a
> feature. Status reflects the codebase as assessed.

Legend: ✅ done · 🟡 partial / gap noted · 🔴 not started · N/A không áp dụng Phase 2.

## 1. States

| Item | Status | Note |
|---|---|---|
| Empty states | ✅ | Fox empty state trên 11 màn (Reports, Finance, Timeline, Chat, Customer, Opportunity, Goals…). |
| Loading states | 🟡 | Chat có typing indicator; progress bars ở Reports/Finance/Journey. Data hiện **đồng bộ** (sample) nên chưa có spinner async — **cần bổ sung khi lên Drift/network** (repository async). |
| Error states | 🟡 | Form validation đầy đủ (product/customer/goal/transaction). Lỗi network/DB chưa có UI (local-first, sync Phase 3). BYOK AI có fallback offline. |

## 2. Platform behaviour

| Item | Status | Note |
|---|---|---|
| Offline behaviour | ✅ | Local-first: mọi luồng core chạy không cần mạng (D-5, ADR-TON-004). AI BYOK có fallback rule-based offline. |
| Responsive layouts | 🟡 | Dùng Expanded/Wrap/ListView + relative spacing; KPI 3-up đã xử lý tràn (vndShort). **Chưa test hệ thống** trên nhiều cỡ máy + text scaling → cần pass thủ công. |
| Performance | 🟡 | Charts vẽ CustomPaint (nhẹ, không lib); lists dùng ListView lazy. Chưa đo cold-start/scroll jank trên máy thật (debug build đã chạy Galaxy S24). |

## 3. Quality gates

| Item | Status | Note |
|---|---|---|
| Accessibility | 🔴 | **Gap:** chỉ ~2 chỗ dùng Semantics/semanticsLabel (fox mascot). Cần semantics cho icon-only buttons, tap target ≥48dp, contrast. Gắn với WTM-119. |
| Localization | 🟡→🔴 | Bilingual EN+VI ở domain enums/labels, nhưng **UI string hard-code** (VI). Migration AppLocalizations/ARB = **WTM-119 (HIGH)**. |
| Automated tests | ✅ | 757 test (unit + widget), evidence-driven, CI GitHub Actions (format+analyze+test) xanh mỗi PR. Cấm placebo test. |
| Analyzer / format | ✅ | `flutter analyze` sạch; `dart format` enforced trong CI. |

## 4. Store readiness

| Item | Status | Note |
|---|---|---|
| App icon + splash | ✅ | Origami fox native (WTM-110) — adaptive icon, iOS no-alpha, splash navy. |
| App identity | ✅ | applicationId `com.workizen.tongtai`, version 0.1.0. |
| Permissions | 🟡 | Rà soát AndroidManifest/Info.plist (camera/ảnh cho attachment) — cần liệt kê + justify trước submit. |
| Privacy policy | 🟡 | No account (D-4), no ad/marketing/profiling (red-line). Firebase Analytics+Crashlytics operational-only được phép (D-7/ADR-TON-005) — **cần privacy policy văn bản** trước Beta. Link WTM-37. |
| Telemetry disclosure | 🟡 | D-7 cho phép operational telemetry closed-beta; cần disclosure + opt-out theo policy. |
| iOS build | 🔴 | Chưa verify trong session (signing/SPM) — Founder làm ngoài session. Android debug đã verify. |
| Release signing | 🔴 | Debug build only. Ký release + upload store = **Founder gate**. |

## Top gaps to close before Closed Beta

1. **Accessibility** (🔴) — semantics + tap targets + contrast pass (with WTM-119).
2. **Localization** (WTM-119, HIGH) — AppLocalizations/ARB; unblocks true multi-language + l10n-safe tests.
3. **Privacy policy + telemetry disclosure** (WTM-37) — required doc before Beta.
4. **iOS build + release signing** (Founder) — outside session.
5. **Responsive + performance manual pass** on real devices.

None of these block continued feature development; they are the pre-Beta gate list. Feature-level empty/error/offline states are already in good shape.
