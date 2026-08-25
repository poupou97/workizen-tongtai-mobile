# 01 · Source Baseline — sáu bản clone, một discrepancy

> WTM-448 (Epic WTM-447) · 2026-08-25 · clone vào `~/projects/_reference/` theo
> REFERENCE-REGISTRY (WTM-309/310). External source **read-only**; mọi trích dẫn
> trong study này neo vào **studied SHA** dưới đây, không phải HEAD tương lai.

## Bảng baseline

| Repo | URL | Branch | Studied SHA | Commit date | License (đọc từ file tại SHA) | Runtime | Cỡ |
|---|---|---|---|---|---|---|---|
| ERPNext | github.com/frappe/erpnext | `develop` | `5fa68dd06835f77a60ccefa033d7955d83294d3b` | 2026-08-24 | **GPL-3.0** (`license.txt`) | Python (Frappe) + JS | 167M · 44 module |
| Relaticle | github.com/Relaticle/relaticle | `main` | `e135b618e1eb9ef13f8b3612a070967ccc86ef20` | 2026-08-25 | **AGPL-3.0** (`LICENSE`) | PHP Laravel + Filament | 33M |
| Trigger.dev | github.com/triggerdotdev/trigger.dev | `main` | `cc69ff4d267fe3e6bb3e4f41f49b9bb38afe1001` | 2026-08-24 | **Apache-2.0** (`LICENSE`) | TypeScript monorepo | 113M · 2 apps + 27 internal-packages + 10 packages |
| Plane | github.com/makeplane/plane | `preview` | `1d0ee2482a5da02f18907d04f06eb9966feaa238` | 2026-08-24 | **AGPL-3.0** (`LICENSE.txt`) | Django + Next.js | 97M · apps: admin·api·live·proxy·space·web |
| Lago (vỏ) | github.com/getlago/lago | `main` | `0b5691536678afb717eb42e762e679f406821e1d` | 2026-08-20 | AGPL-3.0 | docker-compose | 37M |
| **lago-api** | github.com/getlago/lago-api | `main` | `8f604d44ef8856da02ac15041b0cec362d2e43d2` | 2026-08-24 | **AGPL-3.0** (`LICENSE`) | Ruby on Rails | 49M · **105 models** |

## ⚠️ Discrepancy #1 — `getlago/lago` không chứa implementation

Checkpoint *"repo không chứa implementation thật"* của Task Order **bắn ngay ở baseline**:
`lago/api` và `lago/front` là **git submodule** (`.gitmodules` trỏ `lago-api`/`lago-front`).
Repo `lago` chỉ mang docker-compose + deploy script.

**Xử lý:** clone thêm `lago-api` làm đối tượng nghiên cứu domain; giữ `lago` vì
docker-compose của nó là evidence cho câu hỏi *"self-host cần gì"*. Không dừng study —
đây là surprise về **cấu trúc**, không phải về license hay tính mở.

## License Gate — kết luận đứng TRƯỚC mọi verdict ADOPT

| Repo | License | Học kiến trúc | Chép code vào Workizen |
|---|---|:---:|:---:|
| ERPNext | GPL-3.0 | ✅ | ⛔ **CẤM** |
| Relaticle | AGPL-3.0 | ✅ | ⛔ **CẤM** |
| Trigger.dev | Apache-2.0 | ✅ | ✅ được, kèm attribution — *per-package kiểm ở `06`* |
| Plane | AGPL-3.0 | ✅ | ⛔ **CẤM** |
| lago-api | AGPL-3.0 | ✅ | ⛔ **CẤM** |

AGPL nghiêm hơn GPL ở đúng chỗ Workizen dễ vấp: **chạy như network service cũng kích hoạt
nghĩa vụ mở source**. Nên kể cả "self-host Lago/Plane làm service nội bộ có chỉnh sửa" cũng
phải qua Founder trước. Chi tiết ở `15-LICENSE-RISK.md`.

## Điều tra viên lưu ý

Bản clone là `--depth 1`: đủ cho đọc code tại SHA, **không** đủ cho khảo cổ lịch sử commit.
Kết luận nào cần "vì sao họ đổi thiết kế" phải fetch thêm — ghi rõ nếu làm.
