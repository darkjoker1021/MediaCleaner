import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/data/service/duplicate_service.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/duplicate/controllers/duplicates_controller.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';

class DuplicatesView extends GetView<DuplicatesController> {
  const DuplicatesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        body: SafeArea(
          child: Obx(() {
            if (controller.isScanning.value) return _scanning();
            return Column(children: [
              _appBar(),
              if (controller.groups.isEmpty)
                _emptyState()
              else ...[
                _summary(),
                Expanded(child: _groupList()),
                _bottomBar(),
              ],
            ]);
          }),
        ),
      ),
    );
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  Widget _scanning() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 44, height: 44,
        child: CircularProgressIndicator(
            color: Color(0xFFFF9F0A), strokeWidth: 2.5)),
      const SizedBox(height: 20),
      const Text('Analisi in corso...', style: TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Ricerca duplicati per dimensione e data',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
    ]),
  );

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar() => Padding(
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
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Duplicati', style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(width: 8),
          Obx(() => controller.groups.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${controller.groups.length} gruppi',
                      style: const TextStyle(color: Color(0xFFFF9F0A),
                          fontSize: 11, fontWeight: FontWeight.w700)),
                )
              : const SizedBox.shrink()),
        ]),
        Obx(() => Text(
          controller.groups.isEmpty
              ? 'Nessun duplicato trovato'
              : '${controller.totalDuplicateCount} copie · '
                '${PhotoService.formatBytes(controller.totalWasteBytes)} recuperabili',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        )),
      ])),
      // Ri-scansiona
      GestureDetector(
        onTap: controller.scan,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(FluentIcons.arrow_sync_20_filled, color: Colors.white70, size: 20),
        ),
      ),
    ]),
  );

  // ── Summary banner ────────────────────────────────────────────────────────

  Widget _summary() => Obx(() {
    final selected = controller.selectedIds.length;
    final waste    = controller.selectedWasteBytes;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(FluentIcons.delete_20_filled,
            color: Color(0xFFFF9F0A), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$selected copie selezionate',
              style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w700)),
          if (waste > 0)
            Text('${PhotoService.formatBytes(waste)} da liberare',
                style: const TextStyle(color: Color(0xFFFF9F0A), fontSize: 11)),
        ])),
        // Seleziona tutto / Deseleziona
        GestureDetector(
          onTap: () {
            if (controller.selectedIds.length == controller.totalDuplicateCount) {
              controller.clearSelection();
            } else {
              controller.selectAllDuplicates();
            }
          },
          child: Obx(() => Text(
            controller.selectedIds.length == controller.totalDuplicateCount
                ? 'Deseleziona' : 'Seleziona tutti',
            style: const TextStyle(color: Color(0xFFFF9F0A),
                fontSize: 12, fontWeight: FontWeight.w700),
          )),
        ),
      ]),
    );
  });

  // ── Lista gruppi ──────────────────────────────────────────────────────────

  Widget _groupList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    itemCount: controller.groups.length,
    itemBuilder: (ctx, i) => _groupCard(ctx, controller.groups[i]),
  );

  Widget _groupCard(BuildContext context, DuplicateGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header gruppo
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${group.count} copie',
                  style: const TextStyle(color: Color(0xFFFF9F0A),
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('· ${PhotoService.formatBytes(group.wasteBytes)} spreco',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const Spacer(),
            Text(_fmtDate(group.best.createdAt),
                style: const TextStyle(color: Colors.white30, fontSize: 11)),
          ]),
        ),
        // Griglia foto del gruppo
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            itemCount: group.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final item   = group.items[i];
              final isBest = item.id == group.best.id;
              return Obx(() {
                final isSelected = controller.selectedIds.contains(item.id);
                return GestureDetector(
                  onTap: () {
                    if (isBest) {
                      // Tap sul best → apri dettaglio
                      PhotoDetailView.open(
                        item: item,
                        loadFull: controller.loadFull,
                      );
                    } else {
                      controller.toggleSelect(item.id, group);
                    }
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    PhotoDetailView.open(
                      item: item,
                      loadFull: controller.loadFull,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isBest
                            ? const Color(0xFF34C759).withValues(alpha: 0.6)
                            : isSelected
                                ? const Color(0xFFFF3B30).withValues(alpha: 0.7)
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(fit: StackFit.expand, children: [
                        item.thumbnail != null
                          ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover)
                            : Container(color: const Color(0xFF1A1C23)),

                        // Badge ORIGINALE / DA ELIMINARE
                        Positioned(top: 4, left: 0, right: 0,
                          child: Center(child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBest
                                  ? const Color(0xFF34C759).withValues(alpha: 0.85)
                                  : Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isBest ? 'ORIGINALE' : 'COPIA',
                              style: TextStyle(
                                color: isBest ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                fontSize: 8, fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          )),
                        ),

                        // Checkbox selezione (solo duplicati)
                        if (!isBest)
                          Positioned(bottom: 4, right: 4,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFF3B30)
                                    : Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white60, width: 1.2),
                              ),
                              child: isSelected
                                  ? const Icon(FluentIcons.check_20_filled,
                                      color: Colors.white, size: 11)
                                  : null,
                            ),
                          ),

                        // Dimensione
                        Positioned(bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.only(
                                bottom: 4, left: 4, right: 4, top: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent,
                                    Colors.black.withValues(alpha: 0.65)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Text(
                              PhotoService.formatBytes(item.sizeBytes),
                              style: TextStyle(
                                  color: PhotoService.sizeColor(item.sizeBytes),
                                  fontSize: 8, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ]),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: const Icon(FluentIcons.checkmark_circle_20_filled,
              color: Color(0xFF34C759), size: 32),
        ),
        const SizedBox(height: 16),
        const Text('Nessun duplicato', style: TextStyle(
            color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('La libreria è pulita',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 13)),
        const SizedBox(height: 24),
        Text('Nota: la scansione si basa su\ndimensione e data. Ricarica dopo\naver risolto tutte le dimensioni.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2), fontSize: 11,
                height: 1.6)),
      ]),
    ),
  );

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _bottomBar() => Obx(() {
    final count = controller.selectedIds.length;
    final bytes = controller.selectedWasteBytes;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        border: Border(top: BorderSide(
            color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: GestureDetector(
        onTap: count > 0 ? _confirmMoveToTrash : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: count > 0
                ? const Color(0xFFFF3B30)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(FluentIcons.delete_20_filled,
                color: count > 0 ? Colors.white : Colors.white30, size: 20),
            const SizedBox(width: 10),
            Text(
              count > 0
                  ? 'Manda nel cestino ($count copie · ${PhotoService.formatBytes(bytes)})'
                  : 'Seleziona le copie da eliminare',
              style: TextStyle(
                  color: count > 0 ? Colors.white : Colors.white30,
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ]),
        ),
      ),
    );
  });

  void _confirmMoveToTrash() {
    final count = controller.selectedIds.length;
    final bytes = controller.selectedWasteBytes;
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF1C1E27),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Manda nel cestino', style: TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      content: Text(
        'Sposterai $count copie nel cestino.\n'
        '${PhotoService.formatBytes(bytes)} recuperabili.\n\n'
        'Non verranno eliminate finché non svuoti il cestino.',
        style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: const Text('Annulla',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            controller.moveSelectedToTrash();
          },
          child: const Text('Manda nel cestino', style: TextStyle(
              color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  String _fmtDate(DateTime dt) =>
      '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  String _p(int n) => n.toString().padLeft(2, '0');
}