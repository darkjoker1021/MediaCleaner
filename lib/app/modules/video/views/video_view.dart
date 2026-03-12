import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_cleaner/app/modules/shared/stats_bar.dart';
import 'package:media_cleaner/app/modules/shared/swipe_bottom_nav.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import 'package:media_cleaner/core/widgets/swipe_card.dart';

import '../controllers/video_controller.dart';
import 'video_player_view.dart';

class VideoView extends GetView<VideoController> {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          // L'Obx gestisce solo isLoading.
          // _VideoSwiperBody è un widget separato: il suo build() accede a
          // pendingVideos FUORI dall'Obx, così allItems.refresh() non distrugge
          // il CardSwiper ad ogni swipe.
          child: Obx(() {
            if (controller.isLoading.value) return _loader();
            return const _VideoSwiperBody();
          }),
        ),
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────────

  Widget _loader() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Lottie.asset('assets/lottie/search.json', width: 100, height: 100),
      const SizedBox(height: 20),
      Text('Caricamento video...',
          style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 14)),
    ]),
  );

  // ── Body / swiper ─────────────────────────────────────────────────────────
  // NOTA: _body() non è dentro l'Obx principale per evitare che
  // allItems.refresh() (ad ogni swipe) distrugga e ricrei il CardSwiper.

}

// ── Widget separato per il corpo del video swiper ────────────────────────────
// Stare fuori dall'Obx di VideoView evita che allItems.refresh() (ad ogni
// swipe) ricostruisca il CardSwiper.
class _VideoSwiperBody extends StatelessWidget {
  const _VideoSwiperBody();

  VideoController get _ctrl => Get.find<VideoController>();

  @override
  Widget build(BuildContext context) => Obx(() {
    final ctrl    = _ctrl;
    final pending = ctrl.pendingVideos;
    return Column(children: [
      StatsBar(ctrl: ctrl, pendingLabel: 'rimasti'),
      const SizedBox(height: 4),
      Expanded(child: pending.isEmpty ? _doneScreen(ctrl) : _swiper(ctrl, pending)),
      SwipeActionHints(ctrl: ctrl),
      SwipeBottomNav(
        ctrl: ctrl,
        keptLabel: 'Mantenuti',
        onKept: () => Get.toNamed(Routes.VIDEO_KEPT),
        onTrash: () => Get.toNamed(Routes.VIDEO_TRASH),
        onAfterUndo: () => Get.snackbar(
          'Azione annullata', '',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 900),
          backgroundColor: const Color(0xFF0A84FF).withValues(alpha: 0.88),
          colorText: Colors.white,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          messageText: const SizedBox.shrink(),
        ),
      ),
    ]);
  });

  Widget _swiper(VideoController ctrl, List<PhotoItem> pending) {
    return CardSwiper(
      key: ValueKey('${pending.length}_video'),
      cardsCount: pending.length,
      numberOfCardsDisplayed: pending.length >= 3 ? 3 : pending.length,
      backCardOffset: const Offset(0, 26),
      scale: 0.93,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true),
      onSwipe: (prevIdx, _, direction) async {
        final cur = ctrl.pendingVideos;
        if (prevIdx >= cur.length) return true;
        final item = cur[prevIdx];
        if (direction == CardSwiperDirection.left) {
          HapticFeedback.mediumImpact();
          ctrl.moveToTrash(item.id);
        } else if (direction == CardSwiperDirection.right) {
          HapticFeedback.lightImpact();
          ctrl.keepVideo(item.id);
        }
        return true;
      },
      cardBuilder: (context, index, hThreshold, _) {
        if (index >= pending.length) return const SizedBox.shrink();
        // Prende l'item più aggiornato (con thumbnail se già caricata)
        final stale = pending[index];
        final item  = ctrl.allItems.firstWhereOrNull((p) => p.id == stale.id) ?? stale;
        return SwipeCard(
          item: item,
          hThreshold: hThreshold.toDouble(),
          onTap: () => Get.to(() => VideoPlayerView(item: item)),
        );
      },
    );
  }

  Widget _doneScreen(VideoController ctrl) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.12),
              shape: BoxShape.circle),
          child: const Icon(FluentIcons.checkmark_20_filled,
              color: Color(0xFF34C759), size: 40),
        ),
        const SizedBox(height: 24),
        Text('Tutti i video revisionati!',
            style: TextStyle(color: Get.theme.colorScheme.onSurface, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Obx(() => Text(
          '${ctrl.keptCount.value} mantenuti · '
          '${ctrl.trashCount.value} nel cestino',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 14, height: 1.6),
        )),
        const SizedBox(height: 20),
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ctrl.keptCount.value > 0)
              _quickBtn(
                icon: FluentIcons.heart_20_filled,
                color: const Color(0xFF34C759),
                label: 'Mantenuti',
                badge: '${ctrl.keptCount.value}',
                onTap: () => Get.toNamed(Routes.VIDEO_KEPT),
              ),
            if (ctrl.keptCount.value > 0 && ctrl.trashCount.value > 0)
              const SizedBox(width: 12),
            if (ctrl.trashCount.value > 0)
              _quickBtn(
                icon: FluentIcons.delete_20_filled,
                color: const Color(0xFFFF3B30),
                label: 'Cestino',
                badge: '${ctrl.trashCount.value}',
                onTap: () => Get.toNamed(Routes.VIDEO_TRASH),
              ),
          ],
        )),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: ctrl.loadVideos,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(16)),
            child: const Text('Ricomincia',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

  Widget _quickBtn({required IconData icon, required Color color,
      required String label, required String badge,
      required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(badge,
                  style: TextStyle(color: color, fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );
}