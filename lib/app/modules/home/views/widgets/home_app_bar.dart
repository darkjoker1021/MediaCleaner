import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/home/views/widgets/home_menu_sheet.dart';
import 'package:media_cleaner/app/modules/shared/sort_sheet.dart';
import 'package:media_cleaner/app/modules/video/controllers/video_controller.dart';
import 'package:media_cleaner/core/theme/theme_controller.dart';

/// Top app bar for [HomeView] — menu, photo/video switcher and sort button.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() {
      ThemeController.to.themeMode.value; // subscribe to theme changes
      final isVideo = ctrl.isVideoMode.value;
      final vc = isVideo ? Get.find<VideoController>() : null;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                _IconBtn(
                  icon: FluentIcons.navigation_20_filled,
                  onTap: HomeMenuSheet.show,
                ),
                const Spacer(),
                _IconBtn(
                  icon: FluentIcons.arrow_sort_20_filled,
                  onTap: () => SortSheet.show(isVideo ? vc! : ctrl),
                ),
              ],
            ),
            _MediaSwitch(ctrl: ctrl),
          ],
        ),
      );
    });
  }
}

// ── Icon button ──────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}

// ── Photo / Video segmented switch ───────────────────────────────────────────

class _MediaSwitch extends StatelessWidget {
  final HomeController ctrl;

  const _MediaSwitch({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      width: 116,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              icon: FluentIcons.image_20_regular,
              active: !ctrl.isVideoMode.value,
              onTap: () => ctrl.setVideoMode(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              icon: FluentIcons.video_20_regular,
              active: ctrl.isVideoMode.value,
              onTap: () => ctrl.setVideoMode(true),
            ),
          ),
        ],
      ),
    ));
  }
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Segment({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        height: 40,
        duration: const Duration(milliseconds: 170),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0A84FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: active
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          size: 18,
        ),
      ),
    );
  }
}
