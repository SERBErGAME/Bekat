"""Fill the "Eng yaxshi kreativ g'oya" template for the Bekat project.

Base: the AgroZen application (same template, already polished formatting).
Only cell/paragraph text is replaced; styles, borders and fonts are kept.
Run:  python3 build_ariza.py
"""
import copy
import os

import docx
import docx.shared
import docx.text.paragraph

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.expanduser(
    "~/Desktop/Eng_yaxshi_kreativ_goya_AgroZen_Zamalitdinov_Salimbek.docx")
OUT = os.path.join(HERE, "Eng_yaxshi_kreativ_goya_Bekat_Rasulov_Farruh.docx")

TBD = "[to‘ldiriladi]"
AUTHOR = "Rasulov Farruh"
AUTHOR_SHORT = "Rasulov F."
OTM = "Namangan davlat texnika universiteti"
DATE = "14 / 10 / 2026"
TITLE = ("Bekat — Namangan shahar avtobuslari uchun almashinuvli marshrut "
         "rejalashtiruvchi va interaktiv transport xaritasi (mobil ilova)")
TITLE_SHORT = "Bekat — Namangan avtobuslari uchun aqlli marshrut xaritasi"


# Body text sizes (half-points) per table, matching the template's tables.
# The AgroZen base has some cells pasted in Times New Roman / grey italics;
# every filled run is reset to the style font so the document looks uniform.
SIZES = {}


def set_par(p, text, size=None):
    """Put text into the first run of a paragraph, drop the other runs."""
    runs = p.runs
    run = runs[0] if runs else p.add_run()
    run.text = text
    for r in runs[1:]:
        r._r.getparent().remove(r._r)
    rpr = run._r.rPr
    if rpr is not None:
        run._r.remove(rpr)
    if size:
        run.font.size = docx.shared.Pt(size)


def set_cell(cell, text, size=None):
    """text: str or list of lines (one paragraph per line)."""
    lines = [text] if isinstance(text, str) else list(text)
    pars = cell.paragraphs
    tmpl = pars[0]._p
    for extra in pars[1:]:
        extra._p.getparent().remove(extra._p)
    set_par(cell.paragraphs[0], lines[0], size)
    anchor = tmpl
    for line in lines[1:]:
        new = copy.deepcopy(tmpl)
        anchor.addnext(new)
        anchor = new
        set_par(docx.text.paragraph.Paragraph(new, cell._parent), line, size)


def set_row(table, ri, values):
    """Set the distinct cells of a row (merged cells are skipped)."""
    seen, cells = set(), []
    for c in table.rows[ri].cells:
        if id(c._tc) not in seen:
            seen.add(id(c._tc))
            cells.append(c)
    for c, v in zip(cells, values):
        if v is not None:
            set_cell(c, v, SIZES.get(id(table._tbl)))


def fit_rows(table, n_body, header=1, footer=0):
    """Make the table have exactly n_body body rows (copying the last body row)."""
    body = len(table.rows) - header - footer
    while body < n_body:
        last = table.rows[header + body - 1]._tr
        last.addnext(copy.deepcopy(last))
        body += 1
    while body > n_body:
        tr = table.rows[header + body - 1]._tr
        tr.getparent().remove(tr)
        body -= 1


d = docx.Document(SRC)
T = d.tables
for i, pt in {0: 9, 4: 9, 5: 9, 34: 9, 25: 8, 15: 8, 24: 8, 30: 8, 31: 8,
              26: 7.5}.items():
    SIZES[id(T[i]._tbl)] = pt

# ---------------------------------------------------------------- 0. Asosiy
for ri, v in {1: TITLE, 2: AUTHOR, 3: OTM, 4: "Bakalavriat", 5: TBD,
              6: TBD, 7: TBD, 8: TBD, 9: DATE}.items():
    set_row(T[0], ri, [None, v])

# ---------------------------------------------------------------- 1. Ariza
set_cell(T[3].rows[0].cells[0],
         f"Men, {AUTHOR}, “Eng yaxshi kreativ g‘oya” respublika tanlovida "
         f"“{TITLE}” loyihasi bilan ishtirok etish uchun ariza topshiraman. "
         "Loyiha mazmuni, amalga oshirish mexanizmi, smetasi va rivojlanish "
         "rejasi ilova qilinayotgan loyiha hujjatlarida bayon qilingan. "
         "Taqdim etilgan ma’lumotlarning haqqoniyligi va mualliflik "
         "huquqlariga rioya etilishi uchun mas’uliyatni qabul qilaman.")
