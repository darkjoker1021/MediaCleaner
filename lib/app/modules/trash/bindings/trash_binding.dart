import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/modules/trash/controllers/trash_controller.dart';

class TrashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TrashController(media: Get.find<HomeController>()));
  }
}