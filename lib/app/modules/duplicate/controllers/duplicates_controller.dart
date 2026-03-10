import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:media_cleaner/app/data/service/duplicate_service.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

class DuplicatesController extends GetxController {
  final _home   = Get.find<HomeController>();
  final _dupSvc = DuplicateService();

  final groups     = <DuplicateGroup>[].obs;
  final isScanning = false.obs;
  final selectedIds = <String>{}.obs;

  // ── Derivati ──────────────────────────────────────────────────────────────

  int get totalWasteBytes =>
      groups.fold(0, (s, g) => s + g.wasteBytes);

  int get totalDuplicateCount =>
      groups.fold(0, (s, g) => s + g.duplicates.length);

  int get selectedWasteBytes {
    int total = 0;
    for (final id in selectedIds) {
      final item = _home.allItems.firstWhereOrNull((p) => p.id == id);
      if (item != null) total += item.sizeBytes;
    }
    return total;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    scan();
  }

  @override
  void onClose() {
    selectedIds.clear();
    super.onClose();
  }

  // ── Scansione ─────────────────────────────────────────────────────────────

  Future<void> scan() async {
    isScanning.value = true;
    selectedIds.clear();

    // Solo foto con dimensione già risolta
    final items = _home.allItems.where((p) => p.sizeBytes > 0).toList();
    final found = _dupSvc.findDuplicates(items);
    groups.assignAll(found);

    // Auto-seleziona tutte le copie (non l'originale)
    for (final g in found) {
      for (final dup in g.duplicates) {
        selectedIds.add(dup.id);
      }
    }

    isScanning.value = false;
  }

  // ── Selezione ─────────────────────────────────────────────────────────────

  void toggleSelect(String id, DuplicateGroup group) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void selectAllDuplicates() {
    for (final g in groups) {
      for (final dup in g.duplicates) {
        selectedIds.add(dup.id);
      }
    }
  }

  void clearSelection() => selectedIds.clear();

  // ── Azioni ────────────────────────────────────────────────────────────────

  /// Sposta le copie selezionate nel cestino e ri-scansiona
  void moveSelectedToTrash() {
    for (final id in selectedIds.toList()) {
      if (_home.trashItems.any((t) => t.id == id)) continue;
      if (_home.keptItems.any((k) => k.id == id)) continue;
      _home.moveToTrash(id);
    }
    scan();
  }

  // ── Thumbnail full-res per PhotoDetailView ────────────────────────────────

  Future<Uint8List?> loadFull(PhotoItem item) =>
      _home.resolveFullThumb(item).then((p) => p.thumbnail);
}