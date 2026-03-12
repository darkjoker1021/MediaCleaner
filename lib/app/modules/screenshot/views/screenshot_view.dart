import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';

import '../controllers/screenshot_controller.dart';

class ScreenshotView extends GetView<ScreenshotController> {
  const ScreenshotView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: Lottie.asset('assets/lottie/search.json')
              );
            }

            final items = controller.screenshots;
            return Column(
              children: [
                _appBar(items),
                if (controller.isSelecting.value && items.isNotEmpty)
                  _selectAllRow(items),
                items.isEmpty ? _emptyState() : _grid(items),
                if (items.isNotEmpty) _bottomBar(items),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _appBar(List<PhotoItem> items) => MediaAppBar(
    title: 'Screenshot',
    subtitle: Text(
      '${items.length} elementi · ${PhotoService.formatBytes(items.fold(0, (s, e) => s + e.sizeBytes))}',
      style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
    ),
    selectButton: items.isNotEmpty
        ? SelectToggleButton(
            isSelecting: controller.isSelecting,
            onTap: controller.toggleSelectionMode,
            accentColor: const Color(0xFF0A84FF),
          )
        : null,
  );

  Widget _selectAllRow(List<PhotoItem> items) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => controller.allSelected
              ? controller.clearSelection()
              : controller.selectAll(),
          child: Obx(
            () => Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: controller.allSelected
                        ? const Color(0xFF0A84FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: controller.allSelected
                          ? const Color(0xFF0A84FF)
                          : Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: controller.allSelected
                      ? const Icon(
                          FluentIcons.checkmark_20_filled,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  'Seleziona tutto (${items.length})',
                  style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Obx(
          () => controller.selectedIds.isNotEmpty
              ? Text(
                  '${controller.selectedIds.length} selezionati',
                  style: const TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FluentIcons.scan_camera_20_filled,
              color: Color(0xFF5AC8FA),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuno screenshot da revisionare',
            style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gli screenshot in cestino o mantenuti non compaiono qui',
            style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _grid(List<PhotoItem> items) => Expanded(
    child: GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => RepaintBoundary(child: _gridItem(items[i])),
    ),
  );

  Widget _gridItem(PhotoItem item) => Obx(() {
    final isSelected = controller.selectedIds.contains(item.id);
    final sColor = PhotoService.sizeColor(item.sizeBytes);
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
            color: isSelected ? const Color(0xFF0A84FF) : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              item.thumbnail != null
                  ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover,
                      cacheWidth: 200)
                  : Container(color: const Color(0xFF1A1C23)),
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
                          ? const Color(0xFF0A84FF)
                          : Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: isSelected
                        ? const Icon(
                            FluentIcons.checkmark_20_filled,
                            color: Colors.white,
                            size: 12,
                          )
                        : null,
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    PhotoService.formatBytes(item.sizeBytes),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });

  Widget _bottomBar(List<PhotoItem> items) => Obx(
    () => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Get.theme.dividerColor)),
      ),
      child: controller.isSelecting.value && controller.selectedIds.isNotEmpty
          ? _selectionActions()
          : _defaultActions(items),
    ),
  );

  Widget _defaultActions(List<PhotoItem> items) => Row(
    children: [
      Expanded(
        child: _btn(
          label: 'Aggiorna lista',
          icon: FluentIcons.arrow_clockwise_20_filled,
          color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
          bg: Get.theme.cardColor,
          onTap: controller.loadScreenshots,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _btn(
          label: 'Cestino tutto',
          icon: FluentIcons.delete_20_filled,
          color: Colors.white,
          bg: const Color(0xFFFF3B30),
          onTap: () {
            if (items.isEmpty) return;
            final moved = controller.moveAllToTrash();
            if (moved <= 0) return;
            Get.snackbar(
              'Spostati nel cestino',
              '$moved screenshot',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.88),
              colorText: Colors.white,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              borderRadius: 14,
            );
          },
        ),
      ),
    ],
  );

  Widget _selectionActions() => Row(
    children: [
      Expanded(
        child: _btn(
          label: 'Annulla',
          icon: FluentIcons.dismiss_20_filled,
          color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
          bg: Get.theme.cardColor,
          onTap: controller.toggleSelectionMode,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Obx(
          () => _btn(
            label: 'Cestino (${controller.selectedIds.length})',
            icon: FluentIcons.delete_20_filled,
            color: Colors.white,
            bg: const Color(0xFFFF3B30),
            onTap: () {
              final moved = controller.moveSelectedToTrash();
              if (moved <= 0) return;
              Get.snackbar(
                'Spostati nel cestino',
                '$moved screenshot',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor:
                    const Color(0xFFFF3B30).withValues(alpha: 0.88),
                colorText: Colors.white,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                borderRadius: 14,
              );
            },
          ),
        ),
      ),
    ],
  );

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

