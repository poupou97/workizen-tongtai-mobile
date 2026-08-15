#!/usr/bin/env python3
"""Lấy ảnh cho bộ sản phẩm DEMO — WTM-414.

## Vì sao có công cụ này thay vì gọi một API ảnh ngẫu nhiên

Bản đầu dùng `loremflickr` theo **danh mục**: "Bình giữ nhiệt inox" ra ảnh một
dòng suối, "Bình nước thể thao" ra ảnh một con đường. Ảnh **đúng chủ đề nhưng
sai vật thể** — nó đổi "trống" thành "không liên quan", không giải quyết gì.

Founder chốt: *ảnh phải khớp vật thể · cùng sản phẩm luôn ra cùng ảnh · ưu tiên
bundle một bộ hợp lệ hơn API ngẫu nhiên*.

## Cách làm

1. `search`  — tra Openverse (CC, **không cần tài khoản**, giấy phép ghi rõ từng
   kết quả), lấy ứng viên theo truy vấn tiếng Anh của **từng SKU**.
2. `sheet`   — ghép ứng viên thành một **bảng ảnh liên hoàn** có đánh số, để
   người (hoặc agent) **NHÌN** rồi loại ảnh sai vật thể. ⛔ Không tin từ khoá:
   chính việc tin từ khoá đã sinh ra ảnh dòng suối.
3. `keep`    — giữ ảnh đã duyệt, cắt vuông 400×400, ghi vào
   `assets/demo/products/<sku>.jpg` **và** ghi nguồn + giấy phép + tác giả vào
   manifest.

⚠️ Ảnh **bundle vào app**, không hotlink: bố cục không được phụ thuộc mạng, và
một URL bên thứ ba có thể chết bất cứ lúc nào.

Dùng:
    tool/fetch_demo_product_images.py search  <batch>
    tool/fetch_demo_product_images.py sheet   <batch>
    tool/fetch_demo_product_images.py keep    <batch> <chỉ-số-bị-loại...>
"""
import hashlib
import html
import io
import json
import pathlib
import re
import sys
import urllib.parse
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
XLSX = ROOT / 'assets/demo/TongTai-Commerce-Demo-100-Products.xlsx'
WORK = ROOT / 'build/demo-images'
OUT = ROOT / 'assets/demo/products'
MANIFEST = OUT / 'ATTRIBUTION.json'
UA = 'TongTaiDemo/1.0 (https://github.com/poupou97/workizen-tongtai-mobile)'


def products():
    """(sku, tên, danh mục) của 100 sản phẩm demo, đọc thẳng từ workbook."""
    z = zipfile.ZipFile(XLSX)
    xml = z.read('xl/worksheets/sheet1.xml').decode('utf-8', 'ignore')
    rows = re.findall(r'<row[^>]*>(.*?)</row>', xml, re.S)

    def cells(r):
        out = []
        for m in re.finditer(r'<c[^>]*?>(.*?)</c>', r, re.S):
            v = re.search(r'<is><t[^>]*>(.*?)</t></is>', m.group(1), re.S) or \
                re.search(r'<v>(.*?)</v>', m.group(1), re.S)
            out.append(html.unescape(v.group(1)) if v else '')
        return out

    hdr = cells(rows[0])
    i_sku, i_name, i_cat = hdr.index('sku'), hdr.index('name'), hdr.index('category')
    out = []
    for r in rows[1:]:
        c = cells(r)
        if len(c) > max(i_sku, i_name, i_cat):
            out.append((c[i_sku], c[i_name], c[i_cat]))
    return out


def query_for(name):
    """Tên tiếng Việt → truy vấn tiếng Anh **theo VẬT THỂ**.

    Openverse đánh chỉ mục theo tag tiếng Anh; tra bằng tiếng Việt ra rỗng và
    ảnh rơi về ngẫu nhiên — đúng cái bẫy của bản trước.
    """
    n = name.lower()
    for vi, en in _WORDS:
        if vi in n:
            return en
    # ⛔ KHÔNG có truy vấn dự phòng.
    #
    # Bản trước trả 'retail product' cho mọi món chưa có từ khoá — và Openverse
    # trả **cùng một tấm ảnh kệ siêu thị** cho tất cả: 13/20 ô của lô 1 giống
    # hệt nhau. Một truy vấn chung chung không cho ra ảnh chung chung; nó cho ra
    # cùng một ảnh sai, lặp lại.
    #
    # Không biết món này là gì ⇒ **không tra** ⇒ dùng ô ảnh mặc định. Đúng luật
    # Founder: *precision > coverage*.
    return None


