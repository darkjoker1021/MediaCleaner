import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/views/home_view.dart';
import 'package:media_cleaner/core/app_transitions.dart';

import '../modules/blur/bindings/blur_binding.dart';
import '../modules/blur/views/blur_view.dart';
import '../modules/burst/bindings/burst_binding.dart';
import '../modules/burst/views/burst_view.dart';
import '../modules/duplicate/bindings/duplicate_binding.dart';
import '../modules/duplicate/views/duplicates_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/kept/bindings/kept_binding.dart';
import '../modules/kept/bindings/video_kept_binding.dart';
import '../modules/kept/views/kept_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/screenshot/bindings/screenshot_binding.dart';
import '../modules/screenshot/views/screenshot_view.dart';
import '../modules/social/bindings/social_binding.dart';
import '../modules/social/views/social_view.dart';
import '../modules/stats/bindings/stats_binding.dart';
import '../modules/stats/views/stats_view.dart';
import '../modules/trash/bindings/trash_binding.dart';
import '../modules/trash/bindings/video_trash_binding.dart';
import '../modules/trash/views/trash_view.dart';
import '../modules/video/bindings/video_binding.dart';
import '../modules/video/views/video_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.HOME;

  static final _slide = SlideRightFadeTransition();
  static final _modal = ModalUpTransition();
  static final _fade  = FadeTransitionPage();

  static const _stdDuration   = Duration(milliseconds: 320);
  static const _modalDuration = Duration(milliseconds: 400);

  static final routes = [
    GetPage(name: _Paths.HOME,
        page: () => const HomeView(),
        binding: HomeBinding()),
    GetPage(name: _Paths.TRASH,
        page: () => const TrashView(),
        binding: TrashBinding(),
        customTransition: _modal,
        transitionDuration: _modalDuration),
    GetPage(name: _Paths.KEPT,
        page: () => const KeptView(),
        binding: KeptBinding(),
        customTransition: _modal,
        transitionDuration: _modalDuration),
    GetPage(name: _Paths.DUPLICATES,
        page: () => const DuplicatesView(),
        binding: DuplicateBinding(),
        customTransition: _slide,
        transitionDuration: _stdDuration),
    GetPage(name: _Paths.SCREENSHOT,
        page: () => const ScreenshotView(),
        binding: ScreenshotBinding(),
        customTransition: _slide,
        transitionDuration: _stdDuration),
    GetPage(
        name: _Paths.VIDEO,
        page: () => const VideoView(),
        binding: VideoBinding(),
        customTransition: _slide,
        transitionDuration: _stdDuration),
    GetPage(name: _Paths.VIDEO_KEPT,
        page: () => const KeptView(isVideo: true),
        binding: VideoKeptBinding(),
        customTransition: _modal,
        transitionDuration: _modalDuration),
    GetPage(name: _Paths.VIDEO_TRASH,
        page: () => const TrashView(isVideo: true),
        binding: VideoTrashBinding(),
        customTransition: _modal,
        transitionDuration: _modalDuration),
    GetPage(name: _Paths.BLUR,
        page: () => const BlurView(),
        binding: BlurBinding(),
        customTransition: _slide,
        transitionDuration: _stdDuration),
    GetPage(name: _Paths.SOCIAL,
        page: () => const SocialView(),
        binding: SocialBinding(),
        customTransition: _slide,
        transitionDuration: _stdDuration),
    GetPage(name: _Paths.BURST,
        page: () => const BurstView(),
        binding: BurstBinding(),
        customTransition: _slide,
        transitionDuration: _stdDuration),
    GetPage(name: _Paths.STATS,
        page: () => const StatsView(),
        binding: StatsBinding(),
        customTransition: _modal,
        transitionDuration: _modalDuration),
    GetPage(name: _Paths.ONBOARDING,
        page: () => const OnboardingView(),
        binding: OnboardingBinding(),
        customTransition: _fade,
        transitionDuration: _stdDuration),
  ];
}