import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccentPalette {
  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const AccentPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
}

class AppTheme {
  static const List<AccentPalette> palettes = [
    AccentPalette(
      name: 'Indigo Royal',
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF7C3AED),
      tertiary: Color(0xFF6366F1),
    ),
    AccentPalette(
      name: 'Emerald Mint',
      primary: Color(0xFF059669),
      secondary: Color(0xFF0D9488),
      tertiary: Color(0xFF10B981),
    ),
    AccentPalette(
      name: 'Sunset Rose',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFEA580C),
      tertiary: Color(0xFFF43F5E),
    ),
    AccentPalette(
      name: 'Ocean Cyan',
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF0891B2),
      tertiary: Color(0xFF38BDF8),
    ),
    AccentPalette(
      name: 'Electric Purple',
      primary: Color(0xFF9333EA),
      secondary: Color(0xFFC026D3),
      tertiary: Color(0xFFA855F7),
    ),
  ];

  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  static const Map<String, Color> categoryColors = {
    'Work': Color(0xFF3B82F6),
    'Personal': Color(0xFF8B5CF6),
    'Study': Color(0xFFEC4899),
    'Health': Color(0xFF10B981),
    'Finance': Color(0xFFF59E0B),
    'General': Color(0xFF6B7280),
  };

  static const Map<String, IconData> categoryIcons = {
    'Work': Icons.work_rounded,
    'Personal': Icons.person_rounded,
    'Study': Icons.menu_book_rounded,
    'Health': Icons.favorite_rounded,
    'Finance': Icons.account_balance_wallet_rounded,
    'General': Icons.format_list_bulleted_rounded,
  };

  static ThemeData lightTheme(int paletteIndex) {
    final palette = palettes[paletteIndex.clamp(0, palettes.length - 1)];
    final primary = palette.primary;

    final colorScheme = ColorScheme.light(
      primary: primary,
      secondary: palette.secondary,
      tertiary: palette.tertiary,
      surface: const Color(0xFFF8FAFC),
      error: const Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData darkTheme(int paletteIndex) {
    final palette = palettes[paletteIndex.clamp(0, palettes.length - 1)];
    final primary = palette.primary;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: palette.secondary,
      tertiary: palette.tertiary,
      surface: const Color(0xFF1E293B),
      error: const Color(0xFFF87171),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFF8FAFC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF8FAFC),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
