import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_cleaner/core/theme/theme.dart';
import 'package:media_cleaner/core/theme/theme_controller.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'app/routes/app_pages.dart';

ThemeMode _themeMode = ThemeMode.system;
bool _showOnboarding = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limita la cache immagini Flutter per evitare OOM con librerie grandi
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 * 1024 * 1024; // 80 MB
  PaintingBinding.instance.imageCache.maximumSize = 300;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _initializeAppState();

  runApp(const MyApp());
}

Future<void> _initializeAppState() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    _showOnboarding = !(prefs.getBool('onboarding_done') ?? false);

    // Legge il tema salvato (supporta sia nuovo formato stringa sia legacy bool)
    final savedMode = prefs.getString('app_theme_mode');
    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      final wasDark = prefs.getBool('app_theme_dark');
      _themeMode = wasDark == null
          ? ThemeMode.system
          : wasDark
              ? ThemeMode.dark
              : ThemeMode.light;
    }

    // Applica subito colori system UI prima del primo frame
    ThemeHelper.applySystemUI(_themeMode);
  } catch (e) {
    debugPrint('Errore durante l\'inizializzazione: $e');
    _themeMode = ThemeMode.system;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Media Cleaner',
      initialRoute: _showOnboarding ? Routes.ONBOARDING : Routes.HOME,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      smartManagement: SmartManagement.full,
      locale: const Locale('it', 'IT'),
      fallbackLocale: const Locale('en', 'US'),
      initialBinding: BindingsBuilder(() {
        Get.put(ThemeController());
      }),
    );
  }
}