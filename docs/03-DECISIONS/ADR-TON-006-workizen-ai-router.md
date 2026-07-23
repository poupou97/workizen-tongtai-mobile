# ADR-TON-006: AI Provider Strategy — Workizen AI Router

**Status:** ✅ ACCEPTED (Founder, 2026-07-23 — D-9 APPROVED (Updated),
superseding the xAI-first proposal)
**Decides:** OPEN-DECISIONS D-9
**Amends:** "xAI Grok primary" wording in CLAUDE.md / PRODUCT-CONTEXT /
docs cũ (Founder-only change, exercised by the Founder)

## Decision / Quyết định (nguyên văn kiến trúc Founder)

```
Workizen AI
    ↓
AI Router
    ↓
Gemini · xAI · Claude · OpenRouter · Cerebras · Ollama (local)
    ↓
Managed / BYOK / Local
```

- Người dùng chỉ tương tác với **"Workizen AI"** — không chọn/thấy provider.
- **AI Router** quyết định provider theo loại truy vấn, chi phí, khả dụng.
- Ba chế độ chìa khoá: **Managed** (Workizen cấp) · **BYOK** (key của user) ·
  **Local** (Ollama trên máy).

## Phạm vi Phase 2 (ràng buộc bởi D-5: không backend)

- Khả thi ngay: **BYOK** (per-provider key trong secure storage — nền WTM-61)
  và **Local** (Ollama endpoint).
- **Managed** cần key service phía Workizen → **Phase 3** (đi cùng D-5 mở
  backend). Router được thiết kế đủ chỗ cho Managed từ đầu, chỉ chưa bật.
- Key BYOK vẫn chỉ rời máy trong Authorization header gọi thẳng provider
  (nguyên tắc BYOK không đổi).

## Consequences / Hệ quả

- 🔜 **WTM-82** (AI Prompt Routing) đổi scope: xây `WorkizenAiRouter` đa
  provider thay vì chỉ nối Grok; `ChatResponder` (WTM-80/81) là chỗ cắm.
- 📏 Client hiện tại (WTM-61, OpenAI-compatible) tổng quát hoá thành provider
  adapter; thêm adapter mới = thêm 1 file, không sửa router core.
- 📏 Key store (WTM-61) mở rộng thành per-provider key store.
- 📏 UI: mọi nhãn "Grok/xAI" hướng người dùng đổi dần thành "Workizen AI"
  (làm trong các story chat/AI kế tiếp, không big-bang rename).
- 🔁 Tiêu chí routing (model nào cho việc gì) sẽ chốt trong WTM-82 spec —
  đề xuất trình Founder ở PR đó.
