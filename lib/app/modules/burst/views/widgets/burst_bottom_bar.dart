import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/burst/controllers/burst_controller.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

class BurstBottomBar extends StatelessWidget {
  const BurstBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BurstController>();
    return Obx(() {
      final count = ctrl.selectedIds.length;
      final bytes = ctrl.selectedWasteBytes;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Get.theme.dividerColor)),
        ),
        child: GestureDetector(
          onTap: count > 0 ? () => _confirm(ctrl) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: count > 0
                  ? const Color(0xFFFF3B30)
                  : Get.theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                FluentIcons.delete_20_filled,
                color: count > 0
                    ? Colors.white
                    : Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                count > 0
                    ? 'Manda nel cestino ($count extra · ${PhotoService.formatBytes(bytes)})'
                    : 'Seleziona le foto extra da eliminare',
                style: TextStyle(
                    color: count > 0
                        ? Colors.white
                        : Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
      );
    });
  }

  void _confirm(BurstController ctrl) {
    final count = ctrl.selectedIds.length;
    Get.defaultDialog(
      title: 'Manda nel cestino',
      middleText: 'Spostare $count foto extra nel cestino?',
      backgroundColor: Get.theme.cardColor,
      titleStyle: TextStyle(
          color: Get.theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700),
      middleTextStyle: TextStyle(
          color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7)),
      textConfirm: 'Cestino',
      textCancel: 'Annulla',
      confirmTextColor: Colors.white,
      cancelTextColor:
          Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
      buttonColor: const Color(0xFFFF3B30),
      onConfirm: () {
        Get.back();
        ctrl.moveSelectedToTrash();
      },
    );
  }
}