# Bảng tra theo **vật thể**, không theo danh mục. Thứ tự có ý nghĩa: cụm dài
# đứng trước để "bình sữa" không bị "bình" nuốt mất.
_WORDS = [
    # Điện tử
    ('sạc dự phòng', 'power bank'),
    ('bàn phím', 'computer keyboard'),
    ('đồng hồ thông minh', 'smartwatch'),
    ('tai nghe', 'headphones'),
    ('chuột không dây', 'computer mouse'),
    ('cáp sạc', 'usb cable'),
    ('ổ cắm điện', 'power strip'),
    ('loa bluetooth', 'bluetooth speaker'),
    ('quạt mini', 'desk fan'),
    ('giá đỡ điện thoại', 'phone stand'),
    ('đèn led kẹp', 'desk lamp'),
    ('camera hành trình', 'dashcam'),
    # Gia dụng
    ('bình giữ nhiệt', 'thermos flask'),
    ('kệ nhà tắm', 'shelf rack'),
    ('dao kéo', 'kitchen knife'),
    ('nồi chiên', 'air fryer'),
    ('máy xay', 'blender'),
    ('hộp đựng thực phẩm', 'food container'),
    ('khay đá', 'ice cube tray'),
    ('chổi lau nhà', 'floor mop'),
    ('rổ nhựa', 'plastic basket'),
    ('móc treo tường', 'wall hook'),
    ('thảm chùi chân', 'doormat'),
    ('túi hút chân không', 'vacuum storage bag'),
    # Mỹ phẩm
    ('kem chống nắng', 'sunscreen'),
    ('cọ trang điểm', 'makeup brush'),
    ('sữa rửa mặt', 'face wash'),
    ('nước tẩy trang', 'micellar water'),
    ('serum', 'serum dropper bottle'),
    ('phấn nước', 'cushion compact'),
    ('son kem', 'lipstick'),
    ('kem trị mụn', 'skincare cream jar'),
    ('dầu gội', 'shampoo bottle'),
    ('xịt khoáng', 'facial mist spray'),
    ('kem dưỡng ẩm', 'moisturizer jar'),
    ('mặt nạ', 'face mask sheet'),
    # Mẹ & bé
    ('bình sữa', 'baby bottle'),
    ('xe đẩy', 'baby stroller'),
    ('bỉm', 'diapers'),
    ('ghế ăn dặm', 'high chair'),
    ('nôi rung', 'baby crib'),
    ('thảm chơi', 'play mat'),
    ('khăn sữa', 'baby washcloth'),
    ('yếm ăn dặm', 'baby bib'),
    ('máy hút sữa', 'breast pump'),
    ('áo liền quần sơ sinh', 'baby onesie'),
    ('gặm nướu', 'teether toy'),
    ('túi ủ sữa', 'bottle warmer bag'),
    ('xe cân bằng', 'balance bike'),
    # Thể thao
    ('tạ tay', 'dumbbell'),
    ('thảm yoga', 'yoga mat'),
    ('dây nhảy', 'jump rope'),
    ('găng tay tập', 'gym gloves'),
    ('dây kháng lực', 'resistance band'),
    ('bóng tập gym', 'exercise ball'),
    ('vợt cầu lông', 'badminton racket'),
    ('giày chạy bộ', 'running shoes'),
    ('con lăn massage', 'foam roller'),
    ('túi đựng đồ tập', 'gym bag'),
    ('bình nước', 'sports water bottle'),
    # Văn phòng phẩm
    ('bấm kim', 'stapler'),
    ('băng keo', 'adhesive tape'),
    ('kẹp giấy', 'paper clips'),
    ('bìa còng', 'ring binder'),
    ('bút bi', 'ballpoint pen'),
    ('bút highlight', 'highlighter pen'),
    ('sổ tay', 'notebook'),
    ('hộp bút', 'pencil case'),
    ('giấy in', 'printer paper'),
    ('giấy note', 'sticky notes'),
    ('kéo văn phòng', 'scissors'),
    ('bảng trắng', 'whiteboard'),
    ('bộ tô màu', 'coloring pencils'),
    # Đồ chơi
    ('xếp hình', 'jigsaw puzzle'),
    ('cầu trượt', 'playground slide'),
    ('búp bê', 'rag doll'),
    ('đất nặn', 'play dough'),
    ('slime', 'slime toy'),
    ('ô tô điều khiển', 'remote control car'),
    ('bảng vẽ điện tử', 'drawing tablet'),
    ('đồ chơi nấu ăn', 'toy kitchen set'),
    ('đồ chơi bác sĩ', 'toy doctor kit'),
    # ⛔ CỐ Ý KHÔNG ánh xạ 'lego' (DC-095). Tên món **chính là** tên thương hiệu,
    # nên mọi ảnh khớp đều mang logo — vi phạm thẳng luật loại của Founder
    # (*"logo/brand nhìn thấy được ⇒ loại"*). Không tra còn đúng hơn tra rồi loại.
    # Thời trang
    ('áo thun', 'plain t-shirt'),
    ('áo polo', 'polo shirt'),
    ('áo khoác gió', 'windbreaker jacket'),
    ('áo len', 'knitted sweater'),
    ('áo hoodie', 'hoodie'),
    ('áo sơ mi', 'blouse shirt'),
    ('chân váy', 'pleated skirt'),
    ('váy hoa', 'floral dress'),
    ('đầm công sở', 'office dress'),
    ('quần short', 'shorts'),
    ('quần jogger', 'jogger pants'),
    ('quần jean', 'jeans'),
]


