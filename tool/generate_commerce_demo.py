#!/usr/bin/env python3
"""Sinh Commerce Demo Dataset — WTM-325 (C1 · Epic WTM-324).

    python3 tool/generate_commerce_demo.py

Ghi ra `assets/demo/TongTai-Commerce-Demo-100-Products.xlsx`.

## ⭐ Tất định, không ngẫu nhiên

`random.Random(SEED)` với seed cố định: chạy lại cho ra **đúng cùng một file**,
byte-cho-byte về nội dung. Đó là điều kiện để test khẳng định được số lượng
từng nhóm kịch bản — một dataset ngẫu nhiên thì test chỉ khẳng định được
"khoảng chừng", và "khoảng chừng" không bắt được lỗi.

## Không phải dữ liệu random vô nghĩa (Founder §3)

Mỗi sản phẩm thuộc **đúng một** nhóm kịch bản, và nhóm quyết định các con số:
tồn kho, giá vốn, giá bán, phí sàn, nhịp bán. Rule Twin phải tìm ra được đúng
những gì đã cố ý gieo vào — không hơn (không báo động giả), không kém.

Nhóm J (bình thường) tồn tại vì một lý do dễ quên: **không có nhóm đối chứng
thì mọi sản phẩm đều "có vấn đề"**, và một danh sách mà mọi dòng đều đỏ là một
danh sách không ai đọc.
"""

from __future__ import annotations

import datetime as dt
import random
from dataclasses import dataclass, field
from pathlib import Path

from openpyxl import Workbook

SEED = 20260809
OUT = Path(__file__).resolve().parent.parent / "assets" / "demo" / \
    "TongTai-Commerce-Demo-100-Products.xlsx"

# Mốc thời gian cố định — dataset không được đổi theo ngày chạy script.
TODAY = dt.date(2026, 8, 9)

rng = random.Random(SEED)


# ── nhóm kịch bản (Founder §6) ───────────────────────────────────────────────

SCENARIOS = {
    "A_FAST_LOW_STOCK": 12,   # bán chạy + sắp hết  → REORDER
    "B_DEAD_STOCK": 10,       # tồn nhiều, bán chậm → DEAD STOCK
    "C_HIGH_MARGIN": 10,      # lời tốt             → HIGH MARGIN
    "D_LOW_MARGIN": 9,        # lỗ sau phí          → LOW MARGIN ALERT
    "E_NEW": 10,              # mới nhập về
    "F_REORDER_SOON": 10,     # sắp tới điểm đặt lại
    "G_SUPPLIER_DIFF": 12,    # ≥2 báo giá          → SUPPLIER COMPARISON
    "H_BUNDLE": 10,           # bán kèm             → CROSS-SELL
    "I_OUT_OF_STOCK": 5,      # hết hàng
    "J_NORMAL": 12,           # đối chứng — KHÔNG có vấn đề gì
}
assert sum(SCENARIOS.values()) == 100, sum(SCENARIOS.values())


# ── nhà cung cấp (§5) ────────────────────────────────────────────────────────

SUPPLIERS = [
    ("SUP-01", "Xưởng may Tân Bình", "VN", "local_vn", 4.6, 7, 50,
     "Chuyển khoản 50% trước", "Xe tải nội thành"),
    ("SUP-02", "Guangzhou Yifeng Garment", "CN", "1688", 4.2, 21, 100,
     "TT trước 100%", "Đường bộ qua Lạng Sơn"),
    ("SUP-03", "Shenzhen Hualing Electronics", "CN", "alibaba", 4.4, 25, 30,
     "T/T 30% cọc", "Đường biển"),
    ("SUP-04", "Công ty Nhựa Bình Minh", "VN", "manufacturer", 4.8, 5, 20,
     "Công nợ 15 ngày", "Giao tận kho"),
    ("SUP-05", "Yiwu Small Commodity", "CN", "1688", 3.9, 18, 200,
     "TT trước 100%", "Đường bộ"),
    ("SUP-06", "Đại lý Mỹ phẩm Hàn Quốc HN", "VN", "wholesale", 4.5, 3, 10,
     "Trả ngay", "Giao nhanh nội thành"),
    ("SUP-07", "Ningbo Homeware Factory", "CN", "alibaba", 4.1, 28, 150,
     "L/C", "Đường biển"),
    ("SUP-08", "AliExpress - TopHome Store", "CN", "aliexpress", 4.3, 14, 1,
     "Trả qua sàn", "Chuyển phát nhanh"),
    ("SUP-09", "Chợ Kim Biên - Quầy 42", "VN", "wholesale", 4.0, 1, 5,
     "Tiền mặt", "Tự lấy"),
    ("SUP-10", "Hanoi Sport Import", "VN", "wholesale", 4.4, 4, 12,
     "Công nợ 7 ngày", "Giao tận kho"),
    ("SUP-11", "Dongguan Toy Works", "CN", "manufacturer", 4.7, 30, 300,
     "T/T 40% cọc", "Đường biển"),
    ("SUP-12", "Nhà in Minh Khai", "VN", "local_vn", 4.6, 2, 100,
     "Trả ngay", "Giao tận nơi"),
]

