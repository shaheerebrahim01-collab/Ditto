import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Ditto's design system: cream/beige surfaces, warm brown as the primary
// action color, gold as the accent. Fraunces for headings, Plus Jakarta Sans
// for everything else.
class DittoColors {
  static const cream = Color(0xFFFBF7F1);
  static const brown = Color(0xFF8A6244);
  static const gold = Color(0xFFC7A363);
  static const ink = Color(0xFF2B2320);
  static const mutedInk = Color(0xFF7A6F68);
}

class DittoTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DittoColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DittoColors.brown,
        brightness: Brightness.light,
        primary: DittoColors.brown,
        secondary: DittoColors.gold,
        surface: DittoColors.cream,
      ),
    );

    const headingFont = GoogleFonts.fraunces;
    const bodyFont = GoogleFonts.plusJakartaSans;

    // Plus Jakarta Sans everywhere, then Fraunces overrides the heading styles.
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: DittoColors.ink, displayColor: DittoColors.ink)
        .copyWith(
          displayLarge: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          displayMedium: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          displaySmall: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          headlineLarge: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          headlineMedium: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          headlineSmall: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          titleLarge: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          titleMedium: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
          titleSmall: headingFont(fontWeight: FontWeight.w600, color: DittoColors.ink),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: DittoColors.cream,
        foregroundColor: DittoColors.ink,
        elevation: 0,
        titleTextStyle: headingFont(fontSize: 20, fontWeight: FontWeight.w600, color: DittoColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DittoColors.brown,
          foregroundColor: DittoColors.cream,
          textStyle: bodyFont(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DittoColors.brown,
          side: const BorderSide(color: DittoColors.brown),
          textStyle: bodyFont(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DittoColors.brown,
          textStyle: bodyFont(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: DittoColors.brown,
        labelStyle: bodyFont(color: DittoColors.ink, fontWeight: FontWeight.w500),
        secondaryLabelStyle: bodyFont(color: DittoColors.cream, fontWeight: FontWeight.w500),
        side: BorderSide(color: DittoColors.brown.withValues(alpha: 0.25)),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: bodyFont(color: DittoColors.mutedInk),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DittoColors.cream,
        indicatorColor: DittoColors.gold.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(bodyFont(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
