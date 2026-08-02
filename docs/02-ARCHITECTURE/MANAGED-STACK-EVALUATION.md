# Mua hay tự xây — đánh giá 14 vùng năng lực

> **WTM-244 · Wave 1 của Epic WTM-238.** Founder Decision 2026-08-02:
> *"Không mặc định mọi capability đều phải tự xây… Không mặc định 'tự xây' là
> tốt hơn."*
>
> Thứ tự đánh giá bắt buộc: **Native Platform → Managed SaaS → Open Source →
> Self-hosted → VM/K8s**. Không mặc định chọn tầng dưới.
>
> Câu hỏi kiểm định mọi dòng dưới đây: *"Nếu tôi là Founder Workizen đang điều
> hành doanh nghiệp thật, dùng cái này có giúp tôi phát triển nhanh hơn không?"*

---

## Vì sao bảng này ngắn hơn anh nghĩ

Tổng Tài đã trả lời **năm** trong mười bốn vùng bằng **tầng 1 — Native
Platform**, và đó là lý do sản phẩm chạy được tới hôm nay mà không có một dòng
server nào:

| Vùng | Đã giải bằng | File |
|---|---|---|
| Identity | UUID sinh một lần, giữ trong Keychain/Keystore | `identity/tongtai_identity_store.dart` |
| Secret (mobile) | Keychain/Keystore | `ai/tongtai_ai_key_store.dart` |
| Storage (dữ liệu) | SQLite/Drift trên máy, 20 bảng, schema v16 | `database/` |
| Search | **FTS5 on-device**, tokenizer đ-aware | `database/search/` |
| Document/Export | `.ttbk` v2 + share sheet của hệ điều hành | `export/` |

**Kết luận đầu tiên và quan trọng nhất:** với năm vùng này, mua SaaS **không**
làm Workizen nhanh hơn — nó làm sản phẩm **chậm hơn và yếu hơn**, vì phải thêm
mạng vào đường đi của thứ hiện đang chạy offline. Đây không phải doctrine
"tự xây tốt hơn"; đây là tầng 1 trong chính thứ tự Founder đặt ra.

---

## Bảng quyết định — 14 vùng

Nhãn: 🟢 **dùng ngay** · 🟡 **dùng khi chạm điều kiện cụ thể** · ⚪ **chưa cần, và biết vì sao** · 🔴 **không nên**