set_row(T[4], 0, [None, AUTHOR])
set_row(T[4], 2, [None, DATE])

# ---------------------------------------------------------------- 2. Pasport
for ri, v in {
    0: TITLE,
    1: AUTHOR,
    2: "Mavjud emas",
    3: OTM,
    4: TBD,
    5: "Smart City, jamoat transporti, mobil ilovalar (Android / iOS), "
       "geoaxborot tizimlari (GIS)",
    6: "Ishlaydigan prototip (MVP): Android / iOS / veb ilova, almashinuvli "
       "marshrut algoritmi, metro uslubidagi sxema",
    7: "Namangan shahri aholisi va mehmonlari: talabalar, maktab o‘quvchilari, "
       "ishchilar, keksalar, sayyohlar. Tashkilotlar: shahar hokimligi, "
       "viloyat transport boshqarmasi, avtobus tashuvchi korxonalar.",
    8: "3 oy (8 hafta ma’lumot yig‘ish va ilova ishlab chiqish + 4 hafta "
       "pilot sinov)",
    9: "18 000 000 so‘m (ma’lumot yig‘ish, server, xarita xizmatlari, "
       "dizayn va pilot xarajatlari)",
}.items():
    set_row(T[5], ri, [None, v])

# ---------------------------------------------------------------- 3. Annotatsiya
set_cell(T[6].rows[0].cells[0], [
    "“Bekat” — Namangan shahrida avtobusda harakatlanishni oson va tushunarli "
    "qiladigan mobil ilova. Foydalanuvchi xaritadan yoki qidiruv orqali boradigan "
    "joyini tanlaydi, ilova esa unga qaysi bekatdan, qaysi raqamli avtobusga "
    "chiqish, qayerda boshqa avtobusga o‘tish (almashinuv) va qancha piyoda "
    "yurish kerakligini bosqichma-bosqich ko‘rsatadi. To‘g‘ridan-to‘g‘ri "
    "yo‘nalish bo‘lmasa, ilova bir nechta avtobusni birlashtiradi yoki manzilga "
    "eng yaqin yetib boradigan variantni taklif qiladi.",
    "Asosiy imkoniyatlar:",
    "• Butun shahar avtobus tarmog‘ining metro sxemasi uslubidagi rangli, "
    "sodda sxemasi — bir qarashda barcha yo‘nalishlar va almashinuv bekatlari;",
    "• Almashinuvli marshrut rejalashtiruvchi: avtobus + almashinuv + piyoda "
    "yo‘l, umumiy vaqt va keyingi avtobusgacha qolgan daqiqalar bilan;",
    "• Mahalliy diqqatga sazovor joylar (Chorsu, Bobur bog‘i, universitetlar, "
    "bozorlar) 3D-multfilm uslubidagi belgilar bilan ko‘rsatilgan jonli xarita;",
    "• O‘zbek, rus va ingliz tillari; marshrutni internetsiz hisoblash; keksalar "
    "uchun yirik yozuv rejimi (keyingi bosqichda — “bekatimga yetganda "
    "ogohlantir” bildirishnomasi).",
    "Loyiha aholi uchun bepul. Barqarorlik shahar hokimligi va transport "
    "boshqarmasiga anonim “qondirilmagan talab” tahlilini (odamlar qayerga "
    "borishni xohlayotgani, lekin to‘g‘ridan-to‘g‘ri avtobus yo‘qligi) taqdim "
    "etish (B2G) hamda bekatlar atrofidagi mahalliy biznes uchun reklama orqali "
    "ta’minlanadi.",
])

# ---------------------------------------------------------------- 4. Muammo
set_cell(T[7].rows[0].cells[0],
         "Namangan shahrida jamoat transporti tez yangilanmoqda: shahar "
         "yo‘nalishlarida 130 ga yaqin zamonaviy avtobus ishlamoqda, yana 125 ta "
         "avtobus va elektrobus yetkazib berilishi rejalashtirilgan, yo‘nalishlar "
         "brutto-shartnoma asosida qayta tashkil etilmoqda. Ammo yo‘lovchi uchun "
         "eng oddiy savolga — “Men X joydan Y joyga qaysi avtobus bilan, qayerda "
         "almashib boraman?” — tez va ishonchli javob beradigan yagona, tushunarli "
         "manba yo‘q. Ayniqsa manzilga to‘g‘ridan-to‘g‘ri avtobus bo‘lmaganda "
         "odamlar taksiga majbur bo‘ladi, vaqt va pul yo‘qotiladi, yangi avtobuslar "
         "esa to‘liq ishlatilmaydi.")
