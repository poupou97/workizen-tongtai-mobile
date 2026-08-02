# Implementation Evidence — PLATFORM-002

> **Epic WTM-256.** Theo §15 Task Order: *"Không coi container chạy là hoàn
> thành."* Mỗi dòng dưới đây là kết quả lệnh thật, ngày **2026-08-02**.
> ⚠️ Không chứa secret. Token/khoá nằm ở `~/.workizen-secrets/` (600, ngoài mọi repo).

---

## Hạ tầng

| Kiểm | Kết quả | Story |
|---|---|---|
| VM đích | `workforceos-usecases-layer` · 144.24.8.35 (private 10.0.0.52) · Ubuntu 24.04.4 aarch64 · 4 vCPU · 23 GB | WTM-257/260 |
| **Không đụng production** | n8n nằm ở VM usecase; VM observer (137.131.35.185, `workizen.net`) **không bị chạm** | WTM-260 |
| Ổ 200 GB | `/dev/sdb` → ext4 → `/data`, vào `/etc/fstab` bằng **UUID + nofail** · 186 GB trống | WTM-263 |
| Docker data-root | `/data/docker` — xác minh bằng `docker info` | WTM-262 |
| iptables 80/443 | mở, **backup luật cũ** tại `/opt/backup/iptables-*.rules` trước khi sửa · lưu qua `netfilter-persistent` | WTM-261 |
| Oracle Security List | **vốn đã mở** — xác minh bằng `Connection refused` (không phải `timed out`) | WTM-261 |

## Mạng và TLS

| Kiểm | Kết quả |
|---|---|
| DNS | `tongtai.workizen.net` → `144.24.8.35`, A record TTL 300, hosted zone `Z048982110IKRK19LARIQ` |
| Xung đột DNS | **không** — chưa từng có record `tongtai.*` |
| HTTPS | HTTP **200**, TLS verify **0** (hợp lệ) |
| Chứng chỉ | Let's Encrypt · CN `tongtai.workizen.net` · hạn **31/10/2026** |
| Header bảo mật | HSTS `max-age=31536000; includeSubDomains` · `X-Frame-Options: DENY` · `X-Content-Type-Options: nosniff` |

## Cô lập dịch vụ

```
ss -lntup → 5432 / 6379 / 5678 KHÔNG listen trên host
```

Chỉ Caddy giữ 80/443. Postgres · Redis · n8n chỉ nói chuyện qua private Docker network.

## Backup và Restore — **đã chứng minh, không chỉ tạo**

| Kiểm | Kết quả |
|---|---|
| Backup tự động | `/etc/cron.d/n8n-backup` — 02:30 hằng ngày |
| Nội dung | `pg_dump` Postgres + gói cấu hình **kèm `N8N_ENCRYPTION_KEY`** (thiếu khoá này thì bản dump credential là rác) |
| Retention | 14 ngày |
| **Restore test** | khôi phục vào DB tạm `n8n_restoretest` → **115 bảng == 115 bảng** so với production → **xoá DB tạm** |
| Ảnh hưởng production | **không** — restore vào DB riêng |

## Reboot test — **đã chạy thật**

```
sudo systemctl reboot
```

| Kiểm | Kết quả |
|---|---|
| SSH lên lại | **~30 giây** |
| `/data` | tự mount lại (fstab UUID) — 186 GB trống |
| Container | **cả 5 tự lên** (n8n · n8n-worker · caddy · postgres · redis) |
| iptables 80/443 | **còn nguyên** (2 luật) |
| HTTPS sau reboot | **200** |
| MCP sau reboot | **200** |

## MCP

| Đường | Endpoint | Transport | Kiểm |
|---|---|---|---|
| **Workflow MCP** | `/mcp/tongtai/sse` | SSE | có bearer → **200** · không token → **403** |
| **Instance MCP** | `/mcp-server/http` | HTTP | có token → **200** (`initialize` trả `protocolVersion 2024-11-05`) · không token → **401** |

Cả hai đã đăng ký với Claude Code, `claude mcp list` báo **✓ Connected**.

