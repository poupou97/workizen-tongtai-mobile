# Brand assets — Tổng Tài (Business Fox, Origami)

Mascot = **Business Fox**, visual language = **Origami low-poly** (Founder,
2026-07-24; concept 08a). See `docs/01-PRODUCT/MASCOT-BUSINESS-FOX.md`.

## Sources (edit these)
- `app_icon.svg` — full-bleed opaque icon (navy square + fox); iOS/legacy Android.
- `app_icon_foreground.svg` — transparent, padded fox for the Android adaptive foreground.
- The matching `*.png` are 1024² renders (macOS `qlmanage -t -s 1024`).

## Regenerate native icon + splash
```
qlmanage -t -s 1024 -o /tmp assets/branding/app_icon.svg            # → re-export PNGs if the SVG changed
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
Adaptive background + splash ground: `#111827` (navy). iOS alpha stripped
(`remove_alpha_ios: true`) for App Store compliance.
