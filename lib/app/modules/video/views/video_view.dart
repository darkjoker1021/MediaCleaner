import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/stats_bar.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/core/widgets/swipe_card.dart';

import '../controllers/video_controller.dart';
import 'video_player_view.dart';

class VideoView extends GetView<VideoController> {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) return _loader();
            return Column(children: [
              StatsBar(
                ctrl: controller,
                pendingLabel: 'rimasti',
                totalIcon: FluentIcons.video_20_filled,
              ),
              const SizedBox(height: 4),
              Expanded(child: _body()),
              _actionHints(),
              _bottomNav(),
            ]);
          }),
        ),
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────────

  Widget _loader() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(
            color: Color(0xFF0A84FF), strokeWidth: 2),
      ),
      const SizedBox(height: 20),
      Text('Caricamento video...',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35), fontSize: 14)),
    ]),
  );

  // ── Body / swiper ─────────────────────────────────────────────────────────

  Widget _body() {
    final pending = controller.pendingVideos;
    if (pending.isEmpty) return _doneScreen();
    return CardSwiper(
      key: ValueKey(pending.length),
      cardsCount: pending.length,
      numberOfCardsDisplayed: pending.length >= 3 ? 3 : pending.length,
      backCardOffset: const Offset(0, 26),
      scale: 0.93,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onSwipe: (prevIdx, _, direction) async {
        final cur = controller.pendingVideos;
        if (prevIdx >= cur.length) return true;
        final item = cur[prevIdx];
        if (direction == CardSwiperDirection.left) {
          HapticFeedback.mediumImpact();
          controller.moveToTrash(item.id);
        } else if (direction == CardSwiperDirection.right) {
          HapticFeedback.lightImpact();
          controller.keepVideo(item.id);
        }
        return true;
      },
      cardBuilder: (context, index, hThreshold, _) {
        final cur = controller.pendingVideos;
        if (index >= cur.length) return const SizedBox.shrink();
        final item = cur[index];
        
        return SwipeCard(
          item: item,
          hThreshold: hThreshold.toDouble(),
          onTap: () => Get.to(() => VideoPlayerView(item: item)),
        );
      },
    );
  }

  // ── Done screen ───────────────────────────────────────────────────────────

  Widget _doneScreen() => Center(
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
        const Text('Tutti i video revisionati!',
            style: TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Obx(() => Text(
          '${controller.keptCount.value} mantenuti · '
          '${controller.trashCount.value} nel cestino',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14, height: 1.6),
        )),
        const SizedBox(height: 20),
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.keptCount.value > 0)
              _quickBtn(
                icon: FluentIcons.heart_20_filled,
                color: const Color(0xFF34C759),
                label: 'Mantenuti',
                badge: '${controller.keptCount.value}',
                onTap: () => Get.toNamed(Routes.VIDEO_KEPT),
              ),
            if (controller.keptCount.value > 0 &&
                controller.trashCount.value > 0)
              const SizedBox(width: 12),
            if (controller.trashCount.value > 0)
              _quickBtn(
                icon: FluentIcons.delete_20_filled,
                color: const Color(0xFFFF3B30),
                label: 'Cestino',
                badge: '${controller.trashCount.value}',
                onTap: () => Get.toNamed(Routes.VIDEO_TRASH),
              ),
          ],
        )),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: controller.loadVideos,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 14),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
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

  // ── Hints ─────────────────────────────────────────────────────────────────

  Widget _actionHints() => Obx(() {
    if (controller.pendingVideos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Row(children: [
        _hint('← Cestino', const Color(0xFFFF3B30)),
        const Spacer(),
        Text('${controller.pendingCount}',
            style: const TextStyle(color: Colors.white30,
                fontSize: 22, fontWeight: FontWeight.w300)),
        const Spacer(),
        _hint('Mantieni →', const Color(0xFF34C759)),
      ]),
    );
  });

  Widget _hint(String text, Color color) => Text(text,
      style: TextStyle(color: color.withValues(alpha: 0.5),
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3));

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _bottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF16181F),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
          color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Row(children: [
      Expanded(child: Obx(() => _navItem(
        icon: FluentIcons.heart_20_filled,
        label: 'Mantenuti',
        badge: controller.keptCount.value > 0
            ? '${controller.keptCount.value}' : null,
        color: const Color(0xFF34C759),
        onTap: () => Get.toNamed(Routes.VIDEO_KEPT),
      ))),
      Obx(() {
        final ok = controller.canUndo.value;
        return GestureDetector(
          onTap: ok ? () {
            if (controller.undoLastAction()) HapticFeedback.selectionClick();
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: ok ? const Color(0xFF0A84FF)
                        : const Color(0xFF2A2D36),
              shape: BoxShape.circle,
              boxShadow: ok ? [BoxShadow(
                color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                blurRadius: 12, offset: const Offset(0, 4),
              )] : [],
            ),
            child: Icon(FluentIcons.arrow_undo_20_filled,
                color: ok ? Colors.white : Colors.white38, size: 22),
          ),
        );
      }),
      Expanded(child: Obx(() => _navItem(
        icon: FluentIcons.delete_20_filled,
        label: 'Cestino',
        badge: controller.trashCount.value > 0
            ? '${controller.trashCount.value}' : null,
        color: const Color(0xFFFF3B30),
        onTap: () => Get.toNamed(Routes.VIDEO_TRASH),
      ))),
    ]),
  );

  Widget _navItem({required IconData icon, required String label,
      String? badge, required Color color,
      required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon,
                color: badge != null ? color : Colors.white38, size: 22),
            if (badge != null)
              Positioned(top: -4, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(badge,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: badge != null ? color : Colors.white38,
                  fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      );
}