// Bekat contest deck — Uzbek and Russian from one layout.
// Run: cd docs/deck && node build_deck.js   (writes ../Bekat_Taqdimot_UZ.pptx, ../Bekat_Prezentatsiya_RU.pptx)
const path = require("path");
const pptxgen = require("pptxgenjs");
const { applyTheme } = require("./apply_theme.js");

const A = (f) => path.join(__dirname, "..", "assets", f);
const THEME = {
  name: "Bekat",
  headFontFace: "Arial",
  bodyFontFace: "Arial",
  colors: {
    dk1: "15171C", lt1: "FFFFFF", dk2: "1E2024", lt2: "EEF1F6",
    accent1: "2D6BF0", accent2: "E53935", accent3: "22A55B", accent4: "F59E0B",
    accent5: "8B5CF6", accent6: "06B6D4", hlink: "2D6BF0", folHlink: "8B5CF6",
  },
};
const MUTED = "5B6270";
const LINE = "E3E7EE";

const TXT = {
  uz: {
    file: "Bekat_Taqdimot_UZ.pptx",
    footer: "Bekat · Qodirov Ulug‘bek, Zamalitdinov Salimbek · NamDTU · 2026",
    s1: { kicker: "“ENG YAXSHI KREATIV G‘OYA” RESPUBLIKA TANLOVI · 2026", title: "Bekat", sub: "Namangan avtobuslari uchun aqlli marshrut xaritasi", author: "Qodirov Ulug‘bek, Zamalitdinov Salimbek · NamDTU, 37-ATT guruhi (4-kurs)" },
    s2: { k: "MUAMMO", t: "“Qaysi avtobus? Qayerda almashaman?”",
      b: ["Shaharda yangi avtobuslar ko‘paymoqda, yo‘nalishlar qayta tuzilmoqda", "Manzilga to‘g‘ridan-to‘g‘ri avtobus bo‘lmasa, odamlar taksiga o‘tadi", "Almashinuvli yo‘lni sodda ko‘rsatadigan vosita yo‘q"],
      q: "Chorsudan Yuksalishga qanday boraman?" },
    s3: { k: "RAQAMLAR", t: "Tarmoq o‘smoqda — ma’lumot esa yo‘q",
      stats: [["731,3 ming", "Namangan shahri aholisi"], ["130", "zamonaviy avtobus"], ["10", "brutto-shartnomali yo‘nalish"], ["0", "yo‘nalish ochiq xaritada (OSM)"]],
      src: "Manbalar: namstat.uz (01.04.2026), yuz.uz (03.10.2026), gazeta.uz (24.09.2026), OpenStreetMap so‘rovi (14.10.2026)" },
    s4: { k: "YECHIM", t: "Manzilni tanlang — yo‘lni ko‘ring", caps: [["Xarita", "3D shahar, jonli avtobuslar"], ["Variantlar", "avtobus + almashinuv + piyoda"], ["Yo‘lda", "qolgan bekatlar va vaqt"]] },
    s5: { k: "ASOSIY G‘OYA", t: "To‘g‘ri avtobus bo‘lmasa ham — yo‘l bor",
      items: [["Almashinuv", "Bir nechta avtobusni birlashtiradi: №9 bilan vokzalgacha, so‘ng №7 ga o‘tiladi"], ["Eng yaqin nuqta", "Avtobus bormaydigan joyga ham eng yaqin bekatgacha olib boradi"], ["Tez va oflayn", "RAPTOR algoritmi telefon ichida, 1 soniyadan kam vaqtda hisoblaydi"]] },
    s6: { k: "METRO USLUBIDAGI SXEMA", t: "Butun tarmoq — bitta sxemada", note: "Oraliq bekatlar — dala tadqiqotigacha namuna", real: "tasdiqlangan yo‘nalish", demo: "namuna" },
    s7: { k: "3D JONLI XARITA", t: "Shahar xuddi o‘yindagidek",
      b: ["Avtobuslar xaritada harakatlanadi (qatnov jadvali asosida)", "Har bir bekatda — keyingi avtobusgacha necha daqiqa", "Kam matn, katta tugmalar: keksalar ham, bolalar ham tushunadi", "O‘zbek, rus, ingliz tillari"] },
    s8: { k: "TEXNOLOGIYA", t: "Qanday ishlaydi",
      boxes: [["Ma’lumot", "Bekatlar va yo‘nalishlar GPS bilan yig‘iladi (GTFS format)"], ["Telefonda", "Marshrut algoritmi va jadval — internetsiz"], ["Xarita", "MapLibre + OpenStreetMap, 3D binolar"], ["Shahar uchun", "Anonim “talab xaritasi” hokimlikka"]],
      stack: "Flutter: Android · iOS · Web — bitta kod bazasi" },
    s9: { k: "ANALOGLAR", t: "Bekatning farqi",
      head: ["", "Yandex Xaritalar", "OSM ilovalari", "Bekat"],
      rows: [["Namanganda jonli avtobus", "Bor", "Yo‘q", "Jadval asosida; GPS — 2-bosqich"], ["Butun tarmoq sxemasi", "Yo‘q", "Yo‘q", "Bor"], ["“Eng yaqin nuqta” rejimi", "—", "—", "Bor"], ["Shahar uchun talab tahlili", "Yo‘q", "Yo‘q", "Bor"], ["Namangan yo‘nalishlari bazasi", "Yopiq", "0 yo‘nalish", "Ochiq, yangilanadi"]] },
    s10: { k: "BIZNES MODEL", t: "Aholiga bepul — shaharga foydali",
      cards: [["Aholi", "Ilova bepul. Reklama faqat bekatlar atrofidagi mahalliy biznesdan."], ["Hokimlik va transport boshqarmasi", "Yillik B2G obuna: talab xaritasi, yo‘nalish o‘zgarishlari haqida xabar berish."], ["Tashuvchilar", "Ko‘proq yo‘lovchi; GPS ma’lumotlarini ulash orqali hamkorlik."]] },
    s11: { k: "REJA", t: "3 oyda: prototipdan pilotgacha",
      steps: [["1–3 hafta", "Barcha yo‘nalishlar va bekatlarni GPS bilan yig‘ish"], ["3–5 hafta", "Ilova karkasi, qidiruv, 3 til"], ["6–7 hafta", "Almashinuvli marshrut, oflayn"], ["8 hafta", "Sxema, 3D, reliz (APK + veb)"], ["9–12 hafta", "100+ foydalanuvchi bilan pilot"], ["Keyin", "Real vaqt GPS, Andijon, Farg‘ona"]] },
    s12: { k: "SMETA", t: "40 mln so‘m", sub: "1-bosqich (startap): mobil ilova, dala tadqiqoti va pilot sinov",
      cats: ["Mobil ilova (Flutter)", "Dala tadqiqoti (GPS)", "Algoritm (RAPTOR) & backend", "3D dizayn va metro sxemasi", "Server va xarita xizmatlari", "Pilot sinov (100+)", "Do‘kon akkauntlari", "EHM guvohnomasi va zaxira"], vals: [10.0, 8.0, 8.0, 3.5, 3.0, 3.0, 2.5, 2.0], unit: "mln so‘m" },
    s13: { k: "HOLAT VA KPI", t: "Prototip allaqachon ishlaydi",
      done: ["Ishlaydigan ilova: Android, iOS, veb", "6 yo‘nalish, 36 bekat, 69 joy qidiruvda", "Almashinuvli marshrut va metro sxemasi", "Avtomatik testlar: 7 / 7 o‘tdi"],
      kpi: [["100%", "shahar yo‘nalishlari raqamlashtiriladi"], ["< 1 s", "marshrut hisoblash"], ["100+", "faol pilot foydalanuvchi"], ["80%+", "“kerakli yo‘lni topdim”"]], kpiNote: "Maqsadli ko‘rsatkichlar — pilotdan keyin o‘lchanadi" },
    s14: { t: "Bekat — Namangan bo‘ylab oson yo‘l", sub: "Hamkorlarni taklif qilamiz: shahar hokimligi, viloyat transport boshqarmasi, avtobus tashuvchilari", author: "Qodirov Ulug‘bek — muallif · Zamalitdinov Salimbek — hammuallif", contact: "+998 90 555 80 91 · Dragonknight281101@gmail.com · github.com/SERBErGAME/Bekat" },
  },
  ru: {
    file: "Bekat_Prezentatsiya_RU.pptx",
    footer: "Bekat · Кодиров Улугбек, Замалитдинов Салим · НамГТУ · 2026",
    s1: { kicker: "РЕСПУБЛИКАНСКИЙ КОНКУРС «ЛУЧШАЯ КРЕАТИВНАЯ ИДЕЯ» · 2026", title: "Bekat", sub: "Умная карта автобусных маршрутов Намангана", author: "Кодиров Улугбек, Замалитдинов Салим · НамГТУ, группа 37-АТТ (4-курс)" },
    s2: { k: "ПРОБЛЕМА", t: "«Какой автобус? Где пересесть?»",
      b: ["В городе всё больше новых автобусов, маршруты меняются", "Если прямого автобуса нет, люди едут на такси", "Нет простого инструмента, который покажет путь с пересадками"],
      q: "Как доехать от Чорсу до Юксалиша?" },
    s3: { k: "ЦИФРЫ", t: "Сеть растёт, а данных нет",
      stats: [["731,3 тыс.", "жителей Намангана"], ["130", "современных автобусов"], ["10", "маршрутов по брутто-контракту"], ["0", "маршрутов на открытой карте (OSM)"]],
      src: "Источники: namstat.uz (01.04.2026), yuz.uz (03.10.2026), gazeta.uz (24.09.2026), запрос к OpenStreetMap (14.10.2026)" },
    s4: { k: "РЕШЕНИЕ", t: "Выберите место — увидите путь", caps: [["Карта", "3D-город, живые автобусы"], ["Варианты", "автобус + пересадка + пешком"], ["В пути", "остановки и время до цели"]] },
    s5: { k: "ГЛАВНАЯ ИДЕЯ", t: "Даже без прямого автобуса — путь есть",
      items: [["Пересадки", "Соединяет несколько маршрутов: на №9 до вокзала, затем на №7"], ["Ближайшая точка", "Туда, где автобуса нет, — до ближайшей остановки"], ["Быстро и офлайн", "Алгоритм RAPTOR прямо в телефоне, меньше 1 секунды"]] },
    s6: { k: "СХЕМА В СТИЛЕ МЕТРО", t: "Вся сеть — на одной схеме", note: "Промежуточные остановки — пример до полевого исследования", real: "подтверждённый маршрут", demo: "пример" },
    s7: { k: "ЖИВАЯ 3D-КАРТА", t: "Город, как в игре",
      b: ["Автобусы движутся по карте (по расписанию интервалов)", "На каждой остановке — сколько минут до автобуса", "Мало текста, крупные кнопки: понятно и пожилым, и детям", "Узбекский, русский, английский"] },
    s8: { k: "ТЕХНОЛОГИИ", t: "Как это работает",
      boxes: [["Данные", "Остановки и маршруты собираются с GPS (формат GTFS)"], ["В телефоне", "Алгоритм маршрутов и расписание — без интернета"], ["Карта", "MapLibre + OpenStreetMap, 3D-здания"], ["Для города", "Анонимная «карта спроса» для хокимията"]],
      stack: "Flutter: Android · iOS · Web — одна кодовая база" },
    s9: { k: "АНАЛОГИ", t: "Чем отличается Bekat",
      head: ["", "Яндекс Карты", "Приложения на OSM", "Bekat"],
      rows: [["Живые автобусы в Намангане", "Есть", "Нет", "По расписанию; GPS — 2-й этап"], ["Схема всей сети", "Нет", "Нет", "Есть"], ["Режим «ближайшая точка»", "—", "—", "Есть"], ["Анализ спроса для города", "Нет", "Нет", "Есть"], ["База маршрутов Намангана", "Закрытая", "0 маршрутов", "Открытая, обновляется"]] },
    s10: { k: "БИЗНЕС-МОДЕЛЬ", t: "Жителям бесплатно — городу полезно",
      cards: [["Жители", "Приложение бесплатно. Реклама только местного бизнеса у остановок."], ["Хокимият и транспортное управление", "Годовая B2G-подписка: карта спроса, оповещения об изменениях маршрутов."], ["Перевозчики", "Больше пассажиров; партнёрство через подключение GPS-данных."]] },
    s11: { k: "ПЛАН", t: "За 3 месяца: от прототипа до пилота",
      steps: [["Нед. 1–3", "Сбор всех маршрутов и остановок с GPS"], ["Нед. 3–5", "Каркас приложения, поиск, 3 языка"], ["Нед. 6–7", "Маршруты с пересадками, офлайн"], ["Нед. 8", "Схема, 3D, релиз (APK + веб)"], ["Нед. 9–12", "Пилот со 100+ пользователями"], ["Далее", "GPS в реальном времени, Андижан, Фергана"]] },
    s12: { k: "СМЕТА", t: "40 млн сумов", sub: "1-й этап (стартап): мобильное приложение, полевое исследование и пилот",
      cats: ["Мобильное приложение (Flutter)", "Полевое исследование (GPS)", "Алгоритм (RAPTOR) и бэкенд", "3D-дизайн и схема метро", "Сервер и геосервисы", "Пилотный запуск (100+)", "Аккаунты в сторах", "Свидетельство ЭВМ и прочее"], vals: [10.0, 8.0, 8.0, 3.5, 3.0, 3.0, 2.5, 2.0], unit: "млн сумов" },
    s13: { k: "СТАТУС И KPI", t: "Прототип уже работает",
      done: ["Работающее приложение: Android, iOS, веб", "6 маршрутов, 36 остановок, 69 мест в поиске", "Маршруты с пересадками и схема метро", "Автотесты: 7 из 7 пройдены"],
      kpi: [["100%", "маршрутов города оцифровано"], ["< 1 с", "расчёт маршрута"], ["100+", "активных пилотных пользователей"], ["80%+", "«нашёл нужный путь»"]], kpiNote: "Целевые показатели — измеряются после пилота" },
    s14: { t: "Bekat — простой путь по Намангану", sub: "Приглашаем партнёров: хокимият города, областное транспортное управление, перевозчиков", author: "Кодиров Улугбек — автор · Замалитдинов Салим — соавтор", contact: "+998 90 555 80 91 · Dragonknight281101@gmail.com · github.com/SERBErGAME/Bekat" },
  },
};

