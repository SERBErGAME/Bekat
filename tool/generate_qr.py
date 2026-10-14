import urllib.request
import urllib.parse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent
ASSETS = PROJECT_ROOT / "docs" / "assets"
FONTS = PROJECT_ROOT / "assets" / "fonts"

DOWNLOAD_URL = "https://github.com/SERBErGAME/Bekat/releases/latest/download/Bekat-arm64.apk"
GITHUB_REPO_URL = "https://github.com/SERBErGAME/Bekat"

def get_font(name, size):
    font_path = FONTS / name
    if font_path.exists():
        return ImageFont.truetype(str(font_path), size)
    return ImageFont.load_default()

def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask

def make_qr_with_center_logo():
    raw_qr_path = HERE / "qr_raw_1000.png"
    if not raw_qr_path.exists():
        encoded_url = urllib.parse.quote(DOWNLOAD_URL, safe="")
        api_url = f"https://api.qrserver.com/v1/create-qr-code/?size=1000x1000&ecc=H&data={encoded_url}"
        print(f"Downloading QR from: {api_url}")
        req = urllib.request.Request(api_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as resp:
            qr_bytes = resp.read()
        with open(raw_qr_path, "wb") as f:
            f.write(qr_bytes)

    qr_img = Image.open(raw_qr_path).convert("RGBA")
    w, h = qr_img.size

    # Prepare center logo badge
    badge_size = 240
    badge = Image.new("RGBA", (badge_size, badge_size), (255, 255, 255, 255))
    badge_mask = rounded_mask((badge_size, badge_size), 54)
    badge.putalpha(badge_mask)

    # Load app icon
    icon_path = ASSETS / "icon_1024.png"
    if not icon_path.exists():
        icon_path = PROJECT_ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"
    icon = Image.open(icon_path).convert("RGBA")
    
    icon_inner_size = 204
    icon_resized = icon.resize((icon_inner_size, icon_inner_size), Image.Resampling.LANCZOS)
    icon_mask = rounded_mask((icon_inner_size, icon_inner_size), 46)
    icon_resized.putalpha(icon_mask)

    # Composite icon onto badge (with border padding)
    pad = (badge_size - icon_inner_size) // 2
    badge.alpha_composite(icon_resized, (pad, pad))

    # Add soft shadow around the badge
    shadow_margin = 20
    shadow_size = (badge_size + shadow_margin * 2, badge_size + shadow_margin * 2)
    shadow = Image.new("RGBA", shadow_size, (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([shadow_margin, shadow_margin, shadow_margin + badge_size - 1, shadow_margin + badge_size - 1], radius=54, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))

    # Place in center of QR
    cx = (w - badge_size) // 2
    cy = (h - badge_size) // 2

    qr_final = qr_img.copy()
    qr_final.alpha_composite(shadow, (cx - shadow_margin, cy - shadow_margin + 4))
    qr_final.alpha_composite(badge, (cx, cy))

    out_qr_path = PROJECT_ROOT / "qr_bekat.png"
    qr_final.save(out_qr_path)
    print(f"Saved standalone QR code to: {out_qr_path}")
    return qr_final

def make_promo_card(lang="ru"):
    # Card canvas size: 1440 x 900 px
    W, H = 1440, 900
    canvas = Image.new("RGBA", (W, H), (238, 241, 246, 255)) # #EEF1F6
    draw = ImageDraw.Draw(canvas)

    # 1. Subtle top background accent
    top_bar = Image.new("RGBA", (W, 140), (45, 107, 240, 15))
    canvas.alpha_composite(top_bar, (0, 0))

    # Load fonts
    f_badge = get_font("Inter-Bold.ttf", 15)
    f_h1 = get_font("Inter-Black.ttf", 64)
    f_sub = get_font("Inter-SemiBold.ttf", 22)
    f_route = get_font("Inter-Bold.ttf", 16)
    f_feat = get_font("Inter-Medium.ttf", 17)
    f_card_h = get_font("Inter-Bold.ttf", 26)
    f_card_sub = get_font("Inter-Medium.ttf", 15)
    f_btn = get_font("Inter-Bold.ttf", 17)
    f_url = get_font("Inter-SemiBold.ttf", 15)

    texts = {
        "uz": {
            "badge": "Android ilovasi · NamDTU 2026",
            "title": "Bekat",
            "sub": "Namangan avtobuslari uchun aqlli marshrut xaritasi",
            "phone_img": "phone_02_home_uz.png",
            "features": [
                ("⚡", "Tezkor oflayn qidiruv (RAPTOR)"),
                ("🗺️", "3D interaktiv shahar xaritasi"),
                ("🕒", "Avtobus jadvali va oraliq vaqti"),
                ("🌐", "O‘zbek, Rus va Ingliz tillarida"),
                ("📱", "Android ARM64 uchun tayyor APK"),
            ],
            "card_h": "Ilovani yuklab oling",
            "card_sub": "Kamerangizni QR-kodga yo‘naltiring",
            "btn": "⬇  Yuklab olish: Bekat APK (30 MB)",
            "ver": "Talqin: v1.0.0 (ARM64)",
            "official": "✓ Rasmiy GitHub Reliz",
        },
        "ru": {
            "badge": "Android-приложение · НамГТУ 2026",
            "title": "Bekat",
            "sub": "Умная карта автобусных маршрутов Намангана",
            "phone_img": "phone_02_home_ru.png",
            "features": [
                ("⚡", "Быстрый поиск маршрутов офлайн (RAPTOR)"),
                ("🗺️", "3D интерактивная карта города"),
                ("🕒", "Интервалы движения и расписание"),
                ("🌐", "На узбекском, русском и английском"),
                ("📱", "Готовый APK для Android (ARM64)"),
            ],
            "card_h": "Скачать приложение",
            "card_sub": "Наведите камеру на QR-код",
            "btn": "⬇  Скачать: Bekat APK (30 МБ)",
            "ver": "Версия: v1.0.0 (ARM64)",
            "official": "✓ Официальный релиз на GitHub",
        }
    }
    T = texts.get(lang, texts["ru"])

    # Top pill
    draw.rounded_rectangle([70, 50, 360, 84], radius=17, fill=(255, 255, 255, 255), outline=(227, 231, 238, 255), width=2)
    draw.text((88, 56), T["badge"], fill=(45, 107, 240, 255), font=f_badge)

    # Title & Subtitle
    draw.text((70, 100), T["title"], fill=(21, 23, 28, 255), font=f_h1)
    draw.text((70, 178), T["sub"], fill=(91, 98, 112, 255), font=f_sub)

    # Route badges row
    routes = [
        ("1", (229, 57, 53)),
        ("2", (30, 111, 232)),
        ("3", (34, 165, 91)),
        ("5", (245, 158, 11)),
        ("7", (139, 92, 246)),
        ("9", (6, 182, 212)),
    ]
    rx = 70
    ry = 224
    for r_num, col in routes:
        draw.rounded_rectangle([rx, ry, rx + 36, ry + 36], radius=10, fill=col)
        draw.text((rx + 13, ry + 8), r_num, fill=(255, 255, 255, 255), font=f_route)
        rx += 46

    # Phone mockup
    phone_path = ASSETS / T["phone_img"]
    if not phone_path.exists():
        phone_path = ASSETS / "phone_02_home_uz.png"
    if phone_path.exists():
        phone = Image.open(phone_path).convert("RGBA")
        ph_w = 340
        ph_h = int(phone.size[1] * (ph_w / phone.size[0]))
        phone_resized = phone.resize((ph_w, ph_h), Image.Resampling.LANCZOS)
        canvas.alpha_composite(phone_resized, (70, 280))

    # Features list (placed next to phone)
    fx = 445
    fy = 320
    for emoji_icon, feat_text in T["features"]:
        draw.rounded_rectangle([fx, fy, fx + 375, fy + 48], radius=14, fill=(255, 255, 255, 235), outline=(227, 231, 238, 255))
        draw.text((fx + 16, fy + 12), f"{emoji_icon}  {feat_text}", fill=(21, 23, 28, 255), font=f_feat)
        fy += 60

    # Bus mascot (docs/assets/bus.png)
    bus_path = ASSETS / "bus.png"
    if bus_path.exists():
        bus = Image.open(bus_path).convert("RGBA")
        bus_w = 230
        bus_h = int(bus.size[1] * (bus_w / bus.size[0]))
        bus_resized = bus.resize((bus_w, bus_h), Image.Resampling.LANCZOS)
        canvas.alpha_composite(bus_resized, (fx + 60, fy + 15))

    # 3. Right side: Card with QR code
    cw, ch = 480, 760
    cx = W - cw - 70
    cy = 70

    # Card shadow
    card_shadow = Image.new("RGBA", (cw + 40, ch + 40), (0, 0, 0, 0))
    cs_draw = ImageDraw.Draw(card_shadow)
    cs_draw.rounded_rectangle([20, 20, 20 + cw, 20 + ch], radius=32, fill=(20, 30, 60, 40))
    card_shadow = card_shadow.filter(ImageFilter.GaussianBlur(16))
    canvas.alpha_composite(card_shadow, (cx - 20, cy - 14))

    # Card body
    card = Image.new("RGBA", (cw, ch), (255, 255, 255, 255))
    c_mask = rounded_mask((cw, ch), 32)
    card.putalpha(c_mask)

    c_draw = ImageDraw.Draw(card)
    # Card Header
    c_draw.text((40, 40), T["card_h"], fill=(21, 23, 28, 255), font=f_card_h)
    c_draw.text((40, 78), T["card_sub"], fill=(91, 98, 112, 255), font=f_card_sub)

    # QR Code
    qr_img = Image.open(PROJECT_ROOT / "qr_bekat.png").convert("RGBA")
    qr_display_size = 380
    qr_card = qr_img.resize((qr_display_size, qr_display_size), Image.Resampling.LANCZOS)
    card.alpha_composite(qr_card, ((cw - qr_display_size) // 2, 120))

    # Download Button badge
    btn_w = 400
    btn_h = 56
    btn_x = (cw - btn_w) // 2
    btn_y = 525
    c_draw.rounded_rectangle([btn_x, btn_y, btn_x + btn_w, btn_y + btn_h], radius=18, fill=(45, 107, 240, 255))
    
    # Measure text center
    btn_txt = T["btn"]
    bbox = c_draw.textbbox((0, 0), btn_txt, font=f_btn)
    tw = bbox[2] - bbox[0]
    c_draw.text((btn_x + (btn_w - tw) // 2, btn_y + 17), btn_txt, fill=(255, 255, 255, 255), font=f_btn)

    # Info pills below button
    tag_y = 600
    tag1_w = 190
    tag2_w = 202
    c_draw.rounded_rectangle([btn_x, tag_y, btn_x + tag1_w, tag_y + 36], radius=10, fill=(238, 241, 246, 255))
    c_draw.text((btn_x + 16, tag_y + 9), T["ver"], fill=(91, 98, 112, 255), font=get_font("Inter-SemiBold.ttf", 13))

    c_draw.rounded_rectangle([btn_x + tag1_w + 8, tag_y, btn_x + btn_w, tag_y + 36], radius=10, fill=(238, 241, 246, 255))
    c_draw.text((btn_x + tag1_w + 16, tag_y + 9), T["official"], fill=(34, 165, 91, 255), font=get_font("Inter-SemiBold.ttf", 12))

    # GitHub URL footer
    c_draw.text((btn_x + 85, 680), "github.com/SERBErGAME/Bekat", fill=(91, 98, 112, 255), font=f_url)

    canvas.alpha_composite(card, (cx, cy))

    filename = f"bekat_download_card_{lang}.png" if lang != "ru" else "bekat_download_card.png"
    out_card_path = PROJECT_ROOT / filename
    canvas.save(out_card_path)
    print(f"Saved promo card to: {out_card_path}")

if __name__ == "__main__":
    make_qr_with_center_logo()
    make_promo_card("ru")
    make_promo_card("uz")
