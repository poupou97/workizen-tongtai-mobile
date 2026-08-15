#!/usr/bin/env python3
"""Sinh bộ nguồn nhận diện từ tệp gốc Founder giao — WTM-416.

## Vì sao là script chứ không phải cắt tay trong Preview

Một icon Android không phải *một* tệp: nó là icon nền + icon foreground (bị mặt
nạ cắt) + icon legacy + ảnh splash sáng + ảnh splash tối, mỗi thứ một tỉ lệ
khác nhau. Cắt tay thì lần sau đổi logo phải nhớ lại toàn bộ con số — và cái
được nhớ sai luôn là **tỉ lệ vùng an toàn**, thứ chỉ lộ ra trên máy thật.

## Vì sao icon launcher và splash KHÔNG dùng chung một tệp

Hai bên cắt theo hai luật khác nhau, nên một tệp không thể vừa cả hai:

* `flutter_launcher_icons` tự chèn `android:inset="16%"` vào foreground ⇒ ảnh
  còn **68%** trước khi mặt nạ chạm vào. Muốn kết quả cuối 58% thì tệp nguồn
  phải để **85,3%** (0,58 ÷ 0,68).
* Splash Android 12 **không** có inset ấy, nhưng lại bị **mặt nạ tròn** với
  đường kính 768/1152 = 66,7% khung. Đưa tệp 85,3% vào đây là cắt cụt logo.

Dùng chung một tệp thì một trong hai chỗ chắc chắn sai — và chỗ sai chỉ lộ ra
trên máy thật, sau khi cài.

## Ba con số quan trọng

* **58%** — foreground của adaptive icon, và con số này KHÔNG phải 66%.
  Khung 108dp, vùng nhìn thấy 72dp, vùng an toàn **66dp** — mà 66dp trên khung
  108dp là **61%**, không phải 66%. Ghi chú cũ trong `pubspec.yaml` chép thẳng
  số 66 từ đơn vị dp sang đơn vị phần trăm; dựng thử ở 66% thì mặt nạ tròn
  **cắt cụt chấm chữ "i"**. 58% cho content 62,6dp — nằm gọn trong vùng an
  toàn, còn thở được ở mọi hình mặt nạ (tròn · squircle · giọt nước).
* **80%** — icon legacy/iOS, không bị mặt nạ nên để rộng hơn.
* **1024** — cạnh xuất; `flutter_launcher_icons` tự thu nhỏ cho từng mật độ.

## Vì sao có bản logo cho nền tối

Chữ "CRM" trong logo gốc màu **xanh navy đậm** (1,22,61). Đặt nguyên bản ấy lên
splash nền tối thì chữ CRM **biến mất** — logo vẫn "đúng" theo tệp gốc mà người
dùng chỉ thấy một nửa. Bản tối đổi riêng chữ CRM sang trắng, không đụng vào
gradient cam–tím và con cáo.
"""
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/new-icon'
OUT = ROOT / 'assets/branding'      # nguồn để SINH icon native — không bundle
RUNTIME = ROOT / 'assets/startup'   # asset app đọc LÚC CHẠY — có bundle
SIZE = 1024
# Tỉ lệ MONG MUỐN sau khi mọi thứ cắt xong, tính trên khung 108dp.
#
# 0,48 không phải con số cho đẹp: nó **đo từ máy thật**. Bản 0,58 nằm gọn trong
# vùng an toàn và không bị cắt gì — nhưng đo trên ảnh chụp S24 thì logo chiếm
# **88%** bề ngang phần nhìn thấy, trong khi ô icon bản vẽ Founder chỉ ~72%.
# Icon vẫn "đúng luật" mà trông chật, chữ CRM sát đáy. Vùng an toàn nói *cái gì
# KHÔNG bị cắt*, nó không nói *cái gì trông cân*.
#
#   logo / phần nhìn thấy = TARGET ÷ (72/108) ⇒ 0,48 ÷ 0,667 = 72%.
TARGET = 0.48
GEN_INSET = 0.16         # inset flutter_launcher_icons tự chèn vào foreground
FG_RATIO = TARGET / (1 - 2 * GEN_INSET)   # 0,853 — bù lại phần bị inset ăn mất
SPLASH_RATIO = TARGET    # splash không có inset ⇒ dùng thẳng tỉ lệ mong muốn
LEGACY_RATIO = 0.80

# Đo từ chính tệp gốc, không phỏng đoán.
BG_TOP = (252, 251, 252)      # đỉnh ô icon
BG_LEFT = (197, 186, 235)     # tím nhạt góc dưới trái
BG_RIGHT = (240, 226, 232)    # hồng nhạt góc dưới phải
NAVY = (1, 22, 61)            # chữ CRM
DARK_BG = (13, 17, 38)        # nền phiên bản tối trong bảng trình bày


