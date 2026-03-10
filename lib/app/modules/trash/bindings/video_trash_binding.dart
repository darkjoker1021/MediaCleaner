import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/video/controllers/video_controller.dart';
import 'package:media_cleaner/app/modules/trash/controllers/trash_controller.dart';

class VideoTrashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TrashController(media: Get.find<VideoController>()));
  }
}
