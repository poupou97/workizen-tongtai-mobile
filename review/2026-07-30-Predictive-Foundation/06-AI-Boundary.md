# 06 — AI Boundary

`lib/features/tongtai/ai/predictive_ai.dart` · `ai_runtime_boundary.dart` ·
19 test · WTM-158/159

## AI thấy gì

```
[system] kPredictiveAiSystemPrompt — "GIẢI THÍCH kết quả đã tính sẵn, KHÔNG dự đoán lại"
[user]   # Nhiệm vụ: GIẢI THÍCH kết quả của Rule Twin
         Chủ đề: …
         6 quy tắc (xem dưới)
         <capabilityContext.promptBlock()>     ← số tổng hợp, KHÔNG PII
         # Rule Twin
         Provenance: [version] sufficiency=… confidence=… reasons=…
         <các con số của twin>
```

Sáu quy tắc mang tính chịu lực:
1. số đã được tính sẵn ở `# Rule Twin` — hãy giải thích, đừng tính lại;
2. **TUYỆT ĐỐI KHÔNG đưa ra con số khác**; nếu không đồng ý, nói **bằng lời văn**;
3. chỉ dùng dữ liệu trong các khối bên dưới, không bịa;
4. trích reason code **nguyên văn**;
5. nếu twin nói thiếu dữ liệu thì câu trả lời cũng phải nói thiếu dữ liệu;
6. bạn **không có công cụ**, không truy vấn được, không hành động được.

## Bất biến được cưỡng chế bằng cấu trúc (không chỉ bằng lời)

| Bất biến | Cách cưỡng chế |
|---|---|
| AI không truy cập dữ liệu | `PredictiveAiService` **không giữ** repository / `Ref` / capability provider — nhận sẵn context + twin |
| AI không đổi được số | `ruleVersion` + `reasonCodes` **copy** từ twin (`List.unmodifiable`); `PredictiveExplanation` **không chứa con số nào** ⇒ màn hình buộc phải đọc `twin.result` |
| Zero spend | guard trước vòng lặp provider: twin `insufficient` hoặc không capability nào `hasData` ⇒ **không gọi provider** dù đã cấu hình key |
| Luôn có câu trả lời | bản giải thích rule-based tiếng Việt cho: không key · không provider · cả chuỗi lỗi · insufficient |
| Không PII | prompt = khối capability (số tổng hợp) + khối rule (chỉ id) |

## Hostile-AI test (bằng chứng, không phải lời hứa)

Provider giả trả về: *"Doanh thu tháng tới sẽ là 999.999.999 ₫ và mọi khách đều
an toàn"*. Kết quả: văn bản được truyền qua nguyên vẹn (đó là ý kiến của AI),
nhưng `ruleVersion`/`reasonCodes` vẫn là của twin, twin tính lại vẫn ra đúng số
cũ, và **999.999.999 không bao giờ trở thành con số hiển thị**.

Trên thiết bị thật (ảnh `13-ai-explains-twin-number.png`), Grok/xAI trả lời:
> "Rule Twin dự báo doanh thu tháng 2026-07 là **20.769.724 ₫**…"

— đúng bằng con số headline. Kiến trúc hoạt động ngoài đời, không chỉ trong test.

## Tool Runtime — thiết kế sẵn, KHÔNG bật

```dart
abstract interface class AiToolRuntime { Future<String> invoke(String tool, Map<String, Object?> args); }
class DisabledAiToolRuntime implements AiToolRuntime { /* ném StateError → ADR-TON-016 / G-3 */ }
```

- **Không** tool calling · **không** ReAct · **không** autonomous agent.
- **Ratchet:** một test quét toàn bộ `lib/` (bỏ comment) khẳng định **không file
  nào** tham chiếu `AiToolRuntime` hay import file boundary — nó không thể bị
  "vô tình" nối vào.
- Bật nó = vượt red-line G-3 (AI hành động thay vì đọc) ⇒ **quyết định Founder**.
