import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/core/widgets/swipe_card.dart';
import 'home_done_screen.dart';

/// Card swiper used in the photo tab of [HomeView].
/// Shows [HomeDoneScreen] when no pending items remain.
class HomePhotoSwiper extends StatefulWidget {
  const HomePhotoSwiper({super.key});

  @override
  State<HomePhotoSwiper> createState() => _HomePhotoSwiperState();
}

class _HomePhotoSwiperState extends State<HomePhotoSwiper> {
  late final HomeController _ctrl;
  late final CardSwiperController _sc;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<HomeController>();
    _sc = CardSwiperController();
    _ctrl.attachSwiperUndo(() => _sc.undo());
  }

  @override
  void dispose() {
    _ctrl.detachSwiperUndo();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Track allItems and currentSort so any change triggers a rebuild
      final pending = _ctrl.pendingItems;
      _ctrl.currentSort.value;

      if (pending.isEmpty) return const HomeDoneScreen();

      final key = '${pending.length}_${_ctrl.currentSort.value.index}';
      return CardSwiper(
        key: ValueKey(key),
        controller: _sc,
        cardsCount: pending.length,
        numberOfCardsDisplayed: pending.length >= 3 ? 3 : pending.length,
        backCardOffset: const Offset(0, 26),
        scale: 0.93,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        allowedSwipeDirection:
            const AllowedSwipeDirection.only(left: true, right: true),
        onSwipe: (prevIdx, currIdx, direction) async {
          if (prevIdx >= pending.length) return true;
          final item = pending[prevIdx];
          if (direction == CardSwiperDirection.left) {
            HapticFeedback.mediumImpact();
            _ctrl.moveToTrash(item.id);
          } else if (direction == CardSwiperDirection.right) {
            HapticFeedback.lightImpact();
            _ctrl.keepPhoto(item.id);
          }
          return true;
        },
        cardBuilder: (context, index, hThreshold, vThreshold) {
          if (index >= pending.length) return const SizedBox.shrink();
          final stale = pending[index];
          final item =
              _ctrl.allItems.firstWhereOrNull((p) => p.id == stale.id) ??
                  stale;
          return SwipeCard(
            item: item,
            hThreshold: hThreshold.toDouble(),
            onTap: () => PhotoDetailView.open(
              item: item,
              loadFull: (photo) async {
                final result = await _ctrl.resolveFullThumb(photo);
                return result.thumbnail;
              },
              actions: [
                detailAction(
                  label: 'Cestino',
                  color: const Color(0xFFFF3B30),
                  icon: FluentIcons.delete_20_filled,
                  onTap: () {
                    Get.back();
                    _ctrl.moveToTrash(item.id);
                  },
                ),
                detailAction(
                  label: 'Mantieni',
                  color: const Color(0xFF34C759),
                  icon: FluentIcons.heart_20_filled,
                  onTap: () {
                    Get.back();
                    _ctrl.keepPhoto(item.id);
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
