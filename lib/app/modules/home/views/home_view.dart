import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:media_cleaner/app/modules/shared/photo_detail.dart';
import 'package:media_cleaner/app/modules/video/views/video_view.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/app/modules/shared/sort_sheet.dart';
import 'package:media_cleaner/app/modules/shared/stats_bar.dart';
import 'package:media_cleaner/core/widgets/swipe_card.dart';
import '../controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/video/controllers/video_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        body: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => controller.isVideoMode.value = i == 1,
                  children: [
                    _photoPage(),
                    VideoView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Color(0xFF0A84FF),
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Caricamento libreria...',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
        ),
      ],
    ),
  );

  Widget _appBar() => Obx(() {
    final isVideo = controller.isVideoMode.value;
    final vc = isVideo ? Get.find<VideoController>() : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              _iconBtn(FluentIcons.arrow_sort_20_filled,
                  () => SortSheet.show(isVideo ? vc! : controller)),
              if (!isVideo) ...[const SizedBox(width: 8), _iconBtn(FluentIcons.grid_20_filled, _openFeaturesMenu)],
              const Spacer(),
              if (isVideo) _videoOverflowMenu(vc!) else _overflowMenu(),
            ],
          ),
          _mediaSwitchInAppBar(),
        ],
      ),
    );
  });

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white70, size: 20),
    ),
  );

  Widget _mediaSwitchInAppBar() => Obx(
    () => Container(
      width: 116,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _mediaIconBtn(
              icon: FluentIcons.image_20_regular,
              active: !controller.isVideoMode.value,
              onTap: () => controller.setVideoMode(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _mediaIconBtn(
              icon: FluentIcons.video_20_regular,
              active: controller.isVideoMode.value,
              onTap: () => controller.setVideoMode(true),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _mediaIconBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      height: 40,
      duration: const Duration(milliseconds: 170),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0A84FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: active ? Colors.white : Colors.white70,
        size: 18,
      ),
    ),
  );

  Widget _overflowMenu() => PopupMenuButton<String>(
    icon: const Icon(FluentIcons.more_vertical_20_filled, color: Colors.white70, size: 20),
    color: const Color(0xFF1C1E27),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onSelected: (val) async {
      if (val == 'reset_session') {
        await controller.resetSession();
      } else if (val == 'reset_all') {
        await controller.resetAllStats();
      } else {
        controller.loadPhotos();
      }
    },
    itemBuilder: (_) => [
      _menuItem(
        'reload',
        FluentIcons.arrow_clockwise_20_filled,
        'Ricarica libreria',
        Colors.white70,
      ),
      _menuItem(
        'reset_session',
        FluentIcons.replay_20_filled,
        'Reset sessione',
        const Color(0xFFFF3B30),
      ),
      _menuItem(
        'reset_all',
        FluentIcons.delete_dismiss_20_filled,
        'Reset completo',
        const Color(0xFFFF3B30),
      ),
    ],
  );

  PopupMenuItem<String> _menuItem(
    String val,
    IconData icon,
    String label,
    Color color,
  ) => PopupMenuItem(
    value: val,
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _body() {
    final pending = controller.pendingItems;
    if (pending.isEmpty) return _doneScreen();
    final key = '${pending.length}_${controller.currentSort.value.index}';
    return CardSwiper(
      key: ValueKey(key),
      cardsCount: pending.length,
      numberOfCardsDisplayed: pending.length >= 3 ? 3 : pending.length,
      backCardOffset: const Offset(0, 26),
      scale: 0.93,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onSwipe: (prevIdx, currIdx, direction) async {
        final current = controller.pendingItems;
        if (prevIdx >= current.length) return true;
        final item = current[prevIdx];
        if (direction == CardSwiperDirection.left) {
          HapticFeedback.mediumImpact();
          controller.moveToTrash(item.id);
        } else if (direction == CardSwiperDirection.right) {
          HapticFeedback.lightImpact();
          controller.keepPhoto(item.id);
        }
        return true;
      },
      cardBuilder: (context, index, hThreshold, vThreshold) {
        final current = controller.pendingItems;
        if (index >= current.length) return const SizedBox.shrink();
        final item = current[index];
        return SwipeCard(
          item: item,
          hThreshold: hThreshold.toDouble(),
          onTap: () => PhotoDetailView.open(
            item: item,
            loadFull: (photo) async {
              final result = await controller.resolveFullThumb(photo);
              return result.thumbnail;
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
              detailAction(
                label: 'Mantieni',
                color: const Color(0xFF34C759),
                icon: FluentIcons.heart_20_filled,
                onTap: () {
                  Get.back();
                  controller.keepPhoto(item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _doneScreen() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FluentIcons.checkmark_20_filled,
              color: Color(0xFF34C759),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tutto revisionato!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              '${controller.keptCount.value} mantenute · ${controller.trashCount.value} nel cestino',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controller.keptCount.value > 0)
                  _quickBtn(
                    icon: FluentIcons.heart_20_filled,
                    color: const Color(0xFF34C759),
                    label: 'Mantenute',
                    badge: '${controller.keptCount.value}',
                    onTap: _openKept,
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
                    onTap: _openTrash,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: controller.loadPhotos,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Ricomincia',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _quickBtn({
    required IconData icon,
    required Color color,
    required String label,
    required String badge,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actionHints() => Obx(() {
    if (controller.pendingItems.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Row(
        children: [
          _hint('← Cestino', const Color(0xFFFF3B30)),
          const Spacer(),
          Text(
            '${controller.pendingCount}',
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 22,
              fontWeight: FontWeight.w300,
            ),
          ),
          const Spacer(),
          _hint('Mantieni →', const Color(0xFF34C759)),
        ],
      ),
    );
  });

  Widget _hint(String text, Color color) => Text(
    text,
    style: TextStyle(
      color: color.withValues(alpha: 0.5),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );

  Widget _bottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF16181F),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Obx(
            () => _navItem(
              icon: FluentIcons.heart_20_filled,
              label: 'Mantenute',
              badge: controller.keptCount.value > 0
                  ? '${controller.keptCount.value}'
                  : null,
              color: const Color(0xFF34C759),
              onTap: _openKept,
            ),
          ),
        ),
        Obx(() {
          final enabled = controller.canUndo.value;
          return GestureDetector(
            onTap: enabled
                ? () {
                    final undone = controller.undoLastAction();
                    if (!undone) return;
                    HapticFeedback.selectionClick();
                    _snack(
                      'Azione annullata',
                      '',
                      const Color(0xFF0A84FF),
                      dur: const Duration(milliseconds: 900),
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF2A2D36),
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                FluentIcons.arrow_undo_20_filled,
                color: enabled ? Colors.white : Colors.white38,
                size: 22,
              ),
            ),
          );
        }),
        Expanded(
          child: Obx(
            () => _navItem(
              icon: FluentIcons.delete_20_filled,
              label: 'Cestino',
              badge: controller.trashCount.value > 0
                  ? '${controller.trashCount.value}'
                  : null,
              color: const Color(0xFFFF3B30),
              onTap: _openTrash,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _navItem({
    required IconData icon,
    required String label,
    String? badge,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: badge != null ? color : Colors.white38, size: 22),
            if (badge != null)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: badge != null ? color : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  void _openKept() => Get.toNamed(Routes.KEPT);

  void _openDuplicates() => Get.toNamed(Routes.DUPLICATES);

  void _openScreenshots() => Get.toNamed(Routes.SCREENSHOT);

  void _openTrash() => Get.toNamed(Routes.TRASH);

  void _openFeaturesMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF16181F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Funzionalita',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Apri una sezione rapida per pulire la libreria',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _featureTile(
                    icon: FluentIcons.copy_20_filled,
                    color: const Color(0xFFFF9F0A),
                    title: 'Duplicati',
                    subtitle: 'Rileva copie simili',
                    onTap: () {
                      Get.back();
                      _openDuplicates();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _featureTile(
                    icon: FluentIcons.scan_camera_20_filled,
                    color: const Color(0xFF5AC8FA),
                    title: 'Screenshot',
                    subtitle: 'Trova schermate',
                    onTap: () {
                      Get.back();
                      _openScreenshots();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _featureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );

  void _snack(
    String title,
    String msg,
    Color color, {
    Duration dur = const Duration(milliseconds: 1400),
  }) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      duration: dur,
      backgroundColor: color.withValues(alpha: 0.88),
      colorText: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      messageText: msg.isNotEmpty
          ? Text(
              msg,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Photo page ───────────────────────────────────────────

  Widget _photoPage() => Obx(() {
    if (controller.isLoading.value) return _loader();
    return Column(
      children: [
        StatsBar(ctrl: controller),
        const SizedBox(height: 4),
        Expanded(child: _body()),
        _actionHints(),
        _bottomNav(),
      ],
    );
  });

  Widget _videoOverflowMenu(VideoController vc) => PopupMenuButton<String>(
    icon: const Icon(FluentIcons.more_vertical_20_filled, color: Colors.white70, size: 20),
    color: const Color(0xFF1C1E27),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onSelected: (val) async {
      if (val == 'reload') vc.loadVideos();
      if (val == 'reset_session') await vc.resetSession();
      if (val == 'reset_all') await vc.resetAllStats();
    },
    itemBuilder: (_) => [
      _menuItem('reload', FluentIcons.arrow_clockwise_20_filled, 'Ricarica video', Colors.white70),
      _menuItem('reset_session', FluentIcons.replay_20_filled, 'Reset sessione', const Color(0xFFFF3B30)),
      _menuItem(
        'reset_all',
        FluentIcons.delete_dismiss_20_filled,
        'Reset completo',
        const Color(0xFFFF3B30),
      ),
    ],
  );
}