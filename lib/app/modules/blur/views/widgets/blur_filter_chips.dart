import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';
import 'package:media_cleaner/app/service/blur_service.dart';

/// Chip di filtro per [BlurView]: Tutti / Sfocate / Scure / Sovraesposte.
///
/// FIX: i conteggi per issue vengono letti da [BlurController.issueCount]
/// (calcolati una volta a fine scan) invece di eseguire 3× .where() O(n)
/// sulla lista completa ad ogni rebuild.
class BlurFilterChips extends GetView<BlurController> {
  const BlurFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Lettura O(1) dalla mappa precalcolata — zero scan sulla lista
      final counts   = controller.issueCount;
      final all      = controller.blurItems.length;
      final blurCnt  = counts[QualityIssue.blur]        ?? 0;
      final darkCnt  = counts[QualityIssue.dark]        ?? 0;
      final overCnt  = counts[QualityIssue.overexposed] ?? 0;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          _Chip(issue: null,                   label: 'Tutti ($all)',                color: const Color(0xFF5AC8FA)),
          if (blurCnt > 0) _Chip(issue: QualityIssue.blur,        label: 'Sfocate ($blurCnt)',     color: Colors.purple),
          if (darkCnt > 0) _Chip(issue: QualityIssue.dark,        label: 'Scure ($darkCnt)',       color: Colors.amber),
          if (overCnt > 0) _Chip(issue: QualityIssue.overexposed, label: 'Sovraesposte ($overCnt)', color: Colors.orange),
        ]),
      );
    });
  }
}

class _Chip extends GetView<BlurController> {
  final QualityIssue? issue;
  final String label;
  final Color  color;

  const _Chip({required this.issue, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.filter.value == issue;
      return GestureDetector(
        onTap: () {
          controller.filter.value = issue;
          controller.clearSelection();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.2)
                : Get.theme.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? color
                  : Get.theme.colorScheme.onSurface.withValues(alpha: 0.54),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }
}