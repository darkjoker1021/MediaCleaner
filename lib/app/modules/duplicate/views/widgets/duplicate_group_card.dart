import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/duplicate/controllers/duplicates_controller.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/service/duplicate_service.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';
import 'package:media_cleaner/core/widgets/shimmer_box.dart';

class DuplicateGroupCard extends StatelessWidget {
  const DuplicateGroupCard({super.key, required this.group});

  final DuplicateGroup group;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DuplicatesController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Get.theme.dividerColor),
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
                style: TextStyle(
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 11)),
            const Spacer(),
            Text(_fmtDate(group.best.createdAt),
                style: TextStyle(
                    color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 11)),
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
                final isSelected = ctrl.selectedIds.contains(item.id);
                return GestureDetector(
                  onTap: () {
                    if (isBest) {
                      PhotoDetailView.open(
                        item: item,
                        loadFull: ctrl.loadFull,
                      );
                    } else {
                      ctrl.toggleSelect(item.id, group);
                    }
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    PhotoDetailView.open(
                      item: item,
                      loadFull: ctrl.loadFull,
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
                            ? SafeMemoryImage(
                                bytes: item.thumbnail!,
                                fit: BoxFit.cover,
                                cacheWidth: 150)
                            : const ShimmerBox(),

                        // Badge ORIGINALE / COPIA
                        Positioned(
                          top: 4, left: 0, right: 0,
                          child: Center(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBest
                                  ? const Color(0xFF34C759).withValues(alpha: 0.85)
                                  : Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isBest ? 'ORIGINALE' : 'COPIA',
                              style: TextStyle(
                                color: isBest
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          )),
                        ),

                        // Checkbox selezione (solo duplicati)
                        if (!isBest)
                          Positioned(
                            bottom: 4, right: 4,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFF3B30)
                                    : Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white60, width: 1.2),
                              ),
                              child: isSelected
                                  ? const Icon(FluentIcons.check_20_filled,
                                      color: Colors.white, size: 11)
                                  : null,
                            ),
                          ),

                        // Dimensione
                        Positioned(
                          bottom: 0, left: 0, right: 0,
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
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700),
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

  String _fmtDate(DateTime dt) =>
      '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  String _p(int n) => n.toString().padLeft(2, '0');
}
