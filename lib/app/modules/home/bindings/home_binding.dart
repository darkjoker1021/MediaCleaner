import 'package:get/get.dart';

import '../../video/controllers/video_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/media_shell_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MediaShellController>(() => MediaShellController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<VideoController>(() => VideoController());
  }
}
