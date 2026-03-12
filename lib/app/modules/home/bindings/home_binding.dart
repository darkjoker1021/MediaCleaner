import 'package:get/get.dart';
import 'package:media_cleaner/app/service/cache_service.dart';

import '../../video/controllers/video_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/media_shell_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // FIX: CacheService registrato come singleton permanente (Get.put fenix:true)
    // così HomeController e VideoController condividono la stessa istanza e
    // i relativi cache in memoria (_keptCache, _sizeMapCache, ecc.) rimangono
    // coerenti tra i due controller invece di avere due copie indipendenti.
    Get.put<CacheService>(CacheService(), permanent: true);

    Get.lazyPut<MediaShellController>(() => MediaShellController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<VideoController>(() => VideoController());
  }
}