import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

/// Funziona con qualsiasi controller che implementa [IMediaController].
/// Uso:  SortSheet.show(controller)
class SortSheet extends StatelessWidget {
  final IMediaController ctrl;
  const SortSheet._({required this.ctrl});

  static void show(IMediaController ctrl) => Get.bottomSheet(
    SortSheet._(ctrl: ctrl),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E27),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Icon(FluentIcons.arrow_sort_20_filled, color: Colors.white54, size: 16),
            SizedBox(width: 8),
            Text('Ordina per', style: TextStyle(
                color: Colors.white54, fontSize: 13,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
        ),
        const SizedBox(height: 10),
        Obx(() => Column(children: [
          _opt(SortMode.dateNewest,   FluentIcons.arrow_down_20_filled, 'Più recente',  'Data ↓'),
          _opt(SortMode.dateOldest,   FluentIcons.arrow_up_20_filled,   'Più vecchio',  'Data ↑'),
          _opt(SortMode.sizeHeaviest, FluentIcons.resize_20_filled,     'Più pesante',  'Size ↓'),
          _opt(SortMode.sizeLightest, FluentIcons.resize_20_filled,     'Più leggero',  'Size ↑'),
        ])),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _opt(SortMode mode, IconData icon, String label, String sub) {
    final sel = ctrl.currentSort.value == mode;
    return GestureDetector(
      onTap: () { ctrl.setSortMode(mode); Get.back(); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF0A84FF).withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? const Color(0xFF0A84FF).withValues(alpha: 0.3)
                         : Colors.transparent),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF0A84FF).withValues(alpha: 0.2)
                         : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18,
                color: sel ? const Color(0xFF0A84FF) : Colors.white54),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
                color: sel ? Colors.white : Colors.white70,
                fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          if (sel) const Icon(Icons.check_circle_rounded,
              color: Color(0xFF0A84FF), size: 18),
        ]),
      ),
    );
  }
}