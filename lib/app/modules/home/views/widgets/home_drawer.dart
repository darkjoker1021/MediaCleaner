import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/video/controllers/video_controller.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/core/theme/theme_controller.dart';

/// Side drawer shown from [HomeView]. Provides navigation to all tool screens,
/// theme switching, reload and reset actions.
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode    = ThemeController.to.themeMode.value;
      final isVideo = Get.find<HomeController>().isVideoMode.value;
      final ctrl    = Get.find<HomeController>();
      final vc      = isVideo ? Get.find<VideoController>() : null;

      void close() => ctrl.scaffoldKey.currentState?.closeDrawer();

      return Builder(builder: (ctx) {
        final th = Theme.of(ctx);
        return Drawer(
          backgroundColor: th.scaffoldBackgroundColor,
          width: 288,
          child: Column(
            children: [
              _header(th, isVideo, close),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isVideo) ...[
                        _section(th, 'Strumenti'),
                        _tile(th, FluentIcons.copy_20_filled, 'Duplicati',       const Color(0xFFFF9F0A), () { close(); Get.toNamed(Routes.DUPLICATES); }),
                        _tile(th, FluentIcons.scan_camera_20_filled, 'Screenshot', const Color(0xFF5AC8FA), () { close(); Get.toNamed(Routes.SCREENSHOT); }),
                        _tile(th, FluentIcons.eye_off_20_filled, 'Sfocate',       const Color(0xFFBF5AF2), () { close(); Get.toNamed(Routes.BLUR); }),
                        _tile(th, FluentIcons.chat_20_filled, 'Social',           const Color(0xFF34C759), () { close(); Get.toNamed(Routes.SOCIAL); }),
                        _tile(th, FluentIcons.timer_20_filled, 'Sequenze',        const Color(0xFFFF6B35), () { close(); Get.toNamed(Routes.BURST); }),
                        const SizedBox(height: 4),
                        Divider(color: th.dividerColor, height: 1, indent: 16, endIndent: 16),
                      ],
                      const SizedBox(height: 4),
                      _section(th, 'Generali'),
                      _tile(th, FluentIcons.data_bar_vertical_20_filled, 'Statistiche', const Color(0xFF0A84FF), () { close(); Get.toNamed(Routes.STATS); }),
                      _themeControl(th, mode),
                      _tile(
                        th,
                        FluentIcons.arrow_clockwise_20_filled,
                        isVideo ? 'Ricarica video' : 'Ricarica libreria',
                        th.colorScheme.onSurface.withValues(alpha: 0.6),
                        () {
                          close();
                          isVideo ? vc!.loadVideos() : ctrl.loadPhotos();
                        },
                      ),
                      const SizedBox(height: 4),
                      Divider(color: th.dividerColor, height: 1, indent: 16, endIndent: 16),
                      const SizedBox(height: 4),
                      _section(th, 'Reset'),
                      _tile(
                        th,
                        FluentIcons.replay_20_filled, 'Reset sessione', const Color(0xFFFF3B30),
                        () { close(); isVideo ? vc!.resetSession() : ctrl.resetSession(); },
                        isDestructive: true,
                      ),
                      _tile(
                        th,
                        FluentIcons.delete_dismiss_20_filled, 'Reset completo', const Color(0xFFFF3B30),
                        () { close(); isVideo ? vc!.resetAllStats() : ctrl.resetAllStats(); },
                        isDestructive: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _footer(th),
            ],
          ),
        );
      });
    });
  }

  Widget _header(ThemeData th, bool isVideo, VoidCallback close) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A84FF).withValues(alpha: 0.07),
        border: Border(bottom: BorderSide(color: th.dividerColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MediaCleaner',
                      style: TextStyle(
                        color: th.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isVideo
                            ? const Color(0xFFFF9F0A).withValues(alpha: 0.15)
                            : const Color(0xFF0A84FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isVideo ? 'Modalità Video' : 'Modalità Foto',
                        style: TextStyle(
                          color: isVideo ? const Color(0xFFFF9F0A) : const Color(0xFF0A84FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: close,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: th.colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FluentIcons.dismiss_20_filled,
                    color: th.colorScheme.onSurface.withValues(alpha: 0.45),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(ThemeData th) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Row(
          children: [
            Icon(FluentIcons.info_20_regular,
                size: 14,
                color: th.colorScheme.onSurface.withValues(alpha: 0.22)),
            const SizedBox(width: 6),
            Text(
              'v1.0.0',
              style: TextStyle(
                color: th.colorScheme.onSurface.withValues(alpha: 0.22),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData th, String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: th.colorScheme.onSurface.withValues(alpha: 0.32),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _tile(
    ThemeData th,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isDestructive
            ? const Color(0xFFFF3B30).withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? const Color(0xFFFF3B30)
                          : th.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeControl(ThemeData th, AppThemeMode current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: th.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _themeSegment(th, Icons.brightness_auto_rounded, 'Auto',
                current == AppThemeMode.system, AppThemeMode.system),
            _themeSegment(th, FluentIcons.weather_moon_20_filled, 'Scuro',
                current == AppThemeMode.dark, AppThemeMode.dark),
            _themeSegment(th, FluentIcons.weather_sunny_20_filled, 'Chiaro',
                current == AppThemeMode.light, AppThemeMode.light),
          ],
        ),
      ),
    );
  }

  Widget _themeSegment(
    ThemeData th,
    IconData icon,
    String label,
    bool selected,
    AppThemeMode mode,
  ) {
    const accent = Color(0xFFFF9F0A);
    final color = selected
        ? accent
        : th.colorScheme.onSurface.withValues(alpha: 0.38);
    return Expanded(
      child: GestureDetector(
        onTap: () => ThemeController.to.setTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
