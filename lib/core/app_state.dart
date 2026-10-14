import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/network.dart';
import '../data/planner.dart';
import '../data/schedule.dart';
import '../data/search.dart';

/// Where the user is standing when GPS is unavailable or outside Namangan
/// (e.g. at the contest stand): NamDTU main building.
const demoOrigin = Geo(41.0076, 71.6307);
const namanganCenter = Geo(41.0010, 71.6450);

class Endpoint {
  const Endpoint(this.title, this.pos, {this.isMe = false});
  final String title;
  final Geo pos;
  final bool isMe;
}

/// Single place for app state. Screens listen and rebuild.
class AppState extends ChangeNotifier {
  AppState(this.net) : sched = Schedule(net), search = PlaceSearch(net) {
    planner = Planner(net, sched);
  }

  final Network net;
  final Schedule sched;
  final PlaceSearch search;
  late final Planner planner;

  // ---- clock ---------------------------------------------------------
  /// Demo speed for presentations (1 = real time).
  double speed = 1;
  final _wall = Stopwatch()..start();
  double _base = Schedule.nowMinutes();
  double _baseWall = 0;

  double get now =>
      _base + (_wall.elapsedMilliseconds / 60000.0 - _baseWall) * speed;

  void setSpeed(double s) {
    _base = now;
    _baseWall = _wall.elapsedMilliseconds / 60000.0;
    speed = s;
    notifyListeners();
  }

  // ---- settings ------------------------------------------------------
  bool bigText = false;

  Future<void> loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      bigText = p.getBool('bigText') ?? false;
    } catch (_) {}
  }

  Future<void> setBigText(bool v) async {
    bigText = v;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setBool('bigText', v);
    } catch (_) {}
  }

  // ---- location ------------------------------------------------------
  Geo me = demoOrigin;
  bool gpsReal = false;

  Future<void> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 8),
      );
      final g = Geo(p.latitude, p.longitude);
      if (g.distanceTo(namanganCenter) < 20000) {
        me = g;
        gpsReal = true;
        if (origin.isMe) origin = Endpoint(origin.title, me, isMe: true);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ---- trip planning -------------------------------------------------
  late Endpoint origin = Endpoint('', me, isMe: true);
  Endpoint? dest;
  List<Journey> journeys = [];
  int selected = 0;
  Journey? active; // trip in progress

  Journey? get journey => journeys.isEmpty
      ? null
      : journeys[selected.clamp(0, journeys.length - 1)];

  void setDest(Endpoint? e) {
    dest = e;
    active = null;
    _replan();
  }

  void setOrigin(Endpoint e) {
    origin = e;
    active = null;
    _replan();
  }

  void swap() {
    if (dest == null) return;
    final o = origin;
    origin = dest!;
    dest = o;
    _replan();
  }

  void select(int i) {
    selected = i;
    notifyListeners();
  }

  void _replan() {
    selected = 0;
    journeys = dest == null ? [] : planner.plan(origin.pos, dest!.pos, now);
    notifyListeners();
  }

  /// Re-plan with the current time (keeps arrival predictions fresh).
  void refresh() {
    if (dest != null && active == null) {
      final keep = selected;
      journeys = planner.plan(origin.pos, dest!.pos, now);
      selected = keep.clamp(0, journeys.isEmpty ? 0 : journeys.length - 1);
      notifyListeners();
    }
  }

  void start() {
    active = journey;
    notifyListeners();
  }

  void endTrip() {
    active = null;
    dest = null;
    journeys = [];
    notifyListeners();
  }

  void clear() => setDest(null);
}

/// Ticks listeners ~[fps] times per second (animations that follow buses).
class Ticker2 {
  Ticker2(this.fps, this.onTick);
  final int fps;
  final VoidCallback onTick;
  Timer? _t;
  void start() => _t ??= Timer.periodic(
    Duration(milliseconds: 1000 ~/ fps),
    (_) => onTick(),
  );
  void stop() {
    _t?.cancel();
    _t = null;
  }
}
