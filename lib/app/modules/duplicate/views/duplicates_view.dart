import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_cleaner/app/modules/duplicate/controllers/duplicates_controller.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'widgets/duplicate_bottom_bar.dart';
import 'widgets/duplicate_group_card.dart';
import 'widgets/duplicate_summary_banner.dart';

class DuplicatesView extends GetView<DuplicatesController> {
  const DuplicatesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            if (controller.isScanning.value) return _scanning();
            return Column(children: [
              _appBar(),
              if (controller.groups.isEmpty)
                _emptyState()
              else ...[
                const DuplicateSummaryBanner(),
                Expanded(child: _groupList()),
                if (controller.hasMore.value) _loadMoreBanner(),
                const DuplicateBottomBar(),
              ],
            ]);
          }),
        ),
      ),
    );
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  Widget _scanning() {
    return Obx(() {
      final progress = controller.scanProgress.value;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Lottie.asset('assets/lottie/search.json'),
            const SizedBox(height: 20),
            Text('Analisi in corso...', style: TextStyle(
                color: Get.theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Ricerca duplicati · ${(progress * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFFFF9F0A), fontSize: 13)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9F0A)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "L'operazione potrebbe durare anche alcuni minuti",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.30),
                fontSize: 12,
              ),
            ),
          ]),
        ),
      );
    });
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar() => MediaAppBar(
    title: 'Duplicati',
    badge: controller.groups.isNotEmpty ? '${controller.groups.length} gruppi' : null,
    subtitle: Text(
      controller.groups.isEmpty
          ? 'Nessun duplicato trovato'
          : '${controller.totalDuplicateCount} copie · '
            '${PhotoService.formatBytes(controller.totalWasteBytes)} recuperabili',
      style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
    ),
    onRescan: controller.scan,
  );

  // ── Summary banner → DuplicateSummaryBanner ──────────────────────────────
  // ── Group card     → DuplicateGroupCard ──────────────────────────────────

  Widget _groupList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    itemCount: controller.groups.length,
    itemBuilder: (ctx, i) => RepaintBoundary(
        child: DuplicateGroupCard(group: controller.groups[i])),
  );

  Widget _loadMoreBanner() => GestureDetector(
    onTap: controller.scanAll,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(FluentIcons.arrow_clockwise_20_filled,
            color: Color(0xFFFF9F0A), size: 16),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Analizzate le prime ${DuplicatesController.initialScanLimit} foto · Tocca per analizzare tutta la libreria',
            style: TextStyle(color: Color(0xFFFF9F0A), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    ),
  );

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: const Icon(FluentIcons.checkmark_circle_20_filled,
              color: Color(0xFF34C759), size: 32),
        ),
        const SizedBox(height: 16),
        Text('Nessun duplicato', style: TextStyle(
            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('La libreria è pulita',
            style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.25), fontSize: 13)),
        const SizedBox(height: 24),
        Text('Nota: la scansione usa dimensione+data\ne hash percettivo (foto simili).',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 11,
                height: 1.6)),
      ]),
    ),
  );

}