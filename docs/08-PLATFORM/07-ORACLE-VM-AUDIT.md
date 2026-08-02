# Oracle VM Audit — hai máy, và n8n thuộc về máy thứ hai

> **WTM-256 (PLATFORM-002) · Wave 1.** Đo thật qua SSH ngày 2026-08-02, không
> phải ước lượng.
> ⚠️ Repo private. Không ghi private key, không ghi nội dung secret.

---

## ⭐ Đính chính quan trọng so với PLATFORM-001

PLATFORM-001 (WTM-248) kết luận *"VM ở Phase 5 đã tồn tại và đang tải nặng"* và
xếp **R10 đầy đĩa** là rủi ro CAO. Kết luận đó dựa trên **một** máy — máy
observer.

**Founder đính chính 2026-08-02: có HAI máy.** n8n thuộc về máy thứ hai, và máy
đó gần như trống.

⇒ **R10 (đầy đĩa) và R12 (sập Caddy production) không còn áp dụng** cho việc
triển khai n8n. Đây là thay đổi lớn nhất so với kế hoạch cũ, và nó theo hướng
tốt.

---

## Hai máy

| | **VM Observer** (production) | **VM Usecase** ⭐ đích của n8n |
|---|---|---|
| Hostname | `workforcesos-observer-layer` | `workforceos-usecases-layer` |
| Public IP | `137.131.35.185` | **`144.24.8.35`** |
| Private IP | — | **`10.0.0.52`** |
| OS | Ubuntu 24.04.4 LTS | Ubuntu 24.04.4 LTS |
| Kiến trúc | aarch64 | aarch64 |
| CPU | 4 | 4 |
| RAM | 24 GB (đã tải nặng) | **23 GB — còn trống 20 GB** |
| Disk | 45 GB, đã cảnh báo cần block volume | **45 GB — còn trống 41 GB (dùng 9%)** |
| Swap | — | **0 B** ⚠️ |
| Docker | có, đang chạy ~20 container | **CHƯA CÀI** |
| Uptime | — | 17 ngày |
| Đang phục vụ | `workizen.net` + subdomain | **không phục vụ gì** |
| SSH key hoạt động | `workforceos-observer-layer/oracle-key/ssh-key-2026-06-10.key` | `workforceOS-usecases/oracle-key/ssh-key-2026-06-11.key` |

---

## VM Usecase — số đo thật

```
Ubuntu 24.04.4 LTS · aarch64 · 4 vCPU · uptime 17 ngày
Mem:   23Gi total · 710Mi used · 20Gi free · 22Gi available
Swap:  0B
Disk:  /dev/sda1  45G · 3.7G used · 41G avail · 9%
Inode: 5.98M total · 165K used · 3%
Docker: chưa cài
```

**Cổng đang lắng nghe:** 22 (SSH) · 111 (rpcbind) · 53 (systemd-resolved, chỉ
loopback) · 9100 (node_exporter) · 9080 · 41379

`9100` là node_exporter — VM observer đang **scrape metrics** của máy này. Đó là
phụ thuộc chéo **đã tồn tại**, và nó có ích: n8n triển khai ở đây sẽ **tự động
nằm trong hệ giám sát sẵn có**, không cần dựng Prometheus thứ hai.

---

## ⛔ Chặn kỹ thuật đã tìm ra: 80/443 đang bị chặn

```
iptables INPUT:
  ACCEPT  tcp dpt:22                       ← SSH
  ACCEPT  tcp dpt:9100  from 10.0.0.0/16   ← Prometheus nội bộ
  REJECT  all                              ← MỌI THỨ CÒN LẠI
```

Kiểm từ ngoài: `144.24.8.35:80` và `:443` đều **Connection refused**.

Nghĩa là muốn `tongtai.workizen.net` chạy được, phải mở 80/443 ở **hai tầng**:

1. **iptables trên VM** — tôi làm được qua SSH, có rollback (lưu `iptables-save`
   trước khi sửa).
