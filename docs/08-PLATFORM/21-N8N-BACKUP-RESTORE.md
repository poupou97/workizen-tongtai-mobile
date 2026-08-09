# n8n — Backup và Restore

> **WTM-316** (C0 · Epic WTM-315) · 2026-08-09 · đo và chạy thật, không mô tả suông.
> ⚠️ Không chứa secret. Chỉ ghi **chỗ** khoá nằm, không ghi khoá.

## 🐞 Lỗi gốc: backup hỏng im lặng **bốn đêm liền**

Mọi thứ *trông như* đã cấu hình — script có, thư mục có, cron có. Nhưng:

```
Aug 06 02:30:01 crond: (/data/n8n/backup.sh) ERROR (getpwnam() failed - user unknown)
Aug 07 02:30:01 crond: (/data/n8n/backup.sh) ERROR (getpwnam() failed - user unknown)
Aug 08 02:30:01 crond: (/data/n8n/backup.sh) ERROR (getpwnam() failed - user unknown)
Aug 09 02:30:01 crond: (/data/n8n/backup.sh) ERROR (getpwnam() failed - user unknown)
```

**Nguyên nhân:** file trong `/etc/cron.d/` dùng định dạng **sáu trường** — có thêm **user** giữa lịch và lệnh. File đang dùng định dạng `crontab` năm trường:

```cron
# SAI — cron đọc đường dẫn script làm TÊN USER
30 2 * * * /data/n8n/backup.sh >> /data/backup/backup.log 2>&1

# ĐÚNG
30 2 * * * root /data/n8n/backup.sh >> /data/backup/backup.log 2>&1
```

Hai lỗi phụ đi kèm: `/data/backup/config` **chưa tồn tại**, và script `tar` một file `.env.example` **không có** — cả hai đều làm `set -e` dừng script.

### Vì sao nó im lặng được lâu như vậy

Cron ghi lỗi vào **journal hệ thống**, không vào `/data/backup/backup.log` — vì nó chưa từng chạy đến bước ghi log. Không ai nhìn journal. Thư mục `/data/backup/db` rỗng, nhưng **rỗng trông giống chưa tới giờ**.

⇒ Bài học: **thư mục backup rỗng phải được coi là báo động**, không phải trạng thái trung tính.

## Hạ tầng thật (2026-08-09)

| | |
|---|---|
| VM | `137.131.33.103` · `workizen-tongtai-be-volume` · Oracle Linux 9.8 · user `opc` |
| n8n | **2.33.3**, 6 container: `n8n` · `n8n-worker` · `n8n-caddy` · `postgres` · `redis` · `n8n-blackbox` |
| Compose | `/data/n8n/compose/` *(bản nguồn ở `/home/opc/infra-n8n/`)* |
| Dữ liệu n8n | bind `/data/n8n/n8ndata` → `/home/node/.n8n` |
| Postgres | db `n8n`, user `n8n`, **không public** |
| Đĩa backup | `/data` — **199 GB trống** / 200 GB |
| `N8N_ENCRYPTION_KEY` | đặt qua env trong `/data/n8n/compose/.env` |

## Backup lấy gì

| Thứ | Vì sao |
|---|---|
| `pg_dump` toàn bộ DB `n8n` | workflow + credential (**credential đã mã hoá**) |
| `docker-compose.yml` + `.env` | ⭐ chứa **`N8N_ENCRYPTION_KEY`** |
| `Caddyfile` | route + TLS |

⚠️ **Không có `N8N_ENCRYPTION_KEY` thì bản dump credential là rác.** Đó là lý do file cấu hình phải nằm trong backup, và cũng là lý do nó `chmod 600`.

Lịch: **02:30 hằng ngày**, giữ **14 ngày**.

## ✅ Bằng chứng đã chạy

```
$ sudo /data/n8n/backup.sh
2026-08-09T05:37:16+00:00 OK db=1.5M cfg=4.0K

$ sudo ls /data/backup/db/
n8n-20260809-053715.sql.gz   ← chạy tay
n8n-20260809-054001.sql.gz   ← CRON tự chạy

$ journalctl -u crond
05:40:01 CROND[…]: (root) CMD (/data/n8n/backup.sh …)
05:40:02 CROND[…]: (root) CMDEND
```

Không còn `user unknown`. Cron được chứng minh bằng **một lần nổ thật**, không bằng việc đọc lại file cấu hình.

## ✅ Restore đã thử — vào DB nháp, không đụng production

```
nguồn (DB đang chạy):     workflow=1  credential=2
đích  (n8n_restore_test): workflow=1  credential=2
tên workflow khôi phục:   GitHub → Delivery Events (canonical)
```

Sau đó xoá DB nháp; DB thật vẫn 1 workflow.

> Cùng kỷ luật ADR-TON-018: **không verify được bản an toàn ⇒ không xoá gì.** Một bản backup chưa thử khôi phục thì chưa phải backup.

## Thủ tục khôi phục thật

```bash
# 1 · dừng n8n (giữ postgres chạy)
sudo docker stop n8n n8n-worker

# 2 · khôi phục CẤU HÌNH TRƯỚC — khoá giải mã phải có trước dữ liệu
sudo tar xzf /data/backup/config/config-<TS>.tar.gz -C /data/n8n/compose

# 3 · khôi phục DB (dump đã có --clean --if-exists)
sudo gunzip -c /data/backup/db/n8n-<TS>.sql.gz \
  | sudo docker exec -i n8n-runtime-postgres-1 psql -U n8n -d n8n

# 4 · bật lại
sudo docker start n8n n8n-worker

# 5 · kiểm bằng thứ NHÌN THẤY được
curl -s -o /dev/null -w '%{http_code}\n' https://tongtai.workizen.net   # 200
```

⚠️ Bước 2 **trước** bước 3. Đổi thứ tự thì n8n khởi động với khoá cũ và mọi credential đọc ra rác.

## Còn thiếu — quyết định của Founder

Backup đang nằm **cùng VM** với thứ nó bảo vệ. Nó chống được *xoá nhầm* và *hỏng DB*, **không** chống được *mất VM*.

Đưa ra ngoài cần một đích (S3/Drive/máy khác) và một credential — đó là quyết định, không phải việc kỹ thuật. Ghi lại ở `13-FOUNDER-DECISIONS` của gói wave này.
