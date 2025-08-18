// Coloca esto en un archivo separado llamado theme_constants.dart
import 'package:flutter/material.dart';

class ThemeConstants {
  static const Color primaryTeal = Color(0xFF038C7F);
  static const Color secondaryOrange = Color(0xFFFF5722);
  static const Color accentGrey = Color(0xFF78909C);
  static const Color backgroundLight = Color(0xFFF5F5F5);

  static final ThemeData appTheme = ThemeData(
    primaryColor: primaryTeal,
    primarySwatch: MaterialColor(primaryTeal.value, {
      50: primaryTeal.withOpacity(0.1),
      100: primaryTeal.withOpacity(0.2),
      200: primaryTeal.withOpacity(0.3),
      300: primaryTeal.withOpacity(0.4),
      400: primaryTeal.withOpacity(0.5),
      500: primaryTeal.withOpacity(0.6),
      600: primaryTeal.withOpacity(0.7),
      700: primaryTeal.withOpacity(0.8),
      800: primaryTeal.withOpacity(0.9),
      900: primaryTeal,
    }),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryTeal,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: secondaryOrange,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 3,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryTeal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryTeal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryTeal, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: secondaryOrange, width: 3),
        ),
      ),
    ),
  );
}
