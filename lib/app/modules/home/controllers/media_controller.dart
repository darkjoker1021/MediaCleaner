import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';

// ── Undo history ──────────────────────────────────────────────────────────────

enum MediaActionType { keep, trash }

class MediaAction {
  const MediaAction({required this.id, required this.type});
  final String id;
  final MediaActionType type;
}

// ── Base controller ───────────────────────────────────────────────────────────

/// Logica condivisa tra foto e video: lista, swipe, undo, trash, kept.
abstract class MediaController extends GetxController {
  final _service = PhotoService();

  // ── Stato osservabile ────────────────────────────────────────────────────

  final trashItems  = <PhotoItem>[].obs;
  final keptItems   = <PhotoItem>[].obs;
  final isLoading   = true.obs;
  final canUndo     = false.obs;
  final currentSort = SortMode.dateNewest.obs;

  final keptCount  = 0.obs;
  final trashCount = 0.obs;

  // FIX: calcoli aggregati memoizzati — invalida solo quando le liste cambiano
  int get trashBytes => _trashBytesCache ??= trashItems.fold(0, (s, e) => s! + e.sizeBytes) ?? 0;
  int get keptBytes  => _keptBytesCache  ??= keptItems.fold(0,  (s, e) => s! + e.sizeBytes) ?? 0;

  int? _trashBytesCache;
  int? _keptBytesCache;

  int get totalFreedBytes => 0;

  // ── Stato interno ────────────────────────────────────────────────────────

  final _processedIds = <String>{};
  final _history      = <MediaAction>[];

  // FIX: indice O(1) su allItems — aggiornato solo in loadMedia/preload
  final _allIndex   = <String, int>{};
  // FIX: indice O(1) su trashItems e keptItems
  final _trashIndex = <String, int>{};
  final _keptIndex  = <String, int>{};

  // ── Astratti ─────────────────────────────────────────────────────────────

  RxList<PhotoItem> get allItems;
  Future<void> loadMedia();

  // ── Derivati ─────────────────────────────────────────────────────────────

  // FIX: pendingItems cached — lista O(n) costruita una sola volta per frame
  List<PhotoItem>? _pendingCache;
  List<PhotoItem> get pendingItems =>
      _pendingCache ??= [for (final p in allItems) if (!_processedIds.contains(p.id)) p];

  void _invalidatePending() => _pendingCache = null;

  int get pendingCount => pendingItems.length;
  int get totalCount   => allItems.length;
  double get progress  =>
      totalCount == 0 ? 0 : _processedIds.length / totalCount;

  String fmt(int b) => PhotoService.formatBytes(b);

  // ── Caricamento comune ────────────────────────────────────────────────────

  Future<void> initAfterLoad({
    Set<String> keptIds   = const {},
    Set<String> trashIds  = const {},
    Map<String, int> sizeMap = const {},
  }) async {
    // FIX: costruisci l'indice una volta sola
    _rebuildAllIndex();

    final allIds     = _allIndex.keys.toSet();
    final validKept  = keptIds.intersection(allIds);
    final validTrash = trashIds.intersection(allIds);

    _processedIds
      ..clear()
      ..addAll(validKept)
      ..addAll(validTrash);
    _invalidatePending();

    _history.clear();
    canUndo.value = false;

    keptItems.assignAll(allItems.where((p) => validKept.contains(p.id)).map((p) {
      final cached = sizeMap[p.id];
      return cached != null ? p.copyWith(sizeBytes: cached) : p;
    }));
    trashItems.assignAll(allItems.where((p) => validTrash.contains(p.id)).map((p) {
      final cached = sizeMap[p.id];
      return cached != null ? p.copyWith(sizeBytes: cached) : p;
    }));

    _rebuildTrashIndex();
    _rebuildKeptIndex();
    _trashBytesCache = null;
    _keptBytesCache  = null;

    keptCount.value  = keptItems.length;
    trashCount.value = trashItems.length;
  }

  // ── Keep / Trash ──────────────────────────────────────────────────────────

  void keepItem(String id) {
    if (_processedIds.contains(id)) return;
    _processedIds.add(id);
    _invalidatePending();

    final idx = _allIndex[id];
    if (idx == null) return;
    final item = allItems[idx];

    _keptIndex[id] = keptItems.length;
    keptItems.add(item);
    keptCount.value = keptItems.length;
    _keptBytesCache = null;

    _history.add(MediaAction(id: id, type: MediaActionType.keep));
    canUndo.value = true;

    onKeptIdsChanged(Set.from(_processedIds.where(_isKept)));
  }

  void trashItem(String id) {
    if (_processedIds.contains(id)) return;
    _processedIds.add(id);
    _invalidatePending();

    final idx = _allIndex[id];
    if (idx == null) return;
    final item = allItems[idx];

    _trashIndex[id] = trashItems.length;
    trashItems.add(item);
    trashCount.value = trashItems.length;
    _trashBytesCache = null;

    _history.add(MediaAction(id: id, type: MediaActionType.trash));
    canUndo.value = true;

    onTrashIdsChanged(Set.from(_processedIds.where(_isTrash)));
  }

  bool _isKept(String id)  => keptItems.any((p) => p.id == id);
  bool _isTrash(String id) => trashItems.any((p) => p.id == id);

  // ── Undo ─────────────────────────────────────────────────────────────────

  void undo() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    _processedIds.remove(last.id);
    _invalidatePending();

