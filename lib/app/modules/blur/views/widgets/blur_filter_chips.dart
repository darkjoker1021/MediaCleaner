import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';
import 'package:media_cleaner/app/service/blur_service.dart';

/// Horizontal scrolling filter chips for [BlurView]:
/// All / Sfocate / Scure / Sovraesposte.
class BlurFilterChips extends GetView<BlurController> {
  const BlurFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final all       = controller.blurItems.length;
      final blurCount = controller.blurItems.where((b) => b.issue == QualityIssue.blur).length;
      final darkCount = controller.blurItems.where((b) => b.issue == QualityIssue.dark).length;
      final overCount = controller.blurItems.where((b) => b.issue == QualityIssue.overexposed).length;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          _Chip(issue: null,                   label: 'Tutti ($all)',               color: const Color(0xFF5AC8FA)),
          if (blurCount > 0) _Chip(issue: QualityIssue.blur,        label: 'Sfocate ($blurCount)',    color: Colors.purple),
          if (darkCount > 0) _Chip(issue: QualityIssue.dark,        label: 'Scure ($darkCount)',      color: Colors.amber),
          if (overCount > 0) _Chip(issue: QualityIssue.overexposed, label: 'Sovraesposte ($overCount)', color: Colors.orange),
        ]),
      );
    });
  }
}

class _Chip extends GetView<BlurController> {
  final QualityIssue? issue;
  final String label;
  final Color color;

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
