import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

class ScreenshotController extends GetxController {
  final home = Get.find<HomeController>();

  final isLoading = true.obs;
  final isSelecting = false.obs;
  final screenshots = <PhotoItem>[].obs;
  final selectedIds = <String>{}.obs;

  bool get allSelected =>
      screenshots.isNotEmpty && selectedIds.length == screenshots.length;

  @override
  void onReady() {
    super.onReady();
    loadScreenshots();
  }

  Future<void> loadScreenshots() async {
    isLoading.value = true;

    final source = home.allItems.toList();
    final filtered = <PhotoItem>[];
    for (final item in source) {
      if (await _isScreenshot(item) && !isInTrash(item.id) && !isInKept(item.id)) {
        filtered.add(item);
      }
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    screenshots.assignAll(filtered);
    isLoading.value = false;
  }

  Future<bool> _isScreenshot(PhotoItem item) async {
    final title = (await item.asset.titleAsync).toLowerCase();
    return title.contains('screenshot') ||
        title.contains('screen_shot') ||
        title.contains('schermata') ||
        title.contains('capture');
  }

  Future<PhotoItem> loadFullThumb(PhotoItem item) async {
    return home.resolveFullThumb(item);
  }

  bool isInTrash(String id) => home.trashItems.any((e) => e.id == id);

  bool isInKept(String id) => home.keptItems.any((e) => e.id == id);

  void moveToTrash(String id) {
    if (isInTrash(id) || isInKept(id)) return;
    home.moveToTrash(id);
    screenshots.removeWhere((e) => e.id == id);
    selectedIds.remove(id);
    selectedIds.refresh();
  }

  void toggleSelectionMode() {
    isSelecting.value = !isSelecting.value;
    if (!isSelecting.value) clearSelection();
  }

  void toggleSelect(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    selectedIds.refresh();
  }

  void clearSelection() {
    selectedIds.clear();
    selectedIds.refresh();
  }

  void selectAll() {
    selectedIds.assignAll(screenshots.map((e) => e.id));
    selectedIds.refresh();
  }

  int moveSelectedToTrash() {
    if (selectedIds.isEmpty) return 0;
    final ids = selectedIds.toList();
    for (final id in ids) {
      moveToTrash(id);
    }
    final moved = ids.length;
    clearSelection();
    isSelecting.value = false;
    return moved;
  }

  int moveAllToTrash() {
    if (screenshots.isEmpty) return 0;
    selectAll();
    return moveSelectedToTrash();
  }
}
