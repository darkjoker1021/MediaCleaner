import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_cleaner/app/modules/shared/stats_bar.dart';
import 'package:media_cleaner/app/modules/shared/swipe_bottom_nav.dart';
import 'package:media_cleaner/app/modules/video/views/video_view.dart';
import 'package:media_cleaner/app/routes/app_pages.dart';
import 'package:media_cleaner/core/theme/theme_helper.dart';
import '../controllers/home_controller.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_photo_swiper.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeHelper.overlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const HomeAppBar(),
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
        Lottie.asset('assets/lottie/search.json', width: 100, height: 100),
        const SizedBox(height: 20),
        Text(
          'Caricamento libreria...',
          style: TextStyle(color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 14),
        ),
        const SizedBox(height: 10),
        Text(
          "L'operazione potrebbe durare anche alcuni minuti",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.22),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  // ── Photo page ───────────────────────────────────────────

  Widget _photoPage() => Obx(() {
    if (controller.isLoading.value) return _loader();
    return Column(
      children: [
        StatsBar(ctrl: controller),
        const SizedBox(height: 4),
        Expanded(child: HomePhotoSwiper()),
        SwipeActionHints(ctrl: controller),
        SwipeBottomNav(
          ctrl: controller,
          onKept:  () => Get.toNamed(Routes.KEPT),
          onTrash: () => Get.toNamed(Routes.TRASH),
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
      ],
    );
  });
}