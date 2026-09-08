import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.accentRed,
    );

    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.bgLight,
      cardColor: AppColors.surface,
      borderColor: AppColors.border,
      inputFillColor: AppColors.white,
      appBarBackground: AppColors.bgLight,
      navBackground: AppColors.white,
      primarySoft: AppColors.primarySoft,
    );
  }

  static ThemeData get darkTheme {
    const scaffoldBackground = Color(0xFF120D1A);
    const surface = Color(0xFF1D1628);
    const surfaceContainer = Color(0xFF251C32);
    const border = Color(0xFF44384F);
    const onSurface = Color(0xFFF7F1FF);
    const onSurfaceVariant = Color(0xFFC9BED5);
    const primary = Color(0xFFA78BFA);
    const primaryContainer = Color(0xFF3B2560);

    const colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF25103F),
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFEADFFF),
      secondary: Color(0xFFC4B5FD),
      onSecondary: Color(0xFF2E1A49),
      secondaryContainer: Color(0xFF3A2B4C),
      onSecondaryContainer: Color(0xFFEADFFF),
      tertiary: Color(0xFFE879F9),
      onTertiary: Color(0xFF3A0B3E),
      error: Color(0xFFFB7185),
      onError: Color(0xFF3F0711),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: border,
      outlineVariant: Color(0xFF352B40),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: Color(0xFF302839),
      inversePrimary: AppColors.primaryDark,
    );

    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackground: scaffoldBackground,
      cardColor: surface,
      borderColor: border,
      inputFillColor: surfaceContainer,
      appBarBackground: scaffoldBackground,
      navBackground: surface,
      primarySoft: primaryContainer,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color borderColor,
    required Color inputFillColor,
    required Color appBarBackground,
    required Color navBackground,
    required Color primarySoft,
  }) {
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      canvasColor: cardColor,
      dividerColor: borderColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 14, color: onSurface),
        bodyMedium: TextStyle(fontSize: 13, color: onSurfaceVariant),
        bodySmall: TextStyle(color: onSurfaceVariant),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        labelStyle: TextStyle(color: onSurfaceVariant),
        hintStyle: TextStyle(color: onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.6,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        indicatorColor: primarySoft,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colorScheme.primary,
        headerForegroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF30243F)
            : const Color(0xFF2F2438),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return borderColor;
        }),
      ),
    );
  }
}
