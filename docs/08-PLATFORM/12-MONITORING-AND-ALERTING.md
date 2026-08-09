# Giám sát và cảnh báo — n8n Integration Runtime

> ## 🗄️ TÀI LIỆU LỊCH SỬ — hệ mô tả ở đây KHÔNG còn tồn tại
>
> **Founder gỡ Grafana và Prometheus ngày 2026-08-09 để giảm tải hệ thống.**
> Đây là quyết định đã chốt.
>
> Kiểm trên VM chạy n8n cùng ngày: `tcpdump` cổng 9115 trong 100 giây **không
> một kết nối nào**; `iptables` không có luật mở 9115; **không có**
> `node_exporter`. Container `n8n-blackbox` vẫn chạy nhưng không ai gọi tới.
>
> ⇒ Không còn cảnh báo tự động cho n8n. Giữ tài liệu này để hiểu **đã từng dựng
> gì và vì sao**, không để làm hiện trạng. **Không** đề xuất dựng lại.



> **WTM-267 (K · Monitoring and Operations) · Epic WTM-256 (PLATFORM-002).**
> Ngày **2026-08-02**. Đo thật qua SSH, không ước lượng.
> ⚠️ Không chứa secret.

---

## Điều đã có sẵn (và vì sao không dựng stack thứ hai)

VM observer đã chạy **Grafana · Prometheus · Loki · Promtail · node-exporter ·
cAdvisor** với **11 alert rule** và một contact point email
(`workforceos-email`) đã hoạt động.

⇒ Đúng thứ tự đánh giá của Founder (**Native → Managed SaaS → OSS → Self-hosted
→ VM/K8s**): thứ đã có sẵn và đang chạy thắng thứ dựng mới. Không thêm
Alertmanager, không thêm Uptime Kuma, không thêm dịch vụ trả phí.

---

## ⭐ Đính chính: bốn máy, không phải hai

`07-ORACLE-VM-AUDIT.md` viết *"có HAI máy"*. Prometheus cho thấy nó đang scrape
**bốn** node-exporter, tất cả đều `up`:

| instance | nodename | vai trò |
|---|---|---|
| `vm137-observer` | — | observer / production `workizen.net` |
| `vm129-dblayer` | — | data layer (còn chạy cả cAdvisor) |
| `vm-orchestration` | `workizen-visual-team-orchestration` | orchestration |
| **`vm-usecases`** | `workforceos-usecases-layer` | ⭐ nơi n8n chạy |

Audit cũ dựa trên hai máy tôi SSH được bằng khoá đang có; hai máy còn lại lộ ra
từ **cấu hình giám sát**, không từ thư mục khoá. Kết luận đặt n8n ở VM usecase
**không đổi** — nhưng bức tranh hạ tầng thì rộng hơn tài liệu cũ mô tả.

---

## Lỗ hổng thật sự cần bịt

Rule `Server Down (node-exporter)` đã bắt được **VM chết**. Nó **không** bắt được
trường hợp nguy hiểm hơn và dễ xảy ra hơn:

> **VM vẫn sống, node-exporter vẫn trả metric, nhưng n8n / Caddy / TLS hỏng.**

Với trường hợp đó mọi biểu đồ CPU–RAM–đĩa đều xanh trong khi
`tongtai.workizen.net` trả 502. Giám sát tài nguyên không thấy được — chỉ có
kiểm tra **từ ngoài, đúng đường người dùng đi** mới thấy.

---

## Đã thêm gì

```
blackbox-exporter (trên VM usecase, KHÔNG phải VM production)
   │  chỉ nghe 10.0.0.52:9115 — không phơi ra Internet
   ▼
Prometheus (VM observer) — job blackbox-n8n, 60s
   │  probe https://tongtai.workizen.net/healthz
   ▼
Grafana alert rules ──► contact point email đã có sẵn
```

| Thành phần | Đặt ở đâu | Vì sao |
|---|---|---|
| `prom/blackbox-exporter:v0.25.0` | **VM usecase** | không thêm container nào vào VM production |
| job `blackbox-n8n` | prometheus.yml | **chỉ thêm**, không sửa dòng cũ |
| `wz-tongtai-n8n-down` | Grafana | `probe_success < 1` giữ **5 phút** ⇒ critical |
| `wz-tongtai-cert-expiry` | Grafana | chứng chỉ còn **< 14 ngày** ⇒ warning |

Hai rule bù nhau đúng chỗ: **`Server Down` bắt VM chết · `n8n DOWN` bắt VM sống
mà dịch vụ hỏng.** Không rule nào thừa.

### Vì sao có rule chứng chỉ

Caddy tự gia hạn Let's Encrypt. *"Tự động"* nghĩa là **không ai nhìn** — và ngày
nó hỏng thì triệu chứng đầu tiên là HTTPS chết hàng loạt, đúng lúc không ai ngờ.
Chứng chỉ hiện còn **90 ngày**; ngưỡng 14 ngày cho ba lần thử gia hạn nữa mới
báo động.

