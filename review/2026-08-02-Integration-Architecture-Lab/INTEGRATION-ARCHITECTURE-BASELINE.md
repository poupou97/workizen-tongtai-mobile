# Integration Architecture Baseline — thứ đang có, không phải thứ mong muốn

> **WTM-239 · Wave 0 của Epic WTM-238** (Founder Task Order 2026-08-02).
> Mọi hộp dưới đây trỏ tới **file thật**. Một bản đồ vẽ theo trí nhớ sẽ nói dối
> ở đúng chỗ quan trọng — bài học WTM-218: một màn mồ côi sống sót qua **sáu**
> lượt governance vì không lượt nào hỏi *"người bán tới đó bằng đường nào?"*

**Chốt tại:** `main` @ `90a40ef` · schema **v16** · 1818 tests.

---

## 1. Đường dữ liệu hiện tại — một chiều, không có nhánh nào từ bên ngoài

```
                                  ┌─────────────────────────────┐
   người bán gõ  ──────────────►  │  UI (ui/screens, 35 màn)    │
                                  └──────────────┬──────────────┘
                                       ghi │            │ đọc
                            runTongtaiAction │            │ ScreenDataController
                                  ┌──────────▼────────────▼─────┐
                                  │  Repository (ADR-TON-008)   │
                                  └──────────────┬──────────────┘
                                                 │
                                  ┌──────────────▼──────────────┐
                                  │  Drift / SQLite — 20 bảng   │
                                  │  lib/database/tables/       │
                                  └──────────────┬──────────────┘
                                                 │
                    ┌────────────────────────────┼───────────────────────┐
                    │                            │                       │
        ┌───────────▼──────────┐   ┌─────────────▼────────────┐  ┌──────▼───────┐
        │ Capability Context   │   │  Context Provider ×8     │  │ Analytics    │
        │ (on-demand, nặng)    │   │  → BusinessContext       │  │ (thuần)      │
        │ revenue · customer   │   │  (summary nhẹ, v-hoá)    │  │              │
        └───────────┬──────────┘   └─────────────┬────────────┘  └──────────────┘
                    └──────────────┬─────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  Rule Twin — AUTHORITATIVE  │  chạy không cần AI/mạng/khoá
                    │  RuleTwinResult<T>          │  result==null ⟺ insufficient
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  AI Router → provider       │  AI **chỉ giải thích**
                    │  BYOK / Local (Ollama)      │  không được đổi kết luận
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  AiToolRuntime              │  ⛔ `DisabledAiToolRuntime`
                    │  (thiết kế sẵn, CHƯA bật)   │     — throw, có test chặn
                    └─────────────────────────────┘
```

| Hộp | File | Ghi chú |
|---|---|---|
| Repository seam | `lib/features/tongtai/*/\*_repository.dart` | ADR-TON-008; màn nói chuyện với interface |
| Ghi có bảo vệ | `core/screen_data_controller.dart` → `runTongtaiAction` | ADR-TON-017 |
| Đọc có trạng thái | cùng file → `ScreenDataController` | 6 trạng thái, refresh lỗi **giữ dữ liệu cũ** |
| Bảng | `lib/database/tables/` (20 file) | schema v16, `migrations/tongtai_migrations.dart` |
| Context Provider | `features/tongtai/*/\*_context.dart` | mỗi capability **một** provider |
| BusinessContext | `metrics/business_context.dart` | 8 slice + `health`, có `version` + `generatedAt` |
| Capability Context | `capability/`, `predictive/` | on-demand, **không** nhét vào BusinessContext |
| Rule Twin | `predictive/rule_twin.dart` | `revenue-forecast/1` · `customer-risk/1` · `business-alerts/1` |
| AI Router | `ai/workizen_ai_router.dart` | BYOK + Local; Managed chờ Phase 3 |
| Ranh giới AI | `ai/ai_runtime_boundary.dart:63,91` | `AiToolRuntime` khai báo, `DisabledAiToolRuntime` chặn |
| Khoá BYOK | `ai/tongtai_ai_key_store.dart` | **Keychain/Keystore**, KHÔNG nằm trong DB |
| Danh tính máy | `identity/tongtai_identity_store.dart` | `FlutterSecureStorage` |
| Sao lưu | `export/backup_service.dart`, `backup_format.dart` | `.ttbk` v2, Restore = Replace |

**Điểm quan trọng nhất cho Epic này:** đồ thị trên **không có một mũi tên nào đi
vào từ bên ngoài**. Mọi dữ liệu kinh doanh hôm nay sinh ra từ đúng một nguồn —
người bán gõ vào. Connector đầu tiên sẽ là **cạnh mới đầu tiên** trong sơ đồ kể
từ ngày bootstrap, và nó phải cắm vào tầng Repository chứ không phải tầng UI.

---

## 2. Hai bảng CHẾT đã tồn tại sẵn cho việc tích hợp — và cả hai đều mang giả định sai

Grep toàn `lib/` (bỏ `database.g.dart` sinh tự động):

### 2.1 `integrations_table` — **không một dòng code nào đọc hay ghi**

`lib/database/tables/integrations.dart` — có sẵn từ bootstrap:

```
id · businessId · provider · status
apiKeyEncrypted · apiSecretEncrypted · accessTokenEncrypted · refreshTokenEncrypted
config (JSON) · lastSyncAt · createdAt · updatedAt
```

