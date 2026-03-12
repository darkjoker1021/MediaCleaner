import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/media_app_bar.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/modules/social/controllers/social_controller.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';
import 'package:media_cleaner/core/widgets/shimmer_box.dart';

class SocialView extends GetView<SocialController> {
  const SocialView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const _SocialShimmer();
            }
            final items = controller.items;
            return Column(children: [
              _appBar(context, items),
              if (controller.isSelecting.value && items.isNotEmpty)
                _selectAllRow(items),
              items.isEmpty ? _emptyState() : _groupedContent(items),
              if (controller.hasMoreToDisplay) _loadMoreBanner(items.length),
              if (items.isNotEmpty) _bottomBar(items),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, List<PhotoItem> items) => MediaAppBar(
    title: 'Media Social',
    subtitle: Text(
      '${items.length} elementi · ${PhotoService.formatBytes(items.fold(0, (s, e) => s + e.sizeBytes))}',
      style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
    ),
    onRescan: controller.load,
    selectButton: items.isNotEmpty
        ? SelectToggleButton(
            isSelecting: controller.isSelecting,
            onTap: controller.toggleSelectionMode,
            accentColor: const Color(0xFF34C759),
          )
        : null,
  );

  Widget _selectAllRow(List<PhotoItem> items) => Padding(
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
              color: controller.allSelected ? const Color(0xFF34C759) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: controller.allSelected ? const Color(0xFF34C759) : Get.theme.dividerColor,
                  width: 1.5)),
            child: controller.allSelected
                ? const Icon(FluentIcons.checkmark_20_filled, color: Colors.white, size: 13) : null,
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

  Widget _emptyState() => Expanded(
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: Get.theme.colorScheme.secondary,
              shape: BoxShape.circle),
          child: const Icon(FluentIcons.chat_20_filled, color: Color(0xFF34C759), size: 32)),
        const SizedBox(height: 16),
        Text('Nessun media da app social',
            style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Nessuna foto da WhatsApp, Telegram, ecc.',
            style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.25), fontSize: 13)),
      ]),
    ),
  );

  Widget _groupedContent(List<PhotoItem> items) => Expanded(
    child: Obx(() {
      final grouped = controller.groupedVisibleItems;
      final appNames = grouped.keys.toList();
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: appNames.length,
        itemBuilder: (context, i) {
          final appName = appNames[i];
          final groupItems = grouped[appName]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, appName, groupItems),
              const SizedBox(height: 8),
              _sectionGrid(groupItems),
              const SizedBox(height: 16),
            ],
          );
        },
      );
    }),
  );

  Widget _sectionHeader(BuildContext context, String appName, List<PhotoItem> groupItems) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF34C759).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(appName, style: const TextStyle(
            color: Color(0xFF34C759), fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 8),
      Text('${groupItems.length} foto',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
      const Spacer(),
      Text(PhotoService.formatBytes(groupItems.fold(0, (s, e) => s + e.sizeBytes)),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
    ],
  );

  Widget _sectionGrid(List<PhotoItem> groupItems) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
    itemCount: groupItems.length,
    itemBuilder: (context, i) => RepaintBoundary(child: _gridItem(groupItems[i])),
  );

  Widget _gridItem(PhotoItem item) => Obx(() {
    final isSelected  = controller.selectedIds.contains(item.id);
    final appLabel    = controller.sourceApp(item);
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
              final r = await controller.loadFullThumb(it);
              return r.thumbnail;
            },
            actions: [
              detailAction(
                label: 'Cestino', color: const Color(0xFFFF3B30),
                icon: FluentIcons.delete_20_filled,
                onTap: () { Get.back(); controller.moveToTrash(item.id); },
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
              width: 2.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(fit: StackFit.expand, children: [
            item.thumbnail != null
                ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover,
                    cacheWidth: 200)
                : const ShimmerBox(),
            // Source app badge
            Positioned(top: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(appLabel,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 8, fontWeight: FontWeight.w800)),
              ),
            ),
            if (controller.isSelecting.value)
              Positioned(top: 6, right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF34C759)
                        : Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5)),
                  child: isSelected ? const Icon(FluentIcons.checkmark_20_filled,
                      color: Colors.white, size: 12) : null,
                ),
              ),
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: Text(PhotoService.formatBytes(item.sizeBytes),
                    style: TextStyle(color: PhotoService.sizeColor(item.sizeBytes),
                        fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  });

  Widget _loadMoreBanner(int total) => GestureDetector(
    onTap: controller.loadAll,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(FluentIcons.arrow_clockwise_20_filled,
            color: Color(0xFF34C759), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mostrate le prime ${SocialController.pageSize} di $total foto · Tocca per mostrare tutto',
            style: const TextStyle(color: Color(0xFF34C759), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    ),
  );

  Widget _bottomBar(List<PhotoItem> items) => Obx(() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: Get.theme.scaffoldBackgroundColor,
      border: Border(top: BorderSide(color: Get.theme.dividerColor))),
    child: controller.isSelecting.value && controller.selectedIds.isNotEmpty
        ? Row(children: [
            Expanded(child: _btn('Annulla', FluentIcons.dismiss_20_filled,
                Get.theme.colorScheme.onSurface.withValues(alpha: 0.7), Get.theme.colorScheme.secondary,
                controller.toggleSelectionMode)),
            const SizedBox(width: 12),
            Expanded(child: _btn(
              'Cestino (${controller.selectedIds.length})',
              FluentIcons.delete_20_filled, Colors.white, const Color(0xFFFF3B30),
              () {
                final count = controller.moveSelectedToTrash();
                Get.snackbar('Spostati nel cestino', '$count media social',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.88),
                  colorText: Colors.white, margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  borderRadius: 14);
              },
            )),
          ])
        : Row(children: [
            Expanded(child: _btn('Aggiorna', FluentIcons.arrow_clockwise_20_filled,
                Get.theme.colorScheme.onSurface.withValues(alpha: 0.7), Get.theme.colorScheme.secondary, controller.load)),
            const SizedBox(width: 12),
            Expanded(child: _btn('Cestino tutto', FluentIcons.delete_20_filled,
                Colors.white, const Color(0xFFFF3B30), () {
              if (items.isEmpty) return;
              final moved = controller.moveAllToTrash();
              Get.snackbar('Spostati nel cestino', '$moved media social',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.88),
                colorText: Colors.white, margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                borderRadius: 14);
            })),
          ]),
  ));

  Widget _btn(String label, IconData icon, Color color, Color bg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

// ── Shimmer skeleton shown while SocialController.load() is running ──────────

class _SocialShimmer extends StatelessWidget {
  const _SocialShimmer();

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fake app-bar area
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            ShimmerBox(borderRadius: 8, height: 18, width: 120),
            const Spacer(),
            ShimmerBox(borderRadius: 8, height: 18, width: 60),
          ]),
        ),
        // Fake section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: ShimmerBox(borderRadius: 8, height: 28, width: 100),
        ),
        // Fake 3-col grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: 18,
              itemBuilder: (_, _) => ShimmerBox(borderRadius: 6),
            ),
          ),
        ),
        // Fake bottom bar
        Container(
          height: 74,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: th.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: th.dividerColor)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(children: [
            Expanded(child: ShimmerBox(borderRadius: 14)),
            const SizedBox(width: 12),
            Expanded(child: ShimmerBox(borderRadius: 14)),
          ]),
        ),
      ],
    );
  }
}
