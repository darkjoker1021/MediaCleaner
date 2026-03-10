import 'package:get/get.dart';

import '../controllers/screenshot_controller.dart';

class ScreenshotBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScreenshotController>(
      () => ScreenshotController(),
    );
  }
}