2. **Oracle Cloud Security List / NSG** — ⚠️ **tôi KHÔNG có OCI CLI cấu hình**
   trên máy này. Nếu security list cũng chặn thì cần anh mở trong Oracle Console.

**Chưa biết tầng 2 có chặn không** — chỉ biết chắc sau khi mở tầng 1 rồi thử lại
từ ngoài. Đây là bước tiếp theo, làm được ngay và **không đụng gì tới production**.

---

## Kết luận công suất cho n8n

| Thành phần | RAM dự kiến | Disk dự kiến |
|---|---|---|
| n8n (main) | 300–500 MB | ~200 MB image |
| n8n worker (queue mode) | 300–500 MB | dùng chung image |
| PostgreSQL riêng cho n8n | 200–400 MB | 1–5 GB theo thời gian |
| Redis (queue) | 50–150 MB | nhỏ |
| Caddy | 30–60 MB | nhỏ |
| **Tổng** | **~1–1.6 GB / 20 GB rảnh** | **~2–6 GB / 41 GB rảnh** |

**Kết luận: thừa sức.** Không cần block volume. Không cần VM mới. Không phát
sinh chi phí Oracle.

⚠️ **Một việc nên làm:** máy **không có swap**. Với 20 GB rảnh thì không nguy
hiểm, nhưng thêm 2 GB swapfile là bảo hiểm rẻ cho lúc container rò bộ nhớ.

---

## Vì sao đặt n8n ở máy này tốt hơn hẳn máy observer

1. **Không rủi ro với `workizen.net`.** Không đụng Caddy production, không đụng
   Keycloak, không đụng ClickHouse. Ba rủi ro CAO của kế hoạch cũ biến mất.
2. **Ranh giới sạch.** Máy observer = quan sát; máy usecase = tích hợp. Đúng
   phân vai đã đề xuất ở `02-REPOSITORY-STRATEGY.md`.
3. **Đúng tên.** Máy tên `workforceos-usecases-layer`, repo tên
   `workforceOS-usecases` — hạ tầng và mã nguồn khớp nhau.
4. **Giám sát có sẵn.** node_exporter đã chạy, observer đã scrape.
5. **Đĩa rộng gấp 11 lần chỗ trống của máy kia** (41 GB vs ~4 GB ước tính).

---

## SSH key — phát hiện về vệ sinh khoá

Có **5 file khoá riêng biệt** rải ở nhiều thư mục, và **hai file trùng tên nhưng
khác nội dung**:

| Vị trí | Fingerprint (rút gọn) | Vào được máy nào |
|---|---|---|
| `oracle-key/ssh-key-2026-06-09.key` | `qvJcvz…` | ❌ không máy nào (đã thử cả hai) |
| `oracle-key-orchestration/ssh-key-2026-06-10.key` | `Q68iHC…` | ❌ |
| **`observer-layer/oracle-key/ssh-key-2026-06-10.key`** | `I1wzzi…` | ✅ **VM Observer** |
| `workizen-3d/oracle-key/ssh-key-2026-06-10.key` | `I1wzzi…` | ✅ (bản sao của dòng trên) |
| **`workforceOS-usecases/oracle-key/ssh-key-2026-06-11.key`** | `FUapun…` | ✅ **VM Usecase** |
| `~/.ssh/workforceos-key.pem` · `-us.pem` | khác | ❌ với hai máy này |

⚠️ **Hai file cùng tên `ssh-key-2026-06-10.key` nhưng nội dung khác nhau** —
một bản vào được observer, một bản không. Đây là thứ dễ gây nhầm nhất: đọc tên
file thì tưởng cùng một khoá.

**Đề nghị (chưa làm, cần Founder duyệt vì đụng quyền truy cập):**
* giữ nguyên hai khoá đang dùng được, **không thu hồi gì** cho tới khi có đường
  vào thay thế đã kiểm chứng;
* các khoá không vào được máy nào ⇒ archive, không xoá vội;
* ghi runbook nói **khoá nào cho máy nào** — hôm nay phải thử 8 lần mới biết.