---

## Bằng chứng

| Kiểm | Kết quả |
|---|---|
| Probe từ VM observer | `probe_success 1` · `probe_http_status_code 200` |
| Chứng chỉ | còn **90 ngày** (`probe_ssl_earliest_cert_expiry`) |
| `/healthz` của n8n | `{"status":"ok"}` |
| Prometheus nhận job | target `blackbox-n8n` → **up**, tổng 9 target |
| Reload Prometheus | **SIGHUP** — container vẫn `Up 4 weeks`, **không restart** |
| 5 container n8n cũ | vẫn `Up About an hour` — **không bị restart** khi thêm blackbox |
| Rule vào Grafana | `alert_rule` = **13 dòng**, cả hai uid `wz-tongtai-*` có mặt, **không paused** |
| Rule đang đánh giá thật | `alert_rule_state` của `wz-tongtai-n8n-down` chứa `probe_success` + `blackbox-n8n`, trạng thái **Normal** |
| Grafana sau restart | khoẻ lại sau **6 giây**, `finished to provision alerting` không lỗi |
| Tài khoản admin mặc định | `admin/admin` → **401** (không dùng được — điều tốt) |

---

## ⚠️ Điều CHƯA chứng minh, và tôi không giấu

**Chưa chạy diễn tập tắt n8n để xem cảnh báo có thật sự kêu và email có tới không.**

Diễn tập đó cần dừng n8n khoảng 8 phút; thao tác bị guardrail chặn và tôi **không
lách**. Vậy nên hiện trạng chính xác là:

| | |
|---|---|
| Rule tồn tại, không paused, đang đánh giá đúng chuỗi dữ liệu | ✅ đã chứng minh |
| Đường gửi email hoạt động | ✅ **gián tiếp** — dùng chung contact point với 11 rule cũ đang gửi |
| Rule chuyển sang `Alerting` khi n8n chết | ❌ **chưa chứng minh** |
| Email thật rơi vào hộp thư Founder | ❌ **chưa chứng minh** |

Đây đúng là khoảng cách mà §15 Task Order cảnh báo — *"không coi container chạy là
hoàn thành"*. Cấu hình đúng và cảnh báo thật sự kêu là **hai chuyện khác nhau**,
và tôi mới chứng minh được chuyện thứ nhất.

**Quyết định của Founder (2026-08-02): KHÔNG diễn tập.** Được hỏi giữa ba lựa
chọn — chạy diễn tập ~8 phút downtime · để treo ở QA · chờ tới khi có sự cố thật
— Founder chọn **chờ sự cố thật**.

⇒ Đây là một **đánh đổi có chủ ý, không phải việc bỏ quên**. Ghi lại để người đọc
sau không tưởng là sót:

| | |
|---|---|
| Được gì | không có downtime chủ ý; tiết kiệm thời gian ngay lúc này |
| Mất gì | **lần n8n chết thật sẽ là lần kiểm đầu tiên.** Nếu rule sai, ta phát hiện đúng lúc đang cần nó nhất |
| Rẻ nhất khi nào | **bây giờ** — n8n chưa có người dùng, chưa có connector nào chạy theo lịch |

Kịch bản diễn tập vẫn giữ, chạy được bất cứ lúc nào: dừng container `n8n`, xem
`probe_success` xuống 0, rule đi `Normal → Pending → Alerting`, email tới, bật lại.

---

## Đường lùi

| Thay đổi | Cách gỡ | Ảnh hưởng khi gỡ |
|---|---|---|
| blackbox trên VM usecase | `docker compose rm -sf blackbox` | không — không ai phụ thuộc |
| iptables 9115 | `iptables -D INPUT -p tcp -s 10.0.0.0/16 --dport 9115 -j ACCEPT` | không |
| job Prometheus | `cp /opt/backup/prometheus-<TS>.yml` + `docker kill -s HUP` | không restart |
| 2 rule Grafana | `cp /opt/backup/metric-alert-rules-<TS>.yaml` + restart Grafana | ~6s UI |
| Compose VM usecase | `cp /opt/backup/docker-compose-<TS>.yml` | — |

Mọi bản backup đã tạo **trước** khi sửa, nằm ở `/opt/backup/` trên đúng máy tương ứng.

### Một cái bẫy đã sập và cách tránh lần sau

Lần chèn đầu tiên `tee -a` đẩy service blackbox vào **cuối file**, mà cuối file
là khối `networks:` chứ không phải `services:` — Docker báo
`networks.blackbox additional properties not allowed`. Khôi phục từ backup rồi
chèn bằng script định vị đúng cuối khối `services:`.

⇒ **`>>` vào file YAML là đặt cược rằng khối cần thêm nằm cuối file.** Ở đây nó
không nằm cuối. Backup trước khi sửa là thứ đã biến việc này thành một phút phiền
phức thay vì một sự cố.