# Kênh bán và cửa hàng — mã canonical ở cột `sales_channel`.
CHANNELS = [
    ("shopee", "Shop Nhà Mình - Shopee"),
    ("tiktok", "Nhà Mình Store - TikTok"),
    ("facebook", "Fanpage Nhà Mình"),
    ("offline", "Cửa hàng 12 Nguyễn Trãi"),
]

# Phí sàn thật tế theo kênh — đây là thứ biến "doanh thu cao" thành "lỗ".
CHANNEL_FEES = {
    "shopee": dict(commission=0.055, payment=0.028, ship_subsidy=0.02),
    "tiktok": dict(commission=0.050, payment=0.025, ship_subsidy=0.03),
    "facebook": dict(commission=0.0, payment=0.015, ship_subsidy=0.0),
    "offline": dict(commission=0.0, payment=0.0, ship_subsidy=0.0),
}

CATEGORIES = [
    ("Thời trang", ["SUP-01", "SUP-02"]),
    ("Điện tử", ["SUP-03", "SUP-08"]),
    ("Gia dụng", ["SUP-04", "SUP-07"]),
    ("Mỹ phẩm", ["SUP-06", "SUP-09"]),
    ("Mẹ & Bé", ["SUP-05", "SUP-11"]),
    ("Thể thao", ["SUP-10", "SUP-05"]),
    ("Văn phòng phẩm", ["SUP-12", "SUP-09"]),
    ("Đồ chơi", ["SUP-11", "SUP-05"]),
]

NAMES = {
    "Thời trang": ["Áo thun cotton form rộng", "Quần jean nam ống suông",
                   "Áo sơ mi lụa nữ", "Váy hoa nhí mùa hè",
                   "Áo khoác gió chống nước", "Chân váy xếp ly",
                   "Áo hoodie nỉ bông", "Quần short kaki",
                   "Áo polo nam cổ bẻ", "Đầm công sở tay lỡ",
                   "Áo len cổ lọ", "Quần jogger thể thao"],
    "Điện tử": ["Tai nghe bluetooth chụp tai", "Sạc dự phòng 20000mAh",
                "Cáp sạc type-C bọc dù", "Đèn LED kẹp bàn học",
                "Chuột không dây im lặng", "Loa bluetooth mini",
                "Quạt mini cầm tay", "Giá đỡ điện thoại nhôm",
                "Bàn phím cơ mini", "Camera hành trình xe máy",
                "Đồng hồ thông minh thể thao", "Ổ cắm điện thông minh"],
    "Gia dụng": ["Bộ hộp đựng thực phẩm", "Thảm chùi chân silicon",
                 "Kệ nhà tắm 3 tầng", "Nồi chiên không dầu 5L",
                 "Bình giữ nhiệt inox 500ml", "Máy xay sinh tố cầm tay",
                 "Móc treo tường không khoan", "Chổi lau nhà xoay 360",
                 "Rổ nhựa đa năng", "Bộ dao kéo nhà bếp",
                 "Khay đá silicon có nắp", "Túi hút chân không quần áo"],
    "Mỹ phẩm": ["Kem chống nắng SPF50", "Sữa rửa mặt tạo bọt",
                "Son kem lì lâu trôi", "Mặt nạ giấy dưỡng ẩm",
                "Nước tẩy trang micellar", "Kem dưỡng ẩm ban đêm",
                "Serum vitamin C", "Xịt khoáng cấp nước",
                "Phấn nước cushion", "Dầu gội thảo dược",
                "Kem trị mụn chấm", "Bộ cọ trang điểm 5 món"],
    "Mẹ & Bé": ["Bỉm quần size L", "Bình sữa cổ rộng chống sặc",
                "Khăn sữa cotton 10 cái", "Ghế ăn dặm gấp gọn",
                "Xe đẩy du lịch gấp gọn", "Đồ chơi gặm nướu silicon",
                "Túi ủ sữa giữ nhiệt", "Máy hút sữa điện đôi",
                "Nôi rung tự động", "Yếm ăn dặm silicon",
                "Thảm chơi cho bé", "Áo liền quần sơ sinh"],
    "Thể thao": ["Thảm yoga chống trượt", "Dây nhảy đếm số",
                 "Tạ tay bọc cao su 5kg", "Bóng tập gym 65cm",
                 "Găng tay tập gym", "Áo thun thể thao co giãn",
                 "Bình nước thể thao 1L", "Dây kháng lực bộ 5",
                 "Con lăn massage cơ", "Vợt cầu lông khung carbon",
                 "Giày chạy bộ đế êm", "Túi đựng đồ tập"],
    "Văn phòng phẩm": ["Sổ tay bìa cứng A5", "Bút bi gel mực đen",
                       "Kẹp giấy màu hộp 100", "Băng keo trong 5cm",
                       "Giấy note dán 5 màu", "Bìa còng A4",
                       "Máy bấm kim cỡ vừa", "Hộp bút để bàn",
                       "Bút highlight 6 màu", "Giấy in A4 500 tờ",
                       "Bảng trắng mini", "Kéo văn phòng inox"],
    "Đồ chơi": ["Lego lắp ráp 200 mảnh", "Búp bê vải bông",
                "Ô tô điều khiển từ xa", "Bộ đồ chơi nấu ăn",
                "Xếp hình gỗ 3D", "Slime nhiều màu",
                "Bộ tô màu 24 bút", "Cầu trượt mini trong nhà",
                "Đất nặn an toàn 12 màu", "Bảng vẽ điện tử trẻ em",
                "Xe cân bằng cho bé", "Bộ đồ chơi bác sĩ"],
}


