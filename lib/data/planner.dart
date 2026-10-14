import 'network.dart';
import 'schedule.dart';

/// Walking model: 75 m/min (4.5 km/h), streets are ~25% longer than a
/// straight line.
const walkMpm = 75.0;
const walkDetour = 1.25;
double walkMinutes(double meters) => meters * walkDetour / walkMpm;

sealed class Leg {
  double get start;
  double get end;
}

class WalkLeg extends Leg {
  WalkLeg(
    this.from,
    this.to,
    this.meters,
    this.start,
    this.end, {
    this.toStop,
    this.fromStop,
  });
  final Geo from, to;
  final Stop? fromStop, toStop;
  final double meters;
  @override
  final double start, end;
  double get realMeters => meters * walkDetour;
}

class RideLeg extends Leg {
  RideLeg(
    this.dir,
    this.board,
    this.alight,
    this.tripStart,
    this.start,
    this.end,
  );
  final RouteDir dir;
  final int board, alight;

  /// Terminal departure of the bus (identifies the vehicle in [Schedule]).
  final double tripStart;
  @override
  final double start, end;
  Stop get from => dir.stops[board];
  Stop get to => dir.stops[alight];
  int get stopCount => alight - board;
  List<Geo> get shape => dir.line.slice(dir.stopAt[board], dir.stopAt[alight]);
}

class Journey {
  Journey(
    this.legs,
    this.depart, {
    this.approximate = false,
    this.remainingMeters = 0,
  });
  final List<Leg> legs;
  final double depart;

  /// No stop near the destination: this gets as close as buses allow.
  final bool approximate;
  final double remainingMeters;

  double get arrive => legs.isEmpty ? depart : legs.last.end;
  double get minutes => arrive - depart;
  Iterable<RideLeg> get rides => legs.whereType<RideLeg>();
  int get transfers => rides.isEmpty ? 0 : rides.length - 1;
  double get walkMeters =>
      legs.whereType<WalkLeg>().fold(0.0, (a, w) => a + w.realMeters);
  bool get walkOnly => rides.isEmpty;
  double get walkMinutes =>
      legs.whereType<WalkLeg>().fold(0.0, (a, w) => a + (w.end - w.start));

  /// Minutes from now until the first bus leaves.
  double get firstWait {
    final r = rides.firstOrNull;
    return r == null ? 0 : r.start - depart;
  }
}

class _Label {
  _Label(this.time, this.ride, this.walkFrom);
  final double time;
  final RideLeg? ride; // reached by bus in this round
  final Stop? walkFrom; // reached on foot from this stop in this round
}

/// Round-based transit routing (RAPTOR, Delling et al. 2012) on the
/// simulated timetable. Round k = k buses = k-1 transfers.
class Planner {
  Planner(this.net, this.sched) {
    for (final a in net.stops.values) {
      _foot[a.id] = [
        for (final b in net.stops.values)
          if (a != b && a.pos.distanceTo(b.pos) <= maxTransferWalk)
            (b, a.pos.distanceTo(b.pos)),
      ];
    }
  }

  final Network net;
  final Schedule sched;
  final _foot = <String, List<(Stop, double)>>{};

  static const maxRounds = 3;
  static const accessRadius = 1000.0;
  static const maxTransferWalk = 450.0;

