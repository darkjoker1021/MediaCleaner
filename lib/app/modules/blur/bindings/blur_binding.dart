import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/blur/controllers/blur_controller.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

class BlurBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlurController>(
      () => BlurController(),
      fenix: false,
    );
    // Ensure HomeController exists
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
  }
}
