# Producer · Destination · Logistics · Marketing · Finance · Connection Center

*(Báo cáo 8–13 trong 24 · Phase 4–5 của directive)*

> ⚠️ **Đây là ĐỀ XUẤT MỚI, không phải đánh giá cái đang có.** Grep toàn bộ
> workspace (10 repo, mọi `*.md`): **"Connection Center" xuất hiện 0 lần**. Khái
> niệm này do directive hôm nay đặt ra.
>
> Thứ gần nhất đang tồn tại là `docs/02-ARCHITECTURE/INTEGRATION-MAP.md` — mô tả
> 12+ hệ thống ngoài **ở dạng thiết kế**, và **mâu thuẫn với `PRODUCT-SCOPE.md`**
> vốn xếp tích hợp thật ngoài phạm vi.

---

# 13. Connection Center — quyết định kiến trúc trước, danh sách sàn sau

## Câu hỏi thật không phải "kết nối sàn nào"

Mà là: **credential sống ở đâu.** Trả lời xong câu đó thì 90% thiết kế tự ra.

| | Hướng **A** — hoãn | Hướng **C** — File Bridge | Hướng **B** — OAuth Platform |
|---|---|---|---|
| Credential | không có | **không có** | client secret **phải** ở server |
| Backend | không | **không** | **bắt buộc** |
| Tài khoản | không | **không** | **bắt buộc** |
| D-4 / D-5 | giữ nguyên | **giữ nguyên** | **phải huỷ cả hai** |
| Chính sách riêng tư hiện tại | đúng | **vẫn đúng** | **thành sai** |
| Dữ liệu vào từ | — | file người bán tự xuất | API realtime |
| Realtime | — | không | có |
| Thời gian tới giá trị đầu tiên | — | **hàng tuần** | **hàng quý** |
| Phụ thuộc bên ngoài | — | **không** | phê duyệt của Shopee/TikTok/1688… |

## Vì sao tôi đề xuất C

Người bán SME Việt Nam **đã có sẵn** file xuất từ Shopee, TikTok Shop, GHN —
họ tải về hằng tuần để tự tính lãi bằng Excel. Đó chính là công việc thủ công mà
Vision nói sẽ thay thế.

Đọc được file đó cho họ **ngay** thứ giá trị nhất — *"dữ liệu đa kênh về một
chỗ, có AI đọc hộ"* — mà:

- không cần một dòng backend,
- không cần một chữ ký đối tác nào,
- không phá lời hứa riêng tư vừa in vào app,
- và **kiểm chứng được nhu cầu** trước khi đặt cược 6–12 tháng vào hạ tầng.

Nếu C chứng minh người dùng thật sự nhập file mỗi tuần, thì B trở thành quyết
định **có dữ liệu chứng minh**. Nếu họ không nhập, B đã tránh được.

## Kiến trúc Connection Center (chung cho C và B)

```
Nguồn (file | API)
   → Connector          (đọc, không hiểu nghiệp vụ)
   → Normalizer         (về Domain Model: Product/Order/Customer/Shipment)
   → Reconciler         (khớp với dữ liệu đang có: trùng? xung đột? mới?)
   → Staging + Preview  (NGƯỜI DÙNG XEM TRƯỚC KHI GHI)
   → Apply (một transaction)
   → Provenance         (mỗi dòng nhớ nó đến từ đâu, lúc nào)
```

**Bốn quy tắc bắt buộc, rút từ bài học `.ttbk` (ADR-TON-018):**

1. **Không bao giờ ghi trước khi người dùng xem preview.** Nhập dữ liệu sàn là
   thao tác phá huỷ tiềm tàng y như restore.
2. **Provenance là bắt buộc.** Không có nó, ba tháng sau không ai biết đơn này
   do người dùng nhập tay hay do Shopee đẩy về — và khi số liệu sai thì không
   truy được.
3. **Dữ liệu người dùng thắng.** Xung đột ⇒ hỏi, không tự ghi đè.
4. **Không có "best-effort partial import".** Cùng lý do với restore.

Bốn quy tắc này **áp dụng cho cả C lẫn B**, nên làm C không phải là làm bỏ đi —
nó xây đúng cái xương sống mà B sẽ dùng lại.

---

# 8. Producer Assessment

**Hiện trạng:** L2 — màn tìm nhà cung cấp trên `kSampleSuppliers` (fixture tĩnh).
Có yêu thích, có xếp hạng, có chi tiết. **Không có nguồn hàng thật.**

| Nguồn directive nêu | Thực tế | Đề xuất |
|---|---|---|
| **Alibaba / 1688 / Taobao / JD** | API cần doanh nghiệp TQ đăng ký, phần lớn giới hạn theo hợp đồng | ❌ không khả thi gần hạn |
| **Temu** | không có API công khai cho bên thứ ba | ❌ |
| **Shopify** | API tốt, OAuth chuẩn | ⚠️ nhưng đây là *kênh bán*, không phải nguồn hàng — xếp nhầm nhóm |
| **Excel / CSV** | người bán đã dùng hằng ngày | ✅ **làm trước** |
| **Google Drive** | cần OAuth ⇒ cần backend | ⚠️ hướng B |
| **RSS** | ít liên quan tới nguồn hàng | ⏸ bỏ qua |
| **Supplier Discovery** | cần dữ liệu thị trường | ⚠️ phụ thuộc B |

**Kết luận Producer:** danh sách sàn TQ trong directive **không khả thi trong
6 tháng tới** vì lý do ngoài tầm kiểm soát (điều kiện API của họ). Đường thực tế
là **nhập file báo giá / danh mục NCC**, cộng với **nhập thủ công có cấu trúc**.

---

# 9. Destination Assessment