set_cell(T[8].rows[0].cells[0],
         "Namangan — aholisi eng tez o‘sayotgan shaharlardan biri: shahar aholisi "
         "2026-yil 1-aprel holatiga 731,3 ming kishini tashkil etdi (Namangan "
         "viloyati statistika boshqarmasi). 2026-yilda shaharga Yutong, Ankai "
         "avtobuslari va Zhongtong elektrobuslari olib kelindi, 1-sentabrdan esa "
         "brutto-shartnomali yo‘nalishlarda chiqishda to‘lov majburiy bo‘ldi. "
         "Tarmoq o‘zgarayotgan paytda aholiga yo‘nalishlarni sodda tilda "
         "tushuntiruvchi raqamli vosita jamoat transportidan foydalanishni "
         "oshirish, tirbandlik va havoni ifloslanishini kamaytirish uchun "
         "dolzarb.")
set_cell(T[9].rows[0].cells[0], [
    "- Yandex Xaritalar / Yandex Go: 2025-yil iyunidan Namanganda avtobuslarni "
    "real vaqtda kuzatish imkoniyati mavjud. Biroq bu umumiy xarita ilovasi: "
    "butun shahar tarmog‘ini bir qarashda ko‘rsatuvchi sxema yo‘q, yo‘nalishlar "
    "ma’lumoti shahar uchun ochiq emas va shahar rejalashtirish uchun talab "
    "tahlilini olmaydi.",
    "- Ochiq xarita ma’lumotlari: OpenStreetMap bazasida Namangan shahri uchun "
    "birorta ham avtobus yo‘nalishi kiritilmagan, atigi 17 ta bekat bor (14.10.2026 "
    "dagi so‘rov natijasi) — shu sababli xalqaro marshrut ilovalari ham shahar "
    "tarmog‘ini to‘liq ko‘rsata olmaydi.",
    "- Bekatlardagi yozuvlar, Telegram kanallar va so‘rab bilish: ma’lumot "
    "tarqoq, eskirib qoladi va almashinuvli yo‘lni rejalashtirishga yordam bermaydi.",
])

# ---------------------------------------------------------------- 5. Yechim
set_cell(T[10].rows[0].cells[0], [
    "“Bekat” uch qatlamdan iborat:",
    "1) Ma’lumotlar qatlami: shahardagi barcha yo‘nalishlar va bekatlar dala "
    "tadqiqoti orqali GPS bilan belgilanadi va xalqaro GTFS formatida "
    "saqlanadi (yo‘nalish, bekatlar ketma-ketligi, qatnov oralig‘i, narx).",
    "2) Marshrut qatlami: telefon ichida ishlaydigan almashinuvli marshrut "
    "algoritmi (RAPTOR turidagi) eng kam almashinuv va eng qisqa vaqtli "
    "variantlarni topadi. Masalan: “Yuksalish → Otchopar: №3 avtobus bilan "
    "Chorsugacha, so‘ng №2 avtobusga o‘tib Otchopar bosh bekatigacha”.",
    "3) Vizual qatlam: metro uslubidagi rangli sxema va diqqatga sazovor joylar "
    "3D-multfilm belgilar bilan ko‘rsatilgan jonli xarita — ilovani bolalar ham, "
    "keksalar ham tushunadi.",
])
set_cell(T[11].rows[0].cells[0], [
    "- Avtobus tarmog‘i uchun metro uslubidagi sxema: Moskva, Toshkent metrosi "
    "sxemalari kabi, lekin Namangan avtobuslari uchun — shahar miqyosida ilk bor "
    "bunday sxema tayyorlanadi.",
    "- “Eng yaqin yetib borish” rejimi: to‘g‘ridan-to‘g‘ri yo‘l bo‘lmasa, ilova "
    "manzilga eng yaqin bekatgacha olib boradigan va qolgan piyoda masofani "
    "ko‘rsatadigan variantni taklif qiladi.",
    "- Shahar uchun talab xaritasi: foydalanuvchilarning anonim qidiruvlari "
    "asosida “odamlar boradi, lekin avtobus yo‘q” hududlari aniqlanadi va yangi "
    "yo‘nalishlarni rejalashtirishda hokimlikka dalil sifatida beriladi.",
    "- Oflayn ishlash: bekatlar, yo‘nalishlar va marshrut algoritmi telefon "
    "ichida, internetsiz ham ishlaydi.",
])
set_cell(T[12].rows[0].cells[0],
         "Android va iOS uchun yagona kod bazasida (Flutter) ishlab chiqiladi, "
         "arzon smartfonlarda ham yengil ishlaydi. Hakamlar va aholiga ko‘rsatish "
         "uchun veb-versiyasi ham tayyorlanadi. Namanganda sinovdan o‘tgach, xuddi "
         "shu tizim Andijon, Farg‘ona va boshqa viloyat markazlariga faqat "
         "ma’lumotlar qatlamini almashtirish orqali ko‘chiriladi.")
