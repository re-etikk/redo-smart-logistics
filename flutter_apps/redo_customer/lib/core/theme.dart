import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ReDo Design System Color Palette
class ReDoColors {
  // Core Brand Colors
  static const Color primaryYellow = Color(0xFFFFB21A);
  static const Color darkNavy = Color(0xFF111820);
  static const Color warmBg = Color(0xFFFAF6EE);
  static const Color warmBackground = Color(0xFFFAF6EE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF747B82);
  static const Color successGreen = Color(0xFF36A653);
  static const Color danger = Color(0xFFE85B5B);

  // Surface & Borders
  static const Color border = Color(0xFFEAE4D6);
  static const Color cardBorder = Color(0xFFF0EAE0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardMuted = Color(0xFFF7F2E7);
  static const Color pillBg = Color(0xFFF3EEDF);
  static const Color pillBgActive = Color(0xFFFFECC4);

  // Accent & Gradients
  static const Color yellowLight = Color(0xFFFFF7E2);
  static const Color yellowBorder = Color(0xFFFFD573);
  static const Color bannerGradientStart = Color(0xFFFFF6E4);
  static const Color bannerGradientEnd = Color(0xFFFFDF94);
  static const Color greenLight = Color(0xFFE6F7EC);
  static const Color redLight = Color(0xFFFEECEB);

  // Dark Palette (for dark mode support)
  static const Color darkCanvas = Color(0xFF0F1720);
  static const Color darkCard = Color(0xFF18222E);
  static const Color darkBorder = Color(0xFF263342);
  static const Color darkInk = Color(0xFFF2F5F8);
  static const Color darkInkMuted = Color(0xFF8896A6);
}

/// Backwards compatibility alias for existing code
class AppColors {
  static const Color brandYellow = ReDoColors.primaryYellow;
  static const Color brandYellowDark = Color(0xFFE59C0A);
  static const Color slateDark = ReDoColors.darkNavy;
  static const Color slateSoft = Color(0xFF1E293B);
  static const Color canvas = ReDoColors.warmBg;
  static const Color cardBg = ReDoColors.cardBg;
  static const Color border = ReDoColors.border;
  static const Color ink = ReDoColors.darkNavy;
  static const Color inkMuted = ReDoColors.secondaryText;
  static const Color inkFaint = Color(0xFFA1A8B0);
  static const Color success = ReDoColors.successGreen;
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = ReDoColors.danger;

  // Dark palette
  static const Color darkCanvas = ReDoColors.darkCanvas;
  static const Color darkCard = ReDoColors.darkCard;
  static const Color darkBorder = ReDoColors.darkBorder;
  static const Color darkInk = ReDoColors.darkInk;
  static const Color darkInkMuted = ReDoColors.darkInkMuted;
}

/// ReDo Design System Typography
class ReDoTypography {
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: ReDoColors.darkNavy,
        height: 1.15,
        letterSpacing: -0.8,
      );

  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: ReDoColors.darkNavy,
        height: 1.2,
        letterSpacing: -0.6,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: ReDoColors.darkNavy,
        letterSpacing: -0.4,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ReDoColors.darkNavy,
        letterSpacing: -0.2,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: ReDoColors.darkNavy,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: ReDoColors.darkNavy,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: ReDoColors.secondaryText,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ReDoColors.secondaryText,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ReDoColors.darkNavy,
        letterSpacing: -0.2,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ReDoColors.secondaryText,
      );

  static TextStyle get priceDisplay => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: ReDoColors.darkNavy,
        letterSpacing: -0.6,
      );
}

/// ReDo Design System Theme
class ReDoTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ReDoColors.warmBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ReDoColors.primaryYellow,
        onPrimary: ReDoColors.darkNavy,
        secondary: ReDoColors.darkNavy,
        onSecondary: ReDoColors.white,
        error: ReDoColors.danger,
        onError: ReDoColors.white,
        surface: ReDoColors.white,
        onSurface: ReDoColors.darkNavy,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: ReDoColors.warmBg,
        foregroundColor: ReDoColors.darkNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ReDoColors.darkNavy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReDoColors.primaryYellow,
          foregroundColor: ReDoColors.darkNavy,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReDoColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ReDoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ReDoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ReDoColors.primaryYellow, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: ReDoColors.secondaryText,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: ReDoColors.secondaryText.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: ReDoColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ReDoColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReDoColors.darkNavy,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ReDoColors.darkCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ReDoColors.primaryYellow,
        onPrimary: ReDoColors.darkNavy,
        secondary: ReDoColors.primaryYellow,
        onSecondary: ReDoColors.darkNavy,
        error: ReDoColors.danger,
        onError: ReDoColors.white,
        surface: ReDoColors.darkCard,
        onSurface: ReDoColors.darkInk,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: ReDoColors.darkCard,
        foregroundColor: ReDoColors.darkInk,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ReDoColors.darkInk,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReDoColors.primaryYellow,
          foregroundColor: ReDoColors.darkNavy,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: ReDoColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ReDoColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ReDoColors.primaryYellow,
        contentTextStyle: GoogleFonts.inter(
          color: ReDoColors.darkNavy,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for AppTheme
class AppTheme {
  static ThemeData get lightTheme => ReDoTheme.lightTheme;
  static ThemeData get darkTheme => ReDoTheme.darkTheme;
}
