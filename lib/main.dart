import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'data/network.dart';
import 'ui/home_screen.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Lang.i.load();
  runApp(const BekatApp());
}

class BekatApp extends StatefulWidget {
  const BekatApp({super.key});
  @override
  State<BekatApp> createState() => _BekatAppState();
}

class _BekatAppState extends State<BekatApp> {
  AppState? _app;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Lang.i.addListener(() => setState(() {}));
    () async {
      final net = await Network.load();
      final app = AppState(net);
      await app.loadPrefs();
      app.addListener(() => setState(() {}));
      setState(() => _app = app);
    }();
    Future.delayed(
      const Duration(milliseconds: 2300),
      () => setState(() => _splashDone = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    return MaterialApp(
      title: 'Bekat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(app?.bigText == true ? 1.22 : 1.0),
        ),
        child: child!,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: app == null || !_splashDone
            ? const Splash()
            : HomeScreen(app: app),
      ),
    );
  }
}

/// A cartoon bus drives in, the name appears. ~2 s.
class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: C.bg,
    body: AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final drive = Curves.easeOutCubic.transform(
          (_a.value / 0.7).clamp(0, 1),
        );
        final text = Curves.easeOut.transform(
          ((_a.value - 0.45) / 0.55).clamp(0, 1),
        );
        final w = MediaQuery.of(context).size.width;
        return Stack(
          children: [
            // road
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.52,
              child: Container(height: 2, color: C.line),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(
                      (1 - drive) * -w * 0.9,
                      (1 - drive) * w * 0.25,
                    ),
                    child: Transform.rotate(
                      angle: (1 - drive) * 0.05,
                      child: const IsoBus(
                        width: 230,
                        color: C.green,
                        number: '3',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: text,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - text)),
                      child: Column(
                        children: [
                          const Text(
                            'Bekat',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              color: C.ink,
                            ),
                          ),
                          Text(
                            tr('tagline'),
                            style: T.sub.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
