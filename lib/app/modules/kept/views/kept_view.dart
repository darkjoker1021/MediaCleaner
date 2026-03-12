import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/app/modules/kept/controllers/kept_controller.dart';
import 'package:media_cleaner/app/modules/video/views/video_player_view.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';
import 'package:media_cleaner/core/widgets/shimmer_box.dart';

class KeptView extends GetView<KeptController> {
  /// [isVideo] = true  → apre VideoPlayerView al tap, mostra badge play
  /// [isVideo] = false → apre PhotoDetailView al tap  (default)
  final bool isVideo;
  const KeptView({super.key, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            final items = controller.keptItems;
            return Column(children: [
              _appBar(items),
              if (controller.isSelecting.value && items.isNotEmpty)
                _selectAllRow(items),
              items.isEmpty ? _emptyState() : _grid(items),
              if (items.isNotEmpty) _bottomBar(items),
            ]);
          }),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar(List<PhotoItem> items) => MediaAppBar(
    title: isVideo ? 'Video mantenuti' : 'Mantenuti',
    badge: '${items.length}',
    badgeColor: const Color(0xFF34C759),
    subtitle: Text(
      '${PhotoService.formatBytes(controller.keptBytes)} totali',
      style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
    ),
    selectButton: items.isNotEmpty
        ? SelectToggleButton(
            isSelecting: controller.isSelecting,
            onTap: controller.toggleSelectionMode,
            accentColor: const Color(0xFF34C759),
          )
        : null,
  );

  // ── Select all ────────────────────────────────────────────────────────────