set_cell(T[13].rows[0].cells[0],
         "Aholi uchun — vaqt va pul tejaladi (taksi o‘rniga avtobus), shaharni "
         "yangi kelganlar va sayyohlar ham bemalol o‘rganadi. Shahar uchun — yangi "
         "avtobuslardan foydalanish ortadi, xususiy avtomobil va taksi qatnovi, "
         "tirbandlik va chiqindi gazlar kamayadi, yo‘nalishlarni rejalashtirish "
         "real talab ma’lumotlariga tayanadi.")

# ---------------------------------------------------------------- 6. Mexanizm
set_cell(T[14].rows[0].cells[0], [
    "1. Qidiruv: foydalanuvchi manzilni yozadi yoki xaritada nuqtani bosadi; "
    "ilova joriy joylashuvni GPS orqali aniqlaydi.",
    "2. Bekatlarni tanlash: har ikki nuqta atrofida piyoda 10 daqiqagacha "
    "masofadagi bekatlar topiladi.",
    "3. Marshrut hisoblash: algoritm 0, 1 va 2 ta almashinuvli variantlarni "
    "taqqoslab, eng qulaylarini (vaqt, almashinuvlar soni, piyoda masofa) "
    "ko‘rsatadi.",
    "4. Yo‘l davomida: ekranda qolgan bekatlar soni, yetib borish vaqti, "
    "avtobus kelishiga qolgan daqiqalar va qayerda tushish yoki almashish "
    "kerakligi ko‘rsatiladi (push-bildirishnomalar — keyingi versiyada).",
    "5. Tahlil: anonim, shaxsni aniqlamaydigan qidiruv statistikasi shahar "
    "uchun talab xaritasiga yig‘iladi.",
])
fit_rows(T[15], 6)
stages = [
    ("Ma’lumotlar bazasi", "Shaharning barcha yo‘nalishlarini bosib o‘tib, "
     "bekatlarni GPS bilan belgilash; GTFS formatida tarmoq bazasini yaratish",
     "1–3-hafta", "Namangan avtobus tarmog‘ining raqamli bazasi"),
    ("Mobil ilova karkasi", "Xarita, bekatlar, yo‘nalishlar ro‘yxati, manzil "
     "qidiruvi, 3 tilli interfeys (Flutter)", "3–5-hafta",
     "Ishchi holatdagi ilova prototipi"),
    ("Marshrut algoritmi", "Almashinuvli marshrut (RAPTOR), piyoda yo‘l, "
     "“eng yaqin yetib borish” rejimi, oflayn hisoblash", "6–7-hafta",
     "Almashinuvli marshrut quruvchi tizim"),
    ("Vizual qatlam va reliz", "Metro uslubidagi sxema, 3D-multfilm belgilar, "
     "bildirishnomalar, yirik shrift rejimi", "8-hafta",
     "MVP ilova (Release APK + veb-versiya)"),
    ("Pilot sinov", "NamDTU talabalari va shahar aholisi orasida 100+ "
     "foydalanuvchi bilan sinov, so‘rovnoma, xatolarni tuzatish", "9–12-hafta",
     "Pilot natijalari va talab xaritasi hisoboti"),
    ("Kengaytirish", "Tashuvchilar GPS ma’lumotlari bilan real vaqt rejimi, "
     "Andijon va Farg‘onaga moslashtirish", "Kelgusi bosqich",
     "Viloyatlararo kengaytirish rejasi"),
]
for i, (a, b, c, e) in enumerate(stages, start=1):
    set_row(T[15], i, [str(i), a, b, c, e])

