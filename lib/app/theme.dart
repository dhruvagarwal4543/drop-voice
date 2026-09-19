import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DROPVOICE Design System
/// Tactical gaming premium identity.
/// Obsidian surfaces, acid-green accent, Inter + Roboto Mono.
class Dv {
  Dv._();

  // ─── Color Tokens ──────────────────────────────────────────────────────────

  /// Deepest background
  static const Color obsidian = Color(0xFF0A0A0B);

  /// Card base
  static const Color graphite = Color(0xFF111114);

  /// Elevated surface
  static const Color charcoal = Color(0xFF1C1C21);

  /// Border / divider
  static const Color steel = Color(0xFF28282F);

  /// Subtle hover / highlight
  static const Color steelLight = Color(0xFF34343D);

  /// Primary accent — acid green
  static const Color green = Color(0xFF39FF14);

  /// Dimmed accent for backgrounds
  static const Color greenDim = Color(0x1A39FF14);

  /// Secondary accent — cool cyan
  static const Color cyan = Color(0xFF00B4D8);

  /// White text
  static const Color white = Color(0xFFFFFFFF);

  /// Secondary text
  static const Color ash = Color(0xFF9CA3AF);

  /// Muted / disabled
  static const Color slate = Color(0xFF4B5563);

  /// Error / leave / destructive
  static const Color crimson = Color(0xFFEF4444);

  /// Dimmed crimson for error backgrounds
  static const Color crimsonDim = Color(0x1AEF4444);

  // ─── Spacing ───────────────────────────────────────────────────────────────

  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  // ─── Border Radius ─────────────────────────────────────────────────────────

  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r24 = 24;
  static const double r100 = 100; // pill

  // ─── Text Styles ───────────────────────────────────────────────────────────

  // --- Inter ---
  static TextStyle display(
          {Color color = white, double size = 40, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.1);

  static TextStyle headline(
          {Color color = white, double size = 28, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.2);

  static TextStyle title(
          {Color color = white, double size = 18, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.3);

  static TextStyle body(
          {Color color = ash, double size = 15, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.5);

  static TextStyle label(
          {Color color = ash, double size = 12, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3);

  static TextStyle button(
          {Color color = Colors.black, double size = 15, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.5);

  // --- Roboto Mono (telemetry) ---
  static TextStyle mono(
          {Color color = ash, double size = 12, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.robotoMono(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.5);

  static TextStyle monoLarge(
          {Color color = white, double size = 28, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: 4);

  // ─── Shadows ───────────────────────────────────────────────────────────────

  static List<BoxShadow> greenGlow = [
    BoxShadow(color: green.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 0),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  // ─── Borders ───────────────────────────────────────────────────────────────

  static Border get subtleBorder => Border.all(color: steel, width: 1);
  static Border get greenBorder => Border.all(color: green, width: 1.5);
  static Border get dimGreenBorder => Border.all(color: green.withValues(alpha: 0.3), width: 1);
}

/// Complete ThemeData for DROPVOICE.
class DropVoiceTheme {
  DropVoiceTheme._();

  // Legacy aliases — keep so existing code compiles
  static const Color background = Dv.obsidian;
  static const Color surface = Dv.charcoal;
  static const Color accent = Dv.green;
  static const Color textPrimary = Dv.white;
  static const Color textSecondary = Dv.ash;
  static const Color error = Dv.crimson;
  static const Color speaking = Dv.green;
  static const Color muted = Dv.slate;

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Dv.obsidian,
    primaryColor: Dv.green,
    colorScheme: const ColorScheme.dark(
      primary: Dv.green,
      secondary: Dv.cyan,
      surface: Dv.graphite,
      error: Dv.crimson,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Dv.obsidian,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: Dv.title(size: 17, weight: FontWeight.w600),
      iconTheme: const IconThemeData(color: Dv.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Dv.green,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dv.r8)),
        elevation: 0,
        textStyle: Dv.button(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Dv.white,
        side: const BorderSide(color: Dv.steel, width: 1),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dv.r8)),
        textStyle: Dv.button(color: Dv.white),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Dv.graphite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dv.r8),
        borderSide: const BorderSide(color: Dv.steel),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dv.r8),
        borderSide: const BorderSide(color: Dv.steel),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dv.r8),
        borderSide: const BorderSide(color: Dv.green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dv.r8),
        borderSide: const BorderSide(color: Dv.crimson),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dv.r8),
        borderSide: const BorderSide(color: Dv.crimson, width: 1.5),
      ),
      labelStyle: Dv.label(),
      hintStyle: Dv.label(color: Dv.slate),
      errorStyle: Dv.label(color: Dv.crimson),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Dv.charcoal,
      contentTextStyle: Dv.body(color: Dv.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dv.r8),
          side: const BorderSide(color: Dv.steel)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: Dv.steel, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: Dv.ash),
  );
}
