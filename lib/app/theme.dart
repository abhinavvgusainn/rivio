import 'package:flutter/material.dart';

/// Central place for Rivio's visual language:
/// light/off-white background, green accent, charcoal text,
/// rounded cards, minimal shadows.
class RivioColors {
  static const background = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2E7D5B);
  static const primaryContainer = Color(0xFFDCEEE3);
  static const textPrimary = Color(0xFF262624);
  static const textSecondary = Color(0xFF7A7A76);
  static const border = Color(0xFFE6E6E1);

  // Activity heatmap intensity levels, lightest to darkest.
  static const heatmapLevels = [
    Color(0xFFEBEDE9),
    Color(0xFFB9E4C9),
    Color(0xFF7FCB9D),
    Color(0xFF44A873),
    Color(0xFF2E7D5B),
  ];
}

class RivioTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RivioColors.primary,
        brightness: Brightness.light,
        primary: RivioColors.primary,
        surface: RivioColors.surface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: RivioColors.background,
      textTheme: base.textTheme.apply(
        bodyColor: RivioColors.textPrimary,
        displayColor: RivioColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RivioColors.background,
        foregroundColor: RivioColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: RivioColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: RivioColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: RivioColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: RivioColors.surface,
        indicatorColor: RivioColors.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? RivioColors.primary : RivioColors.textSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RivioColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RivioColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RivioColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RivioColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RivioColors.primary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: RivioColors.border,
        thickness: 1,
      ),
    );
  }
}
