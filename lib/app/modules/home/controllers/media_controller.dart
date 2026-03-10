import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';

// ── Undo history ──────────────────────────────────────────────────────────────

enum MediaActionType { keep, trash }

class MediaAction {
  const MediaAction({required this.id, required this.type});
  final String id;
  final MediaActionType type;
}

// ── Base controller ───────────────────────────────────────────────────────────

/// Logica condivisa tra foto e video: lista, swipe, undo, trash, kept.
/// Estendi questa classe e implementa [loadMedia] e [allItems].
abstract class MediaController extends GetxController {
  final _service = PhotoService();

  // ── Stato osservabile ────────────────────────────────────────────────────

  final trashItems = <PhotoItem>[].obs;
  final keptItems  = <PhotoItem>[].obs;
  final isLoading  = true.obs;
  final canUndo    = false.obs;
  final currentSort = SortMode.dateNewest.obs;

  // Statistiche
  final keptCount  = 0.obs;
  final trashCount = 0.obs;
  int get trashBytes => trashItems.fold(0, (s, e) => s + e.sizeBytes);
  int get keptBytes  => keptItems.fold(0, (s, e) => s + e.sizeBytes);

  // Spazio liberato (sovrascrivibile dalle sottoclassi se usano cache)
  int get totalFreedBytes => 0;

  // ── Stato interno ────────────────────────────────────────────────────────

  final _processedIds = <String>{};
  final _history      = <MediaAction>[];

  // ── Astratti — da implementare ───────────────────────────────────────────

  /// Lista osservabile di tutti i media (foto o video).
  RxList<PhotoItem> get allItems;

  /// Carica i media dal dispositivo e popola [allItems].
  Future<void> loadMedia();

  // ── Derivati ──────────────────────────────────────────────────────────────

  List<PhotoItem> get pendingItems =>
      allItems.where((p) => !_processedIds.contains(p.id)).toList();

  int get pendingCount => pendingItems.length;
  int get totalCount   => allItems.length;
  double get progress  =>
      totalCount == 0 ? 0 : _processedIds.length / totalCount;

  String fmt(int b) => PhotoService.formatBytes(b);

  // ── Caricamento comune ────────────────────────────────────────────────────

  /// Chiamato da loadMedia() nelle sottoclassi dopo aver popolato allItems.
  Future<void> initAfterLoad({
    Set<String> keptIds   = const {},
    Set<String> trashIds  = const {},
    Map<String, int> sizeMap = const {},
  }) async {
    final allIds = Set<String>.from(allItems.map((e) => e.id));

    final validKept  = keptIds.intersection(allIds);
    final validTrash = trashIds.intersection(allIds);

    _processedIds
      ..clear()
      ..addAll(validKept)
      ..addAll(validTrash);

    _history.clear();
    canUndo.value = false;

    keptItems.assignAll(
      allItems.where((p) => validKept.contains(p.id)).map((p) {
        final cached = sizeMap[p.id];
        return cached != null ? p.copyWith(sizeBytes: cached) : p;
      }),
    );
    trashItems.assignAll(
      allItems.where((p) => validTrash.contains(p.id)).map((p) {
        final cached = sizeMap[p.id];
        return cached != null ? p.copyWith(sizeBytes: cached) : p;
      }),
    );

    keptCount.value  = keptItems.length;
    trashCount.value = trashItems.length;
  }

  // ── Ordinamento ───────────────────────────────────────────────────────────

  Future<void> setSortMode(SortMode mode) async {
    if (currentSort.value == mode) return;
    currentSort.value = mode;
    final sorted = await _service.sort(allItems.toList(), mode);
    allItems.assignAll(sorted);
    final sortedKept = await _service.sort(keptItems.toList(), mode);
    keptItems.assignAll(sortedKept);
  }

  // ── Keep ──────────────────────────────────────────────────────────────────

  void keepItem(String id, {bool trackHistory = true}) {
    final idx = allItems.indexWhere((p) => p.id == id);
    if (idx == -1 || _processedIds.contains(id)) return;

    _processedIds.add(id);
    keptCount.value++;
    keptItems.add(allItems[idx]);
    allItems.refresh();
    onKeptIdsChanged(Set.from(_processedIds.where(_isKept)));

    if (trackHistory) {
      _history.add(MediaAction(id: id, type: MediaActionType.keep));
      canUndo.value = true;
    }
  }

  // ── Trash ────────────────────────────────────────────────────────────────

  void moveToTrash(String id, {bool trackHistory = true}) {
    final idx = allItems.indexWhere((p) => p.id == id);
    if (idx == -1 || _processedIds.contains(id)) return;

    _processedIds.add(id);
    trashCount.value++;
    trashItems.add(allItems[idx]);
    allItems.refresh();
    onTrashIdsChanged(Set.from(_processedIds.where(_isTrash)));

    if (trackHistory) {
      _history.add(MediaAction(id: id, type: MediaActionType.trash));
      canUndo.value = true;
    }
  }

