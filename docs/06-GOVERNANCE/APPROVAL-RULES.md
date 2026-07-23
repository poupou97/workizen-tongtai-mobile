# Approval Rules — Founder gates

## ⭐ Standing Authorization (Founder, 2026-07-23)

Founder uỷ quyền vận hành cho PM Agent: **nếu một việc thuộc category đã được
phê duyệt bởi Founder Decision / ADR / Product Principle / Working Rule trước
đó → coi như ĐÃ DUYỆT, tiếp tục ngay, không hỏi lại.** Ví dụ (nguyên văn):
documentation sync · ADR status update · Jira workflow · Confluence mirror ·
technical refactoring · CI improvements · dependency updates · code cleanup ·
backlog prioritization · story claiming · branch management · **merge (khi
branch policy cho phép — hiện tại: CI xanh + trong phạm vi quyết định đã
duyệt)**.

- Chỉ ngắt Founder khi cần **quyết định chiến lược MỚI**.
- Nếu không chắc: viết ADR proposal và tiếp tục với phương án an toàn nhất
  cho tới khi Founder quyết.

## Founder-ONLY (vẫn tuyệt đối không tự làm — chưa từng được duyệt)

- Tag release, deploy, submit store, đóng Epic.
- Force-push/rewrite history trên main.
- Quyết định chiến lược MỚI: kiến trúc chưa có ADR, package/bundle id, tiền
  (billing/pricing), dữ liệu người dùng (bất kỳ thứ gì chạm privacy red line).
- Thay đổi các nguyên tắc trong PRODUCT-PRINCIPLES (trừ khi chính Founder ra
  quyết định, như D-7/D-9 ngày 2026-07-23).

## Agent tự quyết (trong feature branch)

- Toàn bộ SDLC của 1 story: code, test, refactor nhỏ, commit, push branch,
  mở PR, cập nhật Jira/docs kèm evidence.
- Kế hoạch thực thi (thứ tự story, retry, tooling) — nguyên tắc self-planning:
  *"Runtime tự lập kế hoạch trong phạm vi quyền hạn được giao"* — đừng hỏi
  Founder chọn phương án vận hành thường ngày.

## Khi nào phải DỪNG và hỏi

- Spec mâu thuẫn ADR/nguyên tắc; blocker công cụ không tự gỡ được;
  build fail không rõ nguyên nhân; rủi ro kiến trúc/dữ liệu.
- Báo cáo Founder chỉ khi: xong Sprint/Epic · lỗi nghiêm trọng · hết task
  khả thi · branch sẵn sàng merge.
