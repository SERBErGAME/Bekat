import docx
import os
import copy

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "Eng_yaxshi_kreativ_goya_Bekat_Rasulov_Farruh.docx")
OUT = os.path.join(HERE, "Eng_yaxshi_kreativ_goya_Bekat_Qodirov_Ulugbek.docx")

AUTHOR = "Qodirov Ulug‘bek"
CO_AUTHOR = "Zamalitdinov Salimbek"
GROUP = "37-ATT guruhi, 4-kurs"
FACULTY = "Axborot texnologiyalari va sunʼiy intellekt"
OTM = "NamDTU (Namangan davlat texnika universiteti)"
DATE = "14 / 10 / 2026"
PRICE_START = "40 000 000 (qirq million) so‘m"
PRICE_FULL = "120 000 000 (bir yuz yigirma million) so‘m"
PHONE = "+998 90 555 80 91"
EMAIL = "Dragonknight281101@gmail.com"

d = docx.Document(SRC)

for t in d.tables:
    for row in t.rows:
        for cell in row.cells:
            for p in cell.paragraphs:
                if "Rasulov Farruh" in p.text:
                    p.text = p.text.replace("Rasulov Farruh", AUTHOR)
                if "Rasulov F." in p.text:
                    p.text = p.text.replace("Rasulov F.", "Qodirov U.")
                if "18 000 000" in p.text:
                    p.text = p.text.replace("18 000 000", "40 000 000")

# Table 0: Asosiy ma'lumotlar
t0 = d.tables[0]
t0.rows[2].cells[1].text = AUTHOR
t0.rows[3].cells[1].text = OTM
t0.rows[4].cells[1].text = "Bakalavriat"
t0.rows[5].cells[1].text = FACULTY
t0.rows[6].cells[1].text = GROUP
t0.rows[7].cells[1].text = PHONE
t0.rows[8].cells[1].text = EMAIL
t0.rows[9].cells[1].text = DATE

# Table 3: Ariza matni
t3 = d.tables[3]
t3.rows[0].cells[0].text = (
    f"Men, NamDTU talabasi {AUTHOR} ({GROUP}), hammuallif {CO_AUTHOR} bilan birgalikda, "
    f"“Eng yaxshi kreativ g‘oya” respublika tanlovida “Bekat — Namangan shahar avtobuslari uchun aqlli marshrut xaritasi, "
    f"almashinuvli navigatsiya va jamoat transporti axborot tizimi (mobil ilova)” loyihasi bilan ishtirok etish uchun ariza topshiraman. "
    f"Loyiha mazmuni, amalga oshirish mexanizmi, smetasi va rivojlanish rejasi ilova qilinayotgan loyiha hujjatlarida bayon qilingan. "
    f"Taqdim etilgan ma’lumotlarning haqqoniyligi va mualliflik huquqlariga rioya etilishi uchun mas’uliyatni qabul qilaman."
)

# Table 5: Loyiha pasporti
t5 = d.tables[5]
t5.rows[1].cells[1].text = AUTHOR
t5.rows[2].cells[1].text = (
    f"{AUTHOR} — asosiy muallif va loyiha rahbari (Lead & Mobile Developer, Flutter/Dart);\n"
    f"{CO_AUTHOR} — hammuallif, jamoa a’zosi (AI, Backend & Algorithm Developer);\n"
    f"Transport logistikasi bo‘yicha maslahatchi va tester (jalb etish rejalashtirilgan)"
)
t5.rows[4].cells[1].text = f"{FACULTY} ({GROUP})"
t5.rows[9].cells[1].text = f"{PRICE_START} (startap, 1-bosqich). Keyingi bosqichlar uchun qo‘shimcha {PRICE_FULL} rejalashtirilgan."

