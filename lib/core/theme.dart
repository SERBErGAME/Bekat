import 'package:flutter/material.dart';

/// Bekat design tokens. Light, calm, lots of air: the map and the coloured
/// bus lines are the only loud things on screen.
class C {
  static const bg = Color(0xFFEEF1F6);
  static const surface = Colors.white;
  static const muted = Color(0xFFF3F5F9);
  static const line = Color(0xFFE3E7EE);
  static const ink = Color(0xFF15171C);
  static const ink2 = Color(0xFF5B6270);
  static const ink3 = Color(0xFF9AA1AE);
  static const night = Color(0xFF1E2024); // the dark info pill
  static const blue = Color(0xFF2D6BF0);
  static const blueSoft = Color(0xFFE6EEFE);
  static const coral = Color(0xFFF2665E);
  static const green = Color(0xFF22A55B);
  static const amber = Color(0xFFF5A524);
}

class R {
  static const s = 12.0, m = 18.0, l = 26.0, xl = 34.0;
}

List<BoxShadow> softShadow([double o = 0.10]) => [
  BoxShadow(
    color: const Color(0xFF1B2440).withValues(alpha: o),
    blurRadius: 30,
    offset: const Offset(0, 12),
  ),
  BoxShadow(
    color: const Color(0xFF1B2440).withValues(alpha: o * 0.4),
    blurRadius: 6,
    offset: const Offset(0, 2),
  ),
];

ThemeData buildTheme({bool bigText = false}) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.blue,
      primary: C.blue,
      surface: C.surface,
    ),
    scaffoldBackgroundColor: C.bg,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

class T {
  static const display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1.0,
    color: C.ink,
  );
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: C.ink,
  );
  static const h = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: C.ink,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: C.ink,
  );
  static const sub = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: C.ink2,
  );
  static const cap = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: C.ink3,
  );
  static const metric = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1,
  );
}