⚠️ **Ghi chú bảo mật:** token Instance MCP đã bị lộ một lần trong hội thoại ⇒ **đã xoay** qua `POST /rest/mcp/api-key/rotate`; bản cũ chết. Token mới không rời máy.

## Hai chỗ vướng và cách xử lý (để lần sau không mất thời gian)

1. **n8n crash-loop lúc đầu** — `EACCES /home/node/.n8n/config`. Nguyên nhân:
   user `ubuntu` trên VM này là **uid 1001**, còn `node` trong ảnh n8n là **uid
   1000**. Sửa: `chown -R 1000:1000` thư mục bind-mount.
2. **MCP endpoint 404** dù workflow đã publish — MCP Server Trigger dùng
   transport **SSE**, đường đúng là `/mcp/<path>/sse`, không phải `/mcp/<path>`.
   Không tài liệu nào nói thẳng; phải dò.

## Rollback

| Thay đổi | Đường lùi |
|---|---|
| iptables | `sudo iptables-restore < /opt/backup/iptables-<TS>.rules` |
| fstab | `/opt/backup/fstab-<TS>.bak` |
| Toàn bộ stack n8n | `docker compose down` + xoá `/data/n8n` — **không ảnh hưởng gì ngoài VM này** |
| DNS | xoá A record `tongtai.workizen.net` (không record nào khác bị chạm) |
| VM observer / `workizen.net` | **không có gì để lùi — chưa từng chạm** |

---

## Đính chính phạm vi dogfood (Founder, 2026-08-02)

> *"Tạm bỏ qua RevenueCat đi, đã lên store đâu."*

Đúng. RevenueCat chỉ có dữ liệu khi app đã bán hàng, mà Tổng Tài **chưa lên
store**. Một webhook receiver đã publish nhưng không bao giờ nhận gì là đúng
hình dạng "thứ chết trông như đang sống" mà repo này đã dọn nhiều lần
(`opportunities_table`, `integrations_table`, n8n trong sơ đồ App Layer).

**Đã xử lý:** `unpublish_workflow` qua MCP → webhook trả 404. Workflow **giữ
nguyên**, publish lại bằng **một lệnh MCP** khi app lên store.

### Dữ liệu thật Workizen có NGAY HÔM NAY

| Nguồn | Có gì | Dùng được? |
|---|---|---|
| **GitHub** | **208 commit/30 ngày · 100 PR đã merge · 0 release** | ✅ nhiều nhất |
| **Jira WTM** | ~50 issue, worklog đầy đủ, tạo mới hằng ngày | ✅ |
| Firebase Crashlytics | app mới cài 2 máy hôm nay, crash rỗng | ⚠️ quá ít |
| App Store · Play · RevenueCat · GA4 | **không có gì** | ❌ chưa lên store |

### Một tín hiệu kinh doanh tìm được mà không cần connector nào

**208 commit, 100 PR merged, và 0 release.**

Đây chính là loại tín hiệu mà capability *Developer Productivity* sinh ra để
bắt: công việc chạy rất nhiều nhưng **không có gì tới tay người dùng**. Với một
doanh nghiệp phần mềm, đó là con số quan trọng hơn mọi biểu đồ commit.

⇒ Dogfood connector đúng đắn kế tiếp là **GitHub**, không phải RevenueCat.

### ✅ Đã làm xong cùng ngày — WTM-268

Founder cấp fine-grained PAT chỉ quyền đọc; connector đã chạy thật:

| Kiểm | Kết quả |
|---|---|
| Không có `Authorization` | **403** |
| Có token · 3 endpoint · 7 trang | **200** · 6,9s · 233 KB · **360 sự kiện** |
| Số liệu vs đo trực tiếp GitHub API | **208 commit / 152 PR merged / 0 release — khớp tuyệt đối** |
| Gọi hai lần | **360 `event_id` trùng, 0 lệch** — retry không sinh bản ghi thứ hai |
| Request cố đổi `repo` | bị bỏ qua — repo **ghim server-side** |

Chi tiết đầy đủ: `docs/08-PLATFORM/11-GITHUB-CONNECTOR-EVIDENCE.md`.

⇒ Mục *"chưa có smoke connector với vendor thật"* trong bộ review **đã đóng**.