# Chi tiết phân biệt khi một danh mục hết tên — vẫn là tên người bán đọc được,
# không phải hậu tố kỹ thuật kiểu "(2)".
QUALIFIERS = ["bản nâng cấp", "hàng loại 1", "size lớn", "phiên bản mới",
              "bản tiết kiệm", "hàng cao cấp"]


@dataclass
class Product:
    index: int
    scenario: str
    category: str
    name: str
    supplier_id: str
    cost: int
    price: int
    quantity: int | None
    reorder: int
    channel: str
    store: str
    created: dt.date
    status: str = "active"
    variants: list = field(default_factory=list)

    @property
    def pid(self) -> str:
        return f"DEMO-P{self.index:03d}"

    @property
    def sku(self) -> str:
        prefix = {
            "Thời trang": "TT", "Điện tử": "DT", "Gia dụng": "GD",
            "Mỹ phẩm": "MP", "Mẹ & Bé": "MB", "Thể thao": "TH",
            "Văn phòng phẩm": "VP", "Đồ chơi": "DC",
        }[self.category]
        return f"{prefix}-{self.index:03d}"


def _round_price(value: float) -> int:
    """Giá tròn nghìn — người bán Việt Nam không niêm yết 187.432 đ."""
    return int(round(value / 1000.0)) * 1000


