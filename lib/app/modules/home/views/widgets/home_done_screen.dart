import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';

/// Shown when all photos have been reviewed. Displays a summary and quick
/// navigation buttons to the kept and trash lists, plus a restart button.
class HomeDoneScreen extends StatelessWidget {
  const HomeDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FluentIcons.checkmark_20_filled,
                color: Color(0xFF34C759),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tutto revisionato!',
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              '${ctrl.keptCount.value} mantenute · ${ctrl.trashCount.value} nel cestino',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.6,
              ),
            )),
            const SizedBox(height: 20),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctrl.keptCount.value > 0)
                  _QuickBtn(
                    icon: FluentIcons.heart_20_filled,
                    color: const Color(0xFF34C759),
                    label: 'Mantenute',
                    badge: '${ctrl.keptCount.value}',
                    onTap: () => Get.toNamed(Routes.KEPT),
                  ),
                if (ctrl.keptCount.value > 0 && ctrl.trashCount.value > 0)
                  const SizedBox(width: 12),
                if (ctrl.trashCount.value > 0)
                  _QuickBtn(
                    icon: FluentIcons.delete_20_filled,
                    color: const Color(0xFFFF3B30),
                    label: 'Cestino',
                    badge: '${ctrl.trashCount.value}',
                    onTap: () => Get.toNamed(Routes.TRASH),
                  ),
              ],
            )),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: ctrl.loadPhotos,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Ricomincia',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick navigation button ──────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String badge;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
