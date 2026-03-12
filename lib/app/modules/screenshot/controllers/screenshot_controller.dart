import 'package:get/get.dart';
import 'package:media_cleaner/app/models/photo_item.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

class ScreenshotController extends GetxController {
  HomeController get home => Get.find<HomeController>();

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

    final trashSet = {for (final p in home.trashItems) p.id};
    final keptSet  = {for (final p in home.keptItems)  p.id};
    final source = home.allItems
        .where((p) => !trashSet.contains(p.id) && !keptSet.contains(p.id))
        .toList();

    // Richieste titleAsync in parallelo: batch di 50 per evitare di saturare il platform channel
    const batchSize = 50;
    final filtered = <PhotoItem>[];
    for (var i = 0; i < source.length; i += batchSize) {
      final batch = source.sublist(i, (i + batchSize).clamp(0, source.length));
      final titles = await Future.wait(batch.map((p) => p.asset.titleAsync));
      for (var j = 0; j < batch.length; j++) {
        final title = titles[j].toLowerCase();
        if (title.contains('screenshot') ||
            title.contains('screen_shot') ||
            title.contains('schermata') ||
            title.contains('capture')) {
          filtered.add(batch[j]);
        }
      }
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    screenshots.assignAll(filtered);
    isLoading.value = false;
  }

  Future<PhotoItem> loadFullThumb(PhotoItem item) async {
    return home.resolveFullThumb(item);
  }

  bool isInTrash(String id) => home.trashItems.any((e) => e.id == id);
  bool isInKept(String  id) => home.keptItems.any((e) => e.id == id);

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
