# Platform Roadmap + Founder Decision Matrix

> **WTM-255 · Phase 12 + Final của PLATFORM-001.**
> Trạng thái: **Draft — đây là tài liệu Founder + GPT cần phản biện kỹ nhất.**

---

## 1. Kiến trúc nền tảng — một hình

```
┌─────────────────────── THIẾT BỊ NGƯỜI BÁN ────────────────────────┐
│  Tổng Tài (Flutter)                                               │
│  SQLite/Drift · Repository · Context Provider · BusinessContext    │
│  Rule Twin (AUTHORITATIVE) · Journey · Opportunity · AI (BYOK)     │
│  Keychain/Keystore ← mọi bí mật                                    │
└───────────────────────────────┬───────────────────────────────────┘
                                │ HTTPS, người dùng chủ động bật
                                │ chỉ dữ liệu ĐÃ CHUẨN HOÁ + provenance
┌───────────────────────────────▼───────────────────────────────────┐
│  OPTIONAL INTEGRATION RUNTIME  (Oracle VM 137.131.35.185)          │
│  Caddy ─ n8n (queue) ─ n8n Postgres ─ Redis                        │
│  Secret vault ← token nền tảng ngoài                               │
│  ⛔ KHÔNG: Order/Product/Customer · KHÔNG tính toán · KHÔNG AI      │
└───────────────────────────────┬───────────────────────────────────┘
                                │ OAuth · webhook · polling
                  ┌─────────────┴─────────────┐
                  ▼                           ▼
          nền tảng ngoài              File Bridge (không qua backend)
       RevenueCat · Stripe · Ads       Store reports · sàn xuất .xlsx
```

**Đọc hình này theo một câu:** đường **File Bridge đi thẳng vào máy**, không
chạm backend. Đó là lý do local-first vẫn đứng vững — backend chỉ nằm trên
nhánh mà nền tảng ngoài **bắt buộc** phải có server.

---

## 2. Roadmap — năm nhịp, mỗi nhịp có điều kiện xong đo được

| Nhịp | Nội dung | Xong khi | Phụ thuộc |
|---|---|---|---|
| **N0 · Nền dữ liệu** (trong app, không cần mạng) | `Provenance` · `Connection`+`CredentialReference` · `CustomerIdentity(confidence)` · `Fee/Refund/Payout` gắn Order | test chứng minh một bản ghi biết mình từ đâu; lãi-trên-một-đơn tính được | — |
| **N1 · File Bridge** | App Store Connect + Play Console | nhập file thật → số khớp cổng nhà phát hành → **huỷ được cả mẻ** | N0 |
| **N2 · n8n Runtime** | dựng n8n + connector RevenueCat | **tắt runtime, app vẫn qua trọn bộ test** | N1 · quyết định P-1/P-2 |
| **N3 · Người dùng cuối** | Telegram · Woo/Shopify | người bán nhận được một tin nhắn có ích, không phải spam | N2 |
| **N4 · Commerce VN** | Shopee · TikTok Shop | lãi-trên-một-đơn đúng **sau phí sàn** | N0 + N3 |

**Vì sao N0 đứng trước và không được đảo:** không có `Provenance`, người bán
không phân biệt được *"số tôi tự nhập"* với *"số Shopee đẩy về"*; không có
`Fee`, import đơn sàn cho **doanh thu đúng, lợi nhuận sai** — sai theo hướng dễ
chịu, tức hướng không ai đi kiểm tra. Làm connector trước rồi quay lại sửa nền
nghĩa là **migrate dữ liệu thật của người dùng**, đắt hơn nhiều lần.

---

## 3. Migration Strategy — cái gì đổi, cái gì không

