import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/social/controllers/social_controller.dart';

class SocialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocialController>(() => SocialController());
  }
}
