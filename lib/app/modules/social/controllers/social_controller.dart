import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/models/photo_item.dart';

class SocialController extends GetxController {
  HomeController get _home => Get.find<HomeController>();

  static const pageSize = 150;

  final isLoading   = true.obs;
  final isSelecting = false.obs;
  final items       = <PhotoItem>[].obs;
  final selectedIds = <String>{}.obs;
  final _visibleCount = pageSize.obs;

  // Lowercase app names — checked via String.contains()
  static const _socialPaths = [
    'whatsapp', 'telegram', 'instagram', 'messenger',
    'viber', 'signal', 'snapchat', 'facebook',
  ];

  // Display labels (capitalised) aligned with _socialPaths by index
  static const _socialLabels = [
    'WhatsApp', 'Telegram', 'Instagram', 'Messenger',
    'Viber', 'Signal', 'Snapchat', 'Facebook',
  ];

  bool get allSelected =>
      items.isNotEmpty && selectedIds.length == items.length;
  bool get hasMoreToDisplay => items.length > _visibleCount.value;

  /// Items grouped by source app, sorted by app name.
  /// Uses a single pass over [items] to build all groups at once.
  Map<String, List<PhotoItem>> get groupedItems =>
      _buildGrouped(items);

  Map<String, List<PhotoItem>> get groupedVisibleItems {
    final cnt     = _visibleCount.value;
    final visible = cnt < items.length ? items.sublist(0, cnt) : items.toList();
    return _buildGrouped(visible);
  }

  void loadAll() => _visibleCount.value = items.length;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;

    final trashSet = {for (final p in _home.trashItems) p.id};
    final keptSet  = {for (final p in _home.keptItems)  p.id};

    // Single pass: filter + classify in one loop
    final filtered = <PhotoItem>[];
    for (final item in _home.allItems) {
      if (trashSet.contains(item.id) || keptSet.contains(item.id)) continue;
      final path = (item.asset.relativePath ?? '').toLowerCase();
      // Early-exit as soon as a matching app is found
      for (final app in _socialPaths) {
        if (path.contains(app)) { filtered.add(item); break; }
      }
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    items.assignAll(filtered);
    _visibleCount.value = pageSize;
    isLoading.value = false;
  }

  Future<PhotoItem> loadFullThumb(PhotoItem item) =>
      _home.resolveFullThumb(item);

  void moveToTrash(String id) {
    _home.moveToTrash(id);
    items.removeWhere((e) => e.id == id);
    selectedIds.remove(id);
    selectedIds.refresh();
  }

  void toggleSelectionMode() {
    isSelecting.value = !isSelecting.value;
    if (!isSelecting.value) clearSelection();
  }

  void toggleSelect(String id) {
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
    selectedIds.refresh();
  }

  void clearSelection() { selectedIds.clear(); selectedIds.refresh(); }

  void selectAll() {
    selectedIds.assignAll(items.map((e) => e.id));
    selectedIds.refresh();
  }

  int moveSelectedToTrash() {
    final ids = List<String>.from(selectedIds);
    for (final id in ids) {
      moveToTrash(id);
    }
    clearSelection();
    isSelecting.value = false;
    return ids.length;
  }

  int moveAllToTrash() {
    selectAll();
    return moveSelectedToTrash();
  }

  /// Returns the display label for a given item (e.g. "WhatsApp").
  String sourceApp(PhotoItem item) {
    final path = (item.asset.relativePath ?? '').toLowerCase();
    for (int i = 0; i < _socialPaths.length; i++) {
      if (path.contains(_socialPaths[i])) return _socialLabels[i];
    }
    return 'Social';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, List<PhotoItem>> _buildGrouped(List<PhotoItem> source) {
    final map = <String, List<PhotoItem>>{};
    final path2app = <String, String>{}; // tiny per-call cache: path → app label

    for (final item in source) {
      final path = (item.asset.relativePath ?? '').toLowerCase();
      final app  = path2app.putIfAbsent(path, () {
        for (int i = 0; i < _socialPaths.length; i++) {
          if (path.contains(_socialPaths[i])) return _socialLabels[i];
        }
        return 'Social';
      });
      map.putIfAbsent(app, () => []).add(item);
    }

    // Sort by key (app name) once, at the end
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(entries);
  }
}