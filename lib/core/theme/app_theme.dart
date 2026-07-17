import 'package:flutter/material.dart';

/// Paleta de marca de SafeWalk.
class AppColors {
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF22C55E);
  static const Color white = Color(0xFFFFFFFF);

  // Tonos derivados para fondos y superficies, manteniendo la paleta base.
  static const Color blueLight = Color(0xFFEFF4FF);
  static const Color greenLight = Color(0xFFEAFBF0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // El rojo se reserva EXCLUSIVAMENTE para contextos de emergencia real
  // (boton SOS, alertas activas). Es una decision de UX de seguridad:
  // el rojo es el color universal de peligro y no debe diluirse
  // usandolo en elementos de navegacion normales.
  static const Color emergencyRed = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.green,
      surface: AppColors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.blue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.blue,
      ),

      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textMuted),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.white,
      ),
    );
  }
}