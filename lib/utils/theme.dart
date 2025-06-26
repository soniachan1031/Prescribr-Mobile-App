import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define primary and additional colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color cardGreen = Color(0xFFE8F5E9);
  static const Color lightBackgroundGrey = Color(0xFFF8F8F8);
  static const Color lightCardGreen = Color(0xFFF1F8E9);
  static const Color lightBackgroundGreen = Color(0xFFE8F5E9);
  static const Color iconColor = Color(0xFF4CAF50);
  static const Color lightIconColor = Color(0xFFC8E6C9);
  static const Color mediumLightIconColor = Color(0xFF81C784);
  static const Color inputFillColor = Color(0xFFF5F5F5);
  static const Color blackColor = Color(0xFF000000);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color redColor = Color(0xFFE57373);
  static const Color greyColor = Color(0xFF9E9E9E);
  static const Color mediumGrey = Color(0xFFB0B0B0);
  static const Color cardBackground = Color(0xFFF8F8F8);
  static const Color shadowColor = Colors.black12;

  // Define light theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    cardColor: cardBackground,
    shadowColor: shadowColor,

    textTheme: GoogleFonts.workSansTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: Colors.black).copyWith(
      titleLarge: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        color: Colors.black54,
      ),
      bodyMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.grey[700],
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      titleTextStyle: GoogleFonts.workSans(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: mediumGrey, // Softer grey for unselected tabs
      showUnselectedLabels: true,
      selectedIconTheme: const IconThemeData(size: 28.0), // Slightly larger active icons
      unselectedIconTheme: const IconThemeData(size: 24.0),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Slightly rounded buttons
        ),
        elevation: 2, // Subtle button shadow
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.inputFillColor,
      hintStyle: GoogleFonts.workSans(color: mediumGrey),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 2.0,
        ),
      ),
      floatingLabelStyle: TextStyle(
        color: AppTheme.darkGreen,
        fontWeight: FontWeight.w500,
      ),
    ),

    iconTheme: IconThemeData(
      color: mediumGrey,
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkGreen,
        textStyle: GoogleFonts.workSans(
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: lightCardGreen,
      labelStyle: GoogleFonts.workSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
  );
}
