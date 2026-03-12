import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/core/widgets/swipe_card.dart';
import 'home_done_screen.dart';

/// Card swiper usato nel tab foto di [HomeView].
/// Mostra [HomeDoneScreen] quando non ci sono più elementi pendenti.
class HomePhotoSwiper extends StatefulWidget {
  const HomePhotoSwiper({super.key});

  @override
  State<HomePhotoSwiper> createState() => _HomePhotoSwiperState();
}

class _HomePhotoSwiperState extends State<HomePhotoSwiper> {
  late final HomeController      _ctrl;
  late final CardSwiperController _sc;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<HomeController>();
    _sc   = CardSwiperController();
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
      // Dipende da allItems (per thumbnail aggiornate) e currentSort
      _ctrl.currentSort.value;
      final allItems = _ctrl.allItems;
      final pending  = _ctrl.pendingItems;

      if (pending.isEmpty) return const HomeDoneScreen();

      // FIX: indice O(1) su allItems costruito UNA VOLTA per rebuild,
      // non O(n) dentro cardBuilder per ogni card.
      final allItemsIndex = <String, int>{
        for (var i = 0; i < allItems.length; i++) allItems[i].id: i,
      };

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

          // FIX: lookup O(1) invece di firstWhereOrNull O(n) per ogni card.
          // Usa l'elemento aggiornato da allItems (thumbnail fresca),
          // fallback allo stale se l'id non è più presente.
          final idx  = allItemsIndex[stale.id];
          final item = idx != null ? allItems[idx] : stale;

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