import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ReDo Partner Design System Colors
class ReDoPartnerColors {
  // Brand palette from specifications:
  static const Color brandYellow = Color(0xFFFFB21A); // ReDo Yellow #FFB21A
  static const Color brandYellowDark = Color(0xFFE5A015);
  static const Color darkNavy = Color(0xFF111820);    // Dark Navy #111820
  static const Color warmBackground = Color(0xFFFAF6EE); // Warm Background #FAF6EE
  static const Color white = Color(0xFFFFFFFF);       // White #FFFFFF
  static const Color secondary = Color(0xFF747B82);   // Secondary #747B82
  static const Color success = Color(0xFF36A653);     // Success #36A653
  static const Color danger = Color(0xFFE85B5B);      // Danger #E85B5B

  // Additional operational UI colors
  static const Color border = Color(0xFFEAE3D2);
  static const Color borderMuted = Color(0xFFE2E8F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color amberCard = Color(0xFFFFF7DC);
  static const Color amberCardEnd = Color(0xFFFEE8AC);
  static const Color amberCardBorder = Color(0xFFFDE68A);
  static const Color lightGreen = Color(0xFFE8F7ED);
  static const Color lightRed = Color(0xFFFDE8E8);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color textDark = Color(0xFF111820);
  static const Color textMuted = Color(0xFF747B82);
  static const Color textFaint = Color(0xFF94A3B8);

  // Dark palette variants
  static const Color darkCanvas = Color(0xFF0D131A);
  static const Color darkCard = Color(0xFF161F28);
  static const Color darkBorder = Color(0xFF26323E);
  static const Color darkInk = Color(0xFFF1F5F9);
  static const Color darkInkMuted = Color(0xFF94A3B8);
}

/// Backwards compatibility alias for existing code
class AppColors {
  static const Color brandYellow = ReDoPartnerColors.brandYellow;
  static const Color brandYellowDark = ReDoPartnerColors.brandYellowDark;
  static const Color slateDark = ReDoPartnerColors.darkNavy;
  static const Color slateSoft = Color(0xFF1E293B);
  static const Color canvas = ReDoPartnerColors.warmBackground;
  static const Color cardBg = ReDoPartnerColors.cardBg;
  static const Color border = ReDoPartnerColors.border;
  static const Color ink = ReDoPartnerColors.textDark;
  static const Color inkMuted = ReDoPartnerColors.secondary;
  static const Color inkFaint = ReDoPartnerColors.textFaint;
  static const Color success = ReDoPartnerColors.success;
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = ReDoPartnerColors.danger;

  static const Color darkCanvas = ReDoPartnerColors.darkCanvas;
  static const Color darkCard = ReDoPartnerColors.darkCard;
  static const Color darkBorder = ReDoPartnerColors.darkBorder;
  static const Color darkInk = ReDoPartnerColors.darkInk;
  static const Color darkInkMuted = ReDoPartnerColors.darkInkMuted;
}

/// High-legibility typography optimized for vehicle operators and drivers
class ReDoTypography {
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: ReDoPartnerColors.darkNavy,
    letterSpacing: -0.5,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: ReDoPartnerColors.darkNavy,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ReDoPartnerColors.darkNavy,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ReDoPartnerColors.darkNavy,
  );

  static TextStyle get bodyMuted => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: ReDoPartnerColors.secondary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: ReDoPartnerColors.secondary,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: ReDoPartnerColors.darkNavy,
    letterSpacing: 0.2,
  );

  static TextStyle get priceLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: ReDoPartnerColors.darkNavy,
    letterSpacing: -0.5,
  );
}

class ReDoPartnerTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ReDoPartnerColors.warmBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: ReDoPartnerColors.brandYellow,
        primary: ReDoPartnerColors.darkNavy,
        secondary: ReDoPartnerColors.brandYellow,
        surface: ReDoPartnerColors.cardBg,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: ReDoPartnerColors.cardBg,
        foregroundColor: ReDoPartnerColors.darkNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ReDoPartnerColors.darkNavy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReDoPartnerColors.brandYellow,
          foregroundColor: ReDoPartnerColors.darkNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReDoPartnerColors.cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReDoPartnerColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReDoPartnerColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReDoPartnerColors.brandYellow, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: ReDoPartnerColors.secondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: ReDoPartnerColors.textFaint, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: ReDoPartnerColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ReDoPartnerColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ReDoPartnerColors.cardBg,
        indicatorColor: ReDoPartnerColors.brandYellow,
        elevation: 8,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: GoogleFonts.inter().fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ReDoPartnerColors.secondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReDoPartnerColors.darkNavy,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ReDoPartnerColors.darkCanvas,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: ReDoPartnerColors.brandYellow,
        primary: ReDoPartnerColors.brandYellow,
        secondary: ReDoPartnerColors.brandYellow,
        surface: ReDoPartnerColors.darkCard,
        onSurface: ReDoPartnerColors.darkInk,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: ReDoPartnerColors.darkCard,
        foregroundColor: ReDoPartnerColors.darkInk,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ReDoPartnerColors.darkInk,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReDoPartnerColors.brandYellow,
          foregroundColor: ReDoPartnerColors.darkNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReDoPartnerColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReDoPartnerColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReDoPartnerColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReDoPartnerColors.brandYellow, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: ReDoPartnerColors.darkInkMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: ReDoPartnerColors.darkInkMuted, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: ReDoPartnerColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ReDoPartnerColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ReDoPartnerColors.darkCard,
        indicatorColor: ReDoPartnerColors.brandYellow,
        elevation: 8,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: GoogleFonts.inter().fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ReDoPartnerColors.darkInkMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReDoPartnerColors.darkCard,
        contentTextStyle: GoogleFonts.inter(color: ReDoPartnerColors.darkInk, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

typedef AppTheme = ReDoPartnerTheme;
