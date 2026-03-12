import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/burst/controllers/burst_controller.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

/// FIX: rimosso Obx annidato ridondante (stesso bug già corretto in
/// DuplicateSummaryBanner). Un solo Obx calcola tutti i valori e
/// costruisce il widget, incluso il testo del pulsante.
class BurstSummaryBanner extends StatelessWidget {
  const BurstSummaryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BurstController>();
    return Obx(() {
      final selected   = ctrl.selectedIds.length;
      final waste      = ctrl.selectedWasteBytes;
      final allSelected = selected == ctrl.totalExtras;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9F0A).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(FluentIcons.clock_20_filled,
              color: Color(0xFFFF9F0A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$selected extra selezionati',
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
            onTap: allSelected ? ctrl.clearSelection : ctrl.selectAllExtras,
            child: Text(
              allSelected ? 'Deseleziona' : 'Seleziona tutti',
              style: const TextStyle(
                  color: Color(0xFFFF9F0A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      );
    });
  }
}