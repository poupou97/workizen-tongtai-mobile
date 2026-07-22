# Documentation Rules

1. **Ngắn, chính xác, phản ánh code thật.** Không tạo doc dài mà rỗng.
2. Cấu trúc cố định: `00-START-HERE` → `06-GOVERNANCE` + `upstream/` +
   `migration/` + `archive/`. Không tạo doc ở root repo.
3. **Không nhân đôi nội dung** — link tới doc gốc thay vì copy.
4. Doc lỗi thời: sửa hoặc chuyển `archive/`, đừng để mâu thuẫn tồn tại
   (thứ tự phân xử: [SOURCE-OF-TRUTH](../00-START-HERE/SOURCE-OF-TRUTH.md)).
5. Khi ship story làm thay đổi hiện trạng: cập nhật `CURRENT-STATUS.md` +
   `SCREEN-INVENTORY.md` (nếu thêm màn) + `CURRENT-STATE-ARCHITECTURE.md`
   (nếu đổi cấu trúc).
6. Quyết định kiến trúc → ADR mới + cập nhật `ADR-INDEX.md`.
7. Adopt gì từ Hub → ghi `upstream/HUB-ADOPTION-LOG.md` (bắt buộc provenance).
8. Bilingual: doc hướng người dùng/Founder ưu tiên VI hoặc song ngữ; doc kỹ
   thuật nội bộ EN được, giữ nhất quán trong từng file.
