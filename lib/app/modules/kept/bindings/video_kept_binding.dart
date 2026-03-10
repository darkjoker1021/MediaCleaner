import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/video/controllers/video_controller.dart';
import 'package:media_cleaner/app/modules/kept/controllers/kept_controller.dart';

class VideoKeptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => KeptController(media: Get.find<VideoController>()));
  }
}
