import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

/// Funziona con FOTO e VIDEO — il binding inietta il controller giusto.
class KeptController extends GetxController {
  final IMediaController media;
  KeptController({required this.media});

  final selectedIds = <String>{}.obs;
  final isSelecting = false.obs;

  List<PhotoItem> get keptItems => media.keptItems;
  int             get keptBytes => media.keptBytes;

  @override
  void onClose() { selectedIds.clear(); super.onClose(); }

  // ── Selezione ─────────────────────────────────────────────────────────────
  void toggleSelectionMode() {
    isSelecting.value = !isSelecting.value;
    if (!isSelecting.value) selectedIds.clear();
  }

  void toggleSelect(String id) =>
      selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);

  void selectAll()      => selectedIds.assignAll(keptItems.map((e) => e.id));
  void clearSelection() => selectedIds.clear();
  bool get allSelected  =>
      keptItems.isNotEmpty && selectedIds.length == keptItems.length;

  // ── Azioni ────────────────────────────────────────────────────────────────
  void unkepSelected() {
    for (final id in selectedIds.toList()) {
      media.unkeepItem(id);
    }
    selectedIds.clear(); isSelecting.value = false;
  }

  void unkepAll() {
    for (final item in List.from(keptItems)) {
      media.unkeepItem(item.id);
    }
    selectedIds.clear(); isSelecting.value = false;
  }

  void unkepSingle(String id) {
    media.unkeepItem(id); selectedIds.remove(id);
  }

  void moveSelectedToTrash() {
    for (final id in selectedIds.toList()) {
      media.unkeepItem(id);
      media.moveToTrash(id, trackHistory: false);
    }
    selectedIds.clear(); isSelecting.value = false;
  }

  void moveSingleToTrash(String id) {
    media.unkeepItem(id);
    media.moveToTrash(id, trackHistory: false);
  }

  Future<Uint8List?> loadFull(PhotoItem item) =>
      media.resolveFullThumb(item).then((p) => p.thumbnail);

  String fmt(int b) => PhotoService.formatBytes(b);
}