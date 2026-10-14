import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny trilingual dictionary. Text in Bekat is deliberately short.
class Lang extends ChangeNotifier {
  Lang._();
  static final Lang i = Lang._();

  String code = 'uz';
  static const codes = ['uz', 'ru', 'en'];
  static const labels = {'uz': 'O‘zbekcha', 'ru': 'Русский', 'en': 'English'};

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      code = p.getString('lang') ?? 'uz';
    } catch (_) {}
  }

  Future<void> set(String c) async {
    code = c;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString('lang', c);
    } catch (_) {}
  }

  String t(String key) => (_s[key] ?? const {})[code] ?? _s[key]?['uz'] ?? key;
}

String tr(String key) => Lang.i.t(key);

/// Formats minutes as "12 daq" / "1 soat 5 daq".
String fmtMin(double m) {
  final v = m.round().clamp(0, 9999);
  if (v < 60) return '$v ${tr('min')}';
  return '${v ~/ 60} ${tr('hour')} ${v % 60} ${tr('min')}';
}

String fmtClock(double minutes) {
  final m = minutes.round() % (24 * 60);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

String fmtMeters(double m) => m < 1000
    ? '${(m / 10).round() * 10} m'
    : '${(m / 1000).toStringAsFixed(1)} km';

const _s = <String, Map<String, String>>{
  'whereTo': {'uz': 'Qayerga borasiz?', 'ru': 'Куда едем?', 'en': 'Where to?'},
  'from': {'uz': 'Qayerdan', 'ru': 'Откуда', 'en': 'From'},
  'to': {'uz': 'Qayerga', 'ru': 'Куда', 'en': 'To'},
  'myPlace': {'uz': 'Men turgan joy', 'ru': 'Моё место', 'en': 'My location'},
  'pinned': {
    'uz': 'Xaritadagi nuqta',
    'ru': 'Точка на карте',
    'en': 'Point on map',
  },
  'min': {'uz': 'daq', 'ru': 'мин', 'en': 'min'},
  'hour': {'uz': 'soat', 'ru': 'ч', 'en': 'h'},
  'go': {'uz': 'Yo‘lga', 'ru': 'Поехали', 'en': 'Go'},
  'walk': {'uz': 'Piyoda', 'ru': 'Пешком', 'en': 'Walk'},
  'transfer': {'uz': 'almashinuv', 'ru': 'пересадка', 'en': 'transfer'},
  'transfers': {'uz': 'almashinuv', 'ru': 'пересадки', 'en': 'transfers'},
  'direct': {'uz': 'To‘g‘ridan-to‘g‘ri', 'ru': 'Без пересадок', 'en': 'Direct'},
  'busIn': {'uz': 'Avtobus', 'ru': 'Автобус через', 'en': 'Bus in'},
  'stopsLeft': {
    'uz': 'Bekat qoldi',
    'ru': 'Осталось остановок',
    'en': 'Stops left',
  },
  'timeLeft': {'uz': 'Yetib borish', 'ru': 'В пути', 'en': 'Time left'},
  'arrive': {'uz': 'Yetib borasiz', 'ru': 'Прибытие', 'en': 'Arrive'},
  'board': {'uz': 'Chiqing', 'ru': 'Садитесь', 'en': 'Board'},
  'alight': {'uz': 'Tushing', 'ru': 'Выходите', 'en': 'Get off'},
  'change': {'uz': 'Almashing', 'ru': 'Пересадка', 'en': 'Change'},
  'stops': {'uz': 'bekat', 'ru': 'ост.', 'en': 'stops'},
  'toward': {'uz': 'tomon', 'ru': 'в сторону', 'en': 'towards'},
  'closest': {
    'uz': 'Manzilga avtobus bormaydi — eng yaqin yo‘l',
    'ru': 'Автобус не доходит — ближайший путь',
    'en': 'No bus goes there — closest way',
  },
  'leftOnFoot': {
    'uz': 'qolgani piyoda',
    'ru': 'остаток пешком',
    'en': 'rest on foot',
  },
  'noRoute': {
    'uz': 'Yo‘l topilmadi',
    'ru': 'Маршрут не найден',
    'en': 'No route found',
  },
  'scheme': {'uz': 'Sxema', 'ru': 'Схема', 'en': 'Lines'},
  'map': {'uz': 'Xarita', 'ru': 'Карта', 'en': 'Map'},
  'nearby': {'uz': 'Yaqin bekat', 'ru': 'Рядом', 'en': 'Nearby'},
  'next': {'uz': 'Keyingi', 'ru': 'Ближайшие', 'en': 'Next'},
  'now': {'uz': 'hozir', 'ru': 'сейчас', 'en': 'now'},
  'demo': {'uz': 'namuna', 'ru': 'пример', 'en': 'sample'},
  'search': {
    'uz': 'Joy yoki bekat',
    'ru': 'Место или остановка',
    'en': 'Place or stop',
  },
  'tapMap': {
    'uz': 'yoki xaritaga bosing',
    'ru': 'или нажмите на карту',
    'en': 'or tap the map',
  },
  'fromHere': {'uz': 'Shu yerdan', 'ru': 'Отсюда', 'en': 'From here'},
  'toHere': {'uz': 'Shu yerga', 'ru': 'Сюда', 'en': 'To here'},
  'lines': {'uz': 'Yo‘nalishlar', 'ru': 'Маршруты', 'en': 'Routes'},
  'settings': {'uz': 'Sozlamalar', 'ru': 'Настройки', 'en': 'Settings'},
  'language': {'uz': 'Til', 'ru': 'Язык', 'en': 'Language'},
  'bigText': {'uz': 'Yirik yozuv', 'ru': 'Крупный текст', 'en': 'Large text'},
  'about': {'uz': 'Ilova haqida', 'ru': 'О приложении', 'en': 'About'},
  'end': {'uz': 'Tugatish', 'ru': 'Завершить', 'en': 'End'},
  'onBus': {'uz': 'Avtobusdasiz', 'ru': 'Вы в автобусе', 'en': 'On the bus'},
  'waiting': {
    'uz': 'Bekatga boring',
    'ru': 'Идите к остановке',
    'en': 'Walk to the stop',
  },
  'arrived': {
    'uz': 'Yetib keldingiz!',
    'ru': 'Вы на месте!',
    'en': 'You have arrived!',
  },
  'busArrives': {
    'uz': 'Avtobus keladi',
    'ru': 'Автобус придёт',
    'en': 'Bus arrives',
  },
  'kmh': {'uz': 'km/s', 'ru': 'км/ч', 'en': 'km/h'},
  'tagline': {
    'uz': 'Namangan avtobuslari',
    'ru': 'Автобусы Намангана',
    'en': 'Namangan buses',
  },
  'aboutText': {
    'uz':
        'Bekat — Namangan shahar avtobuslari uchun marshrut xaritasi. №1, №2, №3 yo‘nalishlari va oxirgi bekatlari rasmiy manbalardan; oraliq bekatlar va №5, №7, №9 — namuna. Avtobus vaqtlari qatnov oralig‘i asosida taxminiy. Xarita: © OpenStreetMap, OpenFreeMap.',
    'ru':
        'Bekat — карта маршрутов автобусов Намангана. Маршруты №1, №2, №3 и их конечные — из официальных источников; промежуточные остановки и №5, №7, №9 — пример. Время прибытия рассчитано по интервалу движения. Карта: © OpenStreetMap, OpenFreeMap.',
    'en':
        'Bekat — bus route map for Namangan. Routes 1, 2, 3 and their end stops come from official sources; intermediate stops and routes 5, 7, 9 are samples. Arrival times are estimated from the service interval. Map: © OpenStreetMap, OpenFreeMap.',
  },
  'author': {
    'uz': 'Muallif: Rasulov Farruh',
    'ru': 'Автор: Расулов Фаррух',
    'en': 'Author: Farrukh Rasulov',
  },
  'estimated': {
    'uz': 'taxminiy vaqt',
    'ru': 'примерное время',
    'en': 'estimated',
  },
};