  Widget _selectAllRow(List<PhotoItem> items) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => controller.allSelected
            ? controller.clearSelection() : controller.selectAll(),
        child: Obx(() => Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: controller.allSelected
                  ? const Color(0xFF34C759) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: controller.allSelected
                      ? const Color(0xFF34C759) : Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child: controller.allSelected
                ? const Icon(FluentIcons.checkmark_20_filled,
                    color: Colors.white, size: 13)
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
              style: const TextStyle(color: Color(0xFF34C759),
                  fontSize: 13, fontWeight: FontWeight.w600))
          : const SizedBox.shrink()),
    ]),
  );

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle),
          child: Icon(
            isVideo ? FluentIcons.video_20_filled : FluentIcons.heart_20_filled,
            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.24), size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isVideo ? 'Nessun video mantenuto' : 'Nessuna foto mantenuta',
          style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          isVideo
              ? 'Fai swipe destra per mantenere i video'
              : 'Fai swipe destra per mantenere le foto',
          style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.25), fontSize: 13),
        ),
      ]),
    ),
  );

  // ── Grid ──────────────────────────────────────────────────────────────────

  Widget _grid(List<PhotoItem> items) => Expanded(
    child: GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => RepaintBoundary(child: _gridItem(items[i])),
    ),
  );

  Widget _gridItem(PhotoItem item) => Obx(() {
    final isSelected = controller.selectedIds.contains(item.id);
    final sColor     = PhotoService.sizeColor(item.sizeBytes);
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (!controller.isSelecting.value) controller.isSelecting.value = true;
        controller.toggleSelect(item.id);
      },
      onTap: () {
        if (controller.isSelecting.value) {
          controller.toggleSelect(item.id);
          return;
        }
        // ── tap: video → player, foto → dettaglio ──────────────────────────
        if (isVideo) {
          Get.to(() => VideoPlayerView(item: item));
        } else {
          PhotoDetailView.open(
            item: item,
            loadFull: controller.loadFull,
            actions: [
              detailAction(
                label: 'Rimuovi', color: Colors.white70,
                icon: FluentIcons.dismiss_20_filled,
                onTap: () { Get.back(); controller.unkepSingle(item.id); },
              ),
              detailAction(
                label: 'Cestino', color: const Color(0xFFFF3B30),
                icon: FluentIcons.delete_20_filled,
                onTap: () { Get.back(); controller.moveSingleToTrash(item.id); },
              ),
            ],
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? const Color(0xFF34C759) : Colors.transparent,
              width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(fit: StackFit.expand, children: [
            // thumbnail
            item.thumbnail != null
                ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover,
                    cacheWidth: 200)
                : const ShimmerBox(),

            // badge play (solo video) o badge cuore (foto)
            Positioned(top: 6, left: 6,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle),
                child: Icon(
                  isVideo
                      ? FluentIcons.play_20_filled
                      : FluentIcons.heart_20_filled,
                  color: const Color(0xFF34C759), size: 12,
                ),
              ),
            ),

            // checkbox selezione
            if (controller.isSelecting.value)
              Positioned(top: 6, right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF34C759)
                        : Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(FluentIcons.checkmark_20_filled,
                          color: Colors.white, size: 12)
                      : null,
                ),
              ),

            // dimensione
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent,
                        Colors.black.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(PhotoService.formatBytes(item.sizeBytes),
                    style: TextStyle(color: sColor, fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  });

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _bottomBar(List<PhotoItem> items) => Obx(() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: Get.theme.scaffoldBackgroundColor,
      border: Border(top: BorderSide(
          color: Get.theme.dividerColor)),
    ),
    child: controller.isSelecting.value && controller.selectedIds.isNotEmpty
        ? _selectionActions()
        : _defaultActions(items),
  ));

  Widget _defaultActions(List<PhotoItem> items) => Row(children: [
    Expanded(child: _btn(
      label: 'Cestino tutto', icon: FluentIcons.delete_20_filled,
      color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7), bg: Get.theme.cardColor,
      onTap: () => _confirmTrashAll(items),
    )),
    const SizedBox(width: 12),
    Expanded(child: _btn(
      label: 'Rimanda in coda', icon: FluentIcons.replay_20_filled,
      color: Get.theme.colorScheme.onSurface, bg: Get.theme.cardColor,
      onTap: _confirmUnkeepAll,
    )),
  ]);

  Widget _selectionActions() => Row(children: [
    Expanded(child: _btn(
      label: 'Rimanda in coda', icon: FluentIcons.replay_20_filled,
      color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7), bg: Get.theme.cardColor,
      onTap: controller.unkepSelected,
    )),
    const SizedBox(width: 12),
    Expanded(child: Obx(() => _btn(
      label: 'Cestino (${controller.selectedIds.length})',
      icon: FluentIcons.delete_20_filled,
      color: Colors.white, bg: const Color(0xFFFF3B30),
      onTap: controller.moveSelectedToTrash,
    ))),
  ]);

  Widget _btn({required String label, required IconData icon,
      required Color color, required Color bg,
      required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(label,
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _confirmTrashAll(List<PhotoItem> items) => Get.dialog(AlertDialog(
    backgroundColor: Get.theme.cardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('Manda tutto nel cestino', style: TextStyle(
        color: Get.theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
    content: Text('Sposterai ${items.length} elementi nel cestino.',
        style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14, height: 1.5)),
    actions: [
      TextButton(onPressed: Get.back,
          child: Text('Annulla', style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600))),
      TextButton(
        onPressed: () {
          Get.back();
          controller.selectAll();
          controller.moveSelectedToTrash();
        },
        child: const Text('Sposta', style: TextStyle(
            color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
      ),
    ],
  ));

  void _confirmUnkeepAll() => Get.dialog(AlertDialog(
    backgroundColor: Get.theme.cardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('Rimanda tutto in coda', style: TextStyle(
        color: Get.theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
    content: Text('Tutti gli elementi torneranno in coda.',
        style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14, height: 1.5)),
    actions: [
      TextButton(onPressed: Get.back,
          child: Text('Annulla', style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600))),
      TextButton(
        onPressed: () { Get.back(); controller.unkepAll(); },
        child: const Text('Rimanda', style: TextStyle(
            color: Colors.orange, fontWeight: FontWeight.w700)),
      ),
    ],
  ));
}