| # | Vùng | Kết luận | Chọn gì | Nếu KHÔNG dùng thì phải tự xây gì |
|---|---|---|---|---|
| 1 | **Authentication** | 🔴 | **Không cái nào** | *Không phải bài toán của Tổng Tài.* D-4: không cần tài khoản. Firebase Auth/Clerk/Auth0/Keycloak giải một bài toán sản phẩm **cố ý không có**. Mua = tự tạo ra vấn đề rồi mua thuốc |
| 2 | **Identity** | 🟢 đã xong | Native (Keystore UUID) | — |
| 3 | **Secret** (mobile) | 🟢 đã xong | Native Keychain/Keystore | — |
| 3b | **Secret** (runtime) | 🟡 | **Google Secret Manager** | Chỉ khi dựng Optional Integration Runtime cho RevenueCat. Cùng dự án Firebase `workizen-hub` đang có ⇒ **không thêm vendor mới** |
| 4 | **Monitoring** | 🟢 đang dùng | **Firebase Crashlytics** | Giữ. Tự xây crash reporting là việc vô nghĩa. Sentry tương đương, nhưng đổi = thêm vendor mà không được gì |
| 5 | **Analytics** | 🟡 giữ nguyên, **cấm mở rộng** | Firebase Analytics, **chỉ** `app_open` + `screen_error` | Red-line D-7: không ad SDK, không profiling. PostHog/Mixpanel **giỏi hơn ở đúng thứ Tổng Tài đã hứa không làm**. Mua = mua một cái cám dỗ |
| 6 | **Notification** | 🟡 | **Local notification (Native)** trước, FCM sau | WTM-179 (AI Weekly Review) tự ghi rõ *"local notification — không cần backend"*. FCM chỉ cần khi muốn đẩy từ server, mà hôm nay không có gì để đẩy |
| 7 | **Messaging** | ⚪ | — | Không có tin nhắn giữa người dùng. Trùng vùng 6 |
| 8 | **Database (cloud)** | ⚪ / 🟡 | — / Firestore hoặc Supabase **chỉ cho connection state** | Core là local-first. Runtime chỉ giữ *"kết nối nào, con trỏ đồng bộ tới đâu"* — vài KB. Dùng Firestore vì đã có dự án; **cấm** lưu dữ liệu doanh nghiệp (Founder: Optional Runtime không lưu toàn bộ dữ liệu) |
| 9 | **Functions** | 🟡 | **Cloud Run** (ưu tiên) hoặc Cloud Functions | Chỉ để nhận webhook RevenueCat + giữ `sk_`. Cloud Run vì container **chạy được ở chỗ khác** ⇒ không khoá vendor |
| 10 | **Queue** | ⚪ | — | Một webhook receiver không cần hàng đợi. Thêm Cloud Tasks/QStash lúc này là kiến trúc cho một quy mô chưa tồn tại |
| 11 | **Scheduler** | ⚪ / 🟡 | — / Cloud Scheduler | Nhịp hằng tuần của Weekly Review chạy **trên máy** khi người dùng mở app. Chỉ cần scheduler nếu muốn kéo dữ liệu **khi app đóng** |
| 12 | **Workflow** | 🔴 lúc này | — | Inngest/Trigger.dev/Temporal/n8n giải bài toán **điều phối nhiều bước có trạng thái**. Thứ đó ở Tổng Tài **đã có tên**: Business Journey, chạy trên máy. Mua workflow engine = có **hai** thứ cùng gọi là "quy trình" ⇒ đúng lỗi P-27 ở quy mô kiến trúc |
| 13 | **Search** | 🟢 đã xong | FTS5 on-device | Meilisearch/Typesense/Algolia đều đòi **đẩy dữ liệu kinh doanh lên mây để tìm kiếm** — phá thẳng lời hứa đã in trong app |
| 14 | **Email (gửi)** | ⚪ | — | Tổng Tài **không gửi email**. Nếu sau này Weekly Review gửi qua email thì **Resend** (API sạch, giá theo lượng, export được) |
| 15 | **Storage (file)** | ⚪ / 🟡 | — / **Cloudflare R2** | `.ttbk` hiện đi qua share sheet. Nếu làm sao lưu đám mây: R2 vì **không tính phí egress** ⇒ tải bản sao lưu về không bị phạt tiền |
| 16 | **Document/Files** | 🟢 đã xong | Share sheet → Drive/Dropbox do người dùng chọn | Người dùng **đã** có Drive; Tổng Tài không cần tích hợp để họ lưu vào đó |

---

## Ba vùng đáng nói kỹ, vì câu trả lời không hiển nhiên

### Workflow — thứ duy nhất tôi khuyên **đừng mua**, dù nó có vẻ hợp

Nhìn qua thì Inngest/Temporal hợp với *"Release → Store → RevenueCat → Weekly
Review"*. Nhưng đọc kỹ chuỗi đó: nó **không phải** workflow của hệ thống, nó là
**hành trình kinh doanh của người dùng** — thứ Tổng Tài đã có object riêng
(`Journey`, `JourneyNode`, Rule Twin đo tiến độ, ADR-TON-021).

Mua một workflow engine ở đây tạo ra **hai nơi định nghĩa "việc tiếp theo là
gì"**: một trên mây, một trong máy người bán. Repo này đã dọn đúng họ lỗi đó bốn
lần trong một ngày (WTM-196/200/201/205 — "cột đã lưu vs luật dẫn xuất").

**Ngoại lệ có thể mua sau:** điều phối **phía runtime** (thử lại khi Shopee trả
429, kéo báo cáo hằng đêm). Đó là workflow **của connector**, không phải của
doanh nghiệp — và lúc đó Inngest là lựa chọn hợp lý nhất vì code chạy trên
Cloud Run, không bị nhốt.

### Analytics — vùng duy nhất mà "SaaS tốt hơn" lại là **lý do để không dùng**

PostHog/Mixpanel mạnh ở phân tích hành vi người dùng: funnel, cohort, session
replay. Tổng Tài đã hứa với người dùng — **in trong app** — rằng không có
tracking, không profiling, không quảng cáo cá nhân hoá. Firebase Analytics hiện
chỉ được gửi hai sự kiện.

