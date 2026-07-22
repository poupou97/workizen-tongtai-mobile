# Lệnh Onboarding Review — dán cho agent mới trước khi giao việc

> Cách dùng: mở Claude Code trong folder `workizen-tongtai-mobile`, dán nguyên
> khối dưới đây. Agent sẽ đọc handoff, kiểm chứng với code thật, và nộp danh
> sách câu hỏi cho Founder TRƯỚC khi được phép làm việc.

---

# NHIỆM VỤ: ONBOARDING REVIEW — đọc kỹ handoff, hỏi trước khi làm

Bạn là agent MỚI tiếp quản repo `workizen-tongtai-mobile` (sản phẩm Tổng Tài).
Nhiệm vụ này CHƯA được code — chỉ ĐỌC, KIỂM CHỨNG và ĐẶT CÂU HỎI.

## Bước 1 — Đọc theo đúng thứ tự (bắt buộc, ~20 phút)

1. `CLAUDE.md`
2. `docs/00-START-HERE/AGENT-ONBOARDING.md`
3. `docs/00-START-HERE/PRODUCT-CONTEXT.md`
4. `docs/02-ARCHITECTURE/CURRENT-STATE-ARCHITECTURE.md`
5. `docs/03-DECISIONS/ADR-INDEX.md` + 2 file ADR-TON
6. `docs/00-START-HERE/CURRENT-STATUS.md` + `WORKING-RULES.md` + `SOURCE-OF-TRUTH.md`
7. `.claude/README.md`
8. Lướt nhanh: `docs/06-GOVERNANCE/*` · `docs/upstream/HUB-UPSTREAM.md` ·
   `docs/migration/KNOWN-GAPS.md` · `docs/04-DELIVERY/TEST-STRATEGY.md`

## Bước 2 — Kiểm chứng docs với code thật (evidence-driven, không tin suông)

- Chạy: `flutter pub get` → `flutter analyze` → `flutter test`
  (kỳ vọng: analyze sạch, 519+ test xanh — nếu khác, ghi lại chính xác).
- Đối chiếu cây `lib/` thật với `CURRENT-STATE-ARCHITECTURE.md` — lệch gì không?
- Đối chiếu bảng built ✅/❌ trong `docs/01-PRODUCT/SCREEN-INVENTORY.md` với
  screens thật trong `lib/features/tongtai/ui/screens/`.

## Bước 3 — Nộp báo cáo cho Founder (output DUY NHẤT của nhiệm vụ, tiếng Việt)

**A. HIỂU BIẾT** (tối đa 10 dòng, bằng lời của bạn): sản phẩm là gì/không là
gì, kiến trúc, trạng thái, luật chơi quan trọng nhất.

**B. KIỂM CHỨNG**: kết quả analyze/test thật + mọi chỗ docs ≠ code phát hiện được.

**C. CÂU HỎI TRƯỚC KHI LÀM** (phần quan trọng nhất) — chia 2 loại:
- 🔴 **BLOCKER**: không rõ thì không dám làm (spec mơ hồ, thiếu quyết định, mâu thuẫn docs↔code)
- 🟡 **NÊN LÀM RÕ**: vẫn làm được nhưng muốn Founder xác nhận

⚠️ Nếu KHÔNG có câu hỏi: nói thẳng "không có câu hỏi" — **đừng bịa câu hỏi cho có**.

**D. ĐỀ XUẤT**: story đầu tiên bạn sẽ nhận (từ backlog Sprint 3+, WTM-76…102 —
xem `docs/04-DELIVERY/BACKLOG-MAP.md` + Jira WTM) + lý do chọn + kế hoạch 5 dòng.

## Ràng buộc cứng

- KHÔNG code, KHÔNG sửa file, KHÔNG commit trong nhiệm vụ này.
- KHÔNG đụng `main`. KHÔNG cần repo Hub — mọi thứ nằm trong repo này.
- Trung thực tuyệt đối: không biết thì nói không biết; lời kể không phải
  bằng chứng — chỉ output lệnh thật được tính.

**DỪNG sau khi nộp báo cáo. Chờ Founder trả lời câu hỏi (nếu có) rồi mới bắt
đầu nhận story.**
