import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color constants - keeping the existing colors
  static const Color primaryColor = Color(0xFFD4A017); // Golden/Yellow color
  static const Color primaryLightColor = Color(0xFFE9C46A); // Lighter gold
  static const Color secondaryColor = Color(0xFF8B4513); // Brown
  static const Color backgroundColor = Color(0xFFF5F5DC); // Light beige
  static const Color successColor = Color(0xFF28A745); // Green
  static const Color errorColor = Color(0xFFDC3545); // Red
  static const Color textColor = Color(0xFF333333); // Dark gray
  static const Color greyColor = Color(0xFF808080); // Grey
  static const Color accentColor = Color(0xFF3498DB); // Blue accent
  static const Color cardColor = Color(0xFFFFFBE9); // Light warm card background
  static const Color darkGoldColor = Color(0xFFB8860B); // Darker gold for contrast
  
  // New colors for enhanced gradients
  static const Color deepGold = Color(0xFFC19A00);
  static const Color softGold = Color(0xFFF4E992);
  static const Color shimmerGold = Color(0xFFFFF6D9);
  
  // Enhanced background gradients
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
    textTheme: GoogleFonts.poppinsTextTheme(),
    
    cardTheme: CardTheme(
      elevation: 6,
      shadowColor: Colors.black45,
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
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.5),
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
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: TextStyle(color: greyColor.withOpacity(0.7)),
      labelStyle: const TextStyle(
        color: secondaryColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      prefixIconColor: primaryColor,
      suffixIconColor: greyColor,
    ),
  );
  
  // New reusable widget styles
  static InputDecoration searchInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search, color: primaryColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
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
