import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/service/blur_service.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';
import 'package:media_cleaner/core/widgets/shimmer_box.dart';

/// 3-column photo grid for [BlurView]. Each cell shows a quality-issue badge
/// and supports single tap (detail/select) and long-press (start selection).
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
    return Obx(() {
      final isSelected = controller.selectedIds.contains(item.id);
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF5AC8FA) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(fit: StackFit.expand, children: [
              item.thumbnail != null
                  ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover, cacheWidth: 200)
                  : const ShimmerBox(),
              // Quality issue badge
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: _issueColor(blurItem.issue).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _issueLabel(blurItem.issue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              // Selection indicator
              if (controller.isSelecting.value)
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5AC8FA)
                          : Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: isSelected
                        ? const Icon(FluentIcons.checkmark_20_filled, color: Colors.white, size: 12)
                        : null,
                  ),
                ),
              // Size label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    PhotoService.formatBytes(item.sizeBytes),
                    style: TextStyle(
                      color: PhotoService.sizeColor(item.sizeBytes),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Color _issueColor(QualityIssue issue) => switch (issue) {
    QualityIssue.blur        => Colors.purple,
    QualityIssue.dark        => Colors.amber.shade700,
    QualityIssue.overexposed => Colors.orange,
  };

  String _issueLabel(QualityIssue issue) => switch (issue) {
    QualityIssue.blur        => 'SFOCATA',
    QualityIssue.dark        => 'SCURA',
    QualityIssue.overexposed => 'SOVRAESPOST.',
  };
}
