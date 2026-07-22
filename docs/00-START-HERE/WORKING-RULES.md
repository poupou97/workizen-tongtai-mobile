# Working Rules — bắt buộc cho mọi agent

## Gates (vi phạm = dừng ngay)

1. **`main` là Founder-only.** Agent làm trên feature branch, mở PR, KHÔNG BAO
   GIỜ merge/push/force-push main, không tag release, không deploy, không đóng
   Epic thiếu evidence.
2. **Không secret trong git**: API key, keystore, google-services.json thật,
   .env thật. BYOK key chỉ nằm trong `flutter_secure_storage` lúc runtime.
3. **Không đổi quyết định kiến trúc của Founder** (xem ADR-INDEX) — muốn đổi
   thì đề xuất ADR mới, chờ duyệt.

## Evidence-Driven (nguồn gốc: bài học WTM-51)

- Lời agent **không phải** bằng chứng. `flutter analyze` + `flutter test`
  output mới là bằng chứng.
- **Cấm test giả**: `expect(true, true)`, test không assertion → bị placebo-scan
  reject tự động.
- Code sinh (Drift `*.g.dart`…) phải do build_runner tạo, không viết tay.
- Mỗi story: analyze sạch + test pass + commit message có mã WTM-xx.

## Quy trình chuẩn 1 story

1. Đọc Jira issue (project **WTM**) — description + AC.
2. Branch `feat/wtm-xx-<slug>` từ main.
3. Code thật + test thật (theo chuẩn test hiện có trong `test/`).
4. `flutter analyze` sạch → `flutter test` xanh → commit → push → PR.
5. Jira → Code Review + comment kèm commit hash + số test.
6. Founder merge → Done.

## Decision levels

- **L1** (tự quyết): chi tiết implement, cấu trúc file trong feature, test.
- **L2** (đề xuất + cờ veto): thêm dependency mới, pattern mới.
- **L3** (Founder bắt buộc): kiến trúc, đổi ADR, package id, release, tiền/dữ liệu.

## Nguyên tắc sản phẩm khi code

- Local-first: không thêm backend call nào ngoài direct-to-AI-provider (BYOK).
- Privacy: không thêm SDK telemetry/tracking.
- Bilingual: string hướng người dùng phải có EN + VI.
- Riverpod only (ADR-TON-002). Extractable modules (ADR-TON-001).