  // ── Undo ─────────────────────────────────────────────────────────────────

  bool undoLastAction() {
    if (_history.isEmpty) return false;
    final last = _history.removeLast();
    canUndo.value = _history.isNotEmpty;

    if (last.type == MediaActionType.keep) {
      final idx = keptItems.indexWhere((p) => p.id == last.id);
      if (idx != -1) keptItems.removeAt(idx);
      _processedIds.remove(last.id);
      if (keptCount.value > 0) keptCount.value--;
      allItems.refresh();
      onKeptIdsChanged(Set.from(_processedIds.where(_isKept)));
    } else {
      final idx = trashItems.indexWhere((p) => p.id == last.id);
      if (idx != -1) trashItems.removeAt(idx);
      _processedIds.remove(last.id);
      if (trashCount.value > 0) trashCount.value--;
      allItems.refresh();
      onTrashIdsChanged(Set.from(_processedIds.where(_isTrash)));
    }
    return true;
  }

  // ── Unkeep ───────────────────────────────────────────────────────────────

  void unkeepItem(String id) {
    final idx = keptItems.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    keptItems.removeAt(idx);
    _processedIds.remove(id);
    if (keptCount.value > 0) keptCount.value--;
    allItems.refresh();
    onKeptIdsChanged(Set.from(_processedIds.where(_isKept)));
  }

  // ── Restore from trash ────────────────────────────────────────────────────

  void restoreFromTrash(String id) {
    final idx = trashItems.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    trashItems.removeAt(idx);
    _processedIds.remove(id);
    if (trashCount.value > 0) trashCount.value--;
    allItems.refresh();
    onTrashIdsChanged(Set.from(_processedIds.where(_isTrash)));
  }

  void restoreAllFromTrash() {
    for (final item in trashItems) {
      _processedIds.remove(item.id);
    }
    trashCount.value = 0;
    trashItems.clear();
    allItems.refresh();
    onTrashIdsChanged({});
  }

  // ── Delete from trash ─────────────────────────────────────────────────────

  Future<int> deleteFromTrash(List<String> ids) async {
    final toDelete = trashItems.where((p) => ids.contains(p.id)).toList();
    if (toDelete.isEmpty) return 0;

    final deletedIds = await _service.deleteAssets(toDelete);
    int freed = 0;

    for (final id in deletedIds) {
      final idx = trashItems.indexWhere((p) => p.id == id);
      if (idx != -1) {
        freed += trashItems[idx].sizeBytes;
        trashItems.removeAt(idx);
      }
      _processedIds.remove(id);
      allItems.removeWhere((p) => p.id == id);
    }

    trashCount.value = trashItems.length;
    onTrashIdsChanged(Set.from(_processedIds.where(_isTrash)));
    onBytesFreed(freed);
    return freed;
  }

  Future<int> emptyTrash() async =>
      deleteFromTrash(trashItems.map((e) => e.id).toList());

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetSession() async {
    _processedIds.clear();
    trashItems.clear();
    keptItems.clear();
    keptCount.value  = 0;
    trashCount.value = 0;
    _history.clear();
    canUndo.value = false;
    allItems.refresh();
    onSessionReset();
  }

  // ── Thumbnail full-res ────────────────────────────────────────────────────

  Future<PhotoItem> resolveFullThumb(PhotoItem item) async {
    final full = await _service.resolveFullThumb(item);
    return item.copyWith(thumbnail: full ?? item.thumbnail);
  }

  // ── Preload stream ────────────────────────────────────────────────────────

  Future<void> preloadAll(Map<String, int> sizeMap) async {
    await for (final resolved in _service.resolveStream(allItems.toList())) {
      for (final r in resolved) {
        final idx = allItems.indexWhere((p) => p.id == r.id);
        if (idx != -1) allItems[idx] = r;
        final tIdx = trashItems.indexWhere((p) => p.id == r.id);
        if (tIdx != -1) trashItems[tIdx] = r;
        final kIdx = keptItems.indexWhere((p) => p.id == r.id);
        if (kIdx != -1) keptItems[kIdx] = r;
        if (r.sizeBytes > 0) sizeMap[r.id] = r.sizeBytes;
      }
    }
  }

  // ── Hooks — override nelle sottoclassi per persistenza / stats ────────────

  /// Chiamato quando gli IDs mantenuti cambiano.
  void onKeptIdsChanged(Set<String> ids) {}

  /// Chiamato quando gli IDs del cestino cambiano.
  void onTrashIdsChanged(Set<String> ids) {}

  /// Chiamato dopo una cancellazione definitiva con i byte liberati.
  void onBytesFreed(int bytes) {}

  /// Chiamato da resetSession().
  void onSessionReset() {}

  // ── Helpers privati ───────────────────────────────────────────────────────

  bool _isKept(String id)  => keptItems.any((p) => p.id == id);
  bool _isTrash(String id) => trashItems.any((p) => p.id == id);
}
