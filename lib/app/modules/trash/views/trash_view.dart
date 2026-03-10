import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/trash/controllers/trash_controller.dart';
import 'package:media_cleaner/app/modules/video/views/video_player_view.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';

class TrashView extends GetView<TrashController> {
  /// [isVideo] = true  → apre VideoPlayerView al tap, mostra badge play
  /// [isVideo] = false → apre PhotoDetailView al tap  (default)
  final bool isVideo;
  const TrashView({super.key, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        body: SafeArea(
          child: Obx(() {
            final trash = controller.trashItems;
            return Column(children: [
              _appBar(trash),
              if (controller.isSelecting.value && trash.isNotEmpty)
                _selectAllRow(trash),
              trash.isEmpty ? _emptyState() : _grid(trash),
              if (trash.isNotEmpty) _bottomBar(trash),
            ]);
          }),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar(List<PhotoItem> trash) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: Get.back,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(FluentIcons.arrow_left_20_filled,
              color: Colors.white70, size: 17),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              isVideo ? 'Cestino video' : 'Cestino',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${trash.length}', style: const TextStyle(
                  color: Color(0xFFFF3B30), fontSize: 12,
                  fontWeight: FontWeight.w700)),
            ),
          ]),
          Text('${PhotoService.formatBytes(controller.trashBytes)} totali',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      )),
      if (trash.isNotEmpty)
        GestureDetector(
          onTap: controller.toggleSelectionMode,
          child: Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: controller.isSelecting.value
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: controller.isSelecting.value
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.3)
                  : Colors.transparent),
            ),
            child: Text(
              controller.isSelecting.value ? 'Annulla' : 'Seleziona',
              style: TextStyle(
                  color: controller.isSelecting.value
                      ? const Color(0xFFFF3B30) : Colors.white70,
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          )),
        ),
    ]),
  );

  // ── Select all ────────────────────────────────────────────────────────────

  Widget _selectAllRow(List<PhotoItem> trash) => Padding(
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
                  ? const Color(0xFFFF3B30) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: controller.allSelected
                      ? const Color(0xFFFF3B30) : Colors.white30,
                  width: 1.5),
            ),
            child: controller.allSelected
                ? const Icon(FluentIcons.checkmark_20_filled,
                    color: Colors.white, size: 13)
                : null,
          ),
          const SizedBox(width: 10),
          Text('Seleziona tutto (${trash.length})',
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ])),
      ),
      const Spacer(),
      Obx(() => controller.selectedIds.isNotEmpty
          ? Text('${controller.selectedIds.length} selezionati',
              style: const TextStyle(color: Color(0xFFFF3B30),
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
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle),
          child: Icon(
            isVideo ? FluentIcons.video_20_filled : FluentIcons.delete_20_filled,
            color: Colors.white24, size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isVideo ? 'Cestino video vuoto' : 'Cestino vuoto',
          style: const TextStyle(
              color: Colors.white54, fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          isVideo
              ? 'I video scartati appariranno qui'
              : 'Le foto scartate appariranno qui',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
        ),
      ]),
    ),
  );

  // ── Grid ──────────────────────────────────────────────────────────────────

  Widget _grid(List<PhotoItem> trash) => Expanded(
    child: GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: trash.length,
      itemBuilder: (ctx, i) => _gridItem(trash[i]),
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
                label: 'Ripristina', color: const Color(0xFF34C759),
                icon: FluentIcons.arrow_undo_20_filled,
                onTap: () { Get.back(); controller.restoreSingle(item.id); },
              ),
              detailAction(
                label: 'Elimina', color: const Color(0xFFFF3B30),
                icon: FluentIcons.delete_20_filled,
                onTap: () { Get.back(); _confirmDelete([item.id]); },
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
              color: isSelected ? const Color(0xFFFF3B30) : Colors.transparent,
              width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(fit: StackFit.expand, children: [
            // thumbnail
            item.thumbnail != null
                ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF1A1C23)),

            // badge play overlay (solo video)
            if (isVideo)
              Center(
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle),
                  child: const Icon(FluentIcons.play_20_filled,
                      color: Colors.white, size: 16),
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
                        ? const Color(0xFFFF3B30)
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

  Widget _bottomBar(List<PhotoItem> trash) => Obx(() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D0F14),
      border: Border(top: BorderSide(
          color: Colors.white.withValues(alpha: 0.07))),
    ),
    child: controller.isSelecting.value && controller.selectedIds.isNotEmpty
        ? _selectionActions()
        : _defaultActions(trash),
  ));

  Widget _defaultActions(List<PhotoItem> trash) => Row(children: [
    Expanded(child: _btn(
      label: 'Ripristina tutto',
      icon: FluentIcons.arrow_undo_20_filled,
      color: Colors.white70, bg: Colors.white.withValues(alpha: 0.07),
      onTap: controller.restoreAll,
    )),
    const SizedBox(width: 12),
    Expanded(child: _btn(
      label: 'Elimina tutto',
      icon: FluentIcons.delete_20_filled,
      color: Colors.white, bg: const Color(0xFFFF3B30),
      onTap: () => _confirmDelete(trash.map((e) => e.id).toList()),
    )),
  ]);

  Widget _selectionActions() => Row(children: [
    Expanded(child: _btn(
      label: 'Ripristina',
      icon: FluentIcons.arrow_undo_20_filled,
      color: Colors.white70, bg: Colors.white.withValues(alpha: 0.07),
      onTap: controller.restoreSelected,
    )),
    const SizedBox(width: 12),
    Expanded(child: Obx(() => _btn(
      label: 'Elimina (${controller.selectedIds.length})',
      icon: FluentIcons.delete_20_filled,
      color: Colors.white, bg: const Color(0xFFFF3B30),
      onTap: () => _confirmDelete(controller.selectedIds.toList()),
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

  void _confirmDelete(List<String> ids) => Get.dialog(AlertDialog(
    backgroundColor: const Color(0xFF1C1E27),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Elimina definitivamente', style: TextStyle(
        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
    content: Text(
      'Stai per eliminare ${ids.length} '
      '${isVideo ? (ids.length == 1 ? "video" : "video") : (ids.length == 1 ? "foto" : "foto")} '
      'in modo permanente.\nQuesta azione non può essere annullata.',
      style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
    ),
    actions: [
      TextButton(onPressed: Get.back,
          child: const Text('Annulla', style: TextStyle(
              color: Colors.white54, fontWeight: FontWeight.w600))),
      TextButton(
        onPressed: () async {
          Get.back();
          final freed = ids.length == controller.trashItems.length
              ? await controller.deleteAll()
              : await controller.deleteSelected();
          if (freed > 0) {
            Get.snackbar(
              isVideo ? '🗑 Video eliminati' : '🗑 Eliminate',
              'Liberati ${PhotoService.formatBytes(freed)}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor:
                  const Color(0xFFFF3B30).withValues(alpha: 0.9),
              colorText: Colors.white,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              borderRadius: 14,
            );
          }
        },
        child: const Text('Elimina', style: TextStyle(
            color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
      ),
    ],
  ));
}