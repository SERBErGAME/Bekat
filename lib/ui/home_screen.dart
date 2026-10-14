import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/network.dart';
import '../data/planner.dart';
import 'map_view.dart';
import 'scheme_screen.dart';
import 'search_screen.dart';
import 'settings_sheet.dart';
import 'trip_progress.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.app});
  final AppState app;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _map = GlobalKey<BekatMapState>();
  Timer? _clock;
  int _sec = 0;

  AppState get app => widget.app;

  /// Web-only ?clean: map without overlays (for poster renders).
  static final _clean = Uri.base.queryParameters.containsKey('clean');

  @override
  void initState() {
    super.initState();
    app.addListener(_rebuild);
    Lang.i.addListener(_rebuild);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _sec++;
      if (_sec % 30 == 0) app.refresh();
      if (mounted) setState(() {});
    });
    app.locate();
  }

  @override
  void dispose() {
    _clock?.cancel();
    app.removeListener(_rebuild);
    Lang.i.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  double get _bottomInset => panelInset(app);

  Future<void> _openSearch({bool forOrigin = false}) async {
    final r = await Navigator.of(context).push<Endpoint>(
      PageRouteBuilder(
        pageBuilder: (_, a, _) => SearchScreen(app: app, forOrigin: forOrigin),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    BekatMapState.suppressTaps();
    if (r == null) return;
    forOrigin ? app.setOrigin(r) : app.setDest(r);
  }

  void _openScheme() => Navigator.of(context)
      .push(
        PageRouteBuilder(
          pageBuilder: (_, a, _) => SchemeScreen(app: app),
          transitionsBuilder: (_, a, _, child) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(
                begin: 0.96,
                end: 1.0,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      )
      .then((_) => BekatMapState.suppressTaps());

  @override
  Widget build(BuildContext context) {
    final trip = app.active;
    final planning = app.dest != null && trip == null;
    final now = app.now;
    final prog = trip == null ? null : TripProgress(app, trip, now);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BekatMap(key: _map, app: app, bottomInset: _bottomInset),
          ),
          if (!_clean) ...[
            // soft fade under the top controls so they read on any map
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        C.bg.withValues(alpha: 0.85),
                        C.bg.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _swap(
                    trip != null
                        ? TripTop(key: const ValueKey('tt'), p: prog!)
                        : planning
                        ? _PlanHeader(
                            key: const ValueKey('ph'),
                            app: app,
                            onFrom: () => _openSearch(forOrigin: true),
                            onTo: _openSearch,
                          )
                        : _SearchPill(
                            key: const ValueKey('sp'),
                            onTap: _openSearch,
                            onMenu: () => showSettings(
                              context,
                              app,
                            ).then((_) => BekatMapState.suppressTaps()),
                          ),
                  ),
                ),
              ),
            ),
            // right-side floating buttons
            Positioned(
              right: 16,
              bottom: _bottomInset + 14,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey((trip != null, planning)),
                  children: [
                    if (trip == null && !planning) ...[
                      RoundButton(
                        icon: Icons.route_rounded,
                        onTap: _openScheme,
                        label: tr('scheme'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    RoundButton(
                      icon: Icons.my_location_rounded,
                      onTap: () => _map.currentState?.recenter(),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 34),
                  child: _swap(
                    trip != null
                        ? _TripBottom(
                            key: const ValueKey('tb'),
                            app: app,
                            p: prog!,
                          )
                        : planning
                        ? _Journeys(key: const ValueKey('jl'), app: app)
                        : _Nearby(
                            key: const ValueKey('nb'),
                            app: app,
                            now: now,
                          ),
                    fromBottom: true,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _swap(Widget child, {bool fromBottom = false}) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (c, a) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0, fromBottom ? 0.25 : -0.25),
          end: Offset.zero,
        ).animate(a),
        child: c,
      ),
    ),
    layoutBuilder: (cur, prev) => Stack(
      alignment: fromBottom ? Alignment.bottomCenter : Alignment.topCenter,
      children: [...prev, ?cur],
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------

class _SearchPill extends StatelessWidget {
  const _SearchPill({super.key, required this.onTap, required this.onMenu});
  final VoidCallback onTap, onMenu;
  @override
  Widget build(BuildContext context) => PointerInterceptor(
    child: Guarded(
      child: Row(
        children: [
          Expanded(
            child: Press(
              onTap: onTap,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: softShadow(),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 26, color: C.ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('whereTo'),
                        style: T.h.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          RoundButton(icon: Icons.tune_rounded, size: 60, onTap: onMenu),
        ],
      ),
    ),
  );
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    super.key,
    required this.app,
    required this.onFrom,
    required this.onTo,
  });
  final AppState app;
  final VoidCallback onFrom, onTo;

  @override
  Widget build(BuildContext context) {
    Widget row(Color dot, String label, String text, VoidCallback tap) => Press(
      onTap: tap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: dot.withValues(alpha: 0.4), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: T.cap),
                  const SizedBox(height: 1),
                  Text(
                    text,
                    style: T.h,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return PointerInterceptor(
      child: Guarded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(R.l),
            boxShadow: softShadow(),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    row(
                      C.blue,
                      tr('from'),
                      app.origin.isMe ? tr('myPlace') : app.origin.title,
                      onFrom,
                    ),
                    const Divider(height: 1, color: C.line, indent: 26),
                    row(C.coral, tr('to'), app.dest!.title, onTo),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: app.clear,
                    icon: const Icon(Icons.close_rounded, color: C.ink2),
                  ),
                  IconButton(
                    onPressed: app.swap,
                    icon: const Icon(Icons.swap_vert_rounded, color: C.ink2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => PointerInterceptor(
    child: Guarded(
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.xl),
          boxShadow: softShadow(0.14),
        ),
        child: child,
      ),
    ),
  );
}

/// Idle state: the closest stop and the next buses — the 80% use case.
class _Nearby extends StatelessWidget {
  const _Nearby({super.key, required this.app, required this.now});
  final AppState app;
  final double now;

  @override
  Widget build(BuildContext context) {
    final (stop, dist) = app.net.nearestStop(app.origin.pos);
    final next = <(RouteDir, double)>[];
    for (final d in app.net.dirs) {
      final i = d.stops.indexOf(stop);
      if (i < 0 || i == d.stops.length - 1) continue;
      next.add((d, app.sched.waitAt(d, i, now)));
    }
    next.sort((a, b) => a.$2.compareTo(b.$2));
    final lang = Lang.i.code;
    return _Card(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: C.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kindIcon(stop.kind), color: C.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('nearby'), style: T.cap),
                    Text(
                      stop.name.of(lang),
                      style: T.h,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text('🚶 ${fmtMin(walkMinutes(dist))}', style: T.sub),
            ],
          ),
          const SizedBox(height: 12),
          for (final (d, w) in next.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  RouteBadge(d.route, size: 28),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: C.ink3,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      d.terminus.name.of(lang),
                      style: T.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _Eta(w),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "4 daq" with a pulsing dot when the bus is about to arrive.
class _Eta extends StatelessWidget {
  const _Eta(this.min);
  final double min;
  @override
  Widget build(BuildContext context) {
    final soon = min < 1.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (soon) const _Pulse(color: C.green),
        if (soon) const SizedBox(width: 6),
        Text(
          soon ? tr('now') : fmtMin(min),
          style: T.body.copyWith(
            fontWeight: FontWeight.w800,
            color: soon ? C.green : C.ink,
          ),
        ),
      ],
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});
  final Color color;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, _) => SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 6 + 8 * _a.value,
            height: 6 + 8 * _a.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.4 * (1 - _a.value)),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Route options. Short: chips, total minutes, one line of detail.
class _Journeys extends StatelessWidget {
  const _Journeys({super.key, required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final js = app.journeys;
    if (js.isEmpty) {
      return _Card(
        child: Row(
          children: [
            const Icon(Icons.wrong_location_rounded, color: C.coral),
            const SizedBox(width: 12),
            Text(tr('noRoute'), style: T.h),
          ],
        ),
      );
    }
    return _Card(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (js.first.approximate)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, size: 18, color: C.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('closest'),
                      style: T.sub.copyWith(color: C.ink),
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < js.length; i++)
            _JourneyTile(
              j: js[i],
              selected: i == app.selected,
              onTap: () => app.select(i),
              onGo: app.start,
              now: app.now,
            ),
        ],
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  const _JourneyTile({
    required this.j,
    required this.selected,
    required this.onTap,
    required this.onGo,
    required this.now,
  });
  final Journey j;
  final bool selected;
  final VoidCallback onTap, onGo;
  final double now;

  @override
  Widget build(BuildContext context) {
    final detail = <String>[
      fmtClock(j.arrive),
      j.walkOnly
          ? tr('walk')
          : (j.transfers == 0
                ? tr('direct')
                : '${j.transfers} ${j.transfers == 1 ? tr('transfer') : tr('transfers')}'),
      if (!j.walkOnly) '🚶 ${fmtMin(j.walkMinutes)}',
    ];
    final wait = j.firstWait - (j.legs.first.end - j.legs.first.start);
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: selected ? C.blueSoft.withValues(alpha: 0.55) : Colors.white,
          borderRadius: BorderRadius.circular(R.l),
          border: Border.all(
            color: selected ? C.blue : C.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: JourneyChips(j)),
                const SizedBox(width: 8),
                Text(fmtMin(j.minutes), style: T.title.copyWith(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(detail.join('  ·  '), style: T.sub)),
                if (!j.walkOnly && wait >= 0)
                  Text(
                    '${tr('busIn')} ${fmtMin(j.firstWait)}',
                    style: T.sub.copyWith(
                      color: C.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: onGo,
                          style: FilledButton.styleFrom(
                            backgroundColor: C.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.navigation_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tr('go'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trip mode

/// The metro-like strip of stops + dark pill with the three numbers that matter.
class TripTop extends StatelessWidget {
  const TripTop({super.key, required this.p});
  final TripProgress p;

  @override
  Widget build(BuildContext context) {
    final r = p.ride;
    final third = p.phase == Phase.riding
        ? (tr('arrive'), fmtClock(p.j.arrive), '')
        : (tr('busArrives'), '${(p.busInMin ?? 0).round()}', tr('min'));
    return PointerInterceptor(
      child: Guarded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r != null)
              _StopStrip(
                ride: r,
                fraction: p.rideFraction,
                color: r.dir.route.color,
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              decoration: BoxDecoration(
                color: C.night,
                borderRadius: BorderRadius.circular(R.xl),
                boxShadow: softShadow(0.25),
              ),
              child: Row(
                children: [
                  _Metric(
                    tr('stopsLeft'),
                    p.stopsLeft.toString().padLeft(2, '0'),
                    '',
                  ),
                  _vr(),
                  _Metric(
                    tr('timeLeft'),
                    '${p.minutesLeft.round()}',
                    tr('min'),
                  ),
                  _vr(),
                  _Metric(
                    third.$1,
                    third.$2,
                    third.$3,
                    accent: p.phase != Phase.riding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vr() => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white12,
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.unit, {this.accent = false});
  final String label, value, unit;
  final bool accent;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(a),
              child: c,
            ),
          ),
          child: Row(
            key: ValueKey(value),
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: T.metric.copyWith(
                  color: accent ? const Color(0xFF7CE0A3) : Colors.white,
                  fontSize: 28,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _StopStrip extends StatelessWidget {
  const _StopStrip({
    required this.ride,
    required this.fraction,
    required this.color,
  });
  final RideLeg ride;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      boxShadow: softShadow(0.1),
    ),
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: fraction),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, f, _) => CustomPaint(
        painter: _StripPainter(ride.stopCount, f, color),
        size: Size.infinite,
      ),
    ),
  );
}

class _StripPainter extends CustomPainter {
  _StripPainter(this.n, this.f, this.color);
  final int n;
  final double f;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final y = s.height / 2;
    final x0 = 6.0, x1 = s.width - 6;
    final xf = x0 + (x1 - x0) * f;
    c.drawLine(
      Offset(x0, y),
      Offset(x1, y),
      Paint()
        ..color = C.line
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      Offset(x0, y),
      Offset(xf, y),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i <= n; i++) {
      final x = x0 + (x1 - x0) * i / n;
      final passed = x <= xf + 0.5;
      final end = i == 0 || i == n;
      c.drawCircle(Offset(x, y), end ? 6 : 4.5, Paint()..color = Colors.white);
      c.drawCircle(
        Offset(x, y),
        end ? 6 : 4.5,
        Paint()
          ..color = i == n ? C.coral : (passed ? color : C.ink)
          ..style = PaintingStyle.stroke
          ..strokeWidth = end ? 3 : 2,
      );
    }
    // the bus
    c.drawCircle(Offset(xf, y), 8, Paint()..color = color);
    c.drawCircle(Offset(xf, y), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _StripPainter o) => o.f != f || o.n != n;
}

class _TripBottom extends StatelessWidget {
  const _TripBottom({super.key, required this.app, required this.p});
  final AppState app;
  final TripProgress p;

  @override
  Widget build(BuildContext context) {
    final lang = Lang.i.code;
    final r = p.ride;
    late final IconData icon;
    late final String big;
    String small = '';
    Widget? badge;
    switch (p.phase) {
      case Phase.arrived:
        icon = Icons.flag_rounded;
        big = tr('arrived');
      case Phase.walking when r == null:
        icon = Icons.directions_walk_rounded;
        big = app.dest!.title;
        small = '${tr('walk')} · ${fmtMin(p.minutesLeft)}';
      case Phase.walking || Phase.waiting:
        icon = Icons.directions_bus_rounded;
        big = r!.from.name.of(lang);
        small =
            '${tr('board')} · ${r.dir.terminus.name.of(lang)} ${tr('toward')}';
        badge = RouteBadge(r.dir.route, size: 44);
      case Phase.riding:
        icon = Icons.logout_rounded;
        big = r!.to.name.of(lang);
        final nr = p.nextRide;
        small = nr != null
            ? '${tr('alight')} → ${tr('change')} №${nr.dir.route.id}'
            : tr('alight');
        badge = RouteBadge(r.dir.route, size: 44);
    }
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          badge ??
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: C.blueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: C.blue),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (small.isNotEmpty)
                  Text(
                    small,
                    style: T.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  big,
                  style: T.title.copyWith(fontSize: 21),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Press(
            onTap: app.endTrip,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tr('end'),
                style: T.body.copyWith(
                  color: C.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
