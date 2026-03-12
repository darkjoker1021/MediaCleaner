import 'package:get/get.dart';
import 'package:media_cleaner/app/service/cache_service.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

class StatsController extends GetxController {
  final _cache = CacheService();

  final photoFreedBytes = 0.obs;
  final videoFreedBytes = 0.obs;
  final photoKeptCount  = 0.obs;
  final photoTrashCount = 0.obs;
  final videoKeptCount  = 0.obs;
  final videoTrashCount = 0.obs;

  int get totalFreedBytes  => photoFreedBytes.value + videoFreedBytes.value;
  int get totalKeptCount   => photoKeptCount.value + videoKeptCount.value;
  int get totalTrashCount  => photoTrashCount.value + videoTrashCount.value;
  int get totalProcessed   => totalKeptCount + totalTrashCount;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    await _cache.init();
    photoFreedBytes.value = _cache.getFreedBytes();
    videoFreedBytes.value = _cache.getVideoFreedBytes();
    photoKeptCount.value  = _cache.getKeptIds().length;
    photoTrashCount.value = _cache.getTrashIds().length;
    videoKeptCount.value  = _cache.getVideoKeptIds().length;
    videoTrashCount.value = _cache.getVideoTrashIds().length;
  }

  String fmt(int b) => PhotoService.formatBytes(b);
}
