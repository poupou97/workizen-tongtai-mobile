# Approval Rules — Founder gates

## Founder-ONLY (agent tuyệt đối không tự làm)

- Merge/push/force-push **main**; xoá branch; rewrite history.
- Tag release, deploy, submit store, đóng Epic.
- Quyết định kiến trúc (ADR), package/bundle id, tiền (billing/pricing),
  dữ liệu người dùng (bất kỳ thứ gì chạm privacy red line).
- Thay đổi các nguyên tắc trong PRODUCT-PRINCIPLES.

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
