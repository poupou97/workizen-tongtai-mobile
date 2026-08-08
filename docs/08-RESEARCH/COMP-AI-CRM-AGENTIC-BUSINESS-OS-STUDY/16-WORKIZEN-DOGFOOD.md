# 16 · Workizen Dogfood — khách hàng số 1

> **PROPOSAL.** Workizen tự dùng Tổng Tài trước khi bán cho ai.

## Vì sao dogfood là phép thử kiến trúc tốt nhất

Workizen có **đúng hình dạng dữ liệu** mà một SME có, nhưng nguồn là công cụ kỹ thuật:

| SME có | Workizen có |
|---|---|
| đơn hàng | RevenueCat subscription / Play Console |
| khách hàng | người cài app |
| tồn kho | — *(không có tương đương — và đó là thông tin hữu ích)* |
| chi phí | AI cost · cloud cost |
| kênh bán | App Store · Google Play |
| vận hành | GitHub · Jira · Firebase Crashlytics |

**Chỗ không có tương đương cũng là dữ liệu:** nó cho biết mô hình miền của Tổng Tài chỗ nào phổ quát, chỗ nào chỉ đúng cho bán lẻ vật lý.

## Luồng dogfood 1 — hoàn tiền RevenueCat 🟡

```
RevenueCat webhook → CanonicalEvent(subscription.refunded)
  → SettlementLine{kind: refund, direction: outbound, fundedBy: seller}
  → Rule Twin: doanh thu thật tháng này
  → nếu tỷ lệ hoàn > ngưỡng ⇒ ProposedChange("xem lại lý do huỷ")
  → Founder duyệt ⇒ Journey follow-up
```

**Đây là luồng duy nhất trong cả bộ nghiên cứu cần đúng `CanonicalEvent`** — và nó có **1 producer**. Vẫn chưa đủ điều kiện tốt nghiệp hypothesis (cần ≥2).

⚠️ Chặn cứng: app **chưa lên store** ⇒ RevenueCat chưa có gì để trả về. Vendor catalog đã ghi đúng: `verification: tried`, note *"workflow đã dựng rồi GỠ — app chưa lên store"*.

## Luồng dogfood 2 — nhịp giao hàng 🟢 **chạy được hôm nay**

```
GitHub connector (ĐÃ CHẠY THẬT, WTM-268/274)
  → delivery.commit · delivery.change_merged · delivery.released
  → Evidence: nhịp giao hàng theo tuần
  → AI Weekly Review: "tuần này 3 story Done, 0 release"
  → ProposedChange("nên cắt release?") ⇒ Founder duyệt
```

**Đây là luồng dogfood khả thi nhất**, vì connector đã có bằng chứng thật: 211 commit · 155 pull · 0 release · 360 `event_id` ổn định qua hai lần gọi.

Và nó là **producer thứ nhất** cho `CanonicalEvent`. Connector Telegram sẽ là **producer thứ hai** ⇒ lúc đó hypothesis tốt nghiệp.

## Luồng dogfood 3 — crash spike 🟡

Firebase Crashlytics → `Evidence(crash_rate tăng)` → đối chiếu `delivery.released` gần nhất → `ProposedChange("bản nào gây ra")` → Journey hotfix.

⚠️ Ràng buộc riêng tư: Crashlytics chỉ mang stack trace, model máy, phiên bản OS — **không** dữ liệu nghiệp vụ (PRIVACY-POLICY §4). Luồng này đọc **số liệu tổng hợp**, không đọc báo cáo lẻ.

## Luồng dogfood 4 — chi phí AI 🟢

Chi phí AI + cloud → `SettlementLine{kind: platform_fee, vendor}` → Rule Twin: chi phí thật mỗi người dùng → cảnh báo khi vượt ngưỡng.

Không cần connector: **Founder tự nhập hàng tháng**, đúng như một chủ shop tự nhập phí sàn. **Và đó chính là phép thử** — nếu nhập tay quá phiền cho Founder thì nó cũng quá phiền cho người bán.

## Thứ tự đề xuất

| # | Luồng | Vì sao trước |
|---|---|---|
| 1 | **Nhịp giao hàng (GitHub)** | connector đã chạy thật, có bằng chứng số |
| 2 | **Chi phí AI/cloud nhập tay** | không cần gì, và kiểm chứng UX nhập liệu |
| 3 | Crash spike | cần nối Crashlytics API |
| 4 | RevenueCat | chặn tới khi app lên store |

## Điều dogfood sẽ trả lời mà nghiên cứu không trả lời được

- `ProposedChange` treo bao lâu thì thành phiền?
- Người bán bấm "bỏ qua" mấy lần thì nên **thôi đề nghị** — và bao lâu thì được đề nghị lại? *(đây là câu hỏi Founder đã nêu ở `reconsiderAfter`)*
- `AUTO` có ai dám bật không?
- Một `correlationId` thực tế kéo dài mấy bước?

Không câu nào trả lời được bằng đọc source. Chúng cần Founder dùng thật.
