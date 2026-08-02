# GitHub Connector — connector thật đầu tiên, đã chạy

> **WTM-268 (L · Smoke Connector) · Epic WTM-256 (PLATFORM-002).**
> Ngày **2026-08-02**. Mọi số dưới đây là output thật của runtime, không phải ước lượng.
> ⚠️ Không chứa secret. PAT và secret webhook nằm ở `~/.workizen-secrets/n8n-tongtai.json`
> (600, ngoài mọi git repo).

---

## Vì sao là GitHub chứ không phải RevenueCat

Kế hoạch cũ (WTM-269) xếp RevenueCat là connector giá trị cao nhất. Founder đính
chính ngày 2026-08-02: *"tạm bỏ qua RevenueCat đi, đã lên store đâu."*

Đúng. RevenueCat chỉ có dữ liệu khi app đã bán hàng. Một receiver publish rồi
không bao giờ nhận gì chính là hình dạng **"thứ chết trông như đang sống"** mà repo
này đã dọn nhiều lần (`opportunities_table`, `integrations_table`, n8n trong sơ đồ
App Layer). Workflow RevenueCat đã được `unpublish`, giữ nguyên, publish lại bằng
**một lệnh MCP** khi app lên store.

GitHub là nguồn **duy nhất hôm nay có dữ liệu thật đủ dày** để một connector chứng
minh được điều gì.

---

## Runtime tự đọc được gì — 30 ngày, một lần gọi

| Loại sự kiện | Số lượng | Ý nghĩa nguồn |
|---|---:|---|
| `delivery.commit` | **208** | commit trên mọi nhánh trong cửa sổ |
| `delivery.change_merged` | **152** | PR đã merge trong cửa sổ |
| `delivery.released` | **0** | ⭐ **không có gì tới tay người dùng** |
| **Tổng** | **360** | |

Cửa sổ `2026-07-03 → 2026-08-02` · `truncated: false` · `event_id` duy nhất **360/360**.

### Tín hiệu kinh doanh nằm ở dòng thứ ba

**208 commit · 152 PR merged · 0 release.**

Đây đúng là loại tín hiệu mà capability *Developer Productivity* sinh ra để bắt:
**công việc chạy rất nhiều nhưng không có gì tới tay người dùng.** Với một doanh
nghiệp phần mềm, đó là con số quan trọng hơn mọi biểu đồ commit.

Tag duy nhất trong repo là `split-baseline` — mốc kỹ thuật lúc tách repo, không
phải một bản phát hành.

⚠️ **Kết luận trên là của con người đọc tài liệu này, KHÔNG phải của backend.**
Runtime chỉ phát ra 360 sự kiện rời rạc; nó không đếm, không xếp hạng, không nói
"0 release là xấu". Xem §Ranh giới bên dưới.

---

## Bốn tính chất đã kiểm, không phải "container chạy là xong" (§15 Task Order)

| # | Tính chất | Cách kiểm | Kết quả |
|---|---|---|---|
| 1 | **Có xác thực** | POST không header `Authorization` | **403** — chặn đúng |
| 2 | **Số liệu đúng** | đối chiếu với lần đo trực tiếp GitHub API bằng script độc lập | 208 / 152 / 0 — **khớp tuyệt đối** |
| 3 | **Chống trùng ổn định** | gọi hai lần, so tập `event_id` | 360 trùng · 0 lệch → retry **không** sinh bản ghi thứ hai |
| 4 | **Repo ghim server-side** | request cố truyền `repo: poupou97/workizen-3d` | runtime vẫn đọc repo đã ghim — request **không** điều khiển được token |

Thời gian một lần gọi đầy đủ: **6,9 giây** · phản hồi **233 KB** · 3 endpoint · 7 trang API.

### Vì sao tính chất 4 quan trọng hơn vẻ ngoài của nó

Nếu `repo` nhận từ request, bất kỳ ai có secret webhook đều biến runtime thành
proxy đọc **mọi repo mà PAT của Founder chạm tới**. Token đang ở phạm vi một repo,
nên thiệt hại có giới hạn — nhưng phạm vi token là thứ đổi được trong 30 giây trên
web GitHub, còn đường code thì không. Ghim ở phía server là chỗ đúng để đặt luật.

---

## Ranh giới Mobile/Backend — chỗ dễ trượt nhất, và cách nó được giữ

Luật WTM-249: **Backend biết dữ liệu ĐẾN TỪ ĐÂU. Chỉ Mobile biết dữ liệu đó NGHĨA LÀ GÌ.**

Cám dỗ rõ ràng ở đây là trả về `{ commits: 208, releases: 0, health: "at_risk" }`.
Nó gọn hơn 233 KB rất nhiều. **Nhưng đó là kết luận kinh doanh**, và đặt nó ở
backend sẽ vi phạm đúng lỗi P-27/P-28 đã lặp bốn lần trong repo này: *trường đã lưu
vs luật dẫn xuất* — hai nguồn sự thật cho cùng một con số, rồi chúng lệch nhau.

Nên backend phát ra **một sự kiện cho một đối tượng có thật** (một commit, một PR,
một release) và dừng ở đó. Rule Twin trên máy đếm và kết luận — chạy được cả khi
không mạng, không key, không AI.

### Khối `sync` — và vì sao nó KHÔNG phải chỉ số kinh doanh

