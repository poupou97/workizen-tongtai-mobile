# Definition of Done — 1 story

Một story chỉ được coi là DONE khi có ĐỦ:

1. ✅ Code thật implement đúng AC trong Jira (đọc AC trước khi code).
2. ✅ Test thật đi kèm (không placebo), suite toàn repo vẫn xanh.
3. ✅ `flutter analyze` sạch (0 error, 0 warning mới).
4. ✅ Codegen (nếu có) do build_runner sinh trong phiên làm việc.
5. ✅ Bilingual EN+VI cho string hướng người dùng.
6. ✅ Commit message có mã `WTM-xx`, push feature branch, PR mở.
7. ✅ Jira → Code Review, comment kèm commit hash + kết quả analyze/test.
8. ✅ **Founder merge PR vào main** → lúc đó mới chuyển Done.

Doc là DONE khi: một kỹ sư Flutter đủ năng lực build được từ doc mà không phải
hỏi thêm câu hỏi sản phẩm. Code task là DONE khi build chạy và feature hoạt
động trên thiết bị thật.
