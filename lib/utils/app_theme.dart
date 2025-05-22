import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color constants - updated for consistency
  static const Color primaryColor = Color(0xFF0D2B3E); // Deep teal/midnight blue
  static const Color primaryLightColor = Color(0xFF1A4A6E); // Medium teal blue
  static const Color secondaryColor = Color(0xFF2C3E50); // Dark blue-gray
  static const Color accentColor = Color(0xFFD8B468); // Gentle gold/amber
  static const Color backgroundColor = Color(0xFF1A2530); // Darker navy
  static const Color successColor = Color(0xFF28A745); // Green
  static const Color errorColor = Color(0xFFDC3545); // Red
  static const Color textColor = Colors.white; // White text
  static const Color greyColor = Color(0xFF6E92A8); // Muted blue-gray
  static const Color cardColor = Color(0xFF21303F); // Slightly lighter card color
  static const Color darkGoldColor = Color(0xFFB8860B); // Darker gold for contrast
  
  // New colors for enhanced gradients (keeping existing)
  static const Color deepGold = Color(0xFFC19A00);
  static const Color softGold = Color(0xFFF4E992);
  static const Color shimmerGold = Color(0xFFFFF6D9);
  
  // Main background gradient
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color(0xFF0D2B3E), // Deep teal/midnight blue
      Color(0xFF1A4A6E), // Medium teal blue
      Color(0xFF2A5E80), // Slightly lighter blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dashboard gradient
  static const LinearGradient dashboardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2C3E50), // Dark blue-gray
      Color(0xFF1A2530), // Darker navy
    ],
  );
  
  // Enhanced background gradients (keep existing)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [deepGold, primaryColor, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [deepGold, shimmerGold, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glass morphism effect color
  static Color glassColor(double opacity) => Colors.white.withOpacity(opacity);
  
  // Shadow styles
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> emphasizedShadow = [
    BoxShadow(
      color: deepGold.withOpacity(0.3),
      blurRadius: 15,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  // Improved Theme data
  static final ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: GoogleFonts.poppins().fontFamily,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
      background: backgroundColor,
      error: errorColor,
    ),
    
    cardTheme: CardTheme(
      elevation: 6,
      shadowColor: Colors.black45,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        elevation: 4,
        shadowColor: accentColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Improved input decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
      labelStyle: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: accentColor,
        fontWeight: FontWeight.bold,
      ),
      prefixIconColor: accentColor,
      suffixIconColor: textColor.withOpacity(0.7),
    ),
  );
  
  // New reusable widget styles
  static InputDecoration searchInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search, color: accentColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
    );
  }
  
  static BoxDecoration glassomorphicContainer() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  static BoxDecoration gradientCard() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          primaryColor.withOpacity(0.7),
          primaryLightColor.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: softShadow,
    );
  }
}