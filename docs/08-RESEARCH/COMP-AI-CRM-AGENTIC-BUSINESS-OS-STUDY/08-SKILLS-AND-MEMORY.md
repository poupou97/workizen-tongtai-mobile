# 08 · Skills và Memory

> **CURRENT — EVIDENCE.**

## Hai loại skill, đừng nhầm

| | `.agents/skills/` (33 cái) | `apps/agent/agent/skills/` (4 cái) |
|---|---|---|
| Dành cho | **agent viết code** (dev-time) | **agent chạy nghiệp vụ** (runtime) |
| Nguồn | kéo từ GitHub, khoá bằng hash trong `skills-lock.json` | viết tay trong repo |
| Ví dụ | `nestjs-best-practices` · `prisma-database-setup` · `zero-tech-debt` | `evidence.md` · `identity-matching.md` · `data-boundaries.md` · `writing-a-brief.md` |

**Chỉ loại thứ hai liên quan tới nghiên cứu này.** Bốn file, và chúng chứa **phần lớn kiến thức nghiệp vụ của hệ thống** — nhiều hơn hẳn `adrs/` (gần như rỗng).

## Skill runtime là *tài liệu thi hành được*

Đây là điểm thiết kế đáng học nhất mục này. `skills/evidence.md` không phải ghi chú cho lập trình viên — nó là **thứ model đọc lúc chạy**, và nó dạy đúng những thứ code không diễn đạt được:

- *vì sao* `employer-only` nặng 0.2 (*"this is how a colleague gets filed as the contact"*)
- *khi nào* một đề xuất là kết quả **đúng**, không phải thất bại
- *cấm* hành vi mà chấm điểm tự sinh ra: *"do not go looking for extra evidence to push a claim over a line"*

Code thi hành **luật**; skill giải thích **ý định**. Cả hai cùng ở trong repo, cùng review trong PR.

⇒ Tổng Tài đã có hình dạng tương đương: doc comment dài trong `identity_resolver.dart`, `settlement.dart` giải thích *vì sao*, và `TESTING-BIBLE.md` cho pattern lỗi. Khác biệt: của ta viết cho **người**, của họ viết cho **model đọc lúc chạy**. Khi Tổng Tài có agent thật, đây là chỗ chuyển đổi.

## Memory — agent nhớ gì giữa các phiên

**Không có vector store, không có memory service.** Trí nhớ là **dữ liệu nghiệp vụ**:

| Cơ chế | Ở đâu | Tác dụng |
|---|---|---|
| `contactBrief` | bảng riêng, 1-1 với contact | bản tóm tắt đã viết; preamble nhắc *"A background already exists, written {date}. **Replace it only if you learn something it does not say.**"* |
| `contactFact` (APPLIED + SUPERSEDED) | ledger | biết đã tin gì, từ nguồn nào, và đã từng tin gì khác |
| `agentTask.outcome` | hàng đợi | `lastDecision(contactId)` — lần trước quyết gì và vì sao |
| `workspaceProfile` | 1 dòng toàn hệ | *"who we are"* — mọi session đọc |
| thread của session | eve runtime, tối đa 30 ngày | lần thử lại **tiếp tục** thay vì làm lại |

**Không cái nào là "bộ nhớ AI".** Tất cả đều là bản ghi nghiệp vụ có thể truy vấn, người đọc được, và nằm trong cùng cơ sở dữ liệu.

⇒ **Bài học cho Tổng Tài:** đừng thêm memory store. `ProposedChange` + `BusinessAction` + `Result` + `correlationId` (xem `10-BUSINESS-CONVERSATION-MODEL.md`) đã là trí nhớ, và nó có ưu điểm mà vector store không có — **người bán đọc được và sửa được**.

## Preamble: ngân sách chú ý, không phải ngân sách token

`lib/preamble.ts` dựng phần mở đầu mỗi session gồm: hồ sơ workspace · những gì CRM đã biết về subject · brief đã có (nếu có) · capability đang bật/tắt · lý do của task.

Điểm đáng chú ý: preamble **nói trước cái gì đã có** để agent không đi tìm lại. Đó là cách rẻ nhất để tiết kiệm `budget` — rẻ hơn mọi tối ưu prompt.