def search(batch):
    """Tra Openverse, tải ứng viên đầu tiên cho mỗi SKU trong lô."""
    WORK.mkdir(parents=True, exist_ok=True)
    items = products()[batch * 20:(batch + 1) * 20]
    meta = []
    for sku, name, cat in items:
        q = query_for(name)
        if q is None:
            meta.append({'sku': sku, 'name': name, 'query': '(bỏ qua)', 'ok': False})
            print(f'  – {sku} {name}: chưa có từ khoá vật thể ⇒ placeholder')
            continue
        url = ('https://api.openverse.org/v1/images/?'
               + urllib.parse.urlencode({
                   'q': q, 'license': 'cc0,pdm,by,by-sa',
                   'page_size': 3, 'mature': 'false'}))
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            data = json.loads(urllib.request.urlopen(req, timeout=25).read())
            results = data.get('results') or []
        except Exception as e:                       # noqa: BLE001
            print(f'  ✗ {sku} {name}: {e}')
            results = []
        if not results:
            meta.append({'sku': sku, 'name': name, 'query': q, 'ok': False})
            continue
        r = results[0]
        img_url = r.get('url')
        try:
            req = urllib.request.Request(img_url, headers={'User-Agent': UA})
            raw = urllib.request.urlopen(req, timeout=25).read()
            (WORK / f'{sku}.raw').write_bytes(raw)
        except Exception as e:                       # noqa: BLE001
            print(f'  ✗ tải {sku}: {e}')
            meta.append({'sku': sku, 'name': name, 'query': q, 'ok': False})
            continue
        meta.append({
            'sku': sku, 'name': name, 'query': q, 'ok': True,
            'source': img_url,
            'page': r.get('foreign_landing_url'),
            'license': f"{r.get('license')} {r.get('license_version') or ''}".strip(),
            'creator': r.get('creator'),
            'title': r.get('title'),
        })
        print(f'  ✓ {sku} {name} ← "{q}"')
    (WORK / f'batch{batch}.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2))
    print(f'\nlô {batch}: {sum(1 for m in meta if m["ok"])}/{len(meta)} có ảnh')


def retry(rnd):
    """Vòng tra lại cho những SKU **chưa có ảnh nào được duyệt**.

    Hai thay đổi so với vòng 1, cả hai đều rút ra từ việc NHÌN kết quả:

    * `category=photograph` — vòng 1 trả về một **biểu tượng** xe đẩy (ô cam,
      hình vẽ) cho "baby stroller". Biểu tượng là ảnh hợp lệ với Openverse
      nhưng vô dụng làm ảnh sản phẩm, và không từ khoá nào loại được nó.
    * `rank` — lấy ứng viên thứ *n*, vì kết quả đầu hỏng không có nghĩa là cả
      truy vấn hỏng.
    """
    WORK.mkdir(parents=True, exist_ok=True)
    todo = [(sku, name) for sku, name, _ in products()
            if not (OUT / f'{sku}.jpg').exists() and query_for(name)]
    print(f'còn thiếu ảnh: {len(todo)} SKU')
    for c in range((len(todo) + 19) // 20):
        chunk = todo[c * 20:(c + 1) * 20]
        meta = [_fetch(sku, name, query_for(name), rnd) for sku, name in chunk]
        label = f'r{rnd}_{c}'
        (WORK / f'batch{label}.json').write_text(
            json.dumps(meta, ensure_ascii=False, indent=2))
        print(f'  lô {label}: {sum(1 for m in meta if m["ok"])}/{len(meta)} có ảnh')


def _fetch(sku, name, q, rank=0, photo_only=True):
    """Tra một SKU, tải ứng viên hạng `rank`. Trả về bản ghi meta."""
    # ⚠️ KHÔNG dùng `license_type=commercial`. Nó cho **by-nd** lọt qua —
    # ND cho phép dùng thương mại nhưng **cấm tác phẩm phái sinh**, trong khi
    # công cụ này cắt vuông + resize *mọi* tấm, nên tấm nào cũng là phái sinh.
    # Bốn ảnh ND đã lọt vào bộ đầu tiên đúng theo đường này.
    params = {'q': q, 'license': 'cc0,pdm,by,by-sa',
              'page_size': 8, 'mature': 'false'}
    if photo_only:
        params['category'] = 'photograph'
    url = 'https://api.openverse.org/v1/images/?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA})
        results = json.loads(urllib.request.urlopen(req, timeout=25).read()).get('results') or []
    except Exception as e:                           # noqa: BLE001
        print(f'  ✗ {sku}: {e}')
        results = []
    if len(results) <= rank:
        return {'sku': sku, 'name': name, 'query': q, 'ok': False}
    r = results[rank]
    try:
        req = urllib.request.Request(r.get('url'), headers={'User-Agent': UA})
        (WORK / f'{sku}.raw').write_bytes(urllib.request.urlopen(req, timeout=25).read())
    except Exception as e:                           # noqa: BLE001
        print(f'  ✗ tải {sku}: {e}')
        return {'sku': sku, 'name': name, 'query': q, 'ok': False}
    return {'sku': sku, 'name': name, 'query': q, 'ok': True,
            'source': r.get('url'), 'page': r.get('foreign_landing_url'),
            'license': f"{r.get('license')} {r.get('license_version') or ''}".strip(),
            'creator': r.get('creator'), 'title': r.get('title')}


def sheet(batch):
    """Ghép bảng ảnh liên hoàn có đánh số + tên, để NHÌN rồi loại."""
    from PIL import Image, ImageDraw

    meta = json.loads((WORK / f'batch{batch}.json').read_text())
    cols, cell, pad, label = 5, 220, 10, 34
    rows = (len(meta) + cols - 1) // cols
    sheet_img = Image.new(
        'RGB', (cols * (cell + pad) + pad, rows * (cell + label + pad) + pad),
        (245, 246, 248))
    draw = ImageDraw.Draw(sheet_img)
    for i, m in enumerate(meta):
        x = pad + (i % cols) * (cell + pad)
        y = pad + (i // cols) * (cell + label + pad)
        raw = WORK / f'{m["sku"]}.raw'
        if m.get('ok') and raw.exists():
            try:
                im = Image.open(io.BytesIO(raw.read_bytes())).convert('RGB')
                s = min(im.size)
                im = im.crop(((im.width - s) // 2, (im.height - s) // 2,
                              (im.width + s) // 2, (im.height + s) // 2))
                sheet_img.paste(im.resize((cell, cell)), (x, y))
            except Exception:                        # noqa: BLE001
                draw.rectangle([x, y, x + cell, y + cell], fill=(220, 220, 220))
        else:
            draw.rectangle([x, y, x + cell, y + cell], fill=(230, 230, 230))
        draw.text((x + 4, y + cell + 4), f'[{i}] {m["name"][:26]}', fill=(20, 20, 30))
        draw.text((x + 4, y + cell + 18), f'    {m["query"]}', fill=(110, 110, 130))
    out = WORK / f'sheet{batch}.png'
    sheet_img.save(out)
    print(out)


def audit():
    """Bảng ảnh **toàn bộ danh mục** — thứ đã bundle, nhìn cùng một lúc.

    Vì sao cần dù mỗi lô đã duyệt: sai sót lớn nhất chỉ lộ ra khi xếp cạnh nhau
    — **hai SKU khác nhau dùng chung một tấm ảnh**. Duyệt theo lô không bao giờ
    thấy được điều đó (mỗi lô đều "đúng vật thể"), nhưng người xem lướt danh
    mục thì thấy ngay hai dòng giống hệt nhau và kết luận dữ liệu là giả.
    """
    from PIL import Image, ImageDraw

    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    items = [(sku, name) for sku, name, _ in products() if (OUT / f'{sku}.jpg').exists()]
    cols, cell, pad, label = 6, 180, 8, 30
    rows = (len(items) + cols - 1) // cols
    img = Image.new('RGB', (cols * (cell + pad) + pad, rows * (cell + label + pad) + pad),
                    (245, 246, 248))
    draw = ImageDraw.Draw(img)
    digests = {}
    for i, (sku, name) in enumerate(items):
        x, y = pad + (i % cols) * (cell + pad), pad + (i // cols) * (cell + label + pad)
        data = (OUT / f'{sku}.jpg').read_bytes()
        digests.setdefault(hashlib.sha256(data).hexdigest(), []).append(sku)
        img.paste(Image.open(io.BytesIO(data)).convert('RGB').resize((cell, cell)), (x, y))
        draw.text((x + 4, y + cell + 3), f'{sku} {name[:22]}', fill=(20, 20, 30))
        draw.text((x + 4, y + cell + 16), (manifest.get(sku, {}).get('license') or '?'),
                  fill=(110, 110, 130))
    out = WORK / 'catalog.png'
    img.save(out)
    dupes = {d: v for d, v in digests.items() if len(v) > 1}
    print(f'{len(items)}/{len(products())} SKU có ảnh · {out}')
    if dupes:
        for v in dupes.values():
            print(f'  ⚠️ TRÙNG ẢNH: {", ".join(v)}')
    else:
        print('  ✓ không có hai SKU nào dùng chung một tấm ảnh')


def dart():
    """Sinh `demo_media_manifest.dart` **từ chính thư mục ảnh**.

    Danh sách viết tay sẽ lệch với thư mục vào ngày ai đó thêm/loại một ảnh, và
    lúc ấy app hỏi một asset không tồn tại — ô ảnh vỡ, tệ hơn ô ảnh trống.
    """
    skus = sorted(f.stem for f in OUT.glob('*.jpg'))
    dest = ROOT / 'lib/features/tongtai/inventory/demo_media_manifest.dart'
    head = dest.read_text().split('const Set<String>')[0]
    body = '\n'.join(f"  '{s}'," for s in skus)
    dest.write_text(f'{head}const Set<String> kDemoProductImageSkus = {{\n{body}\n}};\n')
    print(f'{dest.relative_to(ROOT)}: {len(skus)} SKU')


def keep(batch, rejected):
    """Giữ ảnh đã duyệt: cắt vuông 400×400 + ghi manifest giấy phép."""
    from PIL import Image

    OUT.mkdir(parents=True, exist_ok=True)
    meta = json.loads((WORK / f'batch{batch}.json').read_text())
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    kept = 0
    for i, m in enumerate(meta):
        if i in rejected or not m.get('ok'):
            continue
        raw = WORK / f'{m["sku"]}.raw'
        if not raw.exists():
            continue
        im = Image.open(io.BytesIO(raw.read_bytes())).convert('RGB')
        s = min(im.size)
        im = im.crop(((im.width - s) // 2, (im.height - s) // 2,
                      (im.width + s) // 2, (im.height + s) // 2)).resize((400, 400))
        im.save(OUT / f'{m["sku"]}.jpg', quality=82, optimize=True)
        manifest[m['sku']] = {k: m.get(k) for k in
                              ('name', 'title', 'creator', 'license', 'source', 'page')}
        kept += 1
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True))
    print(f'giữ {kept} ảnh · manifest {len(manifest)} mục')


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'audit':
        audit(); sys.exit(0)
    if cmd == 'dart':
        dart(); sys.exit(0)
    batch = sys.argv[2]
    if cmd == 'search':
        search(int(batch))
    elif cmd == 'retry':
        retry(int(batch))
    elif cmd == 'sheet':
        sheet(batch)
    elif cmd == 'keep':
        keep(batch, {int(x) for x in sys.argv[3:]})