# ---------------------------------------------------------------- 7. Natijalar
set_cell(T[16].rows[0].cells[0], [
    "Loyiha konsepsiyasi va foydalanuvchi yo‘li ishlab chiqilgan. Ochiq "
    "ma’lumotlar tahlil qilingan: OpenStreetMap bazasida Namangan shahar avtobus "
    "yo‘nalishlari yo‘qligi aniqlangan. Rasmiy manbalarda tasdiqlangan №1 "
    "(Otchopar bosh bekati – Taxtako‘prik), №2 (Otchopar – Chorsu) va №3 "
    "(Yuksalish – Chorsu) yo‘nalishlarining oxirgi bekatlari xaritada belgilangan.",
    "Flutter’da ishlaydigan prototip yaratilgan (Android, iOS, veb): 3D xarita "
    "(MapLibre + OpenStreetMap), jadval asosida harakatlanuvchi avtobuslar, "
    "lotin va kirill yozuvida qidiruv, RAPTOR almashinuvli marshrut algoritmi, "
    "“eng yaqin yetib borish” rejimi, metro uslubidagi tarmoq sxemasi, "
    "sayohat rejimi va 3 tilli interfeys. Namuna tarmoq: 6 yo‘nalish "
    "(3 tasi tasdiqlangan, 3 tasi namuna), 36 bekat, qidiruvda 69 ta joy.",
])
set_cell(T[17].rows[0].cells[0],
         "Prototipdagi algoritm almashinuvli marshrutlarni topadi: masalan, "
         "Yuksalishdan Otchoparga to‘g‘ridan-to‘g‘ri yo‘nalish yo‘q, tizim №3 va "
         "№1 avtobuslarni almashinuv bekatida birlashtiradi; Aeroportdan "
         "Yuksalishga esa 2 ta almashinuvli yo‘l quriladi. 7 ta avtomatik test "
         "(tarmoq, almashinuv, “eng yaqin nuqta”, qidiruv, avtobus jadvali) "
         "muvaffaqiyatli o‘tdi. Oraliq bekatlar namuna bo‘lgani uchun vaqtlar "
         "taxminiy; to‘liq tarmoq bo‘yicha natijalar 1-bosqichdagi dala "
         "tadqiqotidan keyin o‘lchanadi.")
set_cell(T[18].rows[0].cells[0], [
    "- Ishlaydigan prototip (manba kodi, veb-versiya) va ilova ekran rasmlari",
    "- Metro uslubidagi tarmoq sxemasi",
    "- Tizim arxitekturasi va ma’lumotlar oqimi sxemasi",
    "- Loyiha taqdimoti (o‘zbek va rus tillarida) va A3 formatdagi poster",
])

# ---------------------------------------------------------------- 8. Bozor
set_cell(T[19].rows[0].cells[0], [
    "- Foydalanuvchilar: Namangan shahri aholisi (731,3 ming kishi) va shaharga "
    "keluvchilar — talabalar, o‘quvchilar, ishchilar, keksalar, sayyohlar.",
    "- To‘lovchi mijozlar: shahar hokimligi va viloyat transport boshqarmasi "
    "(talab tahlili, yo‘lovchilarni xabardor qilish), avtobus tashuvchi "
    "korxonalar, bekatlar atrofidagi mahalliy biznes (reklama).",
])
set_cell(T[20].rows[0].cells[0],
         "Yo‘lovchi uchun — “qaysi avtobus va qayerda almashaman?” savoliga "
         "bir daqiqada javob. Shahar uchun — yangi avtobuslar to‘liq ishlatilishi "
         "va yo‘nalishlarni haqiqiy talab asosida rejalashtirish imkoniyati. "
         "Tashuvchi uchun — ko‘proq yo‘lovchi va barqaror daromad.")
set_cell(T[21].rows[0].cells[0],
         "Birinchi bozor — Namangan shahri: 731,3 ming aholi (01.04.2026), "
         "viloyat bo‘yicha 3,19 mln kishi (01.01.2026). Shaharda 10 ta "
         "brutto-shartnomali yo‘nalish ishlaydi va avtobuslar soni oshib "
         "bormoqda. Keyingi bozor — xuddi shunday yangilanayotgan boshqa viloyat "
         "markazlari. Foydalanuvchilar soni bo‘yicha raqamlar faqat pilot "
         "natijalari asosida kiritiladi.")
