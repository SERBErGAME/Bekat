import '../core/app_state.dart';
import '../data/network.dart';
import '../data/planner.dart';

enum Phase { walking, waiting, riding, arrived }

/// Where the traveller is along a journey at time [now], assuming they
/// follow the plan (walk at normal pace, take the planned bus).
class TripProgress {
  TripProgress(AppState app, this.j, this.now) {
    final legs = j.legs;
    var idx = legs.length - 1;
    for (var i = 0; i < legs.length; i++) {
      if (now < legs[i].end) {
        idx = i;
        break;
      }
    }
    legIndex = idx;
    final l = legs[idx];
    if (now >= j.arrive) {
      phase = Phase.arrived;
      position = (legs.last as WalkLeg).to;
      heading = 0;
    } else if (l is WalkLeg) {
      final t = ((now - l.start) / (l.end - l.start).clamp(0.01, 1e9)).clamp(
        0.0,
        1.0,
      );
      if (now < l.start) {
        // early: standing at the stop, waiting for the bus
        phase = Phase.waiting;
        position = l.from;
      } else {
        phase = Phase.walking;
        position = Geo.lerp(l.from, l.to, t);
      }
      heading = l.from.bearingTo(l.to);
    } else if (l is RideLeg) {
      final bus = app.sched.busOf(l.dir, l.tripStart, now);
      if (now < l.start || bus == null) {
        phase = Phase.waiting;
        position = l.from.pos;
        heading = l.dir.line.at(l.dir.stopAt[l.board]).$2;
      } else {
        phase = Phase.riding;
        final (p, h) = bus.point;
        position = p;
        heading = h;
        busStop = bus.lastStop;
        busMeters = bus.meters;
      }
    }
  }

  final Journey j;
  final double now;
  late final int legIndex;
  late final Phase phase;
  late final Geo position;
  late final double heading;
  int? busStop;
  double? busMeters;

  bool get onBus => phase == Phase.riding;

  /// The ride leg that is current or next.
  RideLeg? get ride {
    for (var i = legIndex; i < j.legs.length; i++) {
      final l = j.legs[i];
      if (l is RideLeg) return l;
    }
    return null;
  }

  /// Ride still to board after the current one (for "change to ..." hints).
  RideLeg? get nextRide {
    var seen = false;
    for (var i = legIndex; i < j.legs.length; i++) {
      final l = j.legs[i];
      if (l is RideLeg) {
        if (seen) return l;
        seen = true;
      }
    }
    return null;
  }

  int get stopsLeft {
    var n = 0;
    for (var i = legIndex; i < j.legs.length; i++) {
      final l = j.legs[i];
      if (l is! RideLeg) continue;
      if (i == legIndex && onBus) {
        n += (l.alight - (busStop ?? l.board)).clamp(0, 99);
      } else {
        n += l.stopCount;
      }
    }
    return n;
  }

  double get minutesLeft => (j.arrive - now).clamp(0, 9999).toDouble();

  /// Minutes until the next bus to board arrives (null while riding).
  double? get busInMin {
    final r = ride;
    if (r == null || onBus) return null;
    return (r.start - now).clamp(0, 999).toDouble();
  }

  /// 0..1 progress through the current/next ride, by stops.
  double get rideFraction {
    final r = ride;
    if (r == null) return 1;
    if (!onBus) return 0;
    final total = r.dir.stopAt[r.alight] - r.dir.stopAt[r.board];
    return (((busMeters ?? 0) - r.dir.stopAt[r.board]) / total).clamp(0.0, 1.0);
  }
}