def build_products() -> list[Product]:
    products: list[Product] = []
    used_names: set[str] = set()
    index = 0

    for scenario, count in SCENARIOS.items():
        for _ in range(count):
            index += 1
            category, supplier_ids = CATEGORIES[index % len(CATEGORIES)]
            pool = [n for n in NAMES[category] if n not in used_names]
            if pool:
                name = pool[index % len(pool)]
            else:
                # Hết tên trong danh mục ⇒ thêm một chi tiết phân biệt thay vì
                # để hai dòng trùng tên. Tên trùng làm hỏng đúng thứ demo cần
                # chứng minh: tìm kiếm, gộp trùng, và "sản phẩm nào bán chạy".
                base = NAMES[category][index % len(NAMES[category])]
                qualifier = QUALIFIERS[index % len(QUALIFIERS)]
                name = f"{base} {qualifier}"
                suffix = 2
                while name in used_names:
                    suffix += 1
                    name = f"{base} {qualifier} {suffix}"
            used_names.add(name)

            base_cost = rng.choice([25, 45, 68, 92, 120, 165, 240, 320]) * 1000
            channel, store = CHANNELS[index % len(CHANNELS)]

            # Nhóm quyết định con số. Đây là chỗ "kịch bản" trở thành dữ liệu.
            if scenario == "A_FAST_LOW_STOCK":
                markup, quantity, reorder = 1.9, rng.randint(2, 6), 15
                created = TODAY - dt.timedelta(days=rng.randint(120, 300))
            elif scenario == "B_DEAD_STOCK":
                markup, quantity, reorder = 1.7, rng.randint(80, 200), 10
                created = TODAY - dt.timedelta(days=rng.randint(300, 540))
            elif scenario == "C_HIGH_MARGIN":
                markup, quantity, reorder = 3.2, rng.randint(30, 80), 10
                created = TODAY - dt.timedelta(days=rng.randint(60, 200))
            elif scenario == "D_LOW_MARGIN":
                # ⭐ Lãi gộp mỏng — sau phí sàn (~10%) thì âm. Đây là câu hỏi
                # "tháng này tôi lời bao nhiêu THẬT" (§9).
                # 1.05 chứ không phải 1.08: làm tròn giá tới nghìn có thể đẩy
                # lãi gộp lên vài trăm đồng, và ở mức 1.08 thì vài trăm đồng đó
                # đủ để một sản phẩm "lỗ sau phí" hoá ra hoà vốn. Kịch bản phải
                # đúng KỂ CẢ sau làm tròn.
                markup, quantity, reorder = 1.05, rng.randint(20, 60), 10
                created = TODAY - dt.timedelta(days=rng.randint(60, 200))
                channel, store = CHANNELS[rng.randint(0, 1)]  # sàn có phí
            elif scenario == "E_NEW":
                markup, quantity, reorder = 2.1, rng.randint(25, 60), 10
                created = TODAY - dt.timedelta(days=rng.randint(3, 20))
            elif scenario == "F_REORDER_SOON":
                markup, reorder = 2.0, 20
                quantity = reorder + rng.randint(1, 4)
                created = TODAY - dt.timedelta(days=rng.randint(90, 240))
            elif scenario == "G_SUPPLIER_DIFF":
                markup, quantity, reorder = 2.0, rng.randint(15, 70), 12
                created = TODAY - dt.timedelta(days=rng.randint(60, 300))
            elif scenario == "H_BUNDLE":
                markup, quantity, reorder = 2.2, rng.randint(30, 90), 12
                created = TODAY - dt.timedelta(days=rng.randint(60, 260))
            elif scenario == "I_OUT_OF_STOCK":
                markup, quantity, reorder = 2.0, 0, 10
                created = TODAY - dt.timedelta(days=rng.randint(90, 300))
            else:  # J_NORMAL — đối chứng
                markup, quantity, reorder = 2.0, rng.randint(25, 70), 10
                created = TODAY - dt.timedelta(days=rng.randint(60, 250))

            products.append(
                Product(
                    index=index,
                    scenario=scenario,
                    category=category,
                    name=name,
                    supplier_id=supplier_ids[index % len(supplier_ids)],
                    cost=base_cost,
                    price=_round_price(base_cost * markup),
                    quantity=quantity,
                    reorder=reorder,
                    channel=channel,
                    store=store,
                    created=created,
                    status="out_of_stock" if scenario == "I_OUT_OF_STOCK"
                    else "active",
                )
            )
    return products


# ── phiên bản (§4) ───────────────────────────────────────────────────────────

VARIANT_SETS = {
    "Thời trang": ("Màu", ["Đen", "Trắng", "Xanh navy"], "Size", ["S", "M", "L"]),
    "Thể thao": ("Size", ["39", "40", "41", "42"], None, None),
    "Mỹ phẩm": ("Dung tích", ["30ml", "50ml", "100ml"], None, None),
    "Đồ chơi": ("Màu", ["Đỏ", "Xanh", "Vàng"], None, None),
}


def build_variants(products: list[Product]) -> list[dict]:
    """20–30% sản phẩm có phiên bản (§4)."""
    rows: list[dict] = []
    eligible = [p for p in products if p.category in VARIANT_SETS]
    # Lấy đều tay, tất định: mỗi sản phẩm thứ hai trong nhóm đủ điều kiện.
    chosen = eligible[::2][:26]
    counter = 0
    for p in chosen:
        o1n, o1v, o2n, o2v = VARIANT_SETS[p.category]
        combos = [(a, b) for a in o1v for b in (o2v or [None])][:3]
        for value1, value2 in combos:
            counter += 1
            label = value1 if value2 is None else f"{value1} / {value2}"
            # Giá phiên bản: một số kế thừa (để trống), một số riêng — cả hai
            # đường phải chạy được, và "để trống" là đường dễ sai hơn.
            own_price = counter % 3 == 0
            rows.append(
                {
                    "variant_id": f"DEMO-V{counter:03d}",
                    "product_id": p.pid,
                    "variant_name": label,
                    "sku": f"{p.sku}-{counter:03d}",
                    "option_1_name": o1n,
                    "option_1_value": value1,
                    "option_2_name": o2n or "",
                    "option_2_value": value2 or "",
                    "cost_price": p.cost if own_price else "",
                    "selling_price": (p.price + 20000) if own_price else "",
                    "quantity": rng.randint(0, 25),
                }
            )
        p.variants = [r["variant_id"] for r in rows if r["product_id"] == p.pid]
    return rows


# ── báo giá nhà cung cấp (§17) ───────────────────────────────────────────────

def build_quotes(products: list[Product]) -> list[dict]:
    """Nhóm G có ≥2 báo giá; các nhóm khác có 1 (nhà cung cấp đang dùng)."""
    rows: list[dict] = []
    supplier_by_id = {s[0]: s for s in SUPPLIERS}
    counter = 0

    for p in products:
        counter += 1
        current = supplier_by_id[p.supplier_id]
        rows.append(
            {
                "quote_id": f"DEMO-Q{counter:04d}",
                "product_id": p.pid,
                "supplier_id": current[0],
                "supplier_name": current[1],
                "unit_cost": p.cost,
                "currency": "VND",
                "minimum_order_quantity": current[6],
                "lead_time_days": current[5],
                "rating": current[4],
                "is_current": "yes",
                "source_url": "",
                "notes": "Nhà cung cấp đang nhập",
            }
        )

        if p.scenario != "G_SUPPLIER_DIFF":
            continue

        # Hai lựa chọn thay thế. Mặc định là **đánh đổi thật**: rẻ hơn nhưng
        # chậm hơn, hoặc nhanh hơn nhưng đắt hơn — không phải "cái nào cũng tốt
        # hơn".
        #
        # Nhưng cứ ba sản phẩm nhóm G thì một sản phẩm có nguồn **rẻ hơn VÀ
        # nhanh hơn**. Đó cũng là thực tế (đôi khi nguồn hiện tại đơn giản là
        # tệ), và không có nó thì engine không bao giờ có "lựa chọn rõ ràng" để
        # đề xuất — dataset sẽ chỉ chứng minh được đường "chưa kết luận được".
        alternatives = [s for s in SUPPLIERS if s[0] != current[0]]
        cheaper = alternatives[counter % len(alternatives)]
        faster = alternatives[(counter + 3) % len(alternatives)]
        # Theo **chỉ số sản phẩm**, không theo `counter`: counter tăng ba đơn
        # vị cho mỗi sản phẩm nhóm G, nên `counter % 3` là một hằng số cho cả
        # nhóm — điều kiện sẽ đúng cho tất cả hoặc không cho cái nào.
        clearly_better = (p.index % 3) == 0

        counter += 1
        rows.append(
            {
                "quote_id": f"DEMO-Q{counter:04d}",
                "product_id": p.pid,
                "supplier_id": cheaper[0],
                "supplier_name": cheaper[1],
                "unit_cost": _round_price(p.cost * 0.88),
                "currency": "VND",
                "minimum_order_quantity": cheaper[6] * 2,
                "lead_time_days": max(1, current[5] - 5)
                if clearly_better
                else current[5] + 6,
                "rating": cheaper[4],
                "is_current": "no",
                "source_url": f"https://detail.1688.com/offer/{700000 + counter}.html",
                "notes": "Rẻ hơn và giao nhanh hơn"
                if clearly_better
                else "Rẻ hơn nhưng giao chậm hơn",
            }
        )

        counter += 1
        rows.append(
            {
                "quote_id": f"DEMO-Q{counter:04d}",
                "product_id": p.pid,
                "supplier_id": faster[0],
                "supplier_name": faster[1],
                "unit_cost": _round_price(p.cost * 1.07),
                "currency": "VND",
                "minimum_order_quantity": faster[6],
                # ⭐ Một báo giá CỐ Ý thiếu lead time: so sánh phải nói "chưa
                # biết" chứ không đoán (§17).
                "lead_time_days": "" if counter % 2 == 0 else max(1, current[5] - 4),
                "rating": faster[4],
                "is_current": "no",
                "source_url": f"https://www.alibaba.com/product-detail/{800000 + counter}.html",
                "notes": "Đắt hơn nhưng giao nhanh hơn",
            }
        )
    return rows


# ── khách hàng (§8) ──────────────────────────────────────────────────────────

FIRST = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Vũ", "Đặng", "Bùi", "Đỗ", "Hồ"]
MID = ["Thị", "Văn", "Minh", "Ngọc", "Thanh", "Quang", "Hải", "Thu"]
LAST = ["An", "Bình", "Chi", "Dũng", "Giang", "Hà", "Khoa", "Lan", "Mai", "Nam",
        "Oanh", "Phúc", "Quyên", "Sơn", "Tâm", "Uyên", "Vy", "Xuân", "Yến", "Đạt"]

SEGMENTS = ["vip", "returning", "new", "dormant", "one_time"]


def build_customers() -> list[dict]:
    rows = []
    for i in range(1, 41):
        segment = SEGMENTS[i % len(SEGMENTS)]
        if segment == "vip":
            order_count, days_since = rng.randint(8, 20), rng.randint(1, 14)
        elif segment == "returning":
            order_count, days_since = rng.randint(3, 7), rng.randint(5, 40)
        elif segment == "new":
            order_count, days_since = 1, rng.randint(1, 10)
        elif segment == "dormant":
            order_count, days_since = rng.randint(2, 6), rng.randint(95, 220)
        else:
            order_count, days_since = 1, rng.randint(60, 180)

        last = TODAY - dt.timedelta(days=days_since)
        first_order = last - dt.timedelta(days=rng.randint(0, 400))
        name = (f"{FIRST[i % len(FIRST)]} {MID[i % len(MID)]} "
                f"{LAST[i % len(LAST)]}")
        rows.append(
            {
                "customer_id": f"DEMO-C{i:03d}",
                "name": name,
                # Rõ ràng là dữ liệu giả (§8) — không PII thật.
                "email": f"khach{i:03d}@demo.tongtai.invalid",
                "phone": f"09{i:02d}000{i:03d}",
                "channel_identity": f"@khach{i:03d}",
                "channel": CHANNELS[i % len(CHANNELS)][0],
                "segment": segment,
                "first_order": first_order.isoformat(),
                "last_order": last.isoformat(),
                "order_count": order_count,
                "total_spent": 0,  # tính lại sau khi có đơn
            }
        )
    return rows


# ── đơn hàng + đối soát (§7, §9) ─────────────────────────────────────────────

def build_orders(products: list[Product], customers: list[dict]):
    """Đơn phải LIÊN KẾT sản phẩm thật (§7) — không doanh thu treo lơ lửng."""
    orders, settlements = [], []
    by_scenario: dict[str, list[Product]] = {}
    for p in products:
        by_scenario.setdefault(p.scenario, []).append(p)

    # Nhịp bán theo nhóm: bán chạy nhiều đơn, hàng tồn gần như không có đơn.
    weights = {
        "A_FAST_LOW_STOCK": 14, "B_DEAD_STOCK": 1, "C_HIGH_MARGIN": 8,
        "D_LOW_MARGIN": 12, "E_NEW": 4, "F_REORDER_SOON": 8,
        "G_SUPPLIER_DIFF": 7, "H_BUNDLE": 9, "I_OUT_OF_STOCK": 5,
        "J_NORMAL": 6,
    }
    pool: list[Product] = []
    for scenario, weight in weights.items():
        pool.extend(by_scenario[scenario] * weight)

    counter = 0
    spent: dict[str, int] = {}
    for _ in range(112):
        counter += 1
        product = pool[rng.randrange(len(pool))]
        customer = customers[rng.randrange(len(customers))]
        quantity = rng.randint(1, 3)
        unit_price = product.price
        gross = unit_price * quantity

        discount = _round_price(gross * 0.05) if counter % 4 == 0 else 0
        shipping = 25000 if product.channel in ("shopee", "tiktok") else 0
        fees = CHANNEL_FEES[product.channel]
        commission = _round_price((gross - discount) * fees["commission"])
        payment_fee = _round_price((gross - discount) * fees["payment"])
        refunded = counter % 23 == 0
        refund = gross - discount if refunded else 0

        order_date = TODAY - dt.timedelta(days=rng.randint(0, 88))
        status = "refunded" if refunded else "completed"
        payout = gross - discount - commission - payment_fee - refund

        orders.append(
            {
                "order_id": f"DEMO-O{counter:04d}",
                "order_date": order_date.isoformat(),
                "channel": product.channel,
                "store": product.store,
                "customer_id": customer["customer_id"],
                "product_id": product.pid,
                "variant_id": product.variants[0] if product.variants else "",
                "quantity": quantity,
                "unit_price": unit_price,
                "discount": discount,
                "shipping_fee": shipping,
                "platform_fee": commission,
                "payment_fee": payment_fee,
                "refund": refund,
                "payout": payout,
                "status": status,
            }
        )
        if not refunded:
            spent[customer["customer_id"]] = (
                spent.get(customer["customer_id"], 0) + gross - discount
            )

        for kind, amount in (
            ("commission", commission),
            ("payment_fee", payment_fee),
            ("shipping_fee", shipping),
            ("discount", discount),
            ("refund", refund),
        ):
            if amount == 0:
                continue
            settlements.append(
                {
                    "settlement_id": f"DEMO-S{len(settlements) + 1:04d}",
                    "order_id": f"DEMO-O{counter:04d}",
                    "kind": kind,
                    "direction": "debit",
                    "amount": amount,
                    "currency": "VND",
                    "occurred_at": order_date.isoformat(),
                    # Ai chịu phí: sàn trợ giá vận chuyển hay người bán trả.
                    "funded_by": "platform" if kind == "shipping_fee"
                    else "seller",
                }
            )

    for customer in customers:
        customer["total_spent"] = spent.get(customer["customer_id"], 0)

    return orders, settlements


# ── vận chuyển (§19) ─────────────────────────────────────────────────────────

def build_shipments(orders: list[dict]) -> list[dict]:
    states = [
        ("delivered", -5, "Đã giao"),
        ("delivered", -3, "Đã giao"),
        ("in_transit", 2, "Đang trung chuyển"),
        ("in_transit", 3, "Đang trung chuyển"),
        ("delayed", 6, "Chậm do thời tiết"),
        ("delayed", 8, "Chậm ở kho phân loại"),
        ("failed", 1, "Giao không thành công — khách không nghe máy"),
        ("delivered", -1, "Đã giao"),
    ]
    carriers = ["GHTK", "GHN", "Viettel Post", "J&T Express"]
    rows = []
    for i, (status, offset, note) in enumerate(states, start=1):
        order = orders[i * 7 % len(orders)]
        rows.append(
            {
                "shipment_id": f"DEMO-SH{i:03d}",
                "order_id": order["order_id"],
                "tracking_number": f"TT{700000000 + i * 137}",
                "carrier": carriers[i % len(carriers)],
                "shipment_status": status,
                "last_update": (TODAY - dt.timedelta(days=1)).isoformat(),
                "eta": (TODAY + dt.timedelta(days=offset)).isoformat(),
                "origin": "Kho Tân Bình, TP.HCM",
                "destination": "Hà Nội",
                "notes": note,
            }
        )
    return rows


# ── ghi XLSX ─────────────────────────────────────────────────────────────────

def _sheet(wb: Workbook, title: str, headers: list[str], rows: list[dict]):
    ws = wb.create_sheet(title)
    ws.append(headers)
    for row in rows:
        ws.append([row.get(h, "") for h in headers])
    return ws