Cùng hình dạng lỗi với `opportunities_table` mà WTM-189 tìm ra: **bảng chết từ
ngày tạo**. Nhưng nguy hiểm hơn, vì nó **mã hoá sẵn một quyết định kiến trúc
sai**:

> Nó giả định **token của nền tảng ngoài nằm trong SQLite**.

Sản phẩm hôm nay làm **ngược lại**: khoá BYOK nằm ở Keychain/Keystore
(`SecureTongtaiAiKeyStore`), và trang quyền riêng tư đã **in ra lời hứa đó cho
người dùng đọc**. Nếu connector ghi token vào bảng này thì:

* token đi vào `.ttbk` nếu ai đó thêm dataset (một dòng code là đủ);
* `.ttbk` **không mã hoá theo mặc định** — mã hoá là tuỳ chọn (WTM-100);
* một file sao lưu vô tình chia sẻ = **rò rỉ quyền truy cập cửa hàng của người bán**,
  không phải rò rỉ dữ liệu đọc được.

Sự cố Zalo 2026-07-31 (hai file `.ttbk` **không mã hoá** bị gửi nhầm lên chat)
chứng minh đây không phải rủi ro lý thuyết.

**Khuyến nghị (chờ Founder chốt ở W1):** giữ nguyên luật hiện hành — *bí mật ở
Keystore, DB chỉ giữ tham chiếu*. Bảng này hoặc **xoá**, hoặc **viết lại** chỉ
còn `Connection` (không cột token nào), + `credentialRef` trỏ sang Keystore.

### 2.2 `sync_queue_items` — sống một nửa

`SyncQueueRepository` **có** người gọi: `producer/supplier_favorites_store.dart`
ghi thao dấu-yêu-thích vào hàng đợi *"cho một Phase-3 tương lai"*. Không ai đọc
hàng đợi đó. Nghĩa là hôm nay nó là **một cột ghi-một-chiều**: dữ liệu vào,
không ai lấy ra — đúng họ lỗi Derived Data Audit đã dọn ở WTM-196…205.

Với Epic này nó lại có ích: **hình dạng outbox đã có sẵn**, nếu Founder chốt cho
phép ghi ngược lên nền tảng ngoài thì đây là chỗ để làm, không phải bịa mới.

---

## 3. Những seam connector BẮT BUỘC phải tôn trọng

| Seam | Ràng buộc với connector |
|---|---|
| **ADR-TON-015** One Data Path | Cấm connector tự cache song song. Dữ liệu ngoài phải đi `Repository → Context Provider → BusinessContext`, không được bơm thẳng vào màn |
| **ADR-TON-016** Rule Twin authoritative | Dữ liệu ngoài **không** được đi tắt vào AI. Rule Twin đọc trước, AI chỉ giải thích. Thiếu dữ liệu ⇒ nói thiếu, **cấm bịa** |
| **ADR-TON-016** AI Runtime Boundary | `AiToolRuntime` đang **tắt cứng**. Mọi "AI tự gọi API nền tảng" là **L3/L4 chờ Founder**, không phải việc kỹ thuật |
| **ADR-TON-017** Error seam | Lỗi mạng/ToS/hết hạn token phải là `TongtaiFailure` **có tên** (kind+code), không phải crash, không phải spinner vô hạn |
| **ADR-TON-018** `.ttbk` v2 | Bảng mới **phải** vào `BackupDatasets.optional`, **không** vào `all` (thêm vào `all` là từ chối mọi file đã phát hành). Enum lưu **mã canonical** |
| **ADR-TON-023** | Product đã có `physical/digital/service`; connector không được sinh loại thứ tư mà mô hình không biết |
| **D-4 / D-7** privacy | Không tracking, không profiling. Telemetry chỉ `kind`+`code`+`screen` |

---

## 4. Ba thứ kiến trúc hiện tại **chưa** có, và connector nào cũng sẽ cần

Đây là kết luận chính của Wave 0 — chi tiết + bằng chứng dòng lệnh nằm ở
[DATA-MODEL-ASSUMPTIONS-TO-VERIFY.md](DATA-MODEL-ASSUMPTIONS-TO-VERIFY.md).

1. **Provenance** — không bản ghi nào biết mình từ đâu ra. `Order`, `Product`,
   `Customer`, `FinanceTransaction` đều **không có** trường nguồn gốc. Người bán
   sẽ không phân biệt được *số tôi tự nhập* với *số Shopee đẩy về*, và khi hai
   bên lệch thì không ai biết tin bên nào.
2. **External identity** — `Customer` có `phone`/`email` nhưng **không có** khái
   niệm "cùng một người ở Shopee và Facebook". Gộp khách đa kênh là bài toán
   danh tính, không phải bài toán import.
3. **Freshness / confidence** — `BusinessContext` có `generatedAt` cho **toàn
   bộ** snapshot, nhưng không có "dữ liệu Shopee cũ 3 ngày, dữ liệu Finance là
   hôm nay". Một AI đọc context trộn hai độ tươi mà không biết sẽ nói sai một
   cách **tự tin**.

---

## 5. Điều tài liệu này KHÔNG kết luận

Không chọn kiến trúc cho bất kỳ connector nào (đó là Wave 1+). Không nói cần hay
không cần backend — Task Order yêu cầu đánh giá **độc lập từng nền tảng**, và
đánh giá đó cần object model thật của họ, chưa có ở Wave 0.