const NET = JSON.parse(require("fs").readFileSync(path.join(__dirname, "..", "..", "assets", "data", "network.json"), "utf8"));
const ROUTE_COLORS = ["E53935", "2D6BF0", "22A55B", "F59E0B", "8B5CF6", "06B6D4"];

async function build(lang) {
  const L = TXT[lang];
  const pres = new pptxgen();
  pres.layout = "LAYOUT_16x9"; // 10 x 5.625 in
  pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
  pres.author = lang === "uz" ? "Rasulov Farruh" : "Расулов Фаррух";
  pres.title = "Bekat";
  const C = pres.SchemeColor;

  const footer = (dark) => [
    { text: { text: L.footer, options: { x: 0.6, y: 5.22, w: 6, h: 0.25, fontSize: 9, color: dark ? "9AA1AE" : MUTED, margin: 0 } } },
  ];
  pres.defineSlideMaster({
    title: "BEKAT_LIGHT",
    background: { color: C.background2 },
    objects: footer(false),
    slideNumber: { x: 9.0, y: 5.18, w: 0.4, h: 0.3, fontSize: 9, color: MUTED, align: "right" },
    placeholders: [],
  });
  pres.defineSlideMaster({
    title: "BEKAT_WHITE",
    background: { color: C.background1 },
    objects: footer(false),
    slideNumber: { x: 9.0, y: 5.18, w: 0.4, h: 0.3, fontSize: 9, color: MUTED, align: "right" },
  });
  pres.defineSlideMaster({ title: "BEKAT_DARK", background: { color: C.text2 } });

  let n = 0;
  // Motif: every content slide opens with a metro-style route badge.
  function head(slide, kicker, title, i) {
    const col = ROUTE_COLORS[i % ROUTE_COLORS.length];
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y: 0.42, w: 0.36, h: 0.36, rectRadius: 0.1, fill: { color: col }, line: { color: col }, objectName: "badge" });
    slide.addText(String(i), { x: 0.6, y: 0.42, w: 0.36, h: 0.36, fontSize: 13, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
    slide.addText(kicker, { x: 1.08, y: 0.42, w: 7.5, h: 0.36, fontSize: 10.5, bold: true, color: MUTED, charSpacing: 1.5, valign: "middle", margin: 0, isTextBox: true, objectName: "kicker" });
    slide.addText(title, { x: 0.6, y: 0.86, w: 8.8, h: 0.7, fontSize: 28, bold: true, color: C.text1, valign: "top", margin: 0, isTextBox: true, objectName: "title" });
  }
  let current = null;
  const add = (master, section) => {
    n++;
    if (section) {
      pres.addSection({ title: section });
      current = section;
    }
    return pres.addSlide({ masterName: master, sectionTitle: current });
  };
  const sec = lang === "uz"
    ? ["Kirish", "Muammo", "Yechim", "Texnologiya", "Bozor", "Reja", "Yakun"]
    : ["Введение", "Проблема", "Решение", "Технологии", "Рынок", "План", "Итог"];

  // 1 — title
  pres.addSection({ title: sec[0] });
  n++;
  let s = pres.addSlide({ masterName: "BEKAT_DARK", sectionTitle: sec[0] });
  s.addText(L.s1.kicker, { x: 0.6, y: 0.6, w: 6.6, h: 0.3, fontSize: 10, bold: true, color: "9AA1AE", charSpacing: 1.5, margin: 0, isTextBox: true });
  s.addText(L.s1.title, { x: 0.6, y: 1.2, w: 5.4, h: 1.2, fontSize: 72, bold: true, color: C.background1, margin: 0, isTextBox: true, objectName: "title" });
  s.addText(L.s1.sub, { x: 0.6, y: 2.45, w: 4.9, h: 0.9, fontSize: 20, color: "D6DAE2", margin: 0, isTextBox: true, valign: "top" });
  ROUTE_COLORS.forEach((col, i) => {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6 + i * 0.46, y: 3.55, w: 0.36, h: 0.36, rectRadius: 0.1, fill: { color: col }, line: { color: col } });
    s.addText(["1", "2", "3", "5", "7", "9"][i], { x: 0.6 + i * 0.46, y: 3.55, w: 0.36, h: 0.36, fontSize: 13, bold: true, color: "FFFFFF", align: "center", valign: "middle", margin: 0, isTextBox: true });
  });
  s.addText(L.s1.author, { x: 0.6, y: 4.65, w: 5.6, h: 0.4, fontSize: 12, color: "9AA1AE", margin: 0, isTextBox: true });
  s.addImage({ path: A("bus.png"), x: 5.2, y: 3.15, w: 2.45, h: 2.04, objectName: "bus" });
  s.addImage({ path: A(`phone_02_home_${lang}.png`), x: 7.35, y: 0.3, w: 2.4, h: 4.61, objectName: "phone" });
  s.addNotes(lang === "uz"
    ? "Assalomu alaykum. Loyihamiz — Bekat: Namangan shahri avtobuslari uchun aqlli marshrut xaritasi."
    : "Здравствуйте. Наш проект — Bekat: умная карта автобусных маршрутов Намангана.");

  // 2 — problem
  s = add("BEKAT_LIGHT", sec[1]);
  head(s, L.s2.k, L.s2.t, n);
  s.addText(L.s2.b.map((t, i) => ({ text: t, options: { bullet: true, breakLine: i < L.s2.b.length - 1, paraSpaceAfter: 10 } })),
    { x: 0.6, y: 1.8, w: 4.3, h: 2.6, fontSize: 16, color: C.text1, valign: "top", margin: 0, isTextBox: true });
  s.addImage({ path: A("map_city.png"), x: 5.2, y: 1.7, w: 4.2, h: 2.62, sizing: { type: "cover", w: 4.2, h: 2.62 }, rounding: false, objectName: "city map" });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 5.55, y: 3.95, w: 3.5, h: 0.62, rectRadius: 0.18, fill: { color: C.text2 }, line: { color: C.text2 }, shadow: { type: "outer", color: "1B2440", opacity: 0.25, blur: 8, offset: 3, angle: 90 } });
  s.addText(L.s2.q, { x: 5.55, y: 3.95, w: 3.5, h: 0.62, fontSize: 13, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0.05, isTextBox: true });
  s.addNotes(lang === "uz"
    ? "Namanganda jamoat transporti tez yangilanmoqda, lekin yo‘lovchi uchun eng oddiy savolga javob beradigan sodda vosita yo‘q."
    : "Транспорт Намангана быстро обновляется, но простого ответа на вопрос «как доехать» у пассажира нет.");

  // 3 — numbers
  s = add("BEKAT_WHITE");
  head(s, L.s3.k, L.s3.t, n);
  L.s3.stats.forEach(([v, lbl], i) => {
    const x = 0.6 + i * 2.25;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.85, w: 2.05, h: 2.2, rectRadius: 0.2, fill: { color: i === 3 ? C.text2 : C.background2 }, line: { color: i === 3 ? C.text2 : C.background2 } });
    s.addText(v, { x: x + 0.18, y: 2.05, w: 1.8, h: 0.9, fontSize: v.length > 6 ? 26 : 44, bold: true, color: i === 3 ? "7CE0A3" : C.text1, margin: 0, isTextBox: true, valign: "bottom" });
    s.addText(lbl, { x: x + 0.18, y: 3.05, w: 1.75, h: 0.8, fontSize: 13, color: i === 3 ? "D6DAE2" : MUTED, margin: 0, isTextBox: true, valign: "top" });
  });
  s.addText(L.s3.src, { x: 0.6, y: 4.45, w: 8.8, h: 0.4, fontSize: 10, italic: true, color: MUTED, margin: 0, isTextBox: true });

  // 4 — solution: three phones
  s = add("BEKAT_LIGHT", sec[2]);
  head(s, L.s4.k, L.s4.t, n);
  ["02_home", "05_plan", "06_trip"].forEach((f, i) => {
    const x = 0.75 + i * 3.05;
    s.addImage({ path: A(`phone_${f}_${lang}.png`), x, y: 1.6, w: 1.66, h: 3.19, objectName: `phone ${f}` });
    s.addText([{ text: L.s4.caps[i][0], options: { bold: true, fontSize: 15, color: C.text1, breakLine: true } }, { text: L.s4.caps[i][1], options: { fontSize: 12, color: MUTED } }],
      { x: x + 1.72, y: 2.75, w: 1.2, h: 1.1, margin: 0, isTextBox: true, valign: "top" });
  });

  // 5 — core idea: transfers
  s = add("BEKAT_WHITE");
  head(s, L.s5.k, L.s5.t, n);
  s.addImage({ path: A(`phone_05_plan_${lang}.png`), x: 0.7, y: 1.55, w: 1.75, h: 3.36 });
  L.s5.items.forEach(([h, b], i) => {
    const y = 1.75 + i * 1.05;
    const col = ["06B6D4", "8B5CF6", "22A55B"][i];
    s.addShape(pres.shapes.OVAL, { x: 3.0, y: y + 0.05, w: 0.42, h: 0.42, fill: { color: col }, line: { color: col } });
    s.addText(String(i + 1), { x: 3.0, y: y + 0.05, w: 0.42, h: 0.42, fontSize: 14, bold: true, color: "FFFFFF", align: "center", valign: "middle", margin: 0, isTextBox: true });
    s.addText([{ text: h, options: { bold: true, fontSize: 16, color: C.text1, breakLine: true } }, { text: b, options: { fontSize: 13, color: MUTED } }],
      { x: 3.6, y, w: 5.8, h: 0.95, margin: 0, isTextBox: true, valign: "top" });
  });

  // 6 — scheme + legend
  s = add("BEKAT_WHITE");
  head(s, L.s6.k, L.s6.t, n);
  s.addImage({ path: A(`scheme_${lang}.png`), x: 0.5, y: 1.45, w: 5.12, h: 3.5, objectName: "scheme" });
  NET.routes.forEach((r, i) => {
    const y = 1.62 + i * 0.52, col = r.color.slice(1);
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 6.35, y, w: 0.36, h: 0.36, rectRadius: 0.1, fill: { color: col }, line: { color: col } });
    s.addText(r.id, { x: 6.35, y, w: 0.36, h: 0.36, fontSize: 13, bold: true, color: "FFFFFF", align: "center", valign: "middle", margin: 0, isTextBox: true });
    s.addText([{ text: r.name[lang], options: { fontSize: 11.5, bold: true, color: "15171C", breakLine: true } },
      { text: r.demo ? L.s6.demo : L.s6.real, options: { fontSize: 9.5, color: r.demo ? "9AA1AE" : "22A55B" } }],
      { x: 6.82, y: y - 0.06, w: 2.65, h: 0.5, margin: 0, isTextBox: true, valign: "middle" });
  });
  s.addText(L.s6.note, { x: 6.35, y: 4.78, w: 3.1, h: 0.3, fontSize: 9.5, italic: true, color: MUTED, margin: 0, isTextBox: true });

  // 7 — 3D map
  s = add("BEKAT_LIGHT");
  head(s, L.s7.k, L.s7.t, n);
  s.addImage({ path: A("map_center.png"), x: 4.6, y: 1.55, w: 4.8, h: 3.0, sizing: { type: "cover", w: 4.8, h: 3.0 } });
  s.addText(L.s7.b.map((t, i) => ({ text: t, options: { bullet: true, breakLine: i < L.s7.b.length - 1, paraSpaceAfter: 9 } })),
    { x: 0.6, y: 1.7, w: 3.8, h: 3.0, fontSize: 14.5, color: C.text1, valign: "top", margin: 0, isTextBox: true });

  // 8 — architecture
  s = add("BEKAT_WHITE", sec[3]);
  head(s, L.s8.k, L.s8.t, n);
  L.s8.boxes.forEach(([h, b], i) => {
    const x = 0.6 + i * 2.25, col = ["F59E0B", "2D6BF0", "22A55B", "8B5CF6"][i];
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.85, w: 2.0, h: 2.0, rectRadius: 0.18, fill: { color: C.background2 }, line: { color: C.background2 } });
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x + 0.2, y: 2.05, w: 0.34, h: 0.34, rectRadius: 0.09, fill: { color: col }, line: { color: col } });
    s.addText([{ text: h, options: { bold: true, fontSize: 15, color: C.text1, breakLine: true } }, { text: b, options: { fontSize: 12, color: MUTED } }],
      { x: x + 0.2, y: 2.52, w: 1.65, h: 1.25, margin: 0, isTextBox: true, valign: "top" });
    if (i < 3) s.addShape(pres.shapes.LINE, { x: x + 2.02, y: 2.85, w: 0.21, h: 0, line: { color: "9AA1AE", width: 1.5, endArrowType: "triangle" } });
  });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y: 4.2, w: 8.75, h: 0.55, rectRadius: 0.15, fill: { color: C.text2 }, line: { color: C.text2 } });
  s.addText(L.s8.stack, { x: 0.6, y: 4.2, w: 8.75, h: 0.55, fontSize: 14, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });

  // 9 — analogs table
  s = add("BEKAT_WHITE", sec[4]);
  head(s, L.s9.k, L.s9.t, n);
  const hdr = L.s9.head.map((h, i) => ({ text: h, options: { bold: true, color: i === 3 ? "FFFFFF" : C.text1, fill: { color: i === 3 ? "2D6BF0" : "EEF1F6" }, fontSize: 12 } }));
  const rows = L.s9.rows.map((r) => r.map((c, i) => ({ text: c, options: { fontSize: 11.5, color: i === 0 ? C.text1 : (i === 3 ? "15171C" : MUTED), bold: i === 0 || i === 3, fill: { color: i === 3 ? "E6EEFE" : "FFFFFF" } } })));
  s.addTable([hdr, ...rows], { x: 0.6, y: 1.7, w: 8.8, colW: [2.9, 1.8, 1.8, 2.3], rowH: 0.48, border: { type: "solid", pt: 0.75, color: LINE }, valign: "middle", margin: 0.06 });

  // 10 — business model
  s = add("BEKAT_LIGHT");
  head(s, L.s10.k, L.s10.t, n);
  L.s10.cards.forEach(([h, b], i) => {
    const x = 0.6 + i * 2.98, dark = i === 1;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.8, w: 2.78, h: 2.3, rectRadius: 0.2, fill: { color: dark ? C.text2 : C.background1 }, line: { color: dark ? C.text2 : C.background1 }, shadow: { type: "outer", color: "1B2440", opacity: 0.12, blur: 10, offset: 4, angle: 90 } });
    s.addText([{ text: h, options: { bold: true, fontSize: 16, color: dark ? "FFFFFF" : C.text1, breakLine: true } }, { text: " ", options: { fontSize: 6, breakLine: true } }, { text: b, options: { fontSize: 13, color: dark ? "D6DAE2" : MUTED } }],
      { x: x + 0.25, y: 2.05, w: 2.3, h: 2.3, margin: 0, isTextBox: true, valign: "top" });
  });

  // 11 — timeline as a metro line
  s = add("BEKAT_WHITE", sec[5]);
  head(s, L.s11.k, L.s11.t, n);
  s.addShape(pres.shapes.LINE, { x: 0.95, y: 2.55, w: 8.1, h: 0, line: { color: "22A55B", width: 6 } });
  L.s11.steps.forEach(([w, d], i) => {
    const x = 0.95 + i * 1.62;
    s.addShape(pres.shapes.OVAL, { x: x - 0.17, y: 2.38, w: 0.34, h: 0.34, fill: { color: "FFFFFF" }, line: { color: i === 5 ? "9AA1AE" : "15171C", width: 2.5 } });
    s.addText(w, { x: x - 0.7, y: 1.85, w: 1.4, h: 0.4, fontSize: 12, bold: true, color: C.text1, align: "center", margin: 0, isTextBox: true });
    s.addText(d, { x: x - 0.72, y: 2.9, w: 1.44, h: 1.4, fontSize: 11.5, color: MUTED, align: "center", valign: "top", margin: 0, isTextBox: true });
  });

  // 12 — budget chart
  s = add("BEKAT_WHITE");
  head(s, L.s12.k, L.s12.t, n);
  s.addText(L.s12.sub, { x: 0.6, y: 1.5, w: 8.8, h: 0.35, fontSize: 13, color: MUTED, margin: 0, isTextBox: true });
  s.addChart(pres.charts.BAR, [{ name: L.s12.unit, labels: L.s12.cats, values: L.s12.vals }], {
    x: 0.6, y: 1.9, w: 8.8, h: 3.1, barDir: "bar", chartColors: ["2D6BF0"], showValue: true, dataLabelPosition: "outEnd",
    dataLabelFormatCode: "0.0", dataLabelFontSize: 11, dataLabelColor: "15171C", dataLabelFontFace: "+mn-lt",
    catAxisLabelColor: "5B6270", catAxisLabelFontSize: 11, catAxisLabelFontFace: "+mn-lt", catAxisOrientation: "maxMin",
    valAxisHidden: true, valGridLine: { style: "none" }, catGridLine: { style: "none" }, showLegend: false, barGapWidthPct: 45,
  });

  // 13 — status & KPI
  s = add("BEKAT_LIGHT");
  head(s, L.s13.k, L.s13.t, n);
  s.addText(L.s13.done.map((t, i) => ({ text: "✓  " + t, options: { breakLine: i < L.s13.done.length - 1, paraSpaceAfter: 9 } })),
    { x: 0.6, y: 1.75, w: 4.2, h: 2.6, fontSize: 14, color: C.text1, valign: "top", margin: 0, isTextBox: true });
  L.s13.kpi.forEach(([v, l], i) => {
    const x = 5.1 + (i % 2) * 2.2, y = 1.7 + Math.floor(i / 2) * 1.35;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w: 2.05, h: 1.2, rectRadius: 0.16, fill: { color: C.background1 }, line: { color: C.background1 } });
    s.addText([{ text: v, options: { bold: true, fontSize: 24, color: "2D6BF0", breakLine: true } }, { text: l, options: { fontSize: 11, color: MUTED } }],
      { x: x + 0.15, y: y + 0.1, w: 1.8, h: 1.0, margin: 0, isTextBox: true, valign: "top" });
  });
  s.addText(L.s13.kpiNote, { x: 5.1, y: 4.45, w: 4.3, h: 0.3, fontSize: 10, italic: true, color: MUTED, margin: 0, isTextBox: true });

  // 14 — closing
  pres.addSection({ title: sec[6] });
  s = pres.addSlide({ masterName: "BEKAT_DARK", sectionTitle: sec[6] });
  s.addImage({ path: A("bus.png"), x: 6.4, y: 0.7, w: 3.0, h: 2.5 });
  s.addText(L.s14.t, { x: 0.6, y: 0.9, w: 5.8, h: 1.5, fontSize: 34, bold: true, color: C.background1, margin: 0, isTextBox: true, valign: "top", objectName: "title" });
  s.addText(L.s14.sub, { x: 0.6, y: 2.55, w: 5.6, h: 0.9, fontSize: 15, color: "D6DAE2", margin: 0, isTextBox: true, valign: "top" });
  s.addText([{ text: L.s14.author, options: { bold: true, fontSize: 15, color: "FFFFFF", breakLine: true } }, { text: L.s14.contact, options: { fontSize: 12, color: "9AA1AE" } }],
    { x: 0.6, y: 4.1, w: 6, h: 0.8, margin: 0, isTextBox: true });

  const qrPath = path.join(__dirname, "..", "..", "qr_bekat.png");
  if (require("fs").existsSync(qrPath)) {
    s.addImage({ path: qrPath, x: 7.1, y: 3.25, w: 1.5, h: 1.5 });
    s.addText(lang === "uz" ? "Skaner qiling — ilovani yuklang" : "Сканируйте — скачайте приложение",
      { x: 6.3, y: 4.82, w: 3.1, h: 0.35, fontSize: 10, color: "9AA1AE", align: "center", margin: 0, isTextBox: true });
  }

  const out = path.join(__dirname, "..", L.file);
  await pres.writeFile({ fileName: out });
  await applyTheme(out, THEME);
  console.log("wrote", out);
}

(async () => {
  for (const lang of ["uz", "ru"]) await build(lang);
})();