  List<Journey> plan(Geo from, Geo to, double now) {
    final direct = from.distanceTo(to);
    final out = <Journey>[];

    var access = net.stopsNear(from, radius: accessRadius);
    if (access.isEmpty) {
      access = net.stopsNear(from, radius: 1e9).take(2).toList();
    }
    var egress = net.stopsNear(to, radius: accessRadius);
    var approximate = false;
    if (egress.isEmpty) {
      egress = net.stopsNear(to, radius: 1e9).take(3).toList();
      approximate = true;
    }
    final egressBy = {for (final e in egress) e.$1.id: e.$2};

    // round 0: walk to the access stops
    var prev = <String, _Label>{
      for (final (s, d) in access)
        s.id: _Label(now + walkMinutes(d), null, null),
    };
    final rounds = <Map<String, _Label>>[prev];
    final best = <String, double>{
      for (final e in prev.entries) e.key: e.value.time,
    };
    var bestArrival = double.infinity;

    for (var k = 1; k <= maxRounds; k++) {
      final cur = <String, _Label>{};
      for (final d in net.dirs) {
        double? tripStart;
        int board = -1;
        for (var i = 0; i < d.stops.length; i++) {
          final s = d.stops[i];
          if (tripStart != null && i > board) {
            final t = sched.arrival(d, tripStart, i);
            if (t < (best[s.id] ?? double.infinity)) {
              best[s.id] = t;
              cur[s.id] = _Label(
                t,
                RideLeg(
                  d,
                  board,
                  i,
                  tripStart,
                  sched.arrival(d, tripStart, board),
                  t,
                ),
                null,
              );
            }
          }
          final p = prev[s.id];
          if (p != null && i < d.stops.length - 1) {
            final cand = sched.nextTripAt(d, i, p.time);
            if (tripStart == null || cand < tripStart) {
              tripStart = cand;
              board = i;
            }
          }
        }
      }
      // transfers on foot between nearby stops
      for (final e in cur.entries.toList()) {
        if (e.value.ride == null) continue;
        for (final (n, m) in _foot[e.key]!) {
          if (cur[n.id]?.ride != null) continue; // keep bus labels intact
          final t = e.value.time + walkMinutes(m);
          if (t < (best[n.id] ?? double.infinity)) {
            best[n.id] = t;
            cur[n.id] = _Label(t, null, net.stops[e.key]);
          }
        }
      }
      if (cur.isEmpty) break;
      rounds.add(cur);

      // best way to finish in this round
      Journey? roundBest;
      for (final e in cur.entries) {
        final m = egressBy[e.key];
        if (m == null) continue;
        final arrive = e.value.time + walkMinutes(m);
        if (arrive < bestArrival - 0.5) {
          bestArrival = arrive;
          roundBest = _build(
            rounds,
            k,
            net.stops[e.key]!,
            from,
            to,
            now,
            m,
            approximate,
          );
        }
      }
      if (roundBest != null) out.add(roundBest);
      prev = cur;
    }

    if (direct < 2500) {
      final w = walkMinutes(direct);
      if (out.isEmpty || w < out.first.minutes) {
        out.insert(0, Journey([WalkLeg(from, to, direct, now, now + w)], now));
      }
    }
    out.sort((a, b) => a.arrive.compareTo(b.arrive));
    return out.take(3).toList();
  }

  Journey _build(
    List<Map<String, _Label>> rounds,
    int k,
    Stop last,
    Geo from,
    Geo to,
    double now,
    double egressM,
    bool approximate,
  ) {
    final legs = <Leg>[];
    var s = last;
    for (var r = k; r >= 1; r--) {
      var l = rounds[r][s.id]!;
      if (l.walkFrom != null) {
        final a = l.walkFrom!;
        final m = a.pos.distanceTo(s.pos);
        legs.add(
          WalkLeg(
            a.pos,
            s.pos,
            m,
            l.time - walkMinutes(m),
            l.time,
            fromStop: a,
            toStop: s,
          ),
        );
        s = a;
        l = rounds[r][s.id]!;
      }
      final ride = l.ride!;
      legs.add(ride);
      s = ride.from;
    }
    final m0 = from.distanceTo(s.pos);
    final firstBus = (legs.last as RideLeg).start;
    legs.add(
      WalkLeg(from, s.pos, m0, firstBus - walkMinutes(m0), firstBus, toStop: s),
    );
    final rev = legs.reversed.toList();
    final arrive = rev.last.end;
    rev.add(
      WalkLeg(
        last.pos,
        to,
        egressM,
        arrive,
        arrive + walkMinutes(egressM),
        fromStop: last,
      ),
    );
    // "depart" = when you need to leave to just catch the first bus
    return Journey(
      rev,
      now,
      approximate: approximate || egressM > accessRadius,
      remainingMeters: egressM * walkDetour,
    );
  }
}
