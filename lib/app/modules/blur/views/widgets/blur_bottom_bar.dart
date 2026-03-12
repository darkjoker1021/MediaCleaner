import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';

/// Bottom action bar for [BlurView].
/// Shows selection actions (cancel + send to trash) or default actions
/// (rescan + trash all) depending on [BlurController.isSelecting].
class BlurBottomBar extends GetView<BlurController> {
  final List<BlurItem> items;

  const BlurBottomBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Get.theme.dividerColor)),
      ),
      child: controller.isSelecting.value && controller.selectedIds.isNotEmpty
          ? Row(children: [
              Expanded(child: _Btn(
                label: 'Annulla',
                icon: FluentIcons.dismiss_20_filled,
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                bg: Get.theme.cardColor,
                onTap: controller.toggleSelectionMode,
              )),
              const SizedBox(width: 12),
              Expanded(child: _Btn(
                label: 'Cestino (${controller.selectedIds.length})',
                icon: FluentIcons.delete_20_filled,
                color: Colors.white,
                bg: const Color(0xFFFF3B30),
                onTap: () {
                  final count = controller.moveSelectedToTrash();
                  Get.snackbar(
                    'Spostati nel cestino', '$count foto',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.88),
                    colorText: Colors.white,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    borderRadius: 14,
                  );
                },
              )),
            ])
          : Row(children: [
              Expanded(child: _Btn(
                label: 'Aggiorna',
                icon: FluentIcons.arrow_clockwise_20_filled,
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                bg: Get.theme.cardColor,
                onTap: controller.scan,
              )),
              const SizedBox(width: 12),
              Expanded(child: _Btn(
                label: 'Cestino tutto',
                icon: FluentIcons.delete_20_filled,
                color: Colors.white,
                bg: const Color(0xFFFF3B30),
                onTap: () {
                  if (items.isEmpty) return;
                  final moved = controller.moveAllToTrash();
                  Get.snackbar(
                    'Spostati nel cestino', '$moved foto',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.88),
                    colorText: Colors.white,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    borderRadius: 14,
                  );
                },
              )),
            ]),
    ));
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
