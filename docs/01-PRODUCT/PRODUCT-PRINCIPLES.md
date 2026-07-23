# Product Principles (bất di bất dịch)

1. **Local First** — dữ liệu kinh doanh của user nằm trên máy user; app chạy
   offline (trừ gọi AI).
2. **Workizen AI / Edge First** — user chỉ tương tác "Workizen AI"; AI Router
   chọn provider (ADR-TON-006). Phase 2: BYOK (key của user, gọi thẳng
   provider, không proxy) + Local (Ollama); Managed chờ Phase 3.
3. **Privacy by Default** — không account bắt buộc; KHÔNG ad SDK / marketing
   tracking / profiling / personalized ads; telemetry vận hành (Firebase
   Analytics + Crashlytics, operational-only) được phép trong closed beta
   theo D-7/ADR-TON-005. Monetize VALUE không monetize DATA (red line).
4. **AI-First, không phải AI-bolt-on** — Copilot là Planner/Advisor/Navigator/
   Executor/Monitor/Optimizer, không phải chatbot gắn thêm.
5. **Opportunity là đơn vị trung tâm**; **Business Journey = goal orchestration**,
   không phải workflow.
6. **Practical over ambitious** — placeholder > perfect, ship > polish.
7. **Bilingual tử tế** — EN+VI là first-class, không dịch máy cẩu thả.

Nếu một task order mâu thuẫn các nguyên tắc này: dừng và flag Founder.
UX chi tiết: xem Design Bible ([BUSINESS-JOURNEY-BIBLE](BUSINESS-JOURNEY-BIBLE.md),
[OPPORTUNITY-ENGINE](OPPORTUNITY-ENGINE.md), [AI-BUSINESS-COPILOT](AI-BUSINESS-COPILOT.md)).
