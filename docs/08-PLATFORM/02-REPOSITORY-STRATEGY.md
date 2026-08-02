# Repository Strategy — đặt backend ở đâu

> **WTM-250 · Phase 2 của PLATFORM-001.**
> Trạng thái: **Draft — có khuyến nghị rõ, cần Founder xác nhận.**

---

## Điều kiện đầu vào (từ Phase 0, đã kiểm bằng lệnh)

| Sự thật | Hệ quả |
|---|---|
| `workforceOS-usecases` **đã tồn tại**, 1 commit, chỉ README + `.gitignore` + SSH key | Luật Founder: đã tồn tại thì **không tạo repo mới** |
| README của nó tự khai mục đích: chứa `usecases/` + `diagrams/` | Khác thứ Task Order muốn (Backend · Infra · Docker · n8n · Deployment · Secrets · Workflow) |
| `workizen-tongtai-mobile` là repo Flutter thuần, CI = `dart format` + `flutter analyze` + `flutter test` | Nhét backend vào đây làm CI phải học một hình dạng thứ hai |
| Hạ tầng thật đang nằm rải ở `workforceos-observer-layer` (compose) và `workforceos-virtual-team-orchestration` (compose + terraform) | Đã có **hai** chỗ chứa infra; thêm chỗ thứ ba là tạo phân mảnh |

---

## Ba phương án, và cái tôi khuyến nghị

### ❌ A. Nhét `/backend` vào repo Tổng Tài

**Bỏ.** Không phải vì "mono-repo xấu", mà vì ba lý do cụ thể của repo này:

* CI hiện tại chạy trên **mọi** PR với ba lệnh Flutter. Thêm backend nghĩa là mỗi
  PR sửa n8n workflow cũng kéo theo `flutter test` (~90 giây, 1818 test) và
  ngược lại — hoặc phải viết path-filter, tức thêm một chỗ nữa để cấu hình sai.
* Repo Tổng Tài đang có **quyền tự merge khi CI xanh** (grant riêng của Founder).
  Backend chạm hạ tầng production của `workizen.net` — đó là mức rủi ro khác, và
  gộp vào một repo là gộp luôn hai chính sách merge.
* `.gitignore`, governance test, `docs/` của repo này đều viết cho một app
  Flutter. Trộn vào sẽ làm mọi luật hiện có phải kèm "trừ thư mục backend".

### ✅ B. Dùng `workforceOS-usecases` làm repo Platform — **khuyến nghị**

Repo đã tồn tại, **gần như trống** (1 commit), và **đã giữ sẵn SSH key Oracle** —
tức nó vốn đã đứng gần vai trò hạ tầng hơn là vai trò tài liệu use-case.

Việc phải làm: **đổi tên vai trò trong README** (một commit), rồi quy hoạch:

```
workforceOS-usecases/            ← đề nghị đổi tên hiển thị thành "Workizen Platform"
├── README.md                    vai trò mới, nói rõ nó KHÔNG chứa business logic
├── docs/
│   ├── platform/                kiến trúc, ranh giới, ADR hạ tầng
│   ├── connectors/              catalog + spec từng connector
│   └── runbooks/                triển khai, khôi phục, xoay khoá
├── infra/
│   ├── n8n/                     compose + Caddy snippet cho n8n
│   └── env/                     .env.example (KHÔNG bao giờ .env thật)
├── workflows/                   n8n workflow xuất ra JSON, có version
├── usecases/                    ← GIỮ LẠI mục đích cũ, không xoá
└── oracle-key/                  đã gitignore sẵn
```

Vì sao giữ `usecases/`: mục đích cũ **không mâu thuẫn** với mục đích mới. Một
repo nền tảng chứa cả "bài toán thật của người dùng" và "hạ tầng phục vụ bài
toán đó" là hợp lý — và xoá thứ Founder từng lập ra là quyết định không cần thiết.

### ⚠️ C. Repo mới `workizen-platform`

Sạch nhất về mặt tên gọi, nhưng **vi phạm luật Phase 0** ("đã tồn tại thì không
tạo mới, không trùng lặp"). Chỉ nên chọn nếu Founder muốn `workforceOS-usecases`
giữ nguyên bản chất tài liệu.

---

## Ranh giới giữa ba repo hạ tầng (để không phân mảnh thêm)

Đã có hai repo chứa infra. Đề nghị phân vai rõ, **không di chuyển gì cả**:

| Repo | Giữ | Không giữ |
|---|---|---|
| `workforceos-observer-layer` | quan sát hệ thống: Prometheus · Grafana · Langfuse · Portainer · **Caddy gateway dùng chung** | connector, business |
| `workforceos-virtual-team-orchestration` | OpenProject · Open WebUI · terraform hiện có | connector |
| **`workforceOS-usecases`** (vai trò mới) | **n8n · connector · vendor/connector catalog · runbook tích hợp** | mọi thứ observability, mọi business logic |

Điểm chạm duy nhất giữa chúng: **Caddy** — n8n cần một subdomain, và Caddy do
observer-layer sở hữu. Đây là **phụ thuộc thật, phải khai** chứ không lờ đi;
chi tiết ở `03-N8N-RUNTIME-AND-ORACLE-VM.md`.

---

## Còn `docs/` của Tổng Tài thì sao

Tài liệu PLATFORM-001 hiện đang nằm ở `workizen-tongtai-mobile/docs/08-PLATFORM/`
vì đó là nơi Epic đang chạy và là nơi có lịch sử quyết định (ADR-TON-*).

**Đề nghị:** giữ nguyên tài liệu **kiến trúc chung** ở đây (vì nó nói về ranh
giới của app), và khi repo Platform nhận vai trò mới thì **runbook + compose +
workflow** sinh ra ở đó. Không copy chéo — mỗi tài liệu **một chủ**, đúng kỷ luật
one-source repo này đã trả giá để học.