set_cell(T[22].rows[0].cells[0],
         "Aholi uchun ilova bepul. Daromad manbalari: shahar hokimligi va transport "
         "boshqarmasi uchun yillik B2G obuna (talab xaritasi, yo‘nalishlar "
         "o‘zgarishi haqida aholini xabardor qilish paneli); bekatlar atrofidagi "
         "mahalliy biznes uchun joylashuvga asoslangan reklama; tashuvchilar bilan "
         "hamkorlik.")
set_cell(T[23].rows[0].cells[0],
         "1-bosqich: NamDTU talabalari bilan pilot -> 2-bosqich: Namangan shahar "
         "hokimligi va viloyat transport boshqarmasiga talab xaritasini taqdim "
         "etish, hamkorlik memorandumi -> 3-bosqich: boshqa viloyat markazlariga "
         "kengaytirish.")

# ---------------------------------------------------------------- 9. Analoglar
fit_rows(T[24], 4)
analogs = [
    ("Yandex Xaritalar / Yandex Go", "Namanganda avtobuslarni real vaqtda "
     "kuzatish (2025-yil iyunidan), keng auditoriya",
     "Umumiy xarita: butun tarmoq sxemasi yo‘q, ma’lumot shahar uchun ochiq "
     "emas, talab tahlilini bermaydi",
     "Metro uslubidagi sxema, “eng yaqin yetib borish” rejimi, shahar uchun "
     "talab xaritasi"),
    ("OpenStreetMap asosidagi xalqaro marshrut ilovalari", "Ochiq va bepul "
     "xarita ma’lumotlari",
     "Namangan uchun avtobus yo‘nalishlari kiritilmagan (0 ta yo‘nalish, 17 ta "
     "bekat)",
     "Butun shahar tarmog‘i dala tadqiqoti orqali raqamlashtiriladi"),
    ("Metro sxemasi ilovalari (Toshkent, Moskva metrosi)", "Tarmoqni bir "
     "qarashda tushunish, almashinuvni qulay ko‘rsatish",
     "Faqat metro uchun; Namanganda metro yo‘q",
     "Shu tajriba avtobus tarmog‘iga birinchi marta qo‘llanadi"),
    ("Bekatdagi yozuvlar va Telegram kanallar", "Oddiy, hammaga tanish",
     "Tarqoq, eskiradi, almashinuvli yo‘lni rejalashtirmaydi",
     "Yagona yangilanadigan baza va bosqichma-bosqich yo‘l ko‘rsatma"),
]
for i, row in enumerate(analogs, start=1):
    set_row(T[24], i, [str(i), *row])

# ---------------------------------------------------------------- 10. IP
set_row(T[25], 0, [None, AUTHOR])
set_row(T[25], 1, [None, "EHM uchun yaratilgan dasturiy ta’minot (mobil ilova "
                   "kodi, marshrut algoritmi) va ma’lumotlar bazasi (Namangan "
                   "avtobus tarmog‘i bazasi)"])
set_row(T[25], 2, [None, "Pilot sinovdan so‘ng O‘zbekiston Respublikasi Adliya "
                   "vazirligidan EHM uchun dastur va ma’lumotlar bazasi sifatida "
                   "rasmiy guvohnoma olinadi."])
set_row(T[25], 3, [None, "Ochiq manbali freymvorklar va kutubxonalar (Flutter — "
                   "BSD, MIT litsenziyalari); OpenStreetMap xarita asosi (ODbL "
                   "litsenziyasi, manba ko‘rsatiladi)."])

