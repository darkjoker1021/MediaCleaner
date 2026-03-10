import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/kept/controllers/kept_controller.dart';

class KeptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => KeptController(media: Get.find<HomeController>()));
  }
}