**Hiện trạng:** L0 — không có khái niệm "kênh bán" trong Domain Model.

| Kênh | API | Ưu tiên đề xuất |
|---|---|---|
| **Shopee** | Open Platform, OAuth, cần đăng ký app | 🥇 **cao nhất** — thị phần VN lớn nhất |
| **TikTok Shop** | có API, đang mở rộng ở VN | 🥈 |
| **Facebook** | Graph API; bán hàng qua inbox **không có API đơn hàng** | ⚠️ giá trị thấp hơn kỳ vọng |
| **WooCommerce** | REST API, self-host, dễ nhất về pháp lý | 🥉 dễ làm nhưng ít người dùng VN |
| **Amazon / eBay** | ít liên quan SME Việt | ⏸ Later |
| **Website riêng** | quá đa dạng | ⏸ |

**Với hướng C:** Shopee và TikTok Shop **đều xuất được file đơn hàng** — đó là
đường vào không cần API.

**Cảnh báo:** ngay khi kéo đơn hàng từ sàn về, sản phẩm bắt đầu giữ **dữ liệu
khách hàng cuối** (tên, điện thoại, địa chỉ) do sàn cung cấp. Điều đó kéo theo
nghĩa vụ pháp lý (Nghị định 13/2023 về bảo vệ dữ liệu cá nhân) **nặng hơn hẳn**
hiện nay. Phải có ý kiến pháp lý trước, không phải sau.

---

# 10. Logistics Assessment

**Hiện trạng:** L0 — không có khái niệm vận đơn/shipment.

| Đơn vị | API | Ghi chú |
|---|---|---|
| **GHN** | API công khai, tài liệu tốt, token đơn giản | 🥇 dễ nhất trong toàn bộ directive |
| **GHTK** | API công khai | 🥈 |
| **VNPost** | có API, thủ tục nặng hơn | 🥉 |
| **Grab / Lalamove** | API cho đối tác doanh nghiệp | ⏸ |
| **DHL** | quốc tế, ít dùng cho SME nội địa | ⏸ |

**Điểm đáng chú ý:** GHN/GHTK dùng **API token đơn giản, không OAuth**. Nghĩa là
người bán có thể tự dán token — **giống hệt mô hình BYOK đang dùng cho AI**, và
**không cần backend**.

Đây có thể là **kết nối API thật đầu tiên** làm được mà không phá D-4/D-5.
Tracking · ETA · COD · phí ship là thứ người bán quan tâm hằng ngày.

> Tôi đề xuất coi **GHN là phép thử đầu tiên của Connection Center**, không phải
> Shopee. Rủi ro thấp nhất, giá trị hằng ngày cao, và không đụng doctrine.

Map (directive nêu) — cần Google Maps API ⇒ chi phí + khoá ⇒ **Later**.

---

# 11. Marketing Assessment

**Hiện trạng:** L0. Vision có nhắc omnichannel/community/affiliate trong
Consumer, nhưng **không có capability Marketing** trong Capability Map.

**Đánh giá thẳng:** với một sản phẩm chưa có kênh bán kết nối, Marketing là
**quá sớm**. Làm chiến dịch mà không đo được đơn hàng phát sinh thì chỉ là gửi
tin nhắn.

**Đề xuất:** giữ ở **Later**. Việc duy nhất đáng làm sớm là **phân khúc khách để
nhắn tin thủ công** — mà RFM đã có sẵn; chỉ cần xuất danh sách theo phân khúc.

---

# 12. Finance Assessment

**Hiện trạng:** **L4** — thu chi, dòng tiền, KPI, dự báo doanh thu (Rule Twin).
Một trong những capability hoàn chỉnh nhất.

**Còn thiếu để thành "Finance Intelligence" thật:**

| Thiếu | Ghi chú |
|---|---|
| **Giá vốn / lợi nhuận thật** | hiện có doanh thu, chưa có COGS đầy đủ ⇒ chưa nói được "lãi bao nhiêu" |
| **Đối soát với sàn** | tiền sàn trả về ≠ giá trị đơn (phí sàn, phí ship, khuyến mãi) ⇒ **cần hướng B/C** |
| **Công nợ** | chưa có |
| **Thuế** | Scope đã loại trừ |

**Điểm quan trọng:** *"lãi thật sau phí sàn"* là **câu hỏi số một** của người bán
online Việt Nam, và hiện sản phẩm **chưa trả lời được** — vì phí sàn chỉ có
trong đối soát của sàn.

Đây là lập luận mạnh nhất ủng hộ Connection Center, mạnh hơn cả Producer: không
phải để "quản lý đa kênh", mà để **trả lời đúng một câu hỏi mà người bán trả
tiền để biết**.

---

## Đánh giá OAuth / API / Permission / Sync (directive yêu cầu)

| Chủ đề | Kết luận |
|---|---|
| **OAuth** | Không làm được nếu không có backend — client secret không thể nằm trong APK (dịch ngược được). Không có ngoại lệ kỹ thuật nào. |
| **API token đơn giản** (GHN/GHTK) | **Làm được không cần backend**, theo đúng mô hình BYOK đã có |
| **Permission** | Nếu kéo dữ liệu khách từ sàn: cần cơ sở pháp lý theo Nghị định 13/2023. **Cần ý kiến pháp lý, không phải quyết định kỹ thuật** |
| **Sync** | Hai chiều là bài toán khó nhất (xung đột, idempotency, thứ tự). **Đề xuất: một chiều vào, giai đoạn đầu.** Đẩy ngược lên sàn ⇒ Future |
| **Rate limit / quota** | Mọi sàn đều có; cần backoff + hàng đợi — `SyncQueueItemsTable` đã có sẵn trong schema (WTM-41, đang mở, đúng chỗ để dùng) |
