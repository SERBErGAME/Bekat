import 'network.dart';

/// Timetable model. Until operators share GPS feeds, buses are simulated
/// from the published headway: departures from each terminal every
/// `headwayMin`, average speed [speedMpm], [dwellMin] at every stop.
/// Map animation, arrival times and trip planning all read from here, so
/// what the user sees moving is exactly what the planner promises.
class Schedule {
  Schedule(this.net) {
    for (final d in net.dirs) {
      final off = <double>[];
      for (var i = 0; i < d.stops.length; i++) {
        off.add(d.stopAt[i] / speedMpm + i * dwellMin);
      }
      _offsets[d.key] = off;
      // Spread the two directions and the routes so buses don't bunch.
      final seed = int.tryParse(d.route.id) ?? 0;
      _phase[d.key] =
          ((seed * 3.7) + d.dir * d.route.headwayMin / 2) % d.route.headwayMin;
    }
  }

  final Network net;

  /// 18 km/h — typical average for a city bus including traffic lights.
  static const speedMpm = 300.0;
  static const dwellMin = 0.5;

  final _offsets = <String, List<double>>{};
  final _phase = <String, double>{};

  /// Minutes after the terminal departure at which a bus reaches stop [i].
  double offset(RouteDir d, int i) => _offsets[d.key]![i];
  double tripMinutes(RouteDir d) => _offsets[d.key]!.last;

  /// Departure time (minutes since midnight) of the first bus of [d] that
  /// reaches stop [i] at or after [t]. Returns that bus's terminal departure.
  double nextTripAt(RouteDir d, int i, double t) {
    final h = d.route.headwayMin.toDouble();
    final base = t - offset(d, i) - _phase[d.key]!;
    final k = (base / h).ceil();
    return _phase[d.key]! + k * h;
  }

  /// Time (minutes since midnight) when the bus that left the terminal at
  /// [tripStart] is at stop [i].
  double arrival(RouteDir d, double tripStart, int i) =>
      tripStart + offset(d, i);

  /// Minutes until the next bus of [d] reaches stop [i].
  double waitAt(RouteDir d, int i, double now) =>
      arrival(d, nextTripAt(d, i, now), i) - now;

  /// All buses on the road at [now].
  List<BusPos> positions(double now) {
    final out = <BusPos>[];
    for (final d in net.dirs) {
      final off = _offsets[d.key]!;
      final total = off.last;
      final h = d.route.headwayMin.toDouble();
      final ph = _phase[d.key]!;
      // Trips that started within the last `total` minutes.
      final kMax = ((now - ph) / h).floor();
      final kMin = ((now - total - ph) / h).ceil();
      for (var k = kMin; k <= kMax; k++) {
        final start = ph + k * h;
        final e = now - start;
        out.add(BusPos(d, start, _distanceAt(d, off, e)));
      }
    }
    return out;
  }

  /// Distance along the line after [e] minutes of a trip.
  double _distanceAt(RouteDir d, List<double> off, double e) {
    for (var i = 0; i < off.length - 1; i++) {
      final leave = off[i] + (i == 0 ? 0 : dwellMin);
      if (e < leave) return d.stopAt[i];
      if (e < off[i + 1]) {
        final t = (e - leave) / (off[i + 1] - leave);
        return d.stopAt[i] + (d.stopAt[i + 1] - d.stopAt[i]) * t;
      }
    }
    return d.line.length;
  }

  /// Where the bus of trip [tripStart] is now, or null if not on the road.
  BusPos? busOf(RouteDir d, double tripStart, double now) {
    final e = now - tripStart;
    final off = _offsets[d.key]!;
    if (e < 0 || e > off.last) return null;
    return BusPos(d, tripStart, _distanceAt(d, off, e));
  }

  static double nowMinutes([DateTime? t]) {
    t ??= DateTime.now();
    return t.hour * 60 + t.minute + t.second / 60 + t.millisecond / 60000;
  }
}

class BusPos {
  BusPos(this.dir, this.tripStart, this.meters);
  final RouteDir dir;
  final double tripStart;
  final double meters;

  (Geo, double) get point => dir.line.at(meters);

  /// Index of the last stop passed.
  int get lastStop {
    var i = 0;
    while (i < dir.stopAt.length - 1 && dir.stopAt[i + 1] <= meters) {
      i++;
    }
    return i;
  }
}
