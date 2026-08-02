# Founder Setup Guide — vận hành n8n mà không cần hỏi ai

> **WTM-272 · Wave 10 của PLATFORM-002.** Không chứa secret. Mọi khoá nằm ở
> `~/.workizen-secrets/n8n-tongtai.json` trên máy anh (quyền 600, ngoài mọi git repo).

---

## Vào đâu

| Việc | Đường |
|---|---|
| Mở n8n | `https://tongtai.workizen.net` |
| Đăng nhập | email + mật khẩu anh đặt lúc tạo owner |
| Xem workflow | Overview (biểu tượng nhà, góc trái) |
| Xem lần chạy | mở workflow → tab **Executions** |
| Bật/tắt workflow | mở workflow → nút **Publish** góc phải trên |
| Cấu hình MCP | Settings → **Instance-level MCP** |
| Xem client đã nối | Settings → Instance-level MCP → **Connected clients** |

---

## Checklist hằng tuần (2 phút)

- ☐ Mở Executions, xem có lần chạy nào **đỏ** không
- ☐ Nếu đỏ: mở ra, đọc node bị lỗi (n8n chỉ đúng node)
- ☐ Kiểm backup còn chạy: file mới nhất trong `/data/backup/db/` phải là **hôm qua**
- ☐ Nếu sắp hết hạn/đổi token vendor: xoay credential **trước** khi nó hết hạn

---

## Kiểm nhanh mọi thứ còn sống (một lệnh)

Dán vào Terminal:

```bash
curl -sS -o /dev/null -w "n8n HTTPS: %{http_code}\n" https://tongtai.workizen.net/
ssh -i ~/projects/workforceOS-usecases/oracle-key/ssh-key-2026-06-11.key ubuntu@144.24.8.35 \
  'sudo docker compose -f /data/n8n/compose/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}"; \
   echo; df -h /data | tail -1; echo; ls -lt /data/backup/db | head -3'
```

Kết quả mong đợi: HTTPS **200** · 5 container **Up** · `/data` dùng dưới 50% ·
file backup mới nhất là **hôm qua**.

---

## Khi có sự cố

| Triệu chứng | Làm gì |
|---|---|
| Web không vào được | Chạy lệnh kiểm ở trên. Container nào không `Up` thì `docker compose restart <tên>` |
| Workflow chạy lỗi | Executions → mở lần chạy đỏ → n8n chỉ đúng node hỏng |
| Đầy đĩa | `/data` 196 GB, hiện dùng dưới 1%. Nếu đầy: giảm `EXECUTIONS_DATA_MAX_AGE` trong `.env` |
| Cần khôi phục | Xem `docs/08-PLATFORM/08-IMPLEMENTATION-EVIDENCE.md` §Backup — đã thử thành công |
| **Quên/lộ mật khẩu** | n8n → Settings → Personal → đổi. Rồi cập nhật `~/.workizen-secrets/n8n-tongtai.json` |
| **Lộ token MCP** | Settings → Instance-level MCP → **Connection details → nút ⟳** (xoay). Token cũ chết ngay |

---

## Secret nằm ở đâu, và khi nào phải xoay

| Secret | Ở đâu | Xoay khi |
|---|---|---|
| Mật khẩu owner n8n | `~/.workizen-secrets/n8n-tongtai.json` | lộ, hoặc định kỳ |
| `N8N_ENCRYPTION_KEY` | `/data/n8n/compose/.env` trên VM (600) + trong bản backup | **KHÔNG BAO GIỜ tự ý đổi** — đổi là mất toàn bộ credential đã lưu |
| Token MCP (instance) | file secret trên máy anh | lộ ⇒ ⟳ trong UI |
| Bearer token workflow MCP | file secret | lộ ⇒ sửa credential trong n8n |
| Secret webhook RevenueCat | file secret | lộ ⇒ đổi credential + cập nhật ở RevenueCat |
| Mật khẩu Postgres | `.env` trên VM | hiếm khi cần — chỉ dùng trong private network |

⚠️ **Điều nguy hiểm nhất trong danh sách trên là `N8N_ENCRYPTION_KEY`.** Nó không
phải mật khẩu đăng nhập — nó là khoá **giải mã mọi credential** trong n8n. Mất
nó thì bản backup Postgres còn nguyên nhưng **không credential nào dùng được**.
Vì thế backup script đóng gói nó cùng bản dump.

---

## Chi phí

| Khoản | Tiền |
|---|---|
| Oracle VM usecase | **0** (đã có sẵn) |
| Ổ 200 GB | đã gắn |
| n8n self-host | **0** (bản community) |
| DNS Route53 | ~0,50 USD/tháng cho hosted zone đã có |
| TLS Let's Encrypt | **0** |
| **Phát sinh mới của PLATFORM-002** | **≈ 0** |

---

## Cấu hình nằm ở đâu (WTM-259)

Toàn bộ cấu hình n8n **đã có trong git**, không còn chỉ nằm trên máy:

> `poupou97/workforceos-usecases` → `infra/n8n/`

compose · Caddyfile · backup.sh · cron · `.env.example` · README dựng lại từng
bước. **`.env` thật không nằm trong repo** — giá trị sinh trên máy bằng
`openssl rand -hex 32`.

⚠️ Trước đó cấu hình chỉ tồn tại trên chính cái máy nó đang chạy, và bản backup
cũng nằm trên máy đó — nên bảng "dựng lại dưới 10 phút" bên dưới **chỉ đúng từ
hôm nay trở đi**.

---

## Thời gian dựng lại nếu mất sạch

| Bước | Thời gian |
|---|---|
| Tạo VM mới + gắn đĩa | ~10 phút (thao tác Oracle Console) |
| Cài Docker + cấu hình data-root | ~2 phút |
| Khôi phục dump + `.env` | ~1 phút |
| `docker compose up -d` | ~1 phút |
| Trỏ lại DNS | ~1 phút + chờ TTL 300s |
| **Tổng phần tự động** | **dưới 10 phút** |

**Dữ liệu kinh doanh của người dùng mất bao nhiêu trong tình huống đó: KHÔNG
MẤT GÌ.** Dữ liệu canonical nằm trên máy người bán (SQLite/Drift); n8n chỉ giữ
workflow + credential + con trỏ đồng bộ.

---

## Việc còn cần anh làm một lần

1. **Publish workflow `RevenueCat → Canonical Event`** — n8n 2.x không cho publish
   qua API, phải bấm trong UI. Sau đó URL webhook mới sống.
2. **Dán URL webhook vào RevenueCat** (Dashboard → Integrations → Webhooks), kèm
   header `Authorization` lấy từ file secret.
3. Nếu muốn Claude tự dựng workflow: Settings → Instance-level MCP → tích
   workflow → **Enable workflows**.
