import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

/// Barra statistiche — progress + spazio liberato.
class StatsBar extends StatelessWidget {
  final IMediaController ctrl;
  final String pendingLabel;

  const StatsBar({
    super.key,
    required this.ctrl,
    this.pendingLabel = 'rimaste',
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.totalCount == 0) return const SizedBox.shrink();
      final pct   = (ctrl.progress * 100).toInt();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(
                '${ctrl.pendingCount} $pendingLabel',
                style: TextStyle(
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: TextStyle(
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 11),
              ),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ctrl.progress,
                backgroundColor: Get.theme.dividerColor,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF0A84FF)),
                minHeight: 3,
              ),
            ),
          ],
        ),
      );
    });
  }
}