| Thay đổi | Loại | Rủi ro |
|---|---|---|
| Thêm `provenance` vào 4 bảng | migration **cộng thêm** (ADR-TON-009) | thấp — cột nullable, dòng cũ = `manual` |
| `Connection` + `CredentialReference` | **bảng mới** | thấp — vào `BackupDatasets.optional`, **không** vào `all` |
| `CustomerIdentity` | bảng mới | trung bình — cần luật gộp, và luật gộp sai thì **trộn hai người** |
| `Fee`/`Refund`/`Payout` | bảng mới + sửa cách tính lợi nhuận | **cao** — đụng con số người bán đang đọc mỗi ngày |
| Xoá `integrations_table` | migration **phá huỷ** | thấp về dữ liệu (bảng chết), nhưng **cần Founder duyệt** vì có từ bootstrap |
| Tách `Channel` / `Store` | đổi cấu trúc | trung bình — đơn đã ghi phải map sang store mặc định |

**Luật giữ nguyên từ ADR-TON-018:** dataset mới vào `optional`, **không** vào
`all` — thêm vào `all` là từ chối mọi file `.ttbk` đã phát hành.

---

## 4. Founder Decision Matrix

| # | Quyết định | Đề xuất | Đánh đổi nếu chọn khác |
|---|---|---|---|
| **P-1** | n8n cùng VM hay VM thứ hai? | **Cùng VM** | VM riêng: sạch hơn, nhưng thêm máy phải vá/giám sát/trả tiền |
| **P-2** | Gắn block volume trước khi thêm n8n? | **Có** | Không gắn: tiết kiệm vài đô, đổi lại rủi ro đầy đĩa trên máy đang phục vụ `workizen.net` |
| **P-3** | Repo hạ tầng: dùng `workforceOS-usecases`? | **Có**, đổi vai trò trong README, giữ `usecases/` | Repo mới: sạch tên gọi nhưng trái luật Phase 0 |
| **P-4** | Xoá `integrations_table` (chết, có 4 cột token)? | **Xoá**, thay bằng `Connection` không cột token | Giữ: rủi ro token vào `.ttbk` còn nguyên |
| **P-5** | Ba SSH key Oracle — bản nào còn hiệu lực? | **Anh xác nhận + thu hồi bản thừa** | Để nguyên: không biết ai còn vào được máy |
| **P-6** | N0 trước hay connector trước? | **N0 trước** | Connector trước: thấy dữ liệu sớm hơn ~1 nhịp, đổi lại migrate dữ liệu thật sau |
| **P-7** | Gmail: chốt Share Sheet, bỏ Gmail API? | **Chốt bỏ** | Dùng API: $500–$4.500+/năm + rủi ro định vị |
| **P-8** | Có cho n8n ghi ngược lên nền tảng (pause campaign, đổi giá)? | **Chưa** — sau N3, và chỉ ở mức L2 (người bán xác nhận) | Cho sớm: mở cửa cho hành động không hoàn tác được |

---

## 5. Rủi ro mới mà Phase 0 lộ ra (ngoài 9 rủi ro của WTM-246)

| # | Rủi ro | Mức | Giảm thiểu |
|---|---|---|---|
| R10 | **Đầy đĩa trên VM đang phục vụ khách thật** — 45 GB, ClickHouse + Prometheus phình theo thời gian, README đã cảnh báo từ trước | **Cao** | Đo `df -h` trước; gắn block volume; đặt retention cho log n8n |
| R11 | n8n **lặng lẽ thành Business Database** | **Cao** | Phép thử một câu: xoá n8n dựng lại, người bán không mất dữ liệu kinh doanh nào |
| R12 | Sửa Caddyfile làm **sập `workizen.net`** | Trung bình | Không sửa trực tiếp; snippet + backup, theo luật observer-layer đã tự đặt |
| R13 | Mất `N8N_ENCRYPTION_KEY` ⇒ **mất toàn bộ credential** | Trung bình | Sao lưu khoá riêng, ngoài repo, ngoài máy chủ |
| R14 | Ba SSH key không rõ hiệu lực | Trung bình | P-5 |

---

## 6. Điều KHÔNG có trong roadmap này

Không triển khai. Không compose thật. Không chạm máy chủ. Không Kubernetes,
microservice, event bus, CQRS. Wave Commerce/Marketing/Support (2–5 của Epic
WTM-238) vẫn chưa nghiên cứu sâu — chúng phụ thuộc N0 và các quyết định trên.