# ---------------------------------------------------------------- 11. Smeta
costs = [
    ("Dala tadqiqoti: yo‘nalishlar va bekatlarni GPS bilan belgilash",
     "2 kishi × 1 oy", "2 000 000 so‘m", "4 000 000 so‘m",
     "Barcha shahar yo‘nalishlarini bosib o‘tish, yo‘l kira, mobil internet"),
    ("Bulutli server (VPS)", "6 oy", "350 000 so‘m", "2 100 000 so‘m",
     "Ma’lumotlar bazasi yangilanishlari va talab tahlili uchun"),
    ("Xarita va geokodlash xizmatlari", "6 oy", "400 000 so‘m",
     "2 400 000 so‘m", "Xarita qatlamlari va manzil qidiruvi"),
    ("3D-multfilm uslubidagi dizayn va illyustratsiyalar", "1 paket",
     "3 000 000 so‘m", "3 000 000 so‘m",
     "Diqqatga sazovor joylar belgilari, ilova ikonkalari, sxema dizayni"),
    ("Google Play / App Store dasturchi akkaunti", "1 to‘plam",
     "1 600 000 so‘m", "1 600 000 so‘m",
     "Ilovani rasmiy do‘konlarga joylash"),
    ("Pilot sinov", "100+ foydalanuvchi", "1 paket", "2 000 000 so‘m",
     "So‘rovnoma, sinov qurilmalari, tarqatma materiallar"),
    ("EHM guvohnomasini rasmiylashtirish", "1 ta", "1 400 000 so‘m",
     "1 400 000 so‘m", "Mualliflik huquqini davlat ro‘yxatidan o‘tkazish"),
    ("Kutilmagan texnik xarajatlar", "1 paket", "1 500 000 so‘m",
     "1 500 000 so‘m", "Domen, aloqa, ehtiyot qismlar"),
]
fit_rows(T[26], len(costs), footer=1)
for i, row in enumerate(costs, start=1):
    set_row(T[26], i, [str(i), *row])
set_row(T[26], len(costs) + 1, [None, "18 000 000 so‘m", ""])

# ---------------------------------------------------------------- 12. Natijalar
set_cell(T[27].rows[0].cells[0], [
    "- “Bekat” mobil ilovasining ishchi talqini (Android / iOS / veb);",
    "- Namangan shahar avtobus tarmog‘ining GTFS formatidagi to‘liq raqamli "
    "bazasi;",
    "- Butun tarmoqning metro uslubidagi sxemasi (ilova ichida va bekatlar "
    "uchun bosma variant);",
    "- Shahar hokimligi uchun “qondirilmagan talab” xaritasi bo‘yicha birinchi "
    "hisobot.",
])
set_cell(T[28].rows[0].cells[0], [
    "- Shahar yo‘nalishlari va bekatlarining raqamlashtirilishi: 100% "
    "(barcha amaldagi yo‘nalishlar);",
    "- Marshrut hisoblash vaqti telefonda: 1 soniyadan kam;",
    "- Pilotda: kamida 300 o‘rnatish va 100 faol foydalanuvchi;",
    "- So‘rovnomada “kerakli marshrutni topdim” deb javob berganlar: kamida 80%.",
    "Bular maqsadli ko‘rsatkichlar; yakuniy raqamlar pilotdan keyin "
    "o‘lchanadi.",
])
set_cell(T[29].rows[0].cells[0],
         "Jamoat transportidan foydalanish qulayroq bo‘ladi, aholining yo‘lga "
         "sarflaydigan vaqti va xarajati kamayadi, shahar transport tizimi esa "
         "real talab ma’lumotlari asosida rivojlanadi — bu “aqlli shahar” "
         "yo‘nalishidagi amaliy qadam.")

# ---------------------------------------------------------------- 13. Xavflar
risks = [
    ("Yo‘nalishlar va bekatlar tez-tez o‘zgarishi", "Yuqori / O‘rta",
     "Baza markaziy serverdan yangilanadi; foydalanuvchilar xatoni bir tugma "
     "bilan xabar qiladi; tashuvchilar bilan muntazam aloqa", AUTHOR_SHORT),
    ("Rasmiy ma’lumot olishning qiyinligi", "O‘rta / Yuqori",
     "Asosiy baza mustaqil dala tadqiqoti orqali yig‘iladi; transport "
     "boshqarmasi bilan hamkorlik keyingi bosqichda", AUTHOR_SHORT),
    ("Real vaqt GPS ma’lumotlari yo‘qligi", "Yuqori / O‘rta",
     "MVP jadval va qatnov oralig‘i asosida ishlaydi; real vaqt rejimi "
     "tashuvchilar bilan kelishuvdan keyin qo‘shiladi", AUTHOR_SHORT),
    ("Yirik raqobatchilar (Yandex) mavjudligi", "O‘rta / O‘rta",
     "Mahalliy ustunliklarga e’tibor: tarmoq sxemasi, oflayn rejim, sodda "
     "o‘zbekcha interfeys, shahar uchun talab tahlili", AUTHOR_SHORT),
]
fit_rows(T[30], len(risks))
for i, row in enumerate(risks, start=1):
    set_row(T[30], i, list(row))