```json
"sync": {
  "connector": "github", "connection_id": "gh-workizen",
  "repo": "...", "window_from": "...", "window_to": "...",
  "fetched_at": "...", "truncated": false,
  "note": "backend chi chuan hoa hinh dang; y nghia kinh doanh do Mobile quyet dinh"
}
```

Khối này chỉ nói về **chính lần đồng bộ**: lấy từ đâu tới đâu, có bị cắt không.
Không có con số nghiệp vụ nào.

`truncated` là trường quan trọng nhất trong đó, và nó tồn tại vì một lý do cụ thể:
**"0 release" đọc từ dữ liệu lấy thiếu là một lời nói dối trông y hệt sự thật.**
Nếu phân trang chạm trần, `truncated: true` và app **không được** kết luận gì về
sự vắng mặt. Cùng kỷ luật với `null` ≠ `0` đã áp trong toàn bộ domain model.

---

## Envelope thật (một bản ghi, cắt từ phản hồi)

```json
{
  "envelope_version": 1,
  "event_id": "github:commit:31d4a71cf236a4c9e613ffe5b2667bdf8eb9ae40",
  "event_type": "delivery.commit",
  "occurred_at": "2026-08-02T13:12:24Z",
  "received_at": "2026-08-02T13:37:38.737Z",
  "provenance": {
    "source": "connector", "connector": "github",
    "connection_id": "gh-workizen",
    "external_id": "github:commit:31d4a71cf236a4c9e613ffe5b2667bdf8eb9ae40",
    "raw_type": "commit"
  },
  "freshness": { "mode": "poll", "confidence": 1 },
  "external_identity": { "platform": "github", "external_id": "poupou97", "confidence": 1 },
  "payload": {
    "repo": "poupou97/workizen-tongtai-mobile",
    "sha": "31d4a71cf236",
    "title": "infra(WTM-256): PLATFORM-002 — n8n Integration Runtime chạy thật trên VM usecase (#154)"
  }
}
```

Đúng hợp đồng `09-MOBILE-BACKEND-CONTRACT.md`, không thêm không bớt trường nào.

### Khác biệt so với connector RevenueCat

| | RevenueCat | GitHub |
|---|---|---|
| `freshness.mode` | `webhook` | **`poll`** |
| Ai khởi động | vendor đẩy | **ta kéo, theo cửa sổ thời gian** |
| `external_identity.confidence` | 0.9 (sàn không trả danh tính thật) | **1** (handle GitHub là định danh xác định) |
| Rủi ro mất sự kiện | vendor retry | **không có** — kéo lại là đủ, khoá `event_id` ổn định |

Hai `freshness.mode` khác nhau là lý do trường đó có mặt trong envelope ngay từ
đầu: AI đọc lẫn dữ liệu poll cũ và dữ liệu webhook tức thời mà không biết ⇒ **nói
sai một cách tự tin**.

---

## Ánh xạ `event_type`

| GitHub | Canonical |
|---|---|
| commit | `delivery.commit` |
| pull request đã merge | `delivery.change_merged` |
| release | `delivery.released` |

PR **đóng mà không merge** không sinh sự kiện — nó không phải một lần giao hàng.
Tag không sinh sự kiện: `split-baseline` là mốc kỹ thuật, và ánh xạ tag → release
chính là kiểu "đoán bừa về mã gần giống nhất" mà ADR-TON-018 cấm.

---

## Kiến trúc workflow

```
Webhook (headerAuth)
  → Time Window   (ghim repo · cửa sổ mặc định 30 ngày, tối đa 365)
  → GH Releases        ┐
  → GH Pull Requests   ├ HTTP Request v4.2 · Header Auth · phân trang tự động, trần 10 trang
  → GH Commits         ┘
  → Canonical Delivery Events  (Code · gộp bằng $('node').all())
```

Hai chi tiết kỹ thuật đáng ghi lại vì mất thời gian mới ra:

1. **`alwaysOutputData: true` trên cả ba node HTTP.** Endpoint `releases` trả mảng
   rỗng ⇒ node không phát item nào ⇒ n8n **dừng nhánh** và node Code cuối không
   bao giờ chạy. Nghĩa là trường hợp *"0 release"* — đúng cái ta cần đo — lại là
   trường hợp duy nhất workflow không chạy. Bật cờ này rồi lọc item rỗng trong Code.
2. **`executeOnce: true` trên cả ba node HTTP.** Chuỗi tuyến tính khiến node sau
   chạy một lần cho **mỗi item** của node trước — 208 commit sẽ thành 208 lần gọi
   endpoint kế tiếp.

---

## Còn nợ gì

**Phía backend: xong.** Connector chạy, có xác thực, số khớp, chống trùng ổn định.

**Phía mobile: chưa có chỗ đặt.** Envelope giả định app có `Provenance`,
`Connection`/`CredentialReference`, `CustomerIdentity`, `Fee/Refund/Payout` — cả
bốn **chưa tồn tại** trong schema v16. Đó là **N0** của WTM-246.

⇒ 360 sự kiện này hôm nay chảy tới cửa app rồi dừng. Đúng thứ tự: **N0 trước, nạp
dữ liệu sau** — làm ngược thì phải migrate dữ liệu thật về sau.

Hai việc nhỏ chưa làm, cố ý: chưa có Schedule Trigger (chạy theo lịch) vì chưa có
nơi nhận; chưa lấy CI runs (`delivery.check_completed`) vì 274 lần chạy không thêm
tín hiệu kinh doanh nào ngoài thứ đã thấy.
