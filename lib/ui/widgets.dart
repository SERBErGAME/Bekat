import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/network.dart';
import '../data/planner.dart';

/// On the web, a tap on a Flutter overlay can also reach the map underneath.
/// Overlays call [TapGuard.hit] on pointer-down; the map ignores taps that
/// arrive shortly after.
class TapGuard {
  static DateTime _quietUntil = DateTime(2000);
  static void hit([Object? _]) =>
      _quietUntil = DateTime.now().add(const Duration(milliseconds: 700));
  static bool get quiet => DateTime.now().isBefore(_quietUntil);
}

/// Wrap any overlay: marks pointer-downs inside it with [TapGuard].
class Guarded extends StatelessWidget {
  const Guarded({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: TapGuard.hit,
    onPointerUp: TapGuard.hit,
    behavior: HitTestBehavior.translucent,
    child: child,
  );
}

/// Metro-style route badge: rounded square with the route number.
class RouteBadge extends StatelessWidget {
  const RouteBadge(this.route, {super.key, this.size = 30});
  final BusRoute route;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: route.color,
      borderRadius: BorderRadius.circular(size * 0.32),
      boxShadow: [
        BoxShadow(
          color: route.color.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      route.id,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.5,
        height: 1,
      ),
    ),
  );
}

class WalkBadge extends StatelessWidget {
  const WalkBadge(this.minutes, {super.key});
  final double minutes;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.directions_walk_rounded, size: 18, color: C.ink2),
      Text(
        '${minutes.round()}',
        style: T.cap.copyWith(color: C.ink2, fontSize: 12.5),
      ),
    ],
  );
}

/// "🚶4 › [3] › [1] › 🚶2" — the whole trip in one glance.
class JourneyChips extends StatelessWidget {
  const JourneyChips(this.j, {super.key, this.size = 28});
  final Journey j;
  final double size;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final l in j.legs) {
      final w = switch (l) {
        RideLeg r => RouteBadge(r.dir.route, size: size),
        WalkLeg w when w.end - w.start >= 1 || j.walkOnly => WalkBadge(
          w.end - w.start,
        ),
        _ => null,
      };
      if (w == null) continue;
      if (items.isNotEmpty) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Icon(Icons.chevron_right_rounded, size: 18, color: C.ink3),
          ),
        );
      }
      items.add(w);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: items,
    );
  }
}

