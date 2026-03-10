import 'package:get/get.dart';

import '../controllers/duplicates_controller.dart';

class DuplicateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DuplicatesController>(
      () => DuplicatesController(),
    );
  }
}
