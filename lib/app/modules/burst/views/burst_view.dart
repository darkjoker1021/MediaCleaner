import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/app/modules/burst/controllers/burst_controller.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'widgets/burst_bottom_bar.dart';
import 'widgets/burst_group_card.dart';
import 'widgets/burst_summary_banner.dart';

class BurstView extends GetView<BurstController> {
  const BurstView({super.key});

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
                const BurstSummaryBanner(),
                Expanded(child: _groupList()),
                if (controller.hasMore.value) _loadMoreBanner(),
                const BurstBottomBar(),
              ],
            ]);
          }),
        ),
      ),
    );
  }

  Widget _scanning() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Lottie.asset('assets/lottie/search.json'),
      const SizedBox(height: 20),
      Text('Analisi sequenze...', style: TextStyle(
          color: Get.theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Raggruppamento foto entro 3 secondi',
          style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13)),
    ]),
  );

  Widget _appBar() => MediaAppBar(
    title: 'Sequenze',
    badge: controller.groups.isNotEmpty ? '${controller.groups.length} gruppi' : null,
    subtitle: Text(
      controller.groups.isEmpty
          ? 'Nessuna sequenza trovata'
          : '${controller.totalExtras} foto extra · '
            '${PhotoService.formatBytes(controller.totalWasteBytes)} recuperabili',
      style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
    ),
    onRescan: controller.scan,
  );


  Widget _groupList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    itemCount: controller.groups.length,
    itemBuilder: (ctx, i) => RepaintBoundary(
        child: BurstGroupCard(group: controller.groups[i])),
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
            'Analizzate le prime ${BurstController.initialScanLimit} foto · Tocca per analizzare tutta la libreria',
            style: TextStyle(color: Color(0xFFFF9F0A), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    ),
  );
  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle),
          child: const Icon(FluentIcons.checkmark_circle_20_filled,
              color: Color(0xFF34C759), size: 32)),
        const SizedBox(height: 16),
        const Text('Nessuna sequenza', style: TextStyle(
            color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Nessun gruppo di foto scattate in rapida sequenza',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13)),
      ]),
    ),
  );

}
