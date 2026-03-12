import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/burst/controllers/burst_controller.dart';

class BurstBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BurstController>(() => BurstController());
  }
}
