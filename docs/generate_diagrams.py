from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent
FONTS = PROJECT_ROOT / "assets" / "fonts"
OUT_DIR = HERE / "assets"
OUT_DIR.mkdir(exist_ok=True)

def get_font(name, size):
    fp = FONTS / name
    if fp.exists():
        return ImageFont.truetype(str(fp), size)
    return ImageFont.load_default()

f_title = get_font("Inter-Black.ttf", 26)
f_h2 = get_font("Inter-Bold.ttf", 20)
f_sub = get_font("Inter-Medium.ttf", 15)
f_card_h = get_font("Inter-Bold.ttf", 17)
f_card_b = get_font("Inter-Regular.ttf", 14)
f_step_num = get_font("Inter-Black.ttf", 16)

# ----------------- DIAGRAM 1: 4 TIER ARCHITECTURE -----------------
def make_architecture_diagram():
    W, H = 1600, 1080
    im = Image.new("RGBA", (W, H), (245, 247, 250, 255))
    draw = ImageDraw.Draw(im)

    # Top banner header
    draw.rounded_rectangle([40, 30, W - 40, 110], radius=18, fill=(18, 38, 32, 255))
    draw.text((W // 2, 70), "АРХИТЕКТУРНАЯ СХЕМА BEKAT (4 УРОВНЯ СИСТЕМЫ)", fill=(255, 255, 255), font=f_title, anchor="mm")

    tiers = [
        {
            "num": "1",
            "title": "1. ЭКРАНЫ ПАССАЖИРА (Flutter UI — Android / iOS / Web)",
            "sub": "То, что видит и нажимает пассажир (на узбекском, русском и английском языках)",
            "border": (34, 165, 91),
            "cards": [
                ("HomeScreen (3D-карта)", "MapLibre GL, зум,\nкнопка GPS, таймер остановок"),
                ("SchemeScreen (Схема метро)", "Октолинейная схема сети,\nживые автобусы, узлы пересадок"),
                ("SearchScreen (Маршруты)", "Быстрый ввод, поиск POI,\nсравнение вариантов пути"),
                ("TripProgress (В пути)", "Счетчик оставшихся остановок,\nвремя до пересадки или выхода")
            ]
        },
        {
            "num": "2",
            "title": "2. УМНОЕ МАТЕМАТИЧЕСКОЕ ЯДРО (Domain Layer — Работает БЕЗ интернета)",
            "sub": "Мгновенные расчёты оптимального пути на процессоре телефона (чистый Dart)",
            "border": (45, 107, 240),
            "cards": [
                ("RaptorPlanner (Алгоритм)", "Пораундовый поиск (Round-Based)\nлучших цепочек с пересадками"),
                ("Schedule (Расписание)", "Интервалы движения (headway),\nсимуляция положения автобусов"),
                ("PlaceSearch (Поиск)", "Двуязычный индекс латиницы\nи кириллицы (chorsu = Чорсу)"),
                ("WalkModel (Пешая модель)", "Расчёт переходов между\nостановками (walkDetour = 1.25)")
            ]
        },
        {
            "num": "3",
            "title": "3. ЛОКАЛЬНЫЕ ДАННЫЕ И ХРАНИЛИЩЕ (Data & Offline-First Assets)",
            "sub": "Полный граф сети и векторные стили хранятся внутри установочного файла приложения",
            "border": (245, 158, 11),
            "cards": [
                ("network.json (GTFS)", "Полный граф: 10+ маршрутов,\n300+ остановок, координаты OSM"),
                ("MapLibre Style JSON", "Векторный стиль OpenFreeMap,\n3D-здания, цветные трассы линий"),
                ("AppState Controller", "Реактивное управление состоянием\nна базе ChangeNotifier"),
                ("Шрифты и Ассеты", "Семейство Inter (Medium, Bold),\nмаскот-автобус, векторные иконки")
            ]
        },
        {
            "num": "4",
            "title": "4. ОБЛАЧНЫЙ СЕРВЕР И B2G АНАЛИТИКА (Cloud API & Transport Analytics)",
            "sub": "Подключается при наличии сети: обновления базы, тепловая карта спроса для хокимията",
            "border": (21, 23, 28),
            "cards": [
                ("B2G Demand Map", "Анонимная тепловая карта\nнеудовлетворенного спроса горожан"),
                ("GTFS Update Server", "Обновления маршрутов и расписаний\nбез переустановки приложения"),
                ("GPS Telematics Gateway", "Шлюз интеграции с трекерами\nперевозчиков (2-й этап пилота)"),
                ("Nominatim Geocoding", "Резервный онлайн-поиск редких\nадресов за пределами базы POI")
            ]
        }
    ]

    ty = 135
    for t in tiers:
        # Tier box
        box_w = W - 80
        box_h = 210
        draw.rounded_rectangle([40, ty, 40 + box_w, ty + box_h], radius=16, fill=(255, 255, 255), outline=t["border"], width=3)

        # Header bar of tier
        draw.text((65, ty + 16), t["title"], fill=t["border"], font=f_h2)
        draw.text((65, ty + 44), t["sub"], fill=(91, 98, 112), font=f_sub)

        # 4 cards inside tier
        card_w = (box_w - 50) // 4
        cx = 65
        cy = ty + 72
        for title, desc in t["cards"]:
            draw.rounded_rectangle([cx, cy, cx + card_w - 12, cy + 120], radius=12, fill=(245, 247, 250), outline=(227, 231, 238), width=1)
            draw.text((cx + 14, cy + 14), title, fill=(21, 23, 28), font=f_card_h)
            draw.text((cx + 14, cy + 42), desc, fill=(91, 98, 112), font=f_card_b)
            cx += card_w

        ty += 230

    out_p = OUT_DIR / "bekat_architecture_diagram.png"
    im.save(out_p)
    print("Saved architecture diagram to:", out_p)

# ----------------- DIAGRAM 2: RAPTOR FLOW -----------------
def make_raptor_flow_diagram():
    W, H = 1600, 480
    im = Image.new("RGBA", (W, H), (245, 247, 250, 255))
    draw = ImageDraw.Draw(im)

    # Top banner header
    draw.rounded_rectangle([40, 24, W - 40, 90], radius=16, fill=(18, 38, 32, 255))
    draw.text((W // 2, 57), "КАК РАБОТАЕТ АЛГОРИТМ RAPTOR В ПРИЛОЖЕНИИ BEKAT", fill=(255, 255, 255), font=f_title, anchor="mm")

    steps = [
        ("ШАГ 1: Ввод маршрута", "Пассажир выбирает\nточку А и точку Б на карте\nили через поиск", (34, 165, 91)),
        ("ШАГ 2: Ближайшие остановки", "Поиск остановок пешком\nв радиусе 800м\n(WalkLeg, 75 м/мин)", (245, 158, 11)),
        ("ШАГ 3: Раунд 1 (Без пересадки)", "Проверка прямых автобусов\nот исходных остановок\nдо целевых (RideLeg)", (45, 107, 240)),
        ("ШАГ 4: Раунд 2 (1–2 пересадки)", "Поиск общих узлов пересадки\n(например, №9 → №7\nна вокзале Намангана)", (139, 92, 246)),
        ("ШАГ 5: Фильтр и Pareto-отбор", "Отбор лучших вариантов:\nминимум времени, минимум\nпересадок и ходьбы", (21, 23, 28)),
    ]

    sw = (W - 80 - 4 * 24) // 5
    sx = 40
    sy = 120
    sh = 320

    for i, (stitle, sdesc, scolor) in enumerate(steps):
        # Step card
        draw.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=16, fill=(255, 255, 255), outline=scolor, width=3)
        
        # Header box inside card
        draw.rounded_rectangle([sx + 10, sy + 10, sx + sw - 10, sy + 75], radius=10, fill=scolor)
        draw.text((sx + sw // 2, sy + 42), stitle, fill=(255, 255, 255), font=f_step_num, anchor="mm")

        # Description text
        draw.text((sx + 16, sy + 110), sdesc, fill=(91, 98, 112), font=get_font("Inter-Medium.ttf", 16))

        # Arrow to next step
        if i < 4:
            ax = sx + sw + 4
            ay = sy + sh // 2
            draw.polygon([(ax, ay - 12), (ax + 16, ay), (ax, ay + 12)], fill=scolor)

        sx += sw + 24

    out_p = OUT_DIR / "raptor_flow_diagram.png"
    im.save(out_p)
    print("Saved raptor flow diagram to:", out_p)

if __name__ == "__main__":
    make_architecture_diagram()
    make_raptor_flow_diagram()
