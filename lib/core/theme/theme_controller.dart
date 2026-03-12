import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, dark, light }

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();
  static const _modeKey = 'app_theme_mode';
  static const _legacyKey = 'app_theme_dark';

  final themeMode = AppThemeMode.system.obs;

  // Kept for any code that still references isDark
  bool get isDarkValue =>
      themeMode.value == AppThemeMode.dark ||
      (themeMode.value == AppThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modeKey);
    AppThemeMode mode;
    if (saved != null) {
      mode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
    } else {
      final wasDark = prefs.getBool(_legacyKey);
      mode = wasDark == null
          ? AppThemeMode.system
          : wasDark
              ? AppThemeMode.dark
              : AppThemeMode.light;
    }
    themeMode.value = mode;
    final flutterMode = _toFlutter(mode);
    Get.changeThemeMode(flutterMode);
    ThemeHelper.applySystemUI(flutterMode);
  }

  ThemeMode _toFlutter(AppThemeMode m) => switch (m) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };

  Future<void> cycleTheme() async {
    final next = switch (themeMode.value) {
      AppThemeMode.system => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.system,
    };
    themeMode.value = next;
    final flutterMode = _toFlutter(next);
    Get.changeThemeMode(flutterMode);
    ThemeHelper.applySystemUI(flutterMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, next.name);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    final flutterMode = _toFlutter(mode);
    Get.changeThemeMode(flutterMode);
    ThemeHelper.applySystemUI(flutterMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  // Backward compat
  Future<void> toggleTheme() => cycleTheme();
}