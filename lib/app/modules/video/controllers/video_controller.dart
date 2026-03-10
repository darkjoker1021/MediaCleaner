import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/data/service/cache_service.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/i_media_controller.dart';

enum _A { keep, trash }
class _R { const _R(this.id, this.t); final String id; final _A t; }

class VideoController extends GetxController implements IMediaController {
  final _service = PhotoService();
  final _cache   = CacheService();

  // ── IMediaController ──────────────────────────────────────────────────────
  @override final allItems    = <PhotoItem>[].obs;
  @override final trashItems  = <PhotoItem>[].obs;
  @override final keptItems   = <PhotoItem>[].obs;
  @override final keptCount   = 0.obs;
  @override final trashCount  = 0.obs;
  @override final canUndo     = false.obs;
  @override final currentSort = SortMode.dateNewest.obs;

  @override int    get totalCount      => allItems.length;
  @override int    get pendingCount    => pendingItems.length;
  @override int    get trashBytes      => trashItems.fold(0, (s, e) => s + e.sizeBytes);
  @override int    get keptBytes       => keptItems.fold(0, (s, e) => s + e.sizeBytes);
  @override double get progress        => totalCount == 0 ? 0 : _ids.length / totalCount;
  @override int    get totalFreedBytes => _totalFreedBytes.value; // video non tracciano storico spazio

  // ── Stato locale ──────────────────────────────────────────────────────────
  final isLoading = true.obs;

  final _ids  = <String>{};
  var   _keptIds  = <String>{};
  var   _trashIds = <String>{};
  final _hist = <_R>[];
  final _totalFreedBytes = 0.obs;

  // alias usati in VideoView
  List<PhotoItem> get pendingItems =>
      allItems.where((p) => !_ids.contains(p.id)).toList();
  List<PhotoItem> get pendingVideos => pendingItems;

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void onReady() { super.onReady(); _initAndLoad(); }

  Future<void> _initAndLoad() async {
    await _cache.init();
    await loadVideos();
  }