    if (last.type == MediaActionType.keep) {
      // FIX: rimozione O(1) via indice invece di indexWhere
      final ki = _keptIndex.remove(last.id);
      if (ki != null && ki < keptItems.length && keptItems[ki].id == last.id) {
        keptItems.removeAt(ki);
        // Aggiorna indici degli elementi rimasti dopo ki
        for (var i = ki; i < keptItems.length; i++) {
          _keptIndex[keptItems[i].id] = i;
        }
      } else {
        // Fallback se l'indice è obsoleto
        final fallback = keptItems.indexWhere((p) => p.id == last.id);
        if (fallback != -1) keptItems.removeAt(fallback);
        _rebuildKeptIndex();
      }
      keptCount.value = keptItems.length;
      _keptBytesCache = null;
    } else {
      final ti = _trashIndex.remove(last.id);
      if (ti != null && ti < trashItems.length && trashItems[ti].id == last.id) {
        trashItems.removeAt(ti);
        for (var i = ti; i < trashItems.length; i++) {
          _trashIndex[trashItems[i].id] = i;
        }
      } else {
        final fallback = trashItems.indexWhere((p) => p.id == last.id);
        if (fallback != -1) trashItems.removeAt(fallback);
        _rebuildTrashIndex();
      }
      trashCount.value = trashItems.length;
      _trashBytesCache = null;
    }

    canUndo.value = _history.isNotEmpty;
    onKeptIdsChanged(Set.from(keptItems.map((p) => p.id)));
    onTrashIdsChanged(Set.from(trashItems.map((p) => p.id)));
  }

  // ── Restore from trash ────────────────────────────────────────────────────

  void restoreAllFromTrash() {
    for (final item in trashItems) {
      _processedIds.remove(item.id);
    }
    _invalidatePending();
    trashCount.value = 0;
    trashItems.clear();
    _trashIndex.clear();
    _trashBytesCache = null;
    allItems.refresh();
    onTrashIdsChanged({});
  }

  // ── Delete from trash ─────────────────────────────────────────────────────

  Future<int> deleteFromTrash(List<String> ids) async {
    final toDelete = trashItems.where((p) => ids.contains(p.id)).toList();
    if (toDelete.isEmpty) return 0;

    final deletedIds = await _service.deleteAssets(toDelete);
    if (deletedIds.isEmpty) return 0;

    // FIX: calcola freed con indice O(1)
    int freed = 0;
    final deletedSet = Set<String>.from(deletedIds);

    for (final id in deletedIds) {
      final ti = _trashIndex.remove(id);
      if (ti != null && ti < trashItems.length && trashItems[ti].id == id) {
        freed += trashItems[ti].sizeBytes;
      }
      _processedIds.remove(id);
    }

    // Rimuovi in blocco (più efficiente di removeAt ripetuti)
    trashItems.removeWhere((p) => deletedSet.contains(p.id));
    allItems.removeWhere((p) => deletedSet.contains(p.id));
    _rebuildTrashIndex();
    _rebuildAllIndex();
    _invalidatePending();

    trashCount.value = trashItems.length;
    _trashBytesCache = null;

    onTrashIdsChanged(Set.from(trashItems.map((p) => p.id)));
    onBytesFreed(freed);
    return freed;
  }

  Future<int> emptyTrash() =>
      deleteFromTrash(trashItems.map((e) => e.id).toList());

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetSession() async {
    _processedIds.clear();
    _invalidatePending();
    trashItems.clear();
    keptItems.clear();
    _trashIndex.clear();
    _keptIndex.clear();
    keptCount.value  = 0;
    trashCount.value = 0;
    _trashBytesCache = null;
    _keptBytesCache  = null;
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
        // FIX: aggiornamento O(1) via indice — niente indexWhere O(n)
        final ai = _allIndex[r.id];
        if (ai != null) allItems[ai] = r;

        final ti = _trashIndex[r.id];
        if (ti != null) trashItems[ti] = r;

        final ki = _keptIndex[r.id];
        if (ki != null) keptItems[ki] = r;

        if (r.sizeBytes > 0) sizeMap[r.id] = r.sizeBytes;
      }
      // Un solo refresh per batch invece di uno per elemento
      allItems.refresh();
      if (_trashIndex.isNotEmpty) trashItems.refresh();
      if (_keptIndex.isNotEmpty)  keptItems.refresh();
      _trashBytesCache = null;
      _keptBytesCache  = null;
    }
  }

  // ── Index helpers ─────────────────────────────────────────────────────────

  void _rebuildAllIndex() {
    _allIndex.clear();
    for (var i = 0; i < allItems.length; i++) {
      _allIndex[allItems[i].id] = i;
    }
  }

  void _rebuildTrashIndex() {
    _trashIndex.clear();
    for (var i = 0; i < trashItems.length; i++) {
      _trashIndex[trashItems[i].id] = i;
    }
  }

  void _rebuildKeptIndex() {
    _keptIndex.clear();
    for (var i = 0; i < keptItems.length; i++) {
      _keptIndex[keptItems[i].id] = i;
    }
  }

  // ── Hooks — override nelle sottoclassi ───────────────────────────────────

  void onKeptIdsChanged(Set<String> ids) {}
  void onTrashIdsChanged(Set<String> ids) {}
  void onBytesFreed(int bytes) {}
  void onSessionReset() {}
}