import 'package:get/get.dart';

import '../modules/duplicate/bindings/duplicate_binding.dart';
import '../modules/duplicate/views/duplicates_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/media_shell_view.dart';
import '../modules/kept/bindings/kept_binding.dart';
import '../modules/kept/bindings/video_kept_binding.dart';
import '../modules/kept/views/kept_view.dart';
import '../modules/screenshot/bindings/screenshot_binding.dart';
import '../modules/screenshot/views/screenshot_view.dart';
import '../modules/trash/bindings/trash_binding.dart';
import '../modules/trash/bindings/video_trash_binding.dart';
import '../modules/trash/views/trash_view.dart';
import '../modules/video/bindings/video_binding.dart';
import '../modules/video/views/video_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(name: _Paths.HOME,
        page: () => const MediaShellView(),
        binding: HomeBinding()),
    GetPage(name: _Paths.TRASH,
        page: () => const TrashView(),
        binding: TrashBinding()),
    GetPage(name: _Paths.KEPT,
        page: () => const KeptView(),
        binding: KeptBinding()),
    GetPage(name: _Paths.DUPLICATES,
        page: () => const DuplicatesView(),
        binding: DuplicateBinding()),
    GetPage(name: _Paths.SCREENSHOT,
        page: () => const ScreenshotView(),
        binding: ScreenshotBinding()),
    GetPage(
        name: _Paths.VIDEO,
        page: () => const VideoView(),
        binding: VideoBinding()),
    // ── route video: stessa view, binding video, isVideo: true ────────────
    GetPage(name: _Paths.VIDEO_KEPT,
        page: () => const KeptView(isVideo: true),
        binding: VideoKeptBinding()),
    GetPage(name: _Paths.VIDEO_TRASH,
        page: () => const TrashView(isVideo: true),
        binding: VideoTrashBinding()),
  ];
}