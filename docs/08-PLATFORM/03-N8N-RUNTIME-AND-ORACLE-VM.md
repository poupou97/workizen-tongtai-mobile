# n8n Integration Runtime + hạ tầng Oracle — sống chung với máy đang phục vụ khách

> **WTM-251 · Phase 4 + 5 của PLATFORM-001.** Gộp hai phase vì Phase 0 chứng
> minh chúng là **một** bài toán.
> Trạng thái: **Draft — cần Founder review (có 2 quyết định).**

---

## Sự thật phải nhìn thẳng trước khi quy hoạch

Task Order viết Phase 5 như một việc provisioning: *"Founder chọn Oracle Cloud,
4 vCPU, 24GB. VM này sẽ là backend đầu tiên."*

**Nhưng VM đó đã tồn tại và đang chạy production.**

| | |
|---|---|
| IP | `137.131.35.185` |
| OS | Ubuntu 24.04.4 LTS (aarch64) |
| CPU | 4× Neoverse-N1 |
| RAM | **24 GB** |
| Disk | **45 GB**, README đã ghi *"block volume required before Phase 3"* |
| Đang phục vụ | `workizen.net` + các subdomain |

Đang chạy trên đó: **Caddy** (gateway :80/:443) · Portainer · **Keycloak** +
Postgres · Prometheus · Grafana · node-exporter · cAdvisor · **Langfuse** (web,
worker, Postgres, **ClickHouse**, Redis, MinIO) · **OpenProject** + Postgres +
cache · Open WebUI · **Workizen 3D**.

⇒ Câu hỏi thật không phải *"dựng VM thế nào"* mà **"thêm một dịch vụ nữa vào
máy này có an toàn không, và nếu có thì với ranh giới nào"**.

---

## Ước lượng công suất — và chỗ tôi KHÔNG biết

**Tôi chưa SSH vào máy** (Founder chưa yêu cầu, và đây là bước quy hoạch). Nên
phần dưới là **ước lượng từ danh sách dịch vụ**, không phải số đo. Muốn chắc thì
một lệnh là đủ: `docker stats --no-stream` + `df -h`.

| Dịch vụ | RAM thường thấy |
|---|---|
| ClickHouse (Langfuse) | 2–4 GB — **hộ tiêu thụ lớn nhất** |
| Keycloak + Postgres | 1.5–2.5 GB |
| OpenProject + Postgres + cache | 2–3 GB |
| Prometheus + Grafana + exporters | 1–2 GB |
| Langfuse web + worker + Redis + MinIO | 1.5–2.5 GB |
| Open WebUI | 0.5–1 GB |
| Caddy + Portainer + Workizen 3D | ~0.5 GB |
| **Ước tính đã dùng** | **9–15 GB / 24 GB** |
| **n8n (queue mode nhẹ, 1 worker)** | **0.5–1 GB** |

**RAM gần như chắc chắn đủ.** Thứ tôi lo là **đĩa**: 45 GB, ClickHouse và
Prometheus đều là dạng phình theo thời gian, và README đã tự cảnh báo cần block
volume **từ trước** khi có n8n. n8n thêm một Postgres nữa (hoặc dùng SQLite) +
log thực thi — không lớn, nhưng là giọt thêm vào một cái ly đã gần đầy.

> **Việc phải làm trước khi triển khai (không phải bây giờ):** đo thật bằng
> `df -h` và `docker stats`, rồi gắn block volume nếu `/` dưới 30% trống.

---

## Kiến trúc đề xuất cho n8n

```
Internet :443
     │
[Caddy]  ← observer-layer sở hữu (KHÔNG sửa trực tiếp, xem §Ranh giới)
     ├── workizen.net              → Workizen 3D
     ├── grafana.workizen.net      → observer
     └── n8n.workizen.net          → n8n   ← THÊM MỚI
                                      │
                          ┌───────────┴───────────┐
                          │ n8n (queue mode)      │
                          │  · webhook endpoint   │
                          │  · scheduler          │
                          │  · OAuth callback     │
                          └───────────┬───────────┘
                                      │ credential đã mã hoá
                          ┌───────────▼───────────┐
                          │ n8n Postgres (riêng)  │  ⚠️ KHÔNG dùng chung
                          └───────────────────────┘  Keycloak/OpenProject DB
```

