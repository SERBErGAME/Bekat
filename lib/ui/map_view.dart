import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../data/network.dart';
import '../data/planner.dart';
import 'map_style.dart';
import 'trip_progress.dart';
import 'widgets.dart';

LatLng ll(Geo g) => LatLng(g.lat, g.lon);

/// The living 3D map: network, moving buses, the chosen trip.
class BekatMap extends StatefulWidget {
  const BekatMap({super.key, required this.app, required this.bottomInset});
  final AppState app;

  /// Height covered by the bottom panel, so camera fits keep things visible.
  final double bottomInset;

  @override
  State<BekatMap> createState() => BekatMapState();
}

class BekatMapState extends State<BekatMap> {
  MapLibreMapController? _c;
  bool _ready = false;
  Timer? _timer;
  late String _style;
  String _lang = Lang.i.code;
  Journey? _shownJourney;
  Journey? _shownActive;
  Endpoint? _shownDest;
  Geo? _shownOrigin;
  bool _busy = false;
  int _frame = 0;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _style = buildStyle(app.net, _lang);
    app.addListener(_onApp);
    Lang.i.addListener(_onLang);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cam?.cancel();
    app.removeListener(_onApp);
    Lang.i.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() {
    if (Lang.i.code == _lang) return;
    _lang = Lang.i.code;
    // stop names follow the language
    _c?.setGeoJsonSource('stops', stopsGeoJson(app.net, _lang));
  }

  Future<void> _onStyle() async {
    final c = _c!;
    for (final r in app.net.routes) {
      await c.addImage('bus-${r.id}', await busSprite(r.color));
      await c.addImage('badge-${r.id}', await busBadge(r));
    }
    await c.addGeoJsonSource('trip', _empty);
    await c.addGeoJsonSource('pins', _empty);
    await c.addGeoJsonSource('buses', _empty);

    await c.addLayer(
      'trip',
      'trip-walk',
      const LineLayerProperties(
        lineColor: '#5B6270',
        lineWidth: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          3,
          16,
          6,
        ],
        lineDasharray: [0.1, 2.0],
        lineCap: 'round',
      ),
      filter: [
        '==',
        ['get', 'kind'],
        'walk',
      ],
    );
    await c.addLayer(
      'trip',
      'trip-ride-case',
      const LineLayerProperties(
        lineColor: '#FFFFFF',
        lineWidth: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          7,
          16,
          16,
        ],
        lineCap: 'round',
        lineJoin: 'round',
      ),
      filter: [
        '==',
        ['get', 'kind'],
        'ride',
      ],
    );
    await c.addLayer(
      'trip',
      'trip-ride',
      const LineLayerProperties(
        lineColor: ['get', 'color'],
        lineWidth: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          4.5,
          16,
          10,
        ],
        lineCap: 'round',
        lineJoin: 'round',
      ),
      filter: [
        '==',
        ['get', 'kind'],
        'ride',
      ],
    );
    await c.addLayer(
      'trip',
      'trip-stops',
      const CircleLayerProperties(
        circleRadius: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          4,
          16,
          9,
        ],
        circleColor: '#FFFFFF',
        circleStrokeColor: ['get', 'color'],
        circleStrokeWidth: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          2,
          16,
          4,
        ],
        circlePitchAlignment: 'map',
      ),
      filter: [
        '==',
        ['get', 'kind'],
        'stop',
      ],
    );

    await c.addLayer(
      'buses',
      'bus-icon',
      const SymbolLayerProperties(
        iconImage: ['get', 'icon'],
        iconRotate: ['get', 'bearing'],
        iconRotationAlignment: 'map',
        iconPitchAlignment: 'map',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconSize: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          0.14,
          14,
          0.3,
          17,
          0.62,
        ],
      ),
    );
    await c.addLayer(
      'buses',
      'bus-badge',
      const SymbolLayerProperties(
        iconImage: ['get', 'badge'],
        iconAnchor: 'bottom',
        iconOffset: [0, -18],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconSize: [
          'interpolate',
          ['linear'],
          ['zoom'],
          12,
          [
            'case',
            ['get', 'focus'],
            0.55,
            0.3,
          ],
          16,
          [
            'case',
            ['get', 'focus'],
            0.8,
            0.5,
          ],
        ],
      ),
      minzoom: 12.8,
    );

    await c.addLayer(
      'pins',
      'pin-halo',
      const CircleLayerProperties(
        circleRadius: ['get', 'halo'],
        circleColor: ['get', 'color'],
        circleOpacity: ['get', 'haloOpacity'],
        circlePitchAlignment: 'map',
      ),
    );
    await c.addLayer(
      'pins',
      'pin-dot',
      const CircleLayerProperties(
        circleRadius: 9,
        circleColor: ['get', 'color'],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 4,
        circlePitchAlignment: 'map',
      ),
    );
    await c.addLayer(
      'pins',
      'pin-me',
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: ['get', 'color'],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
      ),
      filter: [
        '==',
        ['get', 'kind'],
        'walker',
      ],
    );

    _fixedCam = Uri.base.queryParameters.containsKey('cam');
    _ready = true;
    _timer = Timer.periodic(const Duration(milliseconds: 160), (_) => _tick());
    _onApp();
    // Marketing shots (web): ?cam=lat,lon,zoom,tilt,bearing fixes the camera.
    final cam = Uri.base.queryParameters['cam']
        ?.split(',')
        .map(double.parse)
        .toList();
    if (cam != null && cam.length == 5) {
      _fixedCam = true;
      c.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(cam[0], cam[1]),
            zoom: cam[2],
            tilt: cam[3],
            bearing: cam[4],
          ),
        ),
      );
      return;
    }
    // gentle fly-in
    await Future.delayed(const Duration(milliseconds: 300));
    if (app.dest == null) {
      _fly(
        CameraPosition(
          target: ll(app.origin.pos),
          zoom: 14.6,
          tilt: 58,
          bearing: -18,
        ),
        const Duration(milliseconds: 2400),
      );
    }
  }

  // ---- camera ------------------------------------------------------------
  // Own camera animation: MapLibre web's flyTo/easeTo can land off target
  // while sources update every frame; jumpTo is exact, so we tween jumps.
  Timer? _cam;
  bool _fixedCam = false;

  Future<void> _fly(CameraPosition to, Duration d) async {
    final c = _c;
    if (c == null || _fixedCam) return;
    _cam?.cancel();
    final from = await c.queryCameraPosition();
    if (from == null) {
      c.moveCamera(CameraUpdate.newCameraPosition(to));
      return;
    }
    final sw = Stopwatch()..start();
    var db = (to.bearing - from.bearing) % 360;
    if (db > 180) db -= 360;
    if (db < -180) db += 360;
    // zoom out a little mid-way on long moves, like a real flight
    final dist = Geo(
      from.target.latitude,
      from.target.longitude,
    ).distanceTo(Geo(to.target.latitude, to.target.longitude));
    final dip = (dist / 4000).clamp(0.0, 1.2);
    _cam = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final x = (sw.elapsedMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
      final e = Curves.easeInOutCubic.transform(x);
      double lerp(double a, double b) => a + (b - a) * e;
      c.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              lerp(from.target.latitude, to.target.latitude),
              lerp(from.target.longitude, to.target.longitude),
            ),
            zoom: lerp(from.zoom, to.zoom) - dip * math.sin(math.pi * x),
            tilt: lerp(from.tilt, to.tilt),
            bearing: from.bearing + db * e,
          ),
        ),
      );
      if (x >= 1) t.cancel();
    });
  }

  static const _empty = {'type': 'FeatureCollection', 'features': <dynamic>[]};

  // ---- per-frame ---------------------------------------------------------
  Future<void> _tick() async {
    if (!_ready || _busy || !mounted) return;
    _busy = true;
    _frame++;
    try {
      final now = app.now;
      final active = app.active ?? app.journey;
      final focusTrips = <String>{
        if (active != null)
          for (final r in active.rides) '${r.dir.key}@${r.tripStart}',
      };
      final routeFilter = active?.rides.map((r) => r.dir.route.id).toSet();
      final feats = <Map<String, dynamic>>[];
      for (final b in app.sched.positions(now)) {
        if (routeFilter != null && !routeFilter.contains(b.dir.route.id)) {
          continue;
        }
        final (p, bearing) = b.point;
        feats.add({
          'type': 'Feature',
          'properties': {
            'icon': 'bus-${b.dir.route.id}',
            'badge': 'badge-${b.dir.route.id}',
            'bearing': bearing,
            'route': b.dir.route.id,
            'focus': focusTrips.contains('${b.dir.key}@${b.tripStart}'),
          },
          'geometry': {'type': 'Point', 'coordinates': p.lonLat},
        });
      }
      await _c!.setGeoJsonSource('buses', {
        'type': 'FeatureCollection',
        'features': feats,
      });
      await _updatePins(now);
      if (app.active != null && _frame % 6 == 0) _follow(now);
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  Future<void> _updatePins(double now) async {
    final pulse = (_frame % 12) / 12.0;
    Map<String, dynamic> pin(
      Geo g,
      String color,
      String kind, {
      bool halo = true,
    }) => {
      'type': 'Feature',
      'properties': {
        'color': color,
        'kind': kind,
        'halo': halo ? 10 + 22 * pulse : 0,
        'haloOpacity': halo ? 0.35 * (1 - pulse) : 0,
      },
      'geometry': {'type': 'Point', 'coordinates': g.lonLat},
    };
    final feats = <Map<String, dynamic>>[];
    if (app.active != null) {
      final prog = TripProgress(app, app.active!, now);
      if (!prog.onBus) feats.add(pin(prog.position, '#2D6BF0', 'walker'));
      feats.add(pin(app.dest!.pos, '#F2665E', 'dest', halo: false));
    } else {
      feats.add(pin(app.origin.pos, '#2D6BF0', 'origin'));
      if (app.dest != null) feats.add(pin(app.dest!.pos, '#F2665E', 'dest'));
    }
    await _c!.setGeoJsonSource('pins', {
      'type': 'FeatureCollection',
      'features': feats,
    });
  }

  // ---- reacting to state -------------------------------------------------
  void _onApp() {
    if (!_ready) return;
    final j = app.active ?? app.journey;
    if (!identical(j, _shownJourney) || !identical(app.active, _shownActive)) {
      final wasActive = _shownActive != null;
      _shownJourney = j;
      _shownActive = app.active;
      _drawTrip(j);
      if (app.active != null) {
        _follow(app.now, zoomIn: true);
      } else if (j != null && (!identical(app.dest, _shownDest) || wasActive)) {
        _fit(j);
      } else if (j != null) {
        _fit(j);
      }
    }
    if (!identical(app.dest, _shownDest) || app.origin.pos != _shownOrigin) {
      _shownDest = app.dest;
      _shownOrigin = app.origin.pos;
      if (app.dest == null && app.active == null) {
        _fly(
          CameraPosition(
            target: ll(app.origin.pos),
            zoom: 14.4,
            tilt: 55,
            bearing: -18,
          ),
          const Duration(milliseconds: 1200),
        );
      }
    }
  }

  Future<void> _drawTrip(Journey? j) async {
    final c = _c!;
    final dim = j != null;
    await c.setLayerProperties(
      'route-line',
      LineLayerProperties(lineOpacity: dim ? 0.12 : 1.0),
    );
    await c.setLayerProperties(
      'route-case',
      LineLayerProperties(lineOpacity: dim ? 0.3 : 1.0),
    );
    await c.setLayerProperties(
      'stop-dot',
      CircleLayerProperties(
        circleOpacity: dim ? 0.0 : 1.0,
        circleStrokeOpacity: dim ? 0.25 : 1.0,
      ),
    );
    await c.setLayerProperties(
      'stop-label',
      SymbolLayerProperties(textOpacity: dim ? 0.0 : 1.0),
    );
    if (j == null) {
      await c.setGeoJsonSource('trip', _empty);
      return;
    }
    final feats = <Map<String, dynamic>>[];
    for (final l in j.legs) {
      switch (l) {
        case WalkLeg w:
          if (w.meters < 15) continue;
          feats.add(_line([w.from, w.to], {'kind': 'walk'}));
        case RideLeg r:
          final color = hex(r.dir.route.color.toARGB32());
          feats.add(_line(r.shape, {'kind': 'ride', 'color': color}));
          for (var i = r.board; i <= r.alight; i++) {
            feats.add({
              'type': 'Feature',
              'properties': {'kind': 'stop', 'color': color},
              'geometry': {
                'type': 'Point',
                'coordinates': r.dir.stops[i].pos.lonLat,
              },
            });
          }
      }
    }
    await c.setGeoJsonSource('trip', {
      'type': 'FeatureCollection',
      'features': feats,
    });
  }

  Map<String, dynamic> _line(List<Geo> pts, Map<String, dynamic> props) => {
    'type': 'Feature',
    'properties': props,
    'geometry': {
      'type': 'LineString',
      'coordinates': [for (final p in pts) p.lonLat],
    },
  };

  void _fit(Journey j) {
    final pts = <Geo>[app.origin.pos, if (app.dest != null) app.dest!.pos];
    for (final l in j.legs) {
      if (l is RideLeg) pts.addAll(l.shape);
    }
    var s = 90.0, w = 180.0, n = -90.0, e = -180.0;
    for (final p in pts) {
      s = math.min(s, p.lat);
      n = math.max(n, p.lat);
      w = math.min(w, p.lon);
      e = math.max(e, p.lon);
    }
    // Own fit, so it can account for the panels and the tilt.
    final size = MediaQuery.of(context).size;
    const top = 190.0, side = 40.0, tilt = 38.0;
    // read the panel height from state: the widget may not have rebuilt yet
    final bottom = panelInset(app) + 30;
    double mercY(double lat) =>
        math.log(math.tan(math.pi / 4 + lat * math.pi / 360)) * 180 / math.pi;
    final availW = size.width - 2 * side, availH = size.height - top - bottom;
    final dLon = math.max(e - w, 0.004),
        dY = math.max(mercY(n) - mercY(s), 0.004);
    final zx = math.log(availW * 360 / (512 * dLon)) / math.ln2;
    final zy = math.log(availH * 360 / (512 * dY)) / math.ln2;
    final zoom = (math.min(zx, zy) + 0.1).clamp(11.0, 16.5);
    // shift the centre so the trip sits in the free band between the panels
    final degPerPx = 360 / (512 * math.pow(2, zoom));
    final shiftPx = (bottom - top) / 2;
    final cLat =
        (s + n) / 2 -
        shiftPx * degPerPx * math.cos((s + n) / 2 * math.pi / 180);
    _fly(
      CameraPosition(
        target: LatLng(cLat, (w + e) / 2),
        zoom: zoom,
        tilt: tilt,
        bearing: 0,
      ),
      const Duration(milliseconds: 1100),
    );
  }

  void _follow(double now, {bool zoomIn = false}) {
    final j = app.active;
    if (j == null) return;
    final prog = TripProgress(app, j, now);
    _fly(
      CameraPosition(
        target: ll(prog.position),
        zoom: zoomIn ? 15.8 : 15.8,
        tilt: 62,
        bearing: prog.heading,
      ),
      Duration(milliseconds: zoomIn ? 1800 : 1000),
    );
  }

  void recenter() {
    final j = app.active ?? app.journey;
    if (app.active != null) {
      _follow(app.now, zoomIn: true);
    } else if (j != null) {
      _fit(j);
    } else {
      _fly(
        CameraPosition(
          target: ll(app.origin.pos),
          zoom: 14.6,
          tilt: 58,
          bearing: -18,
        ),
        const Duration(milliseconds: 1000),
      );
    }
  }

  /// Ignore map taps right after navigation (see [TapGuard]).
  static void suppressTaps() => TapGuard.hit();

  void _onTap(math.Point<double> pt, LatLng p) {
    if (app.active != null || TapGuard.quiet) return;
    final g = Geo(p.latitude, p.longitude);
    final (stop, d) = app.net.nearestStop(g);
    if (d < 140) {
      app.setDest(Endpoint(stop.name.of(Lang.i.code), stop.pos));
      return;
    }
    String title = tr('pinned');
    var bd = 160.0;
    for (final poi in app.net.pois) {
      final pd = poi.pos.distanceTo(g);
      if (pd < bd) {
        bd = pd;
        title = poi.name;
      }
    }
    app.setDest(Endpoint(title, g));
  }

  @override
  Widget build(BuildContext context) => MapLibreMap(
    styleString: _style,
    initialCameraPosition: CameraPosition(
      target: ll(namanganCenter),
      zoom: 12.3,
      tilt: 30,
      bearing: 0,
    ),
    onMapCreated: (c) => _c = c,
    onStyleLoadedCallback: _onStyle,
    onMapClick: _onTap,
    compassEnabled: false,
    rotateGesturesEnabled: true,
    tiltGesturesEnabled: true,
    attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    attributionButtonMargins: const math.Point(8, 8),
    minMaxZoomPreference: const MinMaxZoomPreference(10.5, 18),
    webPreserveDrawingBuffer: true,
  );
}

/// Height of the bottom panel for the current state (keeps camera fits clear of it).
double panelInset(AppState app) =>
    app.active != null ? 190 : (app.dest != null ? 380 : 230);
