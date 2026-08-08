# 20 · Khuyến nghị

> ⚠️ **Không implement trước Founder + GPT review.** Xếp theo giá trị/chi phí.

## R-1 · `confidence` phải TÍNH, không do chỗ gọi khai 🔴 P0

**Vấn đề:** `IdentityCandidate {customerId, signal, confidence}` — chỗ gọi khai. Ta đã phải thêm lớp phòng thủ (ứng viên tự nhận `exact` bị hạ về `strong`) chính vì chỗ gọi có thể nói dối.

**Đề xuất:** chỗ gọi khai **`EvidenceKind`** từ từ vựng đóng; một hàm thuần định giá.

```dart
// PROPOSAL
enum IdentityEvidenceKind { platformUniqueId, phoneExactMatch, emailExactMatch,
                            nameSimilar, addressSimilar, contradiction }
IdentityConfidence scoreIdentity(List<IdentityEvidence> evidence)
```

**Chi phí:** một file + sửa `IdentityCandidate`. Chưa connector nào dùng ⇒ **không migration, không dữ liệu bị ảnh hưởng**. Rẻ nhất ngay lúc này, đắt dần theo mỗi connector.

**Khoá bằng:** governance test — `IdentityCandidate` không có trường `confidence`; đúng một hàm sinh `IdentityConfidence`.

## R-2 · `ProposedChange` — mảnh thiếu để lên L2 🔴 P0

**Vấn đề:** `SuggestLink` là giá trị trả về **trong bộ nhớ**. Không sống qua một lần đóng app. Tổng Tài **không thể** lên L2 · Prepare.

**Đề xuất:** bảng `proposed_changes` với 4 trạng thái + evidence + `correlationId`.

**Về `DISMISSED`** *(Founder chỉ đạo 2026-08-08)*: **không** cấm vĩnh viễn cho mọi miền.

| Miền | Mặc định |
|---|---|
| Danh tính khách | vĩnh viễn *(như COMP AI — tên người không đổi)* |
| Giá nhà cung cấp · dự báo cầu · mức tồn kho | `reconsiderAfter: 30 ngày` |
| Bất kỳ miền nào | xét lại ngay khi có `EvidenceKind` **mạnh hơn** lần bị bỏ qua |

Lưu `reconsiderAfter` + `dismissedWithEvidenceRank` trên chính bản ghi ⇒ luật đọc được, không nằm trong đầu ai.

## R-3 · `BusinessAction` — cửa ghi DUY NHẤT 🟠 P1

Phủ **cả `vendor: internal`**. Ba lớp chống bypass đã có tiền lệ trong repo (WTM-292 lớp 1+2, WTM-293 constructor private).

**Chỉ có giá trị khi làm TRƯỚC agent đầu tiên.** COMP AI cho thấy sau đó thì đã muộn — 5 ngày là đủ để sinh đường ghi thứ ba.

## R-4 · `correlationId` — một trường, không phải một bảng 🟢 P1

Thêm `correlationId TEXT` nullable + index vào `Evidence`, `AgentTask`, `ProposedChange`, `BusinessAction`, `Result`. Thay cho `BusinessConversation`.

## R-5 · `AutonomyRule` 4 trường + 7 hành động cấm auto 🟠 P1

`OFF | SUGGEST | CONFIRM | AUTO` khớp đúng 4 mức của Founder. Bảy hành động cấm (xem `13-AUTONOMY-POLICY.md`) nên là **hằng số + assert**, không phải mặc định cấu hình.

## R-6 · `AgentTask` chạy lúc mở app 🟠 P1

Bắt đầu **hướng A** (chạy khi mở app). `dueAt` + `attempts` + `leasedUntil` có giá trị ngay cả khi chỉ chạy lúc mở — nó biến *"AI trả lời một câu"* thành *"AI tiếp tục việc dở"*.

Hướng B (WorkManager) / C (Optional Runtime) là **Founder Gate** — xem `21-FOUNDER-DECISIONS.md` D-4.

## R-7 · Bổ sung `requestHash` cho `CanonicalEvent.dedupeKey` 🟢 P2

Hiện chỉ có key. Thiếu hash ⇒ hai sự việc khác nhau lỡ trùng key sẽ **lặng lẽ nuốt nhau**. Sửa lúc chưa có producer nào là rẻ nhất.

## R-8 · Skill runtime cho agent 🟢 P2

Khi có agent, chuyển các doc comment giải thích *vì sao* (`identity_resolver.dart`, `settlement.dart`) thành **file skill model đọc lúc chạy**.

## Điều KHÔNG khuyến nghị

| | Vì sao |
|---|---|
| Mở rộng `CanonicalEvent` | 0 producer/consumer — chờ điều kiện tốt nghiệp |
| `BusinessConversation` entity | projection đủ |
| Memory store / vector DB | trí nhớ là bản ghi nghiệp vụ |
| Policy engine | 4 trường là đủ |
| Temporal/Kafka/microservices | COMP AI chạy production không có |
| Cho agent đổi schema | schema là ADR + migration + governance test |
| Chép trọng số evidence của COMP AI | trọng số của họ hợp CRM; của ta phải rút từ lỗi thật của người bán |

## Thứ tự đề xuất

```
R-1 (confidence)  ─┐
R-2 (ProposedChange)┼─ làm trước agent đầu tiên
R-3 (BusinessAction)┘   ← sau đó thì đã muộn (bằng chứng: COMP AI)
R-4 (correlationId) — đi kèm R-2
R-6 (AgentTask hướng A)
R-5 (AutonomyRule)  — chỉ cần khi có AUTO
R-7, R-8 — khi có producer/agent thật
```
