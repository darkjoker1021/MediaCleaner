import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

/// Funziona con FOTO e VIDEO — il binding inietta il controller giusto.
class TrashController extends GetxController {
  final IMediaController media;
  TrashController({required this.media});

  final selectedIds = <String>{}.obs;
  final isSelecting = false.obs;

  List<PhotoItem> get trashItems => media.trashItems;
  int             get trashBytes => media.trashBytes;

  @override
  void onClose() { selectedIds.clear(); super.onClose(); }

  // ── Selezione ─────────────────────────────────────────────────────────────
  void toggleSelectionMode() {
    isSelecting.value = !isSelecting.value;
    if (!isSelecting.value) selectedIds.clear();
  }

  void toggleSelect(String id) =>
      selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);

  void selectAll()      => selectedIds.assignAll(trashItems.map((e) => e.id));
  void clearSelection() => selectedIds.clear();
  bool get allSelected  =>
      trashItems.isNotEmpty && selectedIds.length == trashItems.length;

  // ── Azioni ────────────────────────────────────────────────────────────────
  void restoreSelected() {
    for (final id in selectedIds.toList()) {
      media.restoreFromTrash(id);
    }
    selectedIds.clear(); isSelecting.value = false;
  }

  void restoreAll() {
    media.restoreAllFromTrash(); selectedIds.clear(); isSelecting.value = false;
  }

  Future<int> deleteSelected() async {
    final freed = await media.deleteFromTrash(selectedIds.toList());
    selectedIds.clear(); isSelecting.value = false;
    return freed;
  }

  Future<int> deleteAll() async {
    final freed = await media.emptyTrash();
    selectedIds.clear(); isSelecting.value = false;
    return freed;
  }

  Future<int> deleteSingle(String id) async {
    final freed = await media.deleteFromTrash([id]);
    selectedIds.remove(id);
    return freed;
  }

  void restoreSingle(String id) {
    media.restoreFromTrash(id); selectedIds.remove(id);
  }

  Future<Uint8List?> loadFull(PhotoItem item) =>
      media.resolveFullThumb(item).then((p) => p.thumbnail);

  String fmt(int b) => PhotoService.formatBytes(b);
}