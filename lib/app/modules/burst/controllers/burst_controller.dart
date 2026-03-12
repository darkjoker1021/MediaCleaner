import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

class BurstGroup {
  final List<PhotoItem> items;
  BurstGroup(this.items);

  PhotoItem get best =>
      items.reduce((a, b) => a.sizeBytes >= b.sizeBytes ? a : b);
  List<PhotoItem> get extras =>
      items.where((i) => i.id != best.id).toList();
  int get wasteBytes  => extras.fold(0, (s, e) => s + e.sizeBytes);
  int get count       => items.length;
  DateTime get time   => best.createdAt;
}

class BurstController extends GetxController {
  HomeController get _home => Get.find<HomeController>();

  static const initialScanLimit = 400;
  static const _windowSeconds   = 3;
  static const _minBurst        = 3;

  final isScanning  = true.obs;
  final hasMore     = false.obs;
  final groups      = <BurstGroup>[].obs;
  final isSelecting = false.obs;
  final selectedIds = <String>{}.obs;

  int get totalExtras      => groups.fold(0, (s, g) => s + g.extras.length);
  int get totalWasteBytes  => groups.fold(0, (s, g) => s + g.wasteBytes);

  int get selectedWasteBytes {
    // Build index once instead of O(n) firstWhereOrNull per selected id
    final index = {for (final p in _home.allItems) p.id: p.sizeBytes};
    return selectedIds.fold(0, (s, id) => s + (index[id] ?? 0));
  }

  @override
  void onReady() {
    super.onReady();
    scan();
  }

  Future<void> scan({bool all = false}) async {
    isScanning.value = true;
    selectedIds.clear();
    await Future.delayed(Duration.zero);

    // Build exclusion sets once (avoids repeated .any() in hot path)
    final trashSet = {for (final t in _home.trashItems) t.id};
    final keptSet  = {for (final k in _home.keptItems)  k.id};

    final allSource = _home.allItems
        .where((p) => !trashSet.contains(p.id) && !keptSet.contains(p.id))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final source = !all && allSource.length > initialScanLimit
        ? allSource.sublist(0, initialScanLimit)
        : allSource;

    final found = _detectBursts(source);

    groups.assignAll(found);
    // Auto-select all extras
    for (final g in found) {
      for (final e in g.extras) {
        selectedIds.add(e.id);
      }
    }

    hasMore.value    = allSource.length > source.length;
    isScanning.value = false;
  }

  Future<void> scanAll() => scan(all: true);

  /// Pure synchronous burst detection — no async needed here.
  List<BurstGroup> _detectBursts(List<PhotoItem> source) {
    final found = <BurstGroup>[];
    int i = 0;
    while (i < source.length) {
      // Extend window as long as consecutive items are within _windowSeconds
      final group = [source[i]];
      int j = i + 1;
      while (j < source.length) {
        final diffSec = source[j].createdAt
            .difference(source[j - 1].createdAt) // compare adjacent, not to group[0]
            .inSeconds
            .abs();
        if (diffSec <= _windowSeconds) {
          group.add(source[j++]);
        } else {
          break;
        }
      }
      if (group.length >= _minBurst) found.add(BurstGroup(group));
      i = j > i ? j : i + 1;
    }
    return found;
  }

  void toggleSelect(String id) {
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
    selectedIds.refresh();
  }

  void clearSelection()  { selectedIds.clear(); selectedIds.refresh(); }

  void selectAllExtras() {
    for (final g in groups) {
      for (final e in g.extras) {
        selectedIds.add(e.id);
      }
    }
    selectedIds.refresh();
  }

  void moveSelectedToTrash() {
    final trashSet = {for (final t in _home.trashItems) t.id};
    final keptSet  = {for (final k in _home.keptItems)  k.id};
    for (final id in selectedIds.toList()) {
      if (trashSet.contains(id) || keptSet.contains(id)) continue;
      _home.moveToTrash(id);
    }
    scan();
  }

  Future<PhotoItem> resolveThumb(PhotoItem item) =>
      _home.resolveFullThumb(item);

  String fmt(int b) => PhotoService.formatBytes(b);
}