  Future<void> loadVideos() async {
    isLoading.value = true;
    if (!await _service.requestPermission()) { isLoading.value = false; return; }

    final sorted = await _service.sort(
        await _service.loadAllVideos(), currentSort.value);
    allItems.assignAll(sorted);

    // Ripristina kept/trash dalla cache
    _keptIds  = Set.from(_cache.getVideoKeptIds());
    _trashIds = Set.from(_cache.getVideoTrashIds());
    final allIds = Set.from(allItems.map((e) => e.id));
    _keptIds.retainAll(allIds);
    _trashIds.retainAll(allIds);
    _ids..clear()..addAll(_keptIds)..addAll(_trashIds);
    _hist.clear(); canUndo.value = false;

    keptItems.assignAll(allItems.where((p) => _keptIds.contains(p.id)));
    trashItems.assignAll(allItems.where((p) => _trashIds.contains(p.id)));
    keptCount.value  = keptItems.length;
    trashCount.value = trashItems.length;
    isLoading.value = false;

    // preload thumbnails in background
    await for (final batch in _service.resolveStream(sorted)) {
      for (final r in batch) {
        final i = allItems.indexWhere((e) => e.id == r.id);
        if (i >= 0) allItems[i] = r;
      }
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  Future<void> resetSession() async {
    _ids.clear(); _keptIds.clear(); _trashIds.clear();
    trashItems.clear(); keptItems.clear();
    keptCount.value = 0; trashCount.value = 0;
    _hist.clear(); canUndo.value = false;
    await _cache.clearAll();
    allItems.assignAll(await _service.sort(allItems.toList(), currentSort.value));
  }

  Future<void> resetAllStats() async {
    await resetSession(); await _cache.resetStats(); _totalFreedBytes.value = 0;
  }

  @override
  Future<void> setSortMode(SortMode m) async {
    if (currentSort.value == m) return;
    currentSort.value = m;
    allItems.assignAll(await _service.sort(allItems.toList(), m));
  }

  // ── IMediaController: swipe ───────────────────────────────────────────────
  @override
  void keepItem(String id, {bool trackHistory = true}) {
    final i = allItems.indexWhere((p) => p.id == id);
    if (i < 0 || _ids.contains(id)) return;
    _ids.add(id); _keptIds.add(id);
    keptItems.add(allItems[i]); keptCount.value++;
    allItems.refresh();
    _cache.saveVideoKeptIds(_keptIds);
    if (trackHistory) { _hist.add(_R(id, _A.keep)); canUndo.value = true; }
  }
  // alias usato in VideoView
  void keepVideo(String id, {bool trackHistory = true}) =>
      keepItem(id, trackHistory: trackHistory);

  @override
  void moveToTrash(String id, {bool trackHistory = true}) {
    final i = allItems.indexWhere((p) => p.id == id);
    if (i < 0 || _ids.contains(id)) return;
    _ids.add(id); _trashIds.add(id);
    trashItems.add(allItems[i]); trashCount.value++;
    allItems.refresh();
    _cache.saveVideoTrashIds(_trashIds);
    if (trackHistory) { _hist.add(_R(id, _A.trash)); canUndo.value = true; }
  }

  @override
  bool undoLastAction() {
    if (_hist.isEmpty) return false;
    final r = _hist.removeLast(); canUndo.value = _hist.isNotEmpty;
    _ids.remove(r.id);
    if (r.t == _A.keep) {
      keptItems.removeWhere((p) => p.id == r.id);
      _keptIds.remove(r.id);
      if (keptCount.value > 0) keptCount.value--;
      _cache.saveVideoKeptIds(_keptIds);
    } else {
      trashItems.removeWhere((p) => p.id == r.id);
      _trashIds.remove(r.id);
      if (trashCount.value > 0) trashCount.value--;
      _cache.saveVideoTrashIds(_trashIds);
    }
    allItems.refresh();
    return true;
  }

  // ── IMediaController: cestino ─────────────────────────────────────────────
  @override
  void restoreFromTrash(String id) {
    final i = trashItems.indexWhere((p) => p.id == id);
    if (i < 0) return;
    trashItems.removeAt(i); _ids.remove(id); _trashIds.remove(id);
    if (trashCount.value > 0) trashCount.value--;
    allItems.refresh();
    _cache.saveVideoTrashIds(_trashIds);
  }

  @override
  void restoreAllFromTrash() {
    for (final p in trashItems) { _ids.remove(p.id); _trashIds.remove(p.id); }
    trashCount.value = 0; trashItems.clear(); allItems.refresh();
    _cache.saveVideoTrashIds(_trashIds);
  }

  @override
  Future<int> deleteFromTrash(List<String> ids) async {
    final del = trashItems.where((p) => ids.contains(p.id)).toList();
    if (del.isEmpty) return 0;
    final done = await _service.deleteAssets(del);
    for (final id in done) {
      trashItems.removeWhere((p) => p.id == id);
      _ids.remove(id); _trashIds.remove(id);
      allItems.removeWhere((p) => p.id == id);
    }
    trashCount.value = trashItems.length;
    _cache.saveVideoTrashIds(_trashIds);
    return done.length;
  }

  @override
  Future<int> emptyTrash() =>
      deleteFromTrash(trashItems.map((e) => e.id).toList());

  // ── IMediaController: mantenuti ───────────────────────────────────────────
  @override
  void unkeepItem(String id) {
    final i = keptItems.indexWhere((p) => p.id == id);
    if (i < 0) return;
    keptItems.removeAt(i); _ids.remove(id); _keptIds.remove(id);
    if (keptCount.value > 0) keptCount.value--;
    allItems.refresh();
    _cache.saveVideoKeptIds(_keptIds);
  }

  // ── IMediaController: thumbnail ───────────────────────────────────────────
  @override
  Future<PhotoItem> resolveFullThumb(PhotoItem item) async {
    final b = await _service.resolveFullThumb(item);
    return item.copyWith(thumbnail: b ?? item.thumbnail);
  }
}