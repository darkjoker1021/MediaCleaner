import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

/// Barra statistiche generica — funziona con foto e video.
/// Uso:  StatsBar(ctrl: controller)
/// Uso:  StatsBar(ctrl: controller, pendingLabel: 'rimasti',
///                totalIcon: FluentIcons.video_20_filled)
class StatsBar extends StatelessWidget {
  final IMediaController ctrl;
  final String   pendingLabel;
  final IconData totalIcon;

  const StatsBar({
    super.key,
    required this.ctrl,
    this.pendingLabel = 'rimaste',
    this.totalIcon    = FluentIcons.content_view_gallery_20_filled,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        if (ctrl.totalCount > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Text('${ctrl.pendingCount} $pendingLabel',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
              const Spacer(),
              Text(
                  '${(ctrl.progress * 100).toStringAsFixed(0)}% completato',
                  style: const TextStyle(
                      color: Colors.white30, fontSize: 11)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ctrl.progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(
                    Color(0xFF0A84FF)),
                minHeight: 3,
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(children: [
            _stat(FluentIcons.data_usage_20_filled,
                ctrl.totalFreedBytes > 0
                    ? '−${PhotoService.formatBytes(ctrl.totalFreedBytes)}'
                    : '—',
                'liberato', const Color(0xFF0A84FF)),
            _div(),
            _stat(FluentIcons.heart_20_filled,
                '${ctrl.keptCount.value}', 'mantenuti',
                const Color(0xFF34C759)),
            _div(),
            _stat(FluentIcons.delete_dismiss_20_filled,
                '${ctrl.trashCount.value}', 'cestino',
                const Color(0xFFFF3B30)),
            _div(),
            _stat(totalIcon, '${ctrl.totalCount}', 'totali',
                Colors.white38),
          ]),
        ),
      ]),
    ));
  }

  Widget _stat(IconData icon, String val, String lbl, Color c) =>
      Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(height: 4),
          Text(val,
              style: TextStyle(color: c, fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text(lbl,
              style: const TextStyle(
                  color: Colors.white24, fontSize: 10)),
        ]),
      );

  Widget _div() => Container(
      width: 1, height: 36,
      color: Colors.white.withValues(alpha: 0.07));
}