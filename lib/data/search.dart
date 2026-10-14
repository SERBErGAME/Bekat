import 'dart:convert';

import 'package:http/http.dart' as http;

import 'network.dart';

class Place {
  Place(this.title, this.subtitle, this.pos, this.kind, {this.stop});
  final String title;
  final String subtitle;
  final Geo pos;
  final String kind;
  final Stop? stop;
}

/// Offline search over stops and landmarks; understands Latin and Cyrillic
/// spellings ("chorsu" finds "Чорсу" and vice versa).
class PlaceSearch {
  PlaceSearch(this.net);
  final Network net;

  List<Place> query(String q, String lang) {
    final n = norm(q);
    if (n.isEmpty) return [];
    final scored = <(int, Place)>[];
    for (final s in net.stops.values) {
      final score = _score(n, [s.name.uz, s.name.ru, s.name.en]);
      if (score > 0) {
        scored.add((
          score + 5,
          Place(
            s.name.of(lang),
            s.routeIds.map((r) => '№$r').join('  '),
            s.pos,
            s.kind,
            stop: s,
          ),
        ));
      }
    }
    for (final p in net.pois) {
      final score = _score(n, [p.name, if (p.nameRu != null) p.nameRu!]);
      if (score > 0) {
        final (st, d) = net.nearestStop(p.pos);
        scored.add((
          score,
          Place(p.name, '${st.name.of(lang)} · ${d.round()} m', p.pos, p.kind),
        ));
      }
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((e) => e.$2).take(12).toList();
  }

  int _score(String q, List<String> names) {
    var best = 0;
    for (final name in names) {
      final n = norm(name);
      if (n == q) {
        best = 100;
      } else if (n.startsWith(q)) {
        best = best < 80 ? 80 : best;
      } else if (n.split(' ').any((w) => w.startsWith(q))) {
        best = best < 60 ? 60 : best;
      } else if (n.contains(q)) {
        best = best < 40 ? 40 : best;
      }
    }
    return best;
  }

  /// Online fallback (OpenStreetMap Nominatim, limited to Namangan).
  Future<List<Place>> online(String q) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '6',
        'bounded': '1',
        'viewbox': '71.50,41.08,71.76,40.95',
        'accept-language': 'uz,ru',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 6));
      final list = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
      return [
        for (final e in list)
          Place(
            (e['display_name'] as String).split(',').first,
            (e['display_name'] as String)
                .split(',')
                .skip(1)
                .take(2)
                .join(',')
                .trim(),
            Geo(
              double.parse(e['lat'] as String),
              double.parse(e['lon'] as String),
            ),
            'place',
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  static const _cyr = {
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'е': 'e',
    'ё': 'yo',
    'ж': 'j',
    'з': 'z',
    'и': 'i',
    'й': 'y',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'х': 'x',
    'ц': 'ts',
    'ч': 'ch',
    'ш': 'sh',
    'щ': 'sh',
    'ъ': '',
    'ы': 'i',
    'ь': '',
    'э': 'e',
    'ю': 'yu',
    'я': 'ya',
    'ў': 'o',
    'қ': 'q',
    'ғ': 'g',
    'ҳ': 'h',
  };

  static String norm(String s) {
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      if ('‘’\'`ʻʼ'.contains(ch)) continue;
      b.write(_cyr[ch] ?? ch);
    }
    return b
        .toString()
        .replaceAll('kh', 'x')
        .replaceAll('h', 'x')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
