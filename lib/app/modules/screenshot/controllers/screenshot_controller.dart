import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

class ScreenshotController extends GetxController {
  HomeController get home => Get.find<HomeController>();

  final isLoading   = true.obs;
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

    // Filtra screenshot per titolo in batch paralleli
    const batchSize = 50;
    final filtered = <PhotoItem>[];
    for (var i = 0; i < source.length; i += batchSize) {
      final batch  = source.sublist(i, (i + batchSize).clamp(0, source.length));
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

    // FIX: carica thumbnail 300 px in background appena la lista è pronta.
    // Prima non venivano mai caricate → shimmer permanente su tutta la grid.
    _loadGridThumbs();
  }

  /// Carica le thumbnail 300 px per la grid 3-col in background.
  /// Usa resolveStreamGrid (batch da 40, thumb 300 px) invece di
  /// resolveStream (batch da 20, thumb 600 px): celle piccole non
  /// beneficiano della risoluzione maggiore.
  Future<void> _loadGridThumbs() async {
    final svc   = PhotoService();
    final items = screenshots.toList();
    if (items.isEmpty) return;

    // Indice O(1) costruito una sola volta
    final idx = <String, int>{for (var i = 0; i < items.length; i++) items[i].id: i};

    await for (final batch in svc.resolveStreamGrid(items)) {
      for (final r in batch) {
        final i = idx[r.id];
        if (i != null) screenshots[i] = r;
      }
      screenshots.refresh();
      // Cede il thread UI tra un batch e l'altro
      await Future.delayed(Duration.zero);
    }
  }

  Future<PhotoItem> loadFullThumb(PhotoItem item) => home.resolveFullThumb(item);

  bool isInTrash(String id) => home.trashItems.any((e) => e.id == id);
  bool isInKept(String  id) => home.keptItems.any((e) => e.id == id);

  void moveToTrash(String id) {
    if (isInTrash(id) || isInKept(id)) return;
    home.moveToTrash(id);
    screenshots.removeWhere((e) => e.id == id);
    selectedIds.remove(id);
  }

  void toggleSelectionMode() {
    isSelecting.value = !isSelecting.value;
    if (!isSelecting.value) clearSelection();
  }

  void toggleSelect(String id) {
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
  }

  void clearSelection() => selectedIds.clear();

  void selectAll() => selectedIds.assignAll(screenshots.map((e) => e.id));

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
    selectAll();
    return moveSelectedToTrash();
  }
}