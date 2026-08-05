# Dựng lại Integration Runtime trên VM mới — và bốn thứ "đã xong" mà chưa xong

> **WTM-274 · Epic WTM-256 (PLATFORM-002).** Ngày **2026-08-05**.
> Founder xoá VM cũ và tạo VM mới. Tài liệu này ghi cái *khác*, không lặp lại
> cái giống — chi tiết kiến trúc vẫn ở `07`, `08`, `11`, `12`.
> ⚠️ Không chứa secret.

---

## Máy mới không phải bản sao của máy cũ

| | VM cũ (đã xoá) | VM mới |
|---|---|---|
| Tên · IP | `workforceos-usecases-layer` · 144.24.8.35 | **`workizen-tongtai-be-volume`** · **137.131.33.103** (nội bộ 10.0.0.235) |
| OS · user | Ubuntu 24.04 · `ubuntu` | **Oracle Linux 9.8** · **`opc`** |
| Gói | apt | **dnf** |
| Tường lửa | iptables + netfilter-persistent | **firewalld** |
| SELinux | không có | **Enforcing** |
| Ổ 200 GB | gắn thẳng, tự hiện | **iSCSI** — không tự hiện |
| Tài nguyên | 4 vCPU / 23 GB | 2 vCPU / 10 GB |

Năm dòng đầu đều là chỗ script triển khai sẽ **chết ngay dòng đầu tiên** nếu
giả định sai OS. Chúng không phải chi tiết nhỏ.

---

## ⭐ Bốn tín hiệu "đã xong" mà thật ra chưa xong

Đây là phần đáng giữ lại nhất của lần dựng này. Cả bốn đều **báo thành công**
trong khi trạng thái thật là chưa.

### 1. Console báo `Attached` — mà đĩa không tồn tại

Block volume gắn kiểu **iSCSI** không tự hiện thành `/dev/sdX`. Ba nguồn cùng
nói "xong":

| Nguồn | Nói gì | Sự thật |
|---|---|---|
| Oracle Console | `Attached` · 200 GB | chưa có phiên iSCSI nào |
| `lsblk` | chỉ thấy `/dev/sda` | — |
| `oci-iscsi-config sync` | **"All known devices are attached"** | vẫn không có đĩa |

Phải dò target thủ công ở `169.254.2.x:3260` rồi `iscsiadm -l`. Sau đó **bắt
buộc** thêm hai thứ, nếu không thì reboot xong `/data` biến mất **trong khi
container vẫn khởi động bình thường** — mất dữ liệu im lặng:

* `iscsiadm -m node -o update -n node.startup -v automatic`
* `_netdev` trong `/etc/fstab` (mount phải đợi mạng)

### 2. `oci-iscsi-config` nói "attached" — công cụ chính hãng cũng sai

Ghi riêng vì đây là công cụ Oracle tự phát hành cho đúng việc này. Tin nó là
mất thời gian đi tìm nhầm chỗ.

### 3. Năm trong sáu container `Up` — cái thứ sáu chết vì IP ghim cứng

`docker-compose.yml` ghim `10.0.0.52:9115:9115` — IP nội bộ của **máy cũ**.
Trên máy mới Docker từ chối: `cannot assign requested address`. Và nó là
container **duy nhất** chết trong khi 5 cái kia lên bình thường ⇒ rất dễ bỏ qua.

Sửa: đọc IP nội bộ từ chính máy đang chạy → `BLACKBOX_BIND`. Mặc định
`127.0.0.1` là **mặc định an toàn**: đoán sai thì Prometheus không scrape được,
chứ không bao giờ vô tình phơi cổng ra Internet.

### 4. `PATCH /rest/workflows/{id}` trả **200** — mà `active` vẫn `false`

n8n 2.x tách draft/published; REST nhận lệnh rồi bỏ qua. Phải publish qua
**Instance MCP** (`publish_workflow`). Bật MCP bằng
`PATCH /rest/mcp/settings {"mcpAccessEnabled": true}` rồi lấy khoá bằng
`POST /rest/mcp/api-key/rotate` — cả hai đều làm được qua REST, không cần bấm UI.

⇒ **Điểm chung của cả bốn: mã trả về 200 và chữ "attached" đều là *lời khai của
hệ thống*, không phải *bằng chứng*.** Cùng một kỷ luật §15 Task Order áp cho
container: chỉ đếm thứ đo được ở đầu ra.

---

## Mất gì

Ổ 200 GB mới **trống hoàn toàn** — không phải ổ cũ gắn lại. Nên:

| | |
|---|---|
| Workflow + credential n8n cũ | **mất** |
| `N8N_ENCRYPTION_KEY` cũ | mất (khoá mới sinh trên máy) |
| Bản backup cũ | mất — **nó nằm trên chính cái ổ đã biến mất** |
| Cấu hình hạ tầng | **còn** — `workforceos-usecases:infra/n8n` (WTM-259, làm trước đó 3 ngày) |
| PAT GitHub · secret webhook | **còn** — `~/.workizen-secrets/` trên máy Founder |

WTM-259 viết: *"mất máy là mất cả hai"* (cấu hình + backup), và đưa cấu hình vào
git để cắt một nửa rủi ro. Ba ngày sau máy mất thật. **Nửa được cứu đúng là nửa
đã cứu; nửa còn lại — bản backup — vẫn mất, đúng như đã cảnh báo.**

Bài học chưa đóng: **bản backup nằm cùng chỗ với thứ nó bảo vệ thì không phải là
backup.** Cần đẩy ra ngoài máy (Object Storage) mới đóng được.

---

## Bằng chứng — kiểm lại đúng bốn tính chất của WTM-268

| Kiểm | Kết quả |
|---|---|
| Không `Authorization` | **403** |
| Có token | **200** · 8,0s · 237 KB · `truncated: false` |
| Số đọc được | **211 commit · 155 PR merged · 0 release** |
| Gọi hai lần | **366 `event_id` trùng · 0 lệch** |
| Cố truyền `repo` khác | bị bỏ qua — **ghim server-side** |
| HTTPS | 200 · Let's Encrypt CN `tongtai.workizen.net` · hạn **03/11/2026** |
| Cô lập | chỉ 22/80/443 ra ngoài; Postgres · Redis · blackbox **không** phơi công khai |
| SELinux | **0 denial** |

211/155 tăng đúng 3 so với 208/152 hôm 02/08 — ba PR hạ tầng đã merge.
**Release vẫn 0.** Tín hiệu không đổi.

---

## ⚠️ Chưa kiểm

| | |
|---|---|
| **Reboot** | `node.startup=onboot` + `_netdev` + `nofail` đã đặt, nhưng **chưa reboot thật**. Đây là chỗ hỏng đắt nhất nếu sai: `/data` không mount mà container vẫn lên ⇒ n8n chạy trên ổ rỗng |
| Backup ra ngoài máy | chưa có — xem §Mất gì |
| Giám sát | Prometheus/Grafana trên VM observer **đang dừng từ 03/08**, và job `blackbox-n8n` vẫn trỏ `10.0.0.52` (máy đã xoá). Cảnh báo WTM-267 hiện **không hoạt động** |

Ba dòng này là nợ đã biết, ghi ra để không ai tưởng hệ thống đang được canh.
