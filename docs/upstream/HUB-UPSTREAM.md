# Hub Upstream Policy

Hub (`workizen-ai-personal-wallet`) là **upstream reference** — không phải
dependency, không phải nguồn sự thật.

## Remote (fetch-only)

```bash
git remote add hub-upstream https://github.com/poupou97/workizen-mobile-north-star-2026-06-12.git
git fetch hub-upstream          # CHỈ fetch/compare — KHÔNG BAO GIỜ merge
```

⛔ Cấm: `git merge hub-upstream/*`, cherry-pick hàng loạt, sync tự động.

## Quy trình adopt 1 thay đổi từ Hub

1. Phát hiện (review Hub commit/PR đáng chú ý).
2. Phân loại: **MUST ADOPT** / **CANDIDATE** / **HUB ONLY** / **NOT APPLICABLE**.
3. Fit/Gap ngắn → tạo Jira task WTM nếu adopt.
4. Port **chọn lọc bằng tay** (đổi import, bỏ phần Hub-only), test evidence.
5. Ghi vào [HUB-ADOPTION-LOG.md](HUB-ADOPTION-LOG.md) (bắt buộc): Hub commit,
   lý do, file ảnh hưởng, test, ADR nếu chạm kiến trúc.

## Ưu tiên đánh giá (đáng theo dõi)

Security fix · store compliance (Hub đã ăn 4 vòng Apple reject — mỏ kinh
nghiệm) · Flutter/platform fix · AI client cải tiến · design-system nâng cấp ·
build tooling · performance · accessibility.

## Không bao giờ tự port

Academy, RSS, Personal Memory, Hub onboarding/home/screens, Hub schema/flags,
store rules đặc thù Hub.

Baseline gốc: xem [BASELINE-MANIFEST.md](BASELINE-MANIFEST.md).