# Table 26: Smeta (40 mln so'm)
t26 = d.tables[26]
costs = [
    ("1", "Dala tadqiqoti: yo‘nalishlar va bekatlarni GPS bilan belgilash", "2 kishi × 2 oy", "4 000 000 so‘m", "8 000 000 so‘m", "Barcha 10+ yo‘nalish va 300+ bekatlarni o‘rganish, yo‘l kira, mobil internet"),
    ("2", "Flutter (Dart) mobil ilovasi va interfeys ishlab chiqish", "Asosiy muallif", "10 000 000 so‘m", "10 000 000 so‘m", "Yagona kod bazasi (Android, iOS, veb), qidiruv, 3D xarita va interaktiv ekranlar"),
    ("3", "Marshrut algoritmi (RAPTOR), GTFS bazasi va backend", "Hammuallif", "8 000 000 so‘m", "8 000 000 so‘m", "Oflyayn marshrutlash algoritmi, GTFS formatini tuzish, server sinxronizatsiyasi"),
    ("4", "Bulutli server (VPS) va xarita xizmatlari", "6 oy", "500 000 so‘m", "3 000 000 so‘m", "Ma’lumotlar bazasi yangilanishlari, hosting va geokodlash"),
    ("5", "3D-multfilm dizayni, metro tarmoq sxemasi va infografika", "1 paket", "3 500 000 so‘m", "3 500 000 so‘m", "Shahar diqqatga sazovor joylari 3D belgilari, vektorli metro sxemasi, ilova ikonkalari"),
    ("6", "Pilot sinov va monitoring (100+ foydalanuvchi)", "1 paket", "3 000 000 so‘m", "3 000 000 so‘m", "Talabalar va aholi orasida sinov, so‘rovnoma, tarqatma materiallar"),
    ("7", "Google Play / App Store dasturchi akkaunti", "1 to‘plam", "2 500 000 so‘m", "2 500 000 so‘m", "Ilovani rasmiy do‘konlarga joylash va reliz xarajatlari"),
    ("8", "EHM guvohnomasini olish va kutilmagan texnik xarajatlar", "1 paket", "2 000 000 so‘m", "2 000 000 so‘m", "Adliya vazirligidan patent/guvohnoma olish, aloqa va ehtiyot qismlar"),
]
for i, row in enumerate(costs, start=1):
    for c_idx, val in enumerate(row):
        t26.rows[i].cells[c_idx].text = val
t26.rows[9].cells[4].text = "40 000 000 so‘m"

# Table 31: Jamoa va vazifalar
t31 = d.tables[31]
# Ensure it has 3 rows
if len(t31.rows) < 4:
    last_tr = t31.rows[-1]._tr
    new_tr = copy.deepcopy(last_tr)
    last_tr.addnext(new_tr)

t31.rows[1].cells[0].text = AUTHOR
t31.rows[1].cells[1].text = "Loyiha rahbari va bosh dasturchi (Lead & Mobile Developer)"
t31.rows[1].cells[2].text = "Flutter/Dart mobil ilovasi, 3D xarita interfeysi, metro sxemasi, dala tadqiqoti"
t31.rows[1].cells[3].text = f"NamDTU talabasi ({GROUP}), Flutter/Dart dasturlash, mobil arxitektura"

t31.rows[2].cells[0].text = CO_AUTHOR
t31.rows[2].cells[1].text = "Hammuallif / Backend & Algorithm Developer"
t31.rows[2].cells[2].text = "RAPTOR marshrut algoritmi, GTFS ma’lumotlar bazasi, server infratuzilmasi va AI tahlili"
t31.rows[2].cells[3].text = "NamDTU talabasi, backend dasturlash, algoritmlar, sun’iy intellekt"

t31.rows[3].cells[0].text = "Taklif etiladigan mutaxassis"
t31.rows[3].cells[1].text = "Ilmiy maslahatchi / Transport logisti"
t31.rows[3].cells[2].text = "Shahar yo‘nalishlari grafigi, brutto-shartnomalar tahlili va pilot monitoringi"
t31.rows[3].cells[3].text = "NamDTU professori / Transport logistikasi mutaxassisi"

# Table 34: Muallif tasdig'i
t34 = d.tables[34]
t34.rows[0].cells[1].text = AUTHOR
t34.rows[2].cells[1].text = DATE

# Paragraphs check
for p in d.paragraphs:
    if "Rasulov Farruh" in p.text:
        p.text = p.text.replace("Rasulov Farruh", AUTHOR)
    if "Rasulov F." in p.text:
        p.text = p.text.replace("Rasulov F.", "Qodirov U.")
    if "18 000 000" in p.text:
        p.text = p.text.replace("18 000 000", "40 000 000")

d.core_properties.author = AUTHOR
d.core_properties.title = "Bekat — Namangan avtobuslari uchun aqlli marshrut xaritasi"
d.save(OUT)
print("Updated DOCX saved to:", OUT)
