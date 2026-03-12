import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'widgets/blur_bottom_bar.dart';
import 'widgets/blur_filter_chips.dart';
import 'widgets/blur_grid.dart';

class BlurView extends GetView<BlurController> {
  const BlurView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            if (controller.isScanning.value) return _scanning();
            final items = controller.displayed;
            return Column(
              children: [
                _appBar(items),
                const BlurFilterChips(),
                if (controller.isSelecting.value && items.isNotEmpty)
                  _selectAllRow(items),
                items.isEmpty ? _emptyState() : BlurGrid(items: items),
                if (controller.hasMore.value) _loadMoreBanner(),
                if (items.isNotEmpty) BlurBottomBar(items: items),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _scanning() {
    return Obx(() {
      final progress = controller.scanProgress.value;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Lottie.asset('assets/lottie/search.json'),
            const SizedBox(height: 20),
            Text('Analisi qualità in corso...',
                style: TextStyle(color: Get.theme.colorScheme.onSurface,
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Analisi isolato · ${(progress * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFF5AC8FA), fontSize: 13)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: const Color(0xFF5AC8FA).withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF5AC8FA)),
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

  Widget _appBar(List<BlurItem> items) => MediaAppBar(
    title: 'Qualità bassa',
    subtitle: Text(
      '${items.length} foto · ${PhotoService.formatBytes(items.fold(0, (s, e) => s + e.item.sizeBytes))}',
      style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
    ),
    onRescan: controller.scan,
    selectButton: items.isNotEmpty
        ? SelectToggleButton(
            isSelecting: controller.isSelecting,
            onTap: controller.toggleSelectionMode,
            accentColor: const Color(0xFF5AC8FA),
          )
        : null,
  );



  Widget _selectAllRow(List<BlurItem> items) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => controller.allSelected
            ? controller.clearSelection() : controller.selectAll(),
        child: Obx(() => Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: controller.allSelected ? const Color(0xFF5AC8FA) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: controller.allSelected ? const Color(0xFF5AC8FA) : Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                width: 1.5),
            ),
            child: controller.allSelected
                ? const Icon(FluentIcons.checkmark_20_filled, color: Colors.white, size: 13)
                : null,
          ),
          const SizedBox(width: 10),
          Text('Seleziona tutto (${items.length})',
              style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
        ])),
      ),
      const Spacer(),
      Obx(() => controller.selectedIds.isNotEmpty
          ? Text('${controller.selectedIds.length} selezionati',
              style: const TextStyle(color: Color(0xFF5AC8FA),
                  fontSize: 13, fontWeight: FontWeight.w600))
          : const SizedBox.shrink()),
    ]),
  );

  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: const Icon(FluentIcons.eye_20_filled, color: Color(0xFF34C759), size: 32),
        ),
        const SizedBox(height: 16),
        Text('Nessuna foto con qualità bassa',
            style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Tutte le foto sembrano nitide e ben esposte',
            style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.25), fontSize: 13)),
      ]),
    ),
  );

  Widget _loadMoreBanner() => GestureDetector(
    onTap: controller.scanAll,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5AC8FA).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5AC8FA).withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(FluentIcons.arrow_clockwise_20_filled,
            color: Color(0xFF5AC8FA), size: 16),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Analizzate le prime ${BlurController.initialScanLimit} foto · Tocca per analizzare tutta la libreria',
            style: TextStyle(color: Color(0xFF5AC8FA), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    ),
  );
}