# ---------------------------------------------------------------- 14. Jamoa
set_row(T[31], 1, [AUTHOR, "Loyiha rahbari va bosh dasturchi",
                   "Mobil ilova, marshrut algoritmi, ma’lumotlar bazasi, "
                   "dala tadqiqotini tashkil etish",
                   "Mobil dasturlash (Flutter), algoritmlar, ma’lumotlar bazasi"])
set_row(T[31], 2, ["Ilmiy rahbar " + TBD, "Ilmiy maslahatchi",
                   "Loyiha metodikasi va hujjatlarini ko‘rib chiqish",
                   "Axborot texnologiyalari / transport logistikasi"])

# ---------------------------------------------------------------- 15. Manbalar
set_cell(T[32].rows[0].cells[0], [
    "1. Namangan viloyati statistika boshqarmasi — Demografiya, 2026-yil mart. "
    "https://namstat.uz/images/Pres-Reliz/2026/Demografiya2026_mart.pdf",
    "2. Gazeta.uz — Namangan shahri jamoat transporti uchun Xitoydan 10 ta "
    "elektrobus olib kelindi (24.09.2026). "
    "https://www.gazeta.uz/oz/2026/09/24/namangan-electrobus/",
    "3. Gazeta.uz — Namangan jamoat transporti uchun 12 ta avtobus olib "
    "kelindi (14.07.2026). https://www.gazeta.uz/oz/2026/07/14/bus-namangan/",
    "4. Yuz.uz — Namanganga yana 12 ta zamonaviy avtobus olib kelindi. "
    "https://yuz.uz/uz/news/namanganga-iana-12-ta-zamonavii-avtobus-olib-kelindi",
    "5. O‘zbekiston Respublikasi Transport vazirligi — Namangan shahrida yangi "
    "avtobuslar yo‘lovchilarga xizmat ko‘rsatishni boshladi. https://www.mintrans.uz",
    "6. Afisha.uz — Avtobuslarni 13 ta shaharda real vaqtda kuzatish mumkin "
    "(17.06.2025). https://www.afisha.uz/ru/gorod/2025/06/17/buses",
    "7. OpenStreetMap (Overpass API) — Namangan shahri bo‘yicha avtobus "
    "yo‘nalishlari va bekatlar so‘rovi. https://www.openstreetmap.org",
    "8. GTFS — General Transit Feed Specification. https://gtfs.org",
    "9. Delling D., Pajor T., Werneck R. Round-Based Public Transit Routing "
    "(RAPTOR). Microsoft Research, 2012.",
    "",
    "Ko‘rilgan sana: 14.10.2026.",
])

# ---------------------------------------------------------------- 18. Tasdiq
set_cell(T[33].rows[0].cells[0],
         f"Men, {AUTHOR}, taqdim etilgan loyiha materiallari mening intellektual "
         "mehnatim natijasi ekanini, keltirilgan ma’lumotlar haqqoniyligini va "
         "uchinchi tomon huquqlariga rioya etilganini tasdiqlayman.")
set_row(T[34], 0, [None, AUTHOR])
set_row(T[34], 2, [None, DATE])

# ---------------------------------------------------------------- paragraphs
checks = {
    "1. Loyiha taqdimoti": True, "2. Prototip / MVP": True,
    "3. Texnik sxema": True, "4. Test natijalari": True,
    "Ariza to‘liq to‘ldirilgan": False,
    "Loyiha muallifi va jamoa": False,
}
for p in d.paragraphs:
    t = p.text
    if t.startswith("Eslatma: VPS server"):
        set_par(p, "Eslatma: server va xarita xizmatlari 6 oyga hisoblangan — "
                   "3 oylik asosiy ishlar va pilot davri, qolgan muddat esa "
                   "bazani yangilab borish va hokimlik bilan hamkorlikni "
                   "boshlash uchun.")
    for key, done in checks.items():
        if key in t and t[:1] in "☐☑":
            set_par(p, ("☑ " if done else "☐ ") + t[2:], 9)

d.core_properties.author = AUTHOR
d.core_properties.title = TITLE_SHORT
d.save(OUT)
print("saved", OUT)
