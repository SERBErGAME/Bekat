import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;

/// A geographic point (WGS84).
class Geo {
  const Geo(this.lat, this.lon);
  final double lat;
  final double lon;

  /// Great-circle distance in metres.
  double distanceTo(Geo o) {
    const r = 6371000.0;
    final dLat = _rad(o.lat - lat), dLon = _rad(o.lon - lon);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(o.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  /// Bearing in degrees (0 = north, clockwise).
  double bearingTo(Geo o) {
    final y = math.sin(_rad(o.lon - lon)) * math.cos(_rad(o.lat));
    final x =
        math.cos(_rad(lat)) * math.sin(_rad(o.lat)) -
        math.sin(_rad(lat)) *
            math.cos(_rad(o.lat)) *
            math.cos(_rad(o.lon - lon));
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static Geo lerp(Geo a, Geo b, double t) =>
      Geo(a.lat + (b.lat - a.lat) * t, a.lon + (b.lon - a.lon) * t);

  List<double> get lonLat => [lon, lat];

  static double _rad(double d) => d * math.pi / 180;
}

/// Trilingual text (uz / ru / en).
class L3 {
  const L3(this.uz, this.ru, this.en);
  factory L3.fromJson(Map<String, dynamic> j) =>
      L3(j['uz'] as String, j['ru'] as String, j['en'] as String);
  final String uz, ru, en;
  String of(String lang) => switch (lang) {
    'ru' => ru,
    'en' => en,
    _ => uz,
  };
}

class Stop {
  Stop(this.id, this.name, this.pos, this.kind, this.routeIds);
  final String id;
  final L3 name;
  final Geo pos;
  final String kind;
  final List<String> routeIds;
}

class Poi {
  Poi(this.name, this.nameRu, this.pos, this.kind);
  final String name;
  final String? nameRu;
  final Geo pos;
  final String kind;
}

/// A polyline with cumulative distances, so points can be looked up by metre.
class Polyline {
  Polyline(this.points) : cum = _cumulative(points);
  final List<Geo> points;
  final List<double> cum;
  double get length => cum.last;

  static List<double> _cumulative(List<Geo> pts) {
    final out = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      out.add(out.last + pts[i - 1].distanceTo(pts[i]));
    }
    return out;
  }

  /// Point and heading at [d] metres from the start.
  (Geo, double) at(double d) {
    d = d.clamp(0, length);
    var lo = 0, hi = cum.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (cum[mid] <= d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final seg = cum[hi] - cum[lo];
    final t = seg == 0 ? 0.0 : (d - cum[lo]) / seg;
    return (
      Geo.lerp(points[lo], points[hi], t),
      points[lo].bearingTo(points[hi]),
    );
  }

  /// Distance along the line of the vertex closest to [p] (searching forward
  /// from [from] so stops keep their order).
  double locate(Geo p, {double from = 0}) {
    var best = double.infinity, bestD = from;
    for (var i = 0; i < points.length; i++) {
      if (cum[i] + 1 < from) continue;
      final d = points[i].distanceTo(p);
      if (d < best) {
        best = d;
        bestD = cum[i];
      }
    }
    return bestD;
  }

  /// Sub-line between two distances (for drawing one leg of a trip).
  List<Geo> slice(double a, double b) {
    if (a > b) return slice(b, a).reversed.toList();
    final out = <Geo>[at(a).$1];
    for (var i = 0; i < points.length; i++) {
      if (cum[i] > a && cum[i] < b) out.add(points[i]);
    }
    out.add(at(b).$1);
    return out;
  }
}

/// One direction of a bus route.
class RouteDir {
  RouteDir(this.route, this.dir, this.stops, this.line, this.stopAt);
  final BusRoute route;

  /// 0 = as listed in the data, 1 = reverse.
  final int dir;
  final List<Stop> stops;
  final Polyline line;

  /// Distance along [line] of every stop, metres.
  final List<double> stopAt;

  String get key => '${route.id}/$dir';
  Stop get terminus => stops.last;
}

class BusRoute {
  BusRoute(this.id, this.color, this.headwayMin, this.demo, this.name);
  final String id;
  final Color color;
  final int headwayMin;
  final bool demo;
  final L3 name;
  late final List<RouteDir> dirs;
  late final List<Geo> shape;
}

class Network {
  Network._(this.stops, this.routes, this.pois);

  final Map<String, Stop> stops;
  final List<BusRoute> routes;
  final List<Poi> pois;

  BusRoute route(String id) => routes.firstWhere((r) => r.id == id);
  Iterable<RouteDir> get dirs => routes.expand((r) => r.dirs);

  static Future<Network> load() async =>
      Network.parse(await rootBundle.loadString('assets/data/network.json'));

  factory Network.parse(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    final stops = <String, Stop>{
      for (final s in (j['stops'] as List).cast<Map<String, dynamic>>())
        s['id'] as String: Stop(
          s['id'] as String,
          L3.fromJson(s['name'] as Map<String, dynamic>),
          Geo((s['lat'] as num).toDouble(), (s['lon'] as num).toDouble()),
          s['kind'] as String,
          (s['routes'] as List).cast<String>(),
        ),
    };
    final routes = <BusRoute>[];
    for (final r in (j['routes'] as List).cast<Map<String, dynamic>>()) {
      final hex = int.parse((r['color'] as String).substring(1), radix: 16);
      final route = BusRoute(
        r['id'] as String,
        Color(0xFF000000 | hex),
        r['headwayMin'] as int,
        r['demo'] as bool,
        L3.fromJson(r['name'] as Map<String, dynamic>),
      );
      final shape = [
        for (final c in (r['line'] as List).cast<List>())
          Geo((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      final seq = [
        for (final id in (r['stops'] as List).cast<String>()) stops[id]!,
      ];
      route.shape = shape;
      RouteDir build(int dir, List<Geo> pts, List<Stop> ss) {
        final line = Polyline(pts);
        final at = <double>[];
        for (final s in ss) {
          at.add(line.locate(s.pos, from: at.isEmpty ? 0 : at.last));
        }
        at[0] = 0;
        at[at.length - 1] = line.length;
        return RouteDir(route, dir, ss, line, at);
      }

      route.dirs = [
        build(0, shape, seq),
        build(1, shape.reversed.toList(), seq.reversed.toList()),
      ];
      routes.add(route);
    }
    final pois = [
      for (final p in (j['pois'] as List).cast<Map<String, dynamic>>())
        Poi(
          p['name'] as String,
          p['ru'] as String?,
          Geo((p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()),
          p['kind'] as String,
        ),
    ];
    return Network._(stops, routes, pois);
  }

  /// Stops within [radius] metres, nearest first.
  List<(Stop, double)> stopsNear(Geo p, {double radius = 1200}) {
    final out = [
      for (final s in stops.values)
        if (s.pos.distanceTo(p) <= radius) (s, s.pos.distanceTo(p)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return out;
  }

  (Stop, double) nearestStop(Geo p) {
    Stop? best;
    var bd = double.infinity;
    for (final s in stops.values) {
      final d = s.pos.distanceTo(p);
      if (d < bd) {
        bd = d;
        best = s;
      }
    }
    return (best!, bd);
  }
}
