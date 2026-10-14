import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/network.dart';
import 'widgets.dart';

/// Hand-laid metro-style positions (grid units) and label side per stop.
const schemePos = <String, (double, double, String)>{
  'yuksalish': (1, 2, 'r'),
  'chet_till': (1, 4, 'l'),
  'ulfatlar': (3, 4, 't'),
  'hidoyat': (7, 6, 't'),
  'yangi_nam': (9, 1, 'r'),
  'oromgoh': (9, 3, 'r'),
  'xorazm': (9, 6, 'tr'),
  'bolalar': (12, 6, 'tr'),
  'nanay': (14, 8, 'r'),
  'taxtakoprik': (17, 7, 't'),
  'uychi': (19, 7, 'b'),
  'saxir': (20, 6, 'r'),
  'texnikum4': (20, 4.5, 'r'),
  'gulbog': (20, 3, 'r'),
  'otchopar': (2, 9, 'l'),
  'namdtu_k': (3, 8, 'tl'),
  'afsonalar': (5, 8, 'b'),
  'namdtu_r': (7, 8, 't'),
  'yangibozor': (9, 8, 'r'),
  'avtovokzal': (9, 9.5, 'r'),
  'yashil': (4, 11, 'b'),
  'diyor': (6, 11, 'b'),
  'vokzal': (9, 11, 'bl'),
  'kichkintoy': (11, 11, 't'),
  'hokimlik': (13, 11, 't'),
  'chorsu': (14, 10, 'r'),
  'teatr': (15, 11, 'r'),
  'bobur': (15, 12.5, 'r'),
  'muzey': (12.5, 12.5, 'b'),
  'kardio': (9, 14, 'br'),
  'vil_bolalar': (7, 16, 'l'),
  'aeroport': (1, 14, 't'),
  'toqimachi': (4.5, 14, 't'),
  'sardoba': (14, 14, 't'),
  'namdu': (17, 14, 't'),
  'lola': (19, 15.5, 'r'),
};

const _unit = 52.0;
const _gap = 7.0; // distance between parallel lines
const _canvas = Size(22.5 * _unit, 17.2 * _unit);

class SchemeScreen extends StatefulWidget {
  const SchemeScreen({super.key, required this.app});
  final AppState app;
  @override
  State<SchemeScreen> createState() => _SchemeScreenState();
}

class _SchemeScreenState extends State<SchemeScreen>
    with TickerProviderStateMixin {
  late final _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();
  final _tc = TransformationController();
  late final _Geometry geo = _Geometry(widget.app.net);
  String? _focus;

  @override
  void dispose() {
    _draw.dispose();
    _loop.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _tapStop(Stop s) => showModalBottomSheet(
    context: context,
    builder: (_) => _StopSheet(
      app: widget.app,
      stop: s,
      onPick: (asOrigin) {
        final e = Endpoint(s.name.of(Lang.i.code), s.pos);
        asOrigin ? widget.app.setOrigin(e) : widget.app.setDest(e);
        Navigator.pop(context); // sheet
        Navigator.pop(context); // scheme
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final fit = box.maxWidth / _canvas.width;
                  if (_tc.value.isIdentity()) {
                    // fill the height, centred on the city centre (Chorsu)
                    final sc = math.min(
                      box.maxWidth / (_canvas.width * 0.6),
                      (box.maxHeight - 150) / _canvas.height,
                    );
                    final cx = 11.8 * _unit;
                    final ty =
                        84 + ((box.maxHeight - 150) - _canvas.height * sc) / 2;
                    _tc.value = Matrix4.identity()
                      ..translateByDouble(box.maxWidth / 2 - cx * sc, ty, 0, 1)
                      ..scaleByDouble(sc, sc, 1, 1);
                  }
                  return InteractiveViewer(
                    transformationController: _tc,
                    constrained: false,
                    minScale: fit * 0.8,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(240),
                    child: GestureDetector(
                      onTapUp: (d) {
                        final s = geo.hit(d.localPosition);
                        if (s != null) _tapStop(s);
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_draw, _loop]),
                        builder: (_, _) => CustomPaint(
                          size: _canvas,
                          painter: _SchemePainter(
                            geo,
                            app,
                            Curves.easeInOutCubic.transform(_draw.value),
                            _loop.value,
                            _focus,
                            Lang.i.code,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: softShadow(0.12),
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final r in app.net.routes)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Center(
                                    child: Press(
                                      onTap: () => setState(
                                        () => _focus = _focus == r.id
                                            ? null
                                            : r.id,
                                      ),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        opacity:
                                            _focus == null || _focus == r.id
                                            ? 1
                                            : 0.3,
                                        child: RouteBadge(r, size: 32),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _focus == null
                        ? Text(
                            '№5 · №7 · №9 — ${tr('demo')}',
                            key: const ValueKey('n'),
                            style: T.cap,
                            textAlign: TextAlign.center,
                          )
                        : Container(
                            key: ValueKey(_focus),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: C.night,
                              borderRadius: BorderRadius.circular(R.l),
                            ),
                            child: Row(
                              children: [
                                RouteBadge(app.net.route(_focus!), size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    app.net.route(_focus!).name.of(Lang.i.code),
                                    style: T.h.copyWith(color: Colors.white),
                                    maxLines: 2,
                                  ),
                                ),
                                Text(
                                  '${app.net.route(_focus!).headwayMin} ${tr('min')}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Precomputed octilinear paths with parallel offsets for shared segments.
class _Geometry {
  _Geometry(this.net) {
    // which routes use each stop pair
    final users = <String, List<String>>{};
    for (final r in net.routes) {
      final s = r.dirs[0].stops;
      for (var i = 0; i < s.length - 1; i++) {
        users.putIfAbsent(_key(s[i].id, s[i + 1].id), () => []).add(r.id);
      }
    }
    for (final r in net.routes) {
      final s = r.dirs[0].stops;
      final segs = <List<Offset>>[];
      for (var i = 0; i < s.length - 1; i++) {
        final u = users[_key(s[i].id, s[i + 1].id)]!;
        final k = u.indexOf(r.id) - (u.length - 1) / 2;
        // keep offsets consistent regardless of travel direction
        final flip = s[i].id.compareTo(s[i + 1].id) > 0 ? -1.0 : 1.0;
        segs.add(_offset(_octi(pt(s[i].id), pt(s[i + 1].id)), k * _gap * flip));
      }
      routeSegs[r.id] = segs;
      final path = Path()..moveTo(segs.first.first.dx, segs.first.first.dy);
      for (final seg in segs) {
        for (final p in seg) {
          path.lineTo(p.dx, p.dy);
        }
      }
      paths[r.id] = path;
    }
  }

  final Network net;
  final routeSegs = <String, List<List<Offset>>>{};
  final paths = <String, Path>{};

  static String _key(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  Offset pt(String id) {
    final p = schemePos[id]!;
    return Offset((p.$1 + 0.8) * _unit, (p.$2 + 0.4) * _unit);
  }

  /// Diagonal first, then straight: classic metro-map routing.
  static List<Offset> _octi(Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    if (dx.abs() < 1 || dy.abs() < 1 || (dx.abs() - dy.abs()).abs() < 1) {
      return [a, b];
    }
    final d = math.min(dx.abs(), dy.abs());
    final mid = Offset(a.dx + d * dx.sign, a.dy + d * dy.sign);
    return [a, mid, b];
  }

  static List<Offset> _offset(List<Offset> pts, double o) {
    if (o == 0) return pts;
    final out = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      Offset n(Offset a, Offset b) {
        final v = b - a;
        final l = v.distance;
        return Offset(-v.dy / l, v.dx / l);
      }

      final nn = i == 0
          ? n(pts[0], pts[1])
          : i == pts.length - 1
          ? n(pts[i - 1], pts[i])
          : ((n(pts[i - 1], pts[i]) + n(pts[i], pts[i + 1])) / 2);
      out.add(pts[i] + nn * o);
    }
    return out;
  }

  /// Point along segment [i] of route [r] at fraction [t].
  Offset along(String r, int i, double t) {
    final seg = routeSegs[r]![i];
    var total = 0.0;
    for (var k = 1; k < seg.length; k++) {
      total += (seg[k] - seg[k - 1]).distance;
    }
    var d = total * t;
    for (var k = 1; k < seg.length; k++) {
      final l = (seg[k] - seg[k - 1]).distance;
      if (d <= l) return Offset.lerp(seg[k - 1], seg[k], l == 0 ? 0 : d / l)!;
      d -= l;
    }
    return seg.last;
  }

  Stop? hit(Offset p) {
    Stop? best;
    var bd = 30.0;
    for (final s in net.stops.values) {
      if (!schemePos.containsKey(s.id)) continue;
      final d = (pt(s.id) - p).distance;
      if (d < bd) {
        bd = d;
        best = s;
      }
    }
    return best;
  }
}

class _SchemePainter extends CustomPainter {
  _SchemePainter(
    this.g,
    this.app,
    this.drawT,
    this.loop,
    this.focus,
    this.lang,
  );
  final _Geometry g;
  final AppState app;
  final double drawT, loop;
  final String? focus;
  final String lang;

  @override
  void paint(Canvas c, Size size) {
    // faint grid dots, like squared paper
    final dot = Paint()..color = const Color(0xFFEFF2F6);
    for (var x = 0.0; x < size.width; x += _unit / 2) {
      for (var y = 0.0; y < size.height; y += _unit / 2) {
        c.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
    final routes = app.net.routes;
    // lines (staggered draw-in)
    for (var i = 0; i < routes.length; i++) {
      final r = routes[i];
      final t = ((drawT * (1 + routes.length * 0.15)) - i * 0.15).clamp(
        0.0,
        1.0,
      );
      if (t <= 0) continue;
      final faded = focus != null && focus != r.id;
      final paint = Paint()
        ..color = r.color.withValues(alpha: faded ? 0.15 : 1)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final m in g.paths[r.id]!.computeMetrics()) {
        c.drawPath(m.extractPath(0, m.length * t), paint);
      }
    }
    if (drawT < 0.6) return;
    final pop = ((drawT - 0.6) / 0.4).clamp(0.0, 1.0);

    // buses
    for (final b in app.sched.positions(app.now)) {
      final r = b.dir.route;
      if (focus != null && focus != r.id) continue;
      final i = b.lastStop;
      final d = b.dir;
      if (i >= d.stops.length - 1) continue;
      final f = ((b.meters - d.stopAt[i]) / (d.stopAt[i + 1] - d.stopAt[i]))
          .clamp(0.0, 1.0);
      // schematic segments are stored in direction 0
      final n = d.stops.length - 1;
      final p = d.dir == 0
          ? g.along(r.id, i, f)
          : g.along(r.id, n - 1 - i, 1 - f);
      // a small capsule pointing along the line, so buses never look like stops
      final ahead = d.dir == 0
          ? g.along(r.id, i, (f + 0.02).clamp(0.0, 1.0))
          : g.along(r.id, n - 1 - i, (1 - f - 0.02).clamp(0.0, 1.0));
      var v = ahead - p;
      if (v.distance < 0.01) v = const Offset(1, 0);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(math.atan2(v.dy, v.dx));
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 22 * pop, height: 12 * pop),
        Radius.circular(6 * pop),
      );
      c.drawRRect(
        body.shift(const Offset(0, 2)),
        Paint()
          ..color = const Color(0x40101830)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      c.drawRRect(body.inflate(2.2), Paint()..color = Colors.white);
      c.drawRRect(body, Paint()..color = r.color);
      // windshield at the front
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(5 * pop, -4 * pop, 4 * pop, 8 * pop),
          Radius.circular(2 * pop),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      c.restore();
    }

    // stations
    for (final s in app.net.stops.values) {
      final pos = schemePos[s.id];
      if (pos == null) continue;
      final p = g.pt(s.id);
      final hub = s.routeIds.length > 1;
      final faded = focus != null && !s.routeIds.contains(focus);
      final a = faded ? 0.25 : 1.0;
      if (hub) {
        final rr = (6 + 2.5 * s.routeIds.length) * pop;
        c.drawCircle(p, rr, Paint()..color = Colors.white.withValues(alpha: a));
        c.drawCircle(
          p,
          rr,
          Paint()
            ..color = C.ink.withValues(alpha: a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      } else {
        final col = app.net.route(s.routeIds.first).color;
        c.drawCircle(
          p,
          6 * pop,
          Paint()..color = Colors.white.withValues(alpha: a),
        );
        c.drawCircle(
          p,
          6 * pop,
          Paint()
            ..color = col.withValues(alpha: a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      _label(c, s.name.of(lang), p, pos.$3, hub, a * pop);
    }
    // "you are here" pulse at the nearest stop
    final (near, _) = app.net.nearestStop(app.origin.pos);
    final pn = g.pt(near.id);
    c.drawCircle(
      pn,
      14 + 16 * loop,
      Paint()..color = C.blue.withValues(alpha: 0.35 * (1 - loop) * pop),
    );
  }

  void _label(
    Canvas c,
    String text,
    Offset p,
    String side,
    bool hub,
    double a,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: hub ? 14 : 12.5,
          fontWeight: hub ? FontWeight.w800 : FontWeight.w600,
          color: C.ink.withValues(alpha: a),
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 120);
    const m = 15.0;
    final o = switch (side) {
      'r' => Offset(m, -tp.height / 2),
      'l' => Offset(-m - tp.width, -tp.height / 2),
      't' => Offset(-tp.width / 2, -m - tp.height),
      'b' => Offset(-tp.width / 2, m),
      'tl' => Offset(-m - tp.width, -m - tp.height + 6),
      'bl' => Offset(-m - tp.width, m - 6),
      'br' => Offset(m, m - 6),
      _ => Offset(m, -m - tp.height + 6),
    };
    // white halo for legibility over lines
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        p.dx + o.dx - 3,
        p.dy + o.dy - 1,
        tp.width + 6,
        tp.height + 2,
      ),
      const Radius.circular(4),
    );
    c.drawRRect(bg, Paint()..color = Colors.white.withValues(alpha: 0.85 * a));
    tp.paint(c, p + o);
  }

  @override
  bool shouldRepaint(covariant _SchemePainter o) => true;
}

class _StopSheet extends StatelessWidget {
  const _StopSheet({
    required this.app,
    required this.stop,
    required this.onPick,
  });
  final AppState app;
  final Stop stop;
  final void Function(bool asOrigin) onPick;

  @override
  Widget build(BuildContext context) {
    final lang = Lang.i.code;
    final rows = <(RouteDir, double)>[];
    for (final d in app.net.dirs) {
      final i = d.stops.indexOf(stop);
      if (i < 0 || i == d.stops.length - 1) continue;
      rows.add((d, app.sched.waitAt(d, i, app.now)));
    }
    rows.sort((a, b) => a.$2.compareTo(b.$2));
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.xl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(kindIcon(stop.kind), color: C.ink2),
                const SizedBox(width: 10),
                Expanded(child: Text(stop.name.of(lang), style: T.title)),
              ],
            ),
            const SizedBox(height: 12),
            for (final (d, w) in rows.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    RouteBadge(d.route, size: 28),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: C.ink3,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(d.terminus.name.of(lang), style: T.body),
                    ),
                    Text(
                      fmtMin(w),
                      style: T.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onPick(true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      tr('fromHere'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => onPick(false),
                    style: FilledButton.styleFrom(
                      backgroundColor: C.blue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      tr('toHere'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
