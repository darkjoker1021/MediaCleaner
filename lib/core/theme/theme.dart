import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_cleaner/core/theme/palette.dart';

// Dark Theme (primary)
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  splashColor: Colors.transparent,
  fontFamily: GoogleFonts.poppins().fontFamily,
  scaffoldBackgroundColor: const Color(0xFF0D0F14),
  cardColor: const Color(0xFF1C1E27),
  dividerColor: Colors.white12,
  colorScheme: const ColorScheme.dark(
    primary: Palette.primaryColor,
    secondary: Color(0xFF16181F),
    surface: Color(0xFF0D0F14),
    onPrimary: Colors.white,
    onSurface: Colors.white,
  ),
);

// Light Theme
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  splashColor: Colors.transparent,
  fontFamily: GoogleFonts.poppins().fontFamily,
  scaffoldBackgroundColor: const Color(0xFFF0F2F7),
  cardColor: Colors.white,
  dividerColor: Colors.black12,
  colorScheme: const ColorScheme.light(
    primary: Palette.primaryColor,
    secondary: Color(0xFFE8EAED),
    surface: Color(0xFFF0F2F7),
    onPrimary: Colors.white,
    onSurface: Color(0xFF0D0F14),
  ),
);