**Bốn quyết định kỹ thuật, kèm lý do:**

1. **Postgres riêng cho n8n**, không dùng chung instance có sẵn. Dùng chung
   nghĩa là một `DROP` nhầm hoặc một lần nâng cấp n8n có thể chạm dữ liệu
   Keycloak — tức chạm đăng nhập của cả hệ sinh thái.
2. **Queue mode ngay từ đầu** (main + 1 worker + Redis). Không phải vì tải, mà
   vì **đổi từ `main` sang queue về sau là một lần migrate**; bắt đầu đúng rẻ hơn.
3. **`N8N_ENCRYPTION_KEY` nằm ngoài compose**, trong `.env` chỉ máy chủ có. Đây
   là khoá giải mã **toàn bộ credential** trong n8n — mất nó là mất mọi kết nối;
   lộ nó là lộ mọi kết nối.
4. **Webhook đi qua Caddy, không mở port riêng.** README observer-layer đã ghi
   luật: *"No public ports except 80/443 (via Caddy)"* — n8n không được là ngoại lệ.

---

## Ranh giới cứng: n8n KHÔNG được là gì

Founder đã nói: *"Không phải Business Database. Không phải Business Rule
Engine."* Cụ thể hoá thành thứ kiểm được:

| n8n **được** | n8n **không được** |
|---|---|
| giữ credential nền tảng ngoài (đã mã hoá) | giữ Order/Product/Customer/Transaction |
| nhận webhook, chuẩn hoá payload | quyết định payload đó *nghĩa là gì* |
| lên lịch kéo dữ liệu | quyết định *khi nào nên báo người bán* |
| retry, backoff, dead-letter | tính doanh thu/lợi nhuận/điểm cơ hội |
| ánh xạ trường sàn → **mã canonical** | tạo mã canonical mới |
| ghi lịch sử thực thi (để gỡ lỗi) | ghi lịch sử **kinh doanh** (đó là Journey/Timeline trên máy) |

**Phép thử một câu:** nếu xoá sạch n8n và dựng lại từ compose + `.env`, người bán
**không mất một dữ liệu kinh doanh nào**. Nếu có mất — n8n đã trở thành Business
Database, và ranh giới đã vỡ.

---

## Ranh giới vận hành với observer-layer

Caddy là **của observer-layer**, và README của nó có dòng cấm rõ ràng về việc sửa
`/srv/workizen-3d/` không có backup + authorization. n8n cần một dòng route
trong Caddyfile ⇒ đây là **phụ thuộc chéo repo thật sự**.

Đề nghị: n8n **không tự sửa Caddyfile**. Thay vào đó xuất một **snippet** trong
repo Platform, và việc chèn vào Caddyfile là một bước có chủ đích trong runbook,
kèm backup — đúng luật *"Caddyfile backup before every edit"* observer-layer đã tự đặt.

---

## Hai quyết định cần Founder

| | Quyết định | Đề xuất | Vì sao cần anh |
|---|---|---|---|
| **P-1** | n8n **cùng VM** hay **VM thứ hai**? | **Cùng VM** — RAM đủ, và VM thứ hai nghĩa là thêm một máy phải vá, phải giám sát, phải trả tiền | Nếu Oracle free tier đã dùng hết hạn mức thì VM thứ hai là chi phí thật |
| **P-2** | Trước khi thêm n8n, có gắn **block volume** không? | **Có** — README đã cảnh báo từ trước khi có n8n | Tốn tiền (nhỏ) và cần thao tác trên Oracle Console — chỉ anh làm được |

---

## Việc KHÔNG làm ở phase này

Không triển khai. Không viết compose thật. Không chạm máy chủ. Không K8s, không
microservice, không event bus, không CQRS — đúng ràng buộc Founder.
