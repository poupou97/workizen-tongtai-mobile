# 07 · Integration và Capability Discovery

> **CURRENT — EVIDENCE.**

## Agent biết mình dùng được gì **trước khi lập kế hoạch**

`capabilitiesMarkdown()` sinh một đoạn markdown và bơm vào prompt:

```
## What you can use here

Available:
- **LinkedIn** — a person's real name, current title, employer and tenure,
  self-reported, and so authoritative on identity.
- **Web research** — open-web context with citations…

Not configured here, so do not plan around them:
- Company brand data
- Picture storage

Their tools will tell you the same thing if you call them. Note what you
could not check rather than guessing at it.
```

Ba chi tiết đáng học:

**1. Liệt kê cả cái TẮT.** Không im lặng bỏ qua — nói rõ *"do not plan around them"*. Agent không biết cái gì vắng mặt sẽ lập kế hoạch quanh nó rồi thất bại giữa chừng.

**2. Mô tả bằng **cái nó cho**, không bằng tên API.** `gives: "a person's real name, current title, employer and tenure, **self-reported, and so authoritative on identity**"` — câu này dạy model *khi nào nên dùng*, không chỉ *có gì*.

**3. Trường hợp không có gì được cấu hình có lời riêng:**

> *"No outside sources are configured on this install. Everything you can learn is already in the CRM — email threads, meetings, signature blocks — and `read_crm_history` reads all of it for free. **That is often enough.**"*

## Gọi nhầm thì tool nói rõ đó không phải lỗi

```js
unavailable(env) => {
  ok: false, configured: false,
  reason: `This install has no ${env}, so that source is unavailable.
           This is not a failure and retrying will not help — use what the
           CRM already knows, and say in your write-up what you could not check.`
}
```

**Phân biệt *chưa cấu hình* với *thất bại*** là chi tiết nhỏ mà quan trọng: không có nó, agent sẽ retry một thứ không bao giờ thành công, đốt hết `budget`.

## ⚠️ Khác biệt then chốt với Tổng Tài

Capability của COMP AI đọc từ **biến môi trường** (`process.env[id]`) và **một khoá trong `appSetting`**. Đó là **cấp cài đặt** — single-tenant, một bộ cho cả hệ thống.

Tổng Tài **mỗi người bán có `Connection` riêng** (WTM-283). Cùng một bản cài, người này nối Shopee, người kia chưa. Nên:

| | COMP AI | Tổng Tài |
|---|---|---|
| Phạm vi | install | **per-seller, per-connection** |
| Nguồn | env var + appSetting | `connections_table` (WTM-283) |
| Trạng thái | có key / không có key | `active` · `paused` · `error` + `lastSyncAt` |
| Ai biết được gì | mọi session giống nhau | phải lọc theo người bán |

⇒ Pattern này là **ADAPT, không ADOPT**. Cái mượn được là *hình dạng câu văn bơm vào prompt* và *sự phân biệt chưa-cấu-hình/thất-bại*. Cái phải thay là **nguồn** — đọc từ `Connection` + `CapabilityMatrix`, lọc theo người bán.

## Tổng Tài đang có mảnh COMP AI **không** có

WTM-293 dựng `CapabilityMatrix` ba cột:

| Cột | COMP AI có tương đương? |
|---|---|
| `platformSupports` | ❌ không — họ chỉ biết "có key hay không" |
| `connectorCovers` | ❌ |
| `verifiedOnDogfood` | ❌ |

COMP AI trộn cả ba thành một boolean `enabled`. Với 4 nguồn thì được. Với 10+ nền tảng và một AI nói chuyện với người bán thì **không** — đó chính là lý do ADR-TON-024 luật 3 tồn tại.

⇒ **Tổng Tài đang đi trước ở điểm này.** Không có gì để học ở đây; có thứ để giữ.
