# Sample schema & row counts (từ thiết bị thật)

`row-counts-after-reset.txt` chụp **sau khi "Xóa dữ liệu mẫu"** trên máy Founder:

```
customers    1     ← khách của NGƯỜI DÙNG (Phương Nguyễn) — sống sót
products     9     ← 1 sản phẩm người dùng + 8 catalog FTS (business demo riêng, WTM-73)
orders       0     ← toàn bộ đơn mẫu đã xoá
transactions 4     ← 4 giao dịch người dùng tự ghi — sống sót
goals        0     ← mục tiêu mẫu đã xoá
```

**Đọc gì từ đây:** sample được xoá sạch, **dữ liệu người dùng nguyên vẹn** —
đúng hợp đồng ADR-TON-014. Catalog `prod-*` thuộc `tongtai-demo-business`
(nguồn cho Unified Search) nên không nằm trong counts/lists của business thật.

Schema: `schema-customers.sql`, `schema-orders.sql` — nguyên văn từ SQLite trên
máy, cho thấy `orders_table.customer_id` là **FOREIGN KEY** tới
`customers_table` (đây chính là ràng buộc gây `SqliteException(787)` trong bug
reset — xem `08-Regression-Mapping`).
