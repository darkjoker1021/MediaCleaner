import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/duplicate/controllers/duplicates_controller.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

class DuplicateBottomBar extends StatelessWidget {
  const DuplicateBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DuplicatesController>();
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
          onTap: count > 0 ? () => _confirmMoveToTrash(ctrl) : null,
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
                    ? 'Manda nel cestino ($count copie · ${PhotoService.formatBytes(bytes)})'
                    : 'Seleziona le copie da eliminare',
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

  void _confirmMoveToTrash(DuplicatesController ctrl) {
    final count = ctrl.selectedIds.length;
    final bytes = ctrl.selectedWasteBytes;
    Get.dialog(AlertDialog(
      backgroundColor: Get.theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Manda nel cestino',
          style: TextStyle(
              color: Get.theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700)),
      content: Text(
        'Sposterai $count copie nel cestino.\n'
        '${PhotoService.formatBytes(bytes)} recuperabili.\n\n'
        'Non verranno eliminate finché non svuoti il cestino.',
        style: TextStyle(
            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54),
            fontSize: 14,
            height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('Annulla',
              style: TextStyle(
                  color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54),
                  fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.moveSelectedToTrash();
          },
          child: const Text('Manda nel cestino',
              style: TextStyle(
                  color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}