def _logo():
    """Logo đã cắt sát phần **NHÌN THẤY ĐƯỢC**.

    ⚠️ Không dùng thẳng `im.getbbox()`. Tệp gốc có một quầng alpha = 1 trải rộng
    quanh logo — mắt không thấy, nhưng `getbbox()` thấy, nên khung cắt rộng hơn
    logo thật ~10%. Hệ quả: mọi tỉ lệ tính ở dưới đều bị hụt đúng 10% và icon
    ra nhỏ hơn thiết kế mà không có gì báo. Đây là dạng "một thứ tự xưng là cái
    nó không phải": hộp giới hạn tự xưng là logo.
    """
    im = Image.open(SRC / 'new-ai-crm-icon-transparent.png').convert('RGBA')
    visible = im.getchannel('A').point(lambda a: 255 if a > 8 else 0)
    return im.crop(visible.getbbox())


def _gradient():
    """Nền chuyển sắc: trắng ở trên, tím nhạt trái ↔ hồng nhạt phải ở dưới."""
    bg = Image.new('RGB', (SIZE, SIZE), BG_TOP)
    d = ImageDraw.Draw(bg)
    for y in range(SIZE):
        t = (y / (SIZE - 1)) ** 1.6          # dồn màu về đáy như bản gốc
        for x0, x1, target in ((0, SIZE // 2, BG_LEFT), (SIZE // 2, SIZE, BG_RIGHT)):
            c = tuple(round(BG_TOP[i] + (target[i] - BG_TOP[i]) * t) for i in range(3))
            d.line([(x0, y), (x1, y)], fill=c)
    return bg.filter(__import__('PIL.ImageFilter', fromlist=['x']).GaussianBlur(20))


def _fit(logo, canvas, ratio):
    """Đặt logo vào giữa canvas, chiếm `ratio` cạnh — giữ nguyên tỉ lệ."""
    box = round(SIZE * ratio)
    w, h = logo.size
    s = min(box / w, box / h)
    small = logo.resize((round(w * s), round(h * s)), Image.LANCZOS)
    canvas.paste(small, ((SIZE - small.width) // 2, (SIZE - small.height) // 2), small)
    return canvas


def _crm_to_white(logo):
    """Đổi RIÊNG chữ CRM sang trắng cho nền tối.

    Nhận diện theo màu chứ không theo toạ độ: chỉ pixel gần navy mới đổi, nên
    con cáo (cam/trắng) và gradient cam–tím không bị đụng tới.
    """
    out = logo.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a > 8 and abs(r - NAVY[0]) < 60 and abs(g - NAVY[1]) < 60 and abs(b - NAVY[2]) < 70:
                px[x, y] = (255, 255, 255, a)
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    logo = _logo()

    # 1. Foreground adaptive — để RỘNG hơn đích vì generator sẽ inset 16%.
    _fit(logo, Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0)), FG_RATIO) \
        .save(OUT / 'app_icon_foreground.png')  # xem ghi chú 58% ở đầu tệp

    # 2. Nền adaptive — chuyển sắc thật, không phải một màu phẳng.
    _gradient().save(OUT / 'app_icon_background.png')

    # 3. Icon legacy / iOS — không bị mặt nạ nên logo để rộng hơn.
    _fit(logo, _gradient().convert('RGBA'), LEGACY_RATIO).convert('RGB') \
        .save(OUT / 'app_icon.png')

    # 4. Logo splash — tỉ lệ khác foreground launcher, xem ghi chú đầu tệp.
    _fit(logo, Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0)), SPLASH_RATIO) \
        .save(OUT / 'app_splash_logo.png')
    _fit(_crm_to_white(logo), Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0)), SPLASH_RATIO) \
        .save(OUT / 'app_splash_logo_dark.png')

    # 5. Asset màn khởi động Flutter. Tách khỏi `assets/branding/` vì hai thứ
    #    khác vòng đời: bên kia chỉ generator đọc lúc dựng, bên này đi vào APK.
    RUNTIME.mkdir(parents=True, exist_ok=True)
    lock = logo.copy()
    lock.thumbnail((640, 640), Image.LANCZOS)
    lock.save(RUNTIME / 'logo_lockup.png')

    # Dải linh vật cắt thẳng từ ảnh Founder giao. Cắt cả nền chuyển sắc chứ
    # KHÔNG tách nền: áo hoodie và giày của cáo đều màu trắng gần bằng nền, nên
    # mọi phép tách nền tự động đều ăn lẹm vào chính con cáo. Mép trên/dưới của
    # dải đo được 250–254 (gần trắng) nên đặt trên nền trắng không lộ đường ghép.
    band = Image.open(SRC / 'loading-screen.png').convert('RGB').crop((0, 855, 941, 1460))
    band.save(RUNTIME / 'startup_mascot.png', quality=90)

    for f in sorted(OUT.glob('app_*.png')) + sorted(RUNTIME.glob('*.png')):
        print(f'{f.relative_to(ROOT)}  {Image.open(f).size}  {Image.open(f).mode}')
    print(f'nền tối dùng {DARK_BG}')


if __name__ == '__main__':
    main()