Mua PostHog không giúp Workizen nhanh hơn; nó đặt một công cụ mạnh vào tay một
sản phẩm đã tự trói tay mình **có chủ đích**. Nếu sau này cần hiểu hành vi, cách
đúng là **hỏi người dùng** (đã có màn Feedback, WTM-175) chứ không phải quan sát
lén.

### Authentication — bài toán không tồn tại, và đó là một tài sản

Founder hỏi "dùng SaaS này có nhanh hơn không". Với Auth, câu trả lời là: **nhanh
hơn để đi tới một nơi Tổng Tài không muốn tới.** D-4 (không cần tài khoản) là
một trong những thứ khiến sản phẩm khác biệt ở thị trường SME Việt Nam — người
bán mở app là dùng được, không đăng ký, không email, không mật khẩu quên.

Khi nào bài toán này **thật sự** xuất hiện: đồng bộ nhiều thiết bị (Founder đã
xếp vào *Core Product Backend*, chưa mở), hoặc Managed AI (Phase 3). Lúc đó
**Firebase Auth** là mặc định hợp lý — cùng dự án đang có, cùng SDK Flutter,
export được user list.

---

## Nếu dựng Optional Integration Runtime thì hình dạng tối thiểu là gì

Chỉ để phục vụ RevenueCat (nền tảng **duy nhất** ở Wave 1 bắt buộc — xem
[WORKIZEN-DOGFOOD-INTEGRATION-PLAN](../07-PRODUCT-RESET/WORKIZEN-DOGFOOD-INTEGRATION-PLAN.md)):

```
RevenueCat  ──webhook──►  Cloud Run (1 service, ~200 dòng)
                              │  đọc sk_ từ Secret Manager
                              │  KHÔNG lưu dữ liệu doanh nghiệp
                              ▼
                          Firestore: {connectionId, cursor, lastEventAt}
                              │
                    app kéo về khi mở  ──► Repository ──► BusinessContext
```

Bốn thứ phải đúng, nếu không nó biến thành Core Product Backend lúc nào không
hay:

1. **Người dùng chủ động bật.** Không bật thì app không gọi một byte nào.
2. **Chỉ giữ credential + con trỏ đồng bộ.** Không đơn hàng, không khách hàng.
3. **Tắt runtime thì app vẫn đủ chức năng lõi** — kiểm bằng test, không bằng lời hứa.
4. **Chi phí:** ở quy mô Workizen (một tài khoản, vài chục sự kiện/ngày), Cloud
   Run + Secret Manager + Firestore nằm trong hạn mức miễn phí hoặc gần như vậy.
   **Không** phải chi phí đáng kể ⇒ theo mục X của Task Order, không cần báo
   Founder như một cảnh báo chi phí.

---

## Bảy câu Founder yêu cầu — trả lời cho các mục 🟢/🟡

| | Crashlytics | Cloud Run + Secret Manager | Firebase Analytics | R2 (nếu làm backup mây) |
|---|---|---|---|---|
| Giải đúng bài toán? | ✅ | ✅ (chỉ webhook) | ⚠️ đủ cho 2 sự kiện | ✅ |
| Đơn giản hơn chỗ nào | Không phải tự thu thập/symbolicate crash | Không phải giữ `sk_` trong app | Có sẵn cùng Crashlytics | Không phí egress |
| Không dùng thì tự xây gì | Một pipeline crash — vô nghĩa | Không có cách hợp lệ giữ `sk_` | Đếm thủ công | Tự chạy object storage |
| Khoá vendor | Trung bình (SDK) | **Thấp** — container chạy chỗ khác được | Trung bình | Thấp (S3-compatible) |
| API export | ✅ BigQuery | ✅ (code là của mình) | ✅ BigQuery | ✅ |
| Thay bằng OSS | Sentry self-host | Bất kỳ container host | PostHog (nhưng xem §Analytics) | MinIO |
| Khi nào migrate | Khi Google đổi giá/chính sách | Khi cần chạy nhiều vùng | Khi cần phân tích sâu **mà chính sách cho phép** | Khi lượng lưu vượt hạn mức |

---

## Điều tài liệu này KHÔNG làm

Không thêm dependency, không dựng gì. Mọi mục 🟡 là **đề xuất chờ Founder chốt**
theo đúng phân biệt A/B (Core Product Backend vs Optional Integration Runtime).
Roadmap và Decision Matrix nằm ở story sau.
