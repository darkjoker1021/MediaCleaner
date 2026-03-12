import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/service/blur_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';
import 'package:media_cleaner/core/widgets/shimmer_box.dart';

/// Griglia foto 3 colonne per [BlurView].
class BlurGrid extends GetView<BlurController> {
  final List<BlurItem> items;

  const BlurGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => RepaintBoundary(
          child: _BlurGridItem(blurItem: items[i]),
        ),
      ),
    );
  }
}

class _BlurGridItem extends GetView<BlurController> {
  final BlurItem blurItem;
  const _BlurGridItem({required this.blurItem});

  @override
  Widget build(BuildContext context) {
    final item = blurItem.item;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (!controller.isSelecting.value) controller.isSelecting.value = true;
        controller.toggleSelect(item.id);
      },
      onTap: () {
        if (controller.isSelecting.value) {
          controller.toggleSelect(item.id);
        } else {
          PhotoDetailView.open(
            item: item,
            loadFull: (it) async {
              final resolved = await controller.loadFullThumb(it);
              return resolved.thumbnail;
            },
            actions: [
              detailAction(
                label: 'Cestino',
                color: const Color(0xFFFF3B30),
                icon: FluentIcons.delete_20_filled,
                onTap: () {
                  Get.back();
                  controller.moveToTrash(item.id);
                },
              ),
            ],
          );
        }
      },
      // FIX: Obx ora avvolge SOLO il bordo/overlay di selezione, non l'intera cella.
      // La thumbnail e il badge rimangono fuori dall'Obx e non vengono ricostruiti
      // ad ogni cambio di selectedIds — solo l'AnimatedContainer del bordo si aggiorna.
      child: Stack(fit: StackFit.expand, children: [
        // ── Thumbnail (stabile, fuori dall'Obx) ───────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.thumbnail != null
              ? SafeMemoryImage(
                  bytes: item.thumbnail!,
                  fit: BoxFit.cover,
                  cacheHeight: 300,
                )
              : const ShimmerBox(),
        ),

        // ── Badge issue (stabile) ──────────────────────────────────────────
        Positioned(
          bottom: 4,
          left: 4,
          child: _IssueBadge(issue: blurItem.issue),
        ),

        // ── Overlay selezione (unica parte reattiva) ──────────────────────
        Obx(() {
          final isSelected = controller.selectedIds.contains(item.id);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5AC8FA)
                    : Colors.transparent,
                width: 2.5,
              ),
              color: isSelected
                  ? const Color(0xFF5AC8FA).withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: isSelected
                ? const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(FluentIcons.checkmark_circle_20_filled,
                          color: Color(0xFF5AC8FA), size: 18),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      ]),
    );
  }
}

/// Badge colorato per il tipo di problema qualità.
class _IssueBadge extends StatelessWidget {
  final QualityIssue issue;
  const _IssueBadge({required this.issue});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (issue) {
      QualityIssue.blur        => ('Sfocata',     Colors.purple),
      QualityIssue.dark        => ('Scura',        Colors.amber),
      QualityIssue.overexposed => ('Sovraesposta', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 9,
              fontWeight: FontWeight.w700)),
    );
  }
}