def main() -> None:
    products = build_products()
    variants = build_variants(products)
    quotes = build_quotes(products)
    customers = build_customers()
    orders, settlements = build_orders(products, customers)
    shipments = build_shipments(orders)

    wb = Workbook()
    wb.remove(wb.active)

    _sheet(
        wb, "PRODUCTS",
        ["product_id", "external_id", "sku", "name", "category", "description",
         "image_url", "brand", "supplier_id", "supplier_name", "supplier_url",
         "supplier_country", "supplier_rating", "cost_price", "selling_price",
         "currency", "quantity", "reorder_level", "lead_time_days",
         "minimum_order_quantity", "sales_channel", "store_name", "status",
         "created_at", "updated_at", "source", "source_account", "scenario",
         "notes"],
        [
            {
                "product_id": p.pid,
                "external_id": p.pid,
                "sku": p.sku,
                "name": p.name,
                "category": p.category,
                "description": (
                    f"{p.name} — hàng {('nhập khẩu' if s[2] == 'CN' else 'trong nước')}, "
                    f"nguồn {s[1]}. Dữ liệu demo để thử Tổng Tài."
                ),
                "image_url": f"https://picsum.photos/seed/tongtai{p.index}/400/400",
                "brand": "Nhà Mình",
                "supplier_id": p.supplier_id,
                "supplier_name": s[1],
                "supplier_url": "",
                "supplier_country": s[2],
                "supplier_rating": s[4],
                "cost_price": p.cost,
                "selling_price": p.price,
                "currency": "VND",
                "quantity": p.quantity,
                "reorder_level": p.reorder,
                "lead_time_days": s[5],
                "minimum_order_quantity": s[6],
                "sales_channel": p.channel,
                "store_name": p.store,
                "status": p.status,
                "created_at": p.created.isoformat(),
                "updated_at": TODAY.isoformat(),
                # §5 — không giả rằng API đã kết nối.
                "source": "DEMO/FILE_BRIDGE",
                "source_account": "",
                "scenario": p.scenario,
                "notes": "",
            }
            for p in products
            for s in [next(x for x in SUPPLIERS if x[0] == p.supplier_id)]
        ],
    )

    _sheet(wb, "VARIANTS",
           ["variant_id", "product_id", "variant_name", "sku", "option_1_name",
            "option_1_value", "option_2_name", "option_2_value", "cost_price",
            "selling_price", "quantity"],
           variants)

    _sheet(wb, "SUPPLIERS",
           ["supplier_id", "name", "country", "platform", "url", "rating",
            "lead_time_days", "minimum_order_quantity", "payment_terms",
            "shipping_method", "currency", "notes"],
           [
               {
                   "supplier_id": s[0], "name": s[1], "country": s[2],
                   "platform": s[3], "url": "", "rating": s[4],
                   "lead_time_days": s[5], "minimum_order_quantity": s[6],
                   "payment_terms": s[7], "shipping_method": s[8],
                   "currency": "VND", "notes": "Nguồn demo",
               }
               for s in SUPPLIERS
           ])

    _sheet(wb, "SUPPLIER_QUOTES",
           ["quote_id", "product_id", "supplier_id", "supplier_name",
            "unit_cost", "currency", "minimum_order_quantity",
            "lead_time_days", "rating", "is_current", "source_url", "notes"],
           quotes)

    _sheet(wb, "CUSTOMERS",
           ["customer_id", "name", "email", "phone", "channel_identity",
            "channel", "segment", "first_order", "last_order", "order_count",
            "total_spent"],
           customers)

    _sheet(wb, "ORDERS",
           ["order_id", "order_date", "channel", "store", "customer_id",
            "product_id", "variant_id", "quantity", "unit_price", "discount",
            "shipping_fee", "platform_fee", "payment_fee", "refund", "payout",
            "status"],
           orders)

    _sheet(wb, "SETTLEMENT",
           ["settlement_id", "order_id", "kind", "direction", "amount",
            "currency", "occurred_at", "funded_by"],
           settlements)

    _sheet(wb, "SHIPMENTS",
           ["shipment_id", "order_id", "tracking_number", "carrier",
            "shipment_status", "last_update", "eta", "origin", "destination",
            "notes"],
           shipments)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    wb.save(OUT)

    print(f"✅ {OUT}")
    print(f"   products   {len(products)}")
    print(f"   variants   {len(variants)}")
    print(f"   suppliers  {len(SUPPLIERS)}")
    print(f"   quotes     {len(quotes)}")
    print(f"   customers  {len(customers)}")
    print(f"   orders     {len(orders)}")
    print(f"   settlement {len(settlements)}")
    print(f"   shipments  {len(shipments)}")
    for scenario, count in SCENARIOS.items():
        actual = sum(1 for p in products if p.scenario == scenario)
        assert actual == count, f"{scenario}: {actual} != {count}"
    print("   ✓ đủ số lượng từng nhóm kịch bản")


if __name__ == "__main__":
    main()
