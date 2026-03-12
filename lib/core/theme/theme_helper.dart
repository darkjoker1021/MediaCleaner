import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static const _modeKey   = 'app_theme_mode';
  static const _legacyKey = 'app_theme_dark';

  /// Applies the given [themeMode] to GetX and syncs system UI overlay style.
  void changeThemeMode(ThemeMode themeMode) async {
    Get.changeThemeMode(themeMode);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _toKey(themeMode));

    _applySystemUI(isDark);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modeKey);
    if (saved != null) {
      return _fromKey(saved);
    }
    // Migrate legacy bool key
    final wasDark = prefs.getBool(_legacyKey);
    return wasDark == null
        ? ThemeMode.system
        : wasDark
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  /// Call once at startup to sync system UI without changing the stored pref.
  static void applySystemUI(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark);
    _applySystemUI(isDark);
  }

  static void _applySystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(_styleForDark(isDark));
  }

  /// Returns the correct [SystemUiOverlayStyle] for use in [AnnotatedRegion],
  /// with transparent status bar and scaffold-matched navigation bar color.
  static SystemUiOverlayStyle overlayStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _styleForDark(isDark);
  }

  static SystemUiOverlayStyle _styleForDark(bool isDark) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor:
        isDark ? const Color(0xFF0D0F14) : const Color(0xFFF0F2F7),
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
  );

  static String _toKey(ThemeMode m) => switch (m) {
    ThemeMode.dark   => 'dark',
    ThemeMode.light  => 'light',
    ThemeMode.system => 'system',
  };

  static ThemeMode _fromKey(String s) => switch (s) {
    'dark'  => ThemeMode.dark,
    'light' => ThemeMode.light,
    _       => ThemeMode.system,
  };
}
