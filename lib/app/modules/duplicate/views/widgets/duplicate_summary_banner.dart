import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/duplicate/controllers/duplicates_controller.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

class DuplicateSummaryBanner extends StatelessWidget {
  const DuplicateSummaryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DuplicatesController>();
    return Obx(() {
      final selected = ctrl.selectedIds.length;
      final waste    = ctrl.selectedWasteBytes;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9F0A).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(FluentIcons.delete_20_filled,
              color: Color(0xFFFF9F0A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$selected copie selezionate',
                  style: TextStyle(
                      color: Get.theme.colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              if (waste > 0)
                Text('${PhotoService.formatBytes(waste)} da liberare',
                    style: const TextStyle(
                        color: Color(0xFFFF9F0A), fontSize: 11)),
            ]),
          ),
          GestureDetector(
            onTap: () {
              if (ctrl.selectedIds.length == ctrl.totalDuplicateCount) {
                ctrl.clearSelection();
              } else {
                ctrl.selectAllDuplicates();
              }
            },
            child: Obx(() => Text(
              ctrl.selectedIds.length == ctrl.totalDuplicateCount
                  ? 'Deseleziona'
                  : 'Seleziona tutti',
              style: const TextStyle(
                  color: Color(0xFFFF9F0A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            )),
          ),
        ]),
      );
    });
  }
}
