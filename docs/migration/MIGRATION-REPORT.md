# Migration Report — Hub → workizen-tongtai-mobile

**Ngày:** 2026-07-22 · **Kiểu:** Product Extraction + Knowledge Handoff
**Source:** Hub `feat/tongtai` @ `145a5c5` · **Target bootstrap:** `66c8ae0` (tag `split-baseline`)

## Việc đã làm

1. **Scaffold** app Flutter mới, `com.workizen.tongtai` (Android+iOS), Dart `^3.12.2`.
2. **Code move**: 133 file Dart (features/tongtai + database + tests), import
   `package:wallet/` → `package:tongtai/` (0 sót).
3. **Cắt phụ thuộc Hub**: 1 dây duy nhất (`mascot_state.sharedPreferencesProvider`,
   6 file) → `lib/core/prefs.dart`. Sau cắt: **0 import vào code Hub**.
4. **Standalone app**: `main.dart` mới → `TongtaiAppShell` (lần đầu Tổng Tài
   chạy như app độc lập).
5. **Evidence gate**: `flutter analyze` sạch · **519/519 test pass** · fix duy
   nhất cần thiết = nâng SDK constraint lên `^3.12.2` (private named params).
6. **Docs**: 60 docs mang theo, tái tổ chức vào hierarchy chuẩn (`4e11f0b`),
   + ~25 doc handoff mới (START-HERE, governance, upstream, migration).
7. **Memory handoff**: inventory 59 memory + 2 file `.claude` Hub, adoption
   matrix, `.claude/` riêng + seed memory máy-local. (Lệnh 2)
8. **Jira/Confluence**: WTM + workizento vốn dành riêng Tổng Tài — chỉ cần
   mapping doc, không phải migrate issue.

## Không làm (chủ ý, theo lệnh)

- KHÔNG cleanup code Tổng Tài khỏi Hub (xem [HUB-CLEANUP-GUIDE.md](HUB-CLEANUP-GUIDE.md)).
- KHÔNG copy Hub foundations chưa dùng (consumer-rule — xem
  [../02-ARCHITECTURE/MODULE-OWNERSHIP.md](../02-ARCHITECTURE/MODULE-OWNERSHIP.md)).
- KHÔNG mang secret nào (không tồn tại trong phạm vi copy — verified).

## Rollback

Repo này là ADDITIVE — Hub không bị sửa. Rollback = xoá repo
`workizen-tongtai-mobile` (hoặc bỏ qua nó); Hub `feat/tongtai` vẫn nguyên vẹn
làm nguồn tái-split.

## Gaps còn lại

Xem [KNOWN-GAPS.md](KNOWN-GAPS.md).
