import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_cleaner/core/theme/palette.dart';

// Light Theme
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: GoogleFonts.poppins().fontFamily,

  scaffoldBackgroundColor: Palette.scaffoldBackgroundColor,
  iconTheme: const IconThemeData(color: Color(0xFF2F75FF)),
  
  colorScheme: const ColorScheme.light(
    primary: Palette.primaryColor,
    secondary: Palette.containerColor,
    surface: Palette.scaffoldBackgroundColor,
  ),
);

// Dark Theme
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  splashColor: Colors.transparent,
  fontFamily: GoogleFonts.poppins().fontFamily,

  scaffoldBackgroundColor: const Color(0xFF343434),
  iconTheme: const IconThemeData(color: Colors.blueAccent),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2F75FF),
    secondary: Color(0xFF464646),
    tertiary: Colors.white,
    surface:  Color(0xFF343434),
  ),
);