/// Scales down slightly while pressed — every tappable thing feels physical.
class Press extends StatefulWidget {
  const Press({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    this.onTap,
    this.dark = false,
    this.size = 48,
    this.label,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;
  final double size;
  final String? label;
  @override
  Widget build(BuildContext context) => PointerInterceptor(
    child: Guarded(
      child: Press(
        onTap: onTap,
        child: Container(
          height: size,
          constraints: BoxConstraints(minWidth: size),
          padding: label == null
              ? null
              : const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: dark ? C.night : Colors.white,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: softShadow(0.12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: dark ? Colors.white : C.ink, size: 22),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label!,
                  style: T.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : C.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

IconData kindIcon(String kind) => switch (kind) {
  'bazaar' => Icons.storefront_rounded,
  'university' => Icons.school_rounded,
  'park' => Icons.park_rounded,
  'hospital' => Icons.local_hospital_rounded,
  'rail' => Icons.train_rounded,
  'airport' => Icons.flight_rounded,
  'mall' => Icons.shopping_bag_rounded,
  'museum' => Icons.museum_rounded,
  'theatre' => Icons.theater_comedy_rounded,
  'gov' => Icons.account_balance_rounded,
  'station' || 'terminal' => Icons.directions_bus_rounded,
  'landmark' => Icons.mosque_rounded,
  _ => Icons.place_rounded,
};

// ---------------------------------------------------------------------------
// Cartoon isometric bus (splash, empty states).

class IsoBus extends StatelessWidget {
  const IsoBus({
    super.key,
    this.color = C.green,
    this.width = 220,
    this.number = '3',
  });
  final Color color;
  final double width;
  final String number;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, width * 0.9),
    painter: _IsoBusPainter(color, number),
  );
}

class _IsoBusPainter extends CustomPainter {
  _IsoBusPainter(this.color, this.number);
  final Color color;
  final String number;

  @override
  void paint(Canvas canvas, Size size) {
    const L = 11.0, W = 3.4, H = 3.6;
    final s = size.width / ((L + W) * math.cos(math.pi / 6) + 0.6);
    final ox = W * math.cos(math.pi / 6) * s + 0.3 * s, oy = (H + 0.6) * s;
    Offset iso(double x, double y, double z) => Offset(
      ox + (x - y) * math.cos(math.pi / 6) * s,
      oy + (x + y) * math.sin(math.pi / 6) * s - z * s,
    );
    Path poly(List<List<double>> pts) {
      final p = Path()
        ..moveTo(
          iso(pts[0][0], pts[0][1], pts[0][2]).dx,
          iso(pts[0][0], pts[0][1], pts[0][2]).dy,
        );
      for (final q in pts.skip(1)) {
        final o = iso(q[0], q[1], q[2]);
        p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    final hsl = HSLColor.fromColor(color);
    final side = color;
    final front = hsl
        .withLightness((hsl.lightness - 0.10).clamp(0, 1))
        .toColor();
    final roof = hsl
        .withLightness((hsl.lightness + 0.18).clamp(0, 1))
        .toColor();
    const glass = Color(0xFF2A3446);
    const glassHi = Color(0xFF51617C);

    // shadow
    canvas.drawPath(
      poly([
        [-.4, -.2, 0],
        [L + .6, -.2, 0],
        [L + .6, W + .7, 0],
        [-.4, W + .7, 0],
      ]),
      Paint()
        ..color = const Color(0x22101830)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // body
    canvas.drawPath(
      poly([
        [0, W, 0],
        [L, W, 0],
        [L, W, H],
        [0, W, H],
      ]),
      Paint()..color = side,
    );
    canvas.drawPath(
      poly([
        [L, 0, 0],
        [L, W, 0],
        [L, W, H],
        [L, 0, H],
      ]),
      Paint()..color = front,
    );
    canvas.drawPath(
      poly([
        [0, 0, H],
        [L, 0, H],
        [L, W, H],
        [0, W, H],
      ]),
      Paint()..color = roof,
    );
    // white skirt stripe
    canvas.drawPath(
      poly([
        [0, W, 0.35],
        [L, W, 0.35],
        [L, W, 0.9],
        [0, W, 0.9],
      ]),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      poly([
        [L, 0, 0.35],
        [L, W, 0.35],
        [L, W, 0.9],
        [L, 0, 0.9],
      ]),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    // side windows
    for (var i = 0; i < 4; i++) {
      final x0 = 0.6 + i * 2.15, x1 = x0 + 1.8;
      canvas.drawPath(
        poly([
          [x0, W, 1.7],
          [x1, W, 1.7],
          [x1, W, 3.1],
          [x0, W, 3.1],
        ]),
        Paint()..color = glass,
      );
      canvas.drawPath(
        poly([
          [x0, W, 2.6],
          [x0 + 0.5, W, 3.1],
          [x0 + 0.9, W, 3.1],
          [x0, W, 2.2],
        ]),
        Paint()..color = glassHi,
      );
    }
    // door
    canvas.drawPath(
      poly([
        [9.3, W, 0.95],
        [10.4, W, 0.95],
        [10.4, W, 3.1],
        [9.3, W, 3.1],
      ]),
      Paint()..color = glass,
    );
    // windshield
    canvas.drawPath(
      poly([
        [L, 0.3, 1.6],
        [L, W - 0.3, 1.6],
        [L, W - 0.3, 3.2],
        [L, 0.3, 3.2],
      ]),
      Paint()..color = glass,
    );
    canvas.drawPath(
      poly([
        [L, 0.5, 2.6],
        [L, 1.3, 3.2],
        [L, 1.7, 3.2],
        [L, 0.5, 2.2],
      ]),
      Paint()..color = glassHi,
    );
    // headlights
    for (final y in [0.6, W - 0.6]) {
      final c = iso(L, y, 0.65);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: s * 0.7, height: s * 0.45),
        Paint()..color = const Color(0xFFFFF4C2),
      );
    }
    // roof AC unit + number plate
    canvas.drawPath(
      poly([
        [3, 0.8, H],
        [7, 0.8, H],
        [7, W - 0.8, H],
        [3, W - 0.8, H],
      ]),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      poly([
        [3, W - 0.8, H],
        [7, W - 0.8, H],
        [7, W - 0.8, H + 0.35],
        [3, W - 0.8, H + 0.35],
      ]),
      Paint()..color = const Color(0xFFDCE2EA),
    );
    // route number sign on the front
    final sign = iso(L, W / 2, 3.45);
    final tp = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          color: Colors.white,
          fontSize: s * 0.9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: sign,
          width: tp.width + s * 0.8,
          height: s * 1.0,
        ),
        Radius.circular(s * 0.25),
      ),
      Paint()..color = const Color(0xFF15171C),
    );
    tp.paint(canvas, sign - Offset(tp.width / 2, tp.height / 2));
    // wheels
    for (final x in [2.2, L - 2.4]) {
      final c = iso(x, W, 0.15);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: s * 1.75, height: s * 1.95),
        Paint()..color = const Color(0xFF1E2229),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: s * 0.8, height: s * 0.9),
        Paint()..color = const Color(0xFFB7BFCC),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IsoBusPainter old) =>
      old.color != color || old.number != number;
}

/// Top-down bus sprite for the map (rotated by heading, lies on the 3D ground).
Future<Uint8List> busSprite(Color color) async {
  const w = 44.0, h = 96.0, pad = 10.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(pad, pad, w, h),
    const Radius.circular(12),
  );
  c.drawRRect(
    body.shift(const Offset(0, 4)),
    Paint()
      ..color = const Color(0x44101830)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  c.drawRRect(body, Paint()..color = color);
  c.drawRRect(
    body.deflate(1.5),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  // windshield at the front (top of sprite = heading)
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(pad + 5, pad + 4, w - 10, 12),
      const Radius.circular(5),
    ),
    Paint()..color = const Color(0xFF26303F),
  );
  // roof units
  final roof = HSLColor.fromColor(color);
  final light = roof
      .withLightness((roof.lightness + 0.2).clamp(0, 1))
      .toColor();
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(pad + 8, pad + 26, w - 16, 26),
      const Radius.circular(5),
    ),
    Paint()..color = light,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(pad + 8, pad + 60, w - 16, 26),
      const Radius.circular(5),
    ),
    Paint()..color = light,
  );
  final pic = rec.endRecording();
  final img = await pic.toImage((w + pad * 2).toInt(), (h + pad * 2).toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// Little white disc with the route number, shown above each bus.
Future<Uint8List> busBadge(BusRoute r) async {
  const d = 46.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawCircle(
    const Offset(d / 2 + 4, d / 2 + 5),
    d / 2,
    Paint()
      ..color = const Color(0x33101830)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  c.drawCircle(
    const Offset(d / 2 + 4, d / 2 + 3),
    d / 2,
    Paint()..color = Colors.white,
  );
  c.drawCircle(
    const Offset(d / 2 + 4, d / 2 + 3),
    d / 2 - 4,
    Paint()..color = r.color,
  );
  final tp = TextPainter(
    text: TextSpan(
      text: r.id,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        fontFamily: 'Inter',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, Offset(d / 2 + 4 - tp.width / 2, d / 2 + 3 - tp.height / 2));
  final img = await rec.endRecording().toImage(
    (d + 8).toInt(),
    (d + 10).toInt(),
  );
  return (await img.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
}

String stopsWord(int n) => '$n ${tr('stops')}';
