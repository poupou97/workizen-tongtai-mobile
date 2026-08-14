#!/usr/bin/env python3
"""Cắt bộ linh vật Ai CRM từ tờ art Founder giao — WTM-417.

## Vì sao không cắt theo lưới

Tờ art xếp hình theo bốn khu (TƯ THẾ · LÀM VIỆC + TƯƠNG TÁC · BIỂU CẢM · PHỤ
KIỆN) và **các ô không đều nhau**: hình cao thấp khác nhau, khoảng cách khác
nhau. Cắt theo lưới đều thì mỗi ảnh dính một mẩu của hình bên cạnh — đúng lỗi
mà bộ linh vật cũ (WTM-349) đã tránh bằng cách này.

## Cách làm

1. **Nền = vùng sáng NỐI TỪ MÉP vào.** Không dùng "mọi pixel sáng": áo hoodie
   của cáo cũng trắng, và một phép thử theo màu sẽ khoét thủng chính con cáo.
   Nền phải được định nghĩa bằng *liên thông với bên ngoài*, không bằng màu.
2. **Thành phần liên thông** trên phần không phải nền ⇒ mỗi hình một khối.
3. Lọc khối lớn, **xếp theo hàng rồi theo cột**, gán tên theo đúng thứ tự đọc
   của tờ art.

⚠️ Hình lớn ở panel trái (cáo vẫy tay trên nền chuyển sắc) **bị bỏ qua**: nền
của nó không phải màu sáng nên không tách được, và tư thế ấy đã có bản sạch
trong khu TƯ THẾ ("Chào mừng").
"""
import collections
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/mascot/new-mascot.png'
OUT = ROOT / 'assets/mascot/brand'

# Tên theo đúng thứ tự đọc của tờ art. Nhãn tiếng Việt là của Founder; slug
# tiếng Anh để trùng quy ước đặt tên asset trong repo.
NAMES = [
    # TƯ THẾ
    ('waving', 'Chào mừng'),
    ('pointing', 'Chỉ tay gợi ý'),
    ('thumbs_up', 'Thumbs up'),
    ('running', 'Đang chạy'),
    ('jumping', 'Nhảy vui mừng'),
    ('confident', 'Tự tin'),
    # LÀM VIỆC + TƯƠNG TÁC (cùng một dải chiều cao)
    ('at_laptop', 'Làm việc'),
    ('online_meeting', 'Họp online'),
    ('analyzing', 'Phân tích dữ liệu'),
    ('searching', 'Tìm kiếm'),
    ('idea', 'Có ý tưởng'),
    ('loving', 'Yêu thích'),
    ('ok', 'OK!'),
    # BIỂU CẢM (chỉ phần đầu) + PHỤ KIỆN
    ('happy', 'Vui vẻ'),
    ('excited', 'Hào hứng'),
    ('surprised', 'Ngạc nhiên'),
    ('thinking', 'Suy nghĩ'),
    ('focused', 'Tập trung'),
    ('wink', 'Nháy mắt'),
    ('sad', 'Buồn'),
    ('superhero', 'Siêu tốc'),
    ('security', 'Bảo mật'),
    ('announcing', 'Thông báo'),
    ('celebrating', 'Chúc mừng'),
]


def _background_mask(im):
    """Bitmap nền: vùng sáng **nối từ mép ảnh** vào."""
    w, h = im.size
    px = im.load()
    bg = bytearray(w * h)
    q = collections.deque()

    def light(p):
        return min(p) > 232

    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if bg[i] or not light(px[x, y]):
            continue
        bg[i] = 1
        if x > 0:
            q.append((x - 1, y))
        if x < w - 1:
            q.append((x + 1, y))
        if y > 0:
            q.append((x, y - 1))
        if y < h - 1:
            q.append((x, y + 1))
    return bg


def _components(bg, w, h):
    """Khối liên thông của phần KHÔNG phải nền, kèm hộp giới hạn."""
    seen = bytearray(w * h)
    out = []
    for sy in range(h):
        for sx in range(w):
            if bg[sy * w + sx] or seen[sy * w + sx]:
                continue
            stack = [(sx, sy)]
            seen[sy * w + sx] = 1
            x0 = x1 = sx
            y0 = y1 = sy
            n = 0
            while stack:
                x, y = stack.pop()
                n += 1
                x0, x1 = min(x0, x), max(x1, x)
                y0, y1 = min(y0, y), max(y1, y)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1),
                               (1, 1), (1, -1), (-1, 1), (-1, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        j = ny * w + nx
                        if not bg[j] and not seen[j]:
                            seen[j] = 1
                            stack.append((nx, ny))
            out.append((x0, y0, x1, y1, n))
    return out


def main():
    im = Image.open(SRC).convert('RGB')
    w, h = im.size
    bg = _background_mask(im)

    figures = [
        c for c in _components(bg, w, h)
        if (c[2] - c[0]) > 55 and (c[3] - c[1]) > 55 and c[4] > 2500
        # ⛔ bỏ hình hero ở panel trái: nền chuyển sắc, không tách được
        and not (c[0] < 400 and (c[2] - c[0]) > 300)
    ]
    figures.sort(key=lambda c: (c[1] // 120, c[0]))

    if len(figures) != len(NAMES):
        raise SystemExit(
            f'tìm được {len(figures)} hình nhưng bảng tên có {len(NAMES)} — '
            'tờ art đã đổi bố cục, ĐỪNG gán bừa theo thứ tự'
        )

    OUT.mkdir(parents=True, exist_ok=True)
    for (x0, y0, x1, y1, _), (slug, label) in zip(figures, NAMES):
        cell = im.crop((x0, y0, x1 + 1, y1 + 1)).convert('RGBA')
        cp = cell.load()
        for y in range(cell.height):
            for x in range(cell.width):
                if bg[(y0 + y) * w + (x0 + x)]:
                    cp[x, y] = (255, 255, 255, 0)
        cell = cell.crop(cell.getbbox())
        cell.thumbnail((512, 512), Image.LANCZOS)
        cell.save(OUT / f'{slug}.png')
        print(f'  {slug:16} {label:20} {cell.size}')
    print(f'{len(figures)} tư thế → {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
