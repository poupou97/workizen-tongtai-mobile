# 19 · Mười bài học đáng nhớ nhất

Xếp theo mức thay đổi cách nghĩ, không theo thứ tự đọc.

## 1 · "You never set a confidence. You report what you saw, and the ledger prices it."

Bài học trung tâm. Agent khai **cái nó thấy** (`kind` từ từ vựng đóng); một **hàm thuần** định giá. `record_fact` không có tham số `score` — **nói dối không viết ra được**.

Tổng Tài đang làm ngược ở đúng một chỗ: `IdentityCandidate.confidence`.

## 2 · Một đề xuất là **kết quả đúng**, không phải thất bại

> *"Kept as a proposal for a rep to accept or dismiss. This is a normal outcome, not a failure — **do not try to raise the score**."*

Câu này chặn đúng hành vi mà mọi hệ thống chấm điểm sinh ra: model đi tìm thêm bằng chứng để vượt ngưỡng. Skill nói lại lần nữa: *"that is how a wrong answer gets dressed up as a right one."*

## 3 · Đoán ở **chỗ tìm**, không đoán ở **câu trả lời**

> *"`pmarchetti` is not a name… asking a model produces 'Paula Marchetti' — which happens to be right, and **would have been just as confident had it been wrong**."*

Suy đoán đi vào **truy vấn**; câu trả lời đến từ **nguồn**. Áp được cho mọi việc AI làm, không riêng identity.

## 4 · Tính năng mới hơn có bảo đảm **yếu hơn**

Fact ledger (`20260801`) có evidence + lifecycle + human-owned. Dynamic fields (`20260806`, **5 ngày sau**) không có gì cả.

**Kỷ luật không tự lan.** Nó lan khi có thứ **bắt** nó lan — và COMP AI không có boundary test nào. Đây là biện hộ mạnh nhất cho các suite governance của Tổng Tài.

## 5 · Bảng append-only cho **sự kiện đời sống** miễn phí

Fact cũ → `SUPERSEDED`, không xoá. `lastEmployerChange()` chỉ là một truy vấn. Không cơ chế riêng, không cột `hasChangedJob`.

## 6 · `contradiction` **kẹp** điểm, không trừ dần

> *"A profile saying one employer and a mail header saying another is **not 60% true, it is unresolved**."*

Cùng họ với `ProfitInsufficient` của Tổng Tài: từ chối trả lời tốt hơn trả lời trung bình cộng.

## 7 · Biên là **egress**, không phải read

> *"You may read everything… A signature block settles a job title more reliably than LinkedIn does, because people update a signature the week they are promoted."*

Đảo ngược trực giác "hạn chế AI đọc". Cái phải canh là **cái rời đi**.

## 8 · Không có gì thất bại khi kiến trúc bị vi phạm

`apps/agent/test/` 24 file, không file nào là boundary test. Ba kỷ luật ghi cùng tồn tại **vì không có gì bắt chúng hợp nhất**.

Đúng câu Tổng Tài đã viết trong `CLAUDE.md` về Jira: *"Board đứng im thì KHÔNG có gì thất bại."* Cùng một hình dạng lỗi, ở một hệ khác, tự sinh ra lần nữa.

## 9 · Postgres + cron + `SKIP LOCKED` là đủ cho durable agent

174 dòng. Không Temporal, không Kafka, không hàng đợi ngoài. Chạy production.

Bằng chứng mạnh cho §22 — và nó **phản bác trước** mọi đề xuất hạ tầng nặng.

## 10 · Cấu hình mang theo lời giải thích của chính nó

`sandboxPolicy.summary`, `scopeSummary()`, `targetLabel`, `agentTask.reason` viết cho người đọc. Không có tầng dịch riêng ⇒ không có tầng nào lệch.

Giải quyết §16 rẻ hơn bất kỳ thiết kế UX nào.

---

## Một bài học ngược — điều COMP AI **không** dạy được

Họ giải bài toán *"agent làm giàu dữ liệu CRM"*, nơi hành động tệ nhất là ghi sai một chức danh và sửa mất năm giây.

Tổng Tài giải bài toán *"AI vận hành việc kinh doanh của người ta"*, nơi hành động tệ nhất là **đặt đơn 20 triệu** hoặc **gửi tin sai cho khách**.

`sensitiveWrite` 29 dòng đủ cho họ. Không đủ cho ta. Mọi thứ ở `13-AUTONOMY-POLICY.md` vượt quá source là **có chủ ý**, và phải được đọc như đề xuất chưa có bằng chứng vận hành.
