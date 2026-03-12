import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/cache_service.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import '../../shared/i_media_controller.dart';

enum _Action { keep, trash }
class _Rec { const _Rec(this.id, this.type); final String id; final _Action type; }

class HomeController extends GetxController implements IMediaController {
  final _service    = PhotoService();
  CacheService get _cache => Get.find<CacheService>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ── IMediaController ──────────────────────────────────────────────────────
  @override final allItems   = <PhotoItem>[].obs;
  @override final trashItems = <PhotoItem>[].obs;
  @override final keptItems  = <PhotoItem>[].obs;
  @override final keptCount  = 0.obs;
  @override final trashCount = 0.obs;
  @override final canUndo    = false.obs;
  @override final currentSort = SortMode.dateNewest.obs;

  @override int get totalCount    => allItems.length;
  @override int get pendingCount  => pendingItems.length;
  @override int get trashBytes    => trashItems.fold(0, (s, e) => s + e.sizeBytes);
  @override int get keptBytes     => keptItems.fold(0, (s, e) => s + e.sizeBytes);
  @override double get progress   => totalCount == 0 ? 0 : _processedIds.length / totalCount;
  @override int get totalFreedBytes => _totalFreedBytes.value;

  // ── Stato locale ──────────────────────────────────────────────────────────
  final isLoading        = true.obs;
  final isVideoMode      = false.obs;
  final _totalFreedBytes = 0.obs;
  final pageController   = PageController();

  final _processedIds = <String>{};
  var   _keptIds      = <String>{};
  var   _trashIds     = <String>{};
  final _history      = <_Rec>[];

  VoidCallback? _swiperUndo;
  void attachSwiperUndo(VoidCallback cb) => _swiperUndo = cb;
  void detachSwiperUndo() => _swiperUndo = null;

  List<PhotoItem> get pendingItems =>
      allItems.where((p) => !_processedIds.contains(p.id)).toList();

  String fmt(int b) => PhotoService.formatBytes(b);

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void onInit() { super.onInit(); _initAndLoad(); }

  Future<void> _initAndLoad() async {
    await _cache.init();
    _totalFreedBytes.value = _cache.getFreedBytes();
    await loadPhotos();
  }

  // ── Caricamento ───────────────────────────────────────────────────────────
  Future<void> loadPhotos() async {
    isLoading.value = true;
    final ok = await _service.requestPermission();
    if (!ok) {
      isLoading.value = false;
      return;
    }

    final raw    = await _service.loadAllPhotos();
    final sorted = _service.sort(raw, currentSort.value);
    allItems.assignAll(sorted);

    _keptIds  = Set.from(_cache.getKeptIds());
    _trashIds = Set.from(_cache.getTrashIds());
    final allIds = Set.from(allItems.map((e) => e.id));
    _keptIds.retainAll(allIds);
    _trashIds.retainAll(allIds);
    _processedIds..clear()..addAll(_keptIds)..addAll(_trashIds);
    _history.clear();
    canUndo.value = false;

    final sizeMap = _cache.getSizeMap();
    keptItems.assignAll(allItems.where((p) => _keptIds.contains(p.id)).map(
        (p) { final c = sizeMap[p.id]; return c != null ? p.copyWith(sizeBytes: c) : p; }));
    trashItems.assignAll(allItems.where((p) => _trashIds.contains(p.id)).map(
        (p) { final c = sizeMap[p.id]; return c != null ? p.copyWith(sizeBytes: c) : p; }));
    keptCount.value  = keptItems.length;
    trashCount.value = trashItems.length;
    isLoading.value  = false;
    _preload();
  }

  @override
   Future<void> setSortMode(SortMode mode) async {
     if (currentSort.value == mode) return;
     currentSort.value = mode;
     allItems.assignAll(_service.sort(allItems.toList(), mode));
     keptItems.assignAll(_service.sort(keptItems.toList(), mode));
   }

  // ── Swipe ─────────────────────────────────────────────────────────────────
  @override
  void keepItem(String id, {bool trackHistory = true}) {
    final idx = allItems.indexWhere((p) => p.id == id);
    if (idx == -1 || _processedIds.contains(id)) return;
    _processedIds.add(id); _keptIds.add(id);
    keptCount.value++; keptItems.add(allItems[idx]);
    allItems.refresh(); _cache.saveKeptIds(_keptIds);
    if (trackHistory) { _history.add(_Rec(id, _Action.keep)); canUndo.value = true; }
  }

  // alias retrocompatibile per HomeView
  void keepPhoto(String id, {bool trackHistory = true}) =>
      keepItem(id, trackHistory: trackHistory);

  @override
  void moveToTrash(String id, {bool trackHistory = true}) {
    final idx = allItems.indexWhere((p) => p.id == id);
    if (idx == -1 || _processedIds.contains(id)) return;
    _processedIds.add(id); _trashIds.add(id);
    trashCount.value++; trashItems.add(allItems[idx]);
    allItems.refresh(); _cache.saveTrashIds(_trashIds);
    if (trackHistory) { _history.add(_Rec(id, _Action.trash)); canUndo.value = true; }
  }

  @override
  bool undoLastAction() {
    if (_history.isEmpty) return false;
    final last = _history.removeLast();
    canUndo.value = _history.isNotEmpty;
    if (last.type == _Action.keep) {
      keptItems.removeWhere((p) => p.id == last.id);
      _keptIds.remove(last.id); _processedIds.remove(last.id);
      if (keptCount.value > 0) keptCount.value--;
      allItems.refresh(); _cache.saveKeptIds(_keptIds);
    } else {
      trashItems.removeWhere((p) => p.id == last.id);
      _trashIds.remove(last.id); _processedIds.remove(last.id);
      if (trashCount.value > 0) trashCount.value--;
      allItems.refresh(); _cache.saveTrashIds(_trashIds);
    }
    _swiperUndo?.call();
    return true;
  }

  // ── Cestino ───────────────────────────────────────────────────────────────
  @override
  void restoreFromTrash(String id) {
    final idx = trashItems.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    trashItems.removeAt(idx); _processedIds.remove(id); _trashIds.remove(id);
    if (trashCount.value > 0) trashCount.value--;
    allItems.refresh(); _cache.saveTrashIds(_trashIds);
  }

  @override
  void restoreAllFromTrash() {
    for (final item in trashItems) { _processedIds.remove(item.id); _trashIds.remove(item.id); }
    trashCount.value = 0; trashItems.clear();
    allItems.refresh(); _cache.saveTrashIds(_trashIds);
  }

  @override
  Future<int> deleteFromTrash(List<String> ids) async {
    final toDelete = trashItems.where((p) => ids.contains(p.id)).toList();
    if (toDelete.isEmpty) return 0;
    final deletedIds = await _service.deleteAssets(toDelete);
    int freed = 0;
    for (final id in deletedIds) {
      final idx = trashItems.indexWhere((p) => p.id == id);
      if (idx != -1) { freed += trashItems[idx].sizeBytes; trashItems.removeAt(idx); }
      _trashIds.remove(id); _processedIds.remove(id);
      allItems.removeWhere((p) => p.id == id);
    }
    trashCount.value = trashItems.length;
    await _cache.addFreedBytes(freed);
    _totalFreedBytes.value = _cache.getFreedBytes();
    await _cache.saveTrashIds(_trashIds);
    return freed;
  }

  @override
  Future<int> emptyTrash() => deleteFromTrash(trashItems.map((e) => e.id).toList());

  // ── Mantenuti ─────────────────────────────────────────────────────────────
  @override
  void unkeepItem(String id) {
    final idx = keptItems.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    keptItems.removeAt(idx); _processedIds.remove(id); _keptIds.remove(id);
    if (keptCount.value > 0) keptCount.value--;
    allItems.refresh(); _cache.saveKeptIds(_keptIds);
  }

  // alias retrocompatibile
  void unkeepPhoto(String id) => unkeepItem(id);

  // ── Thumbnail ─────────────────────────────────────────────────────────────
  @override
  Future<PhotoItem> resolveFullThumb(PhotoItem item) async {
    final full = await _service.resolveFullThumb(item);
    return item.copyWith(thumbnail: full ?? item.thumbnail);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  Future<void> resetSession() async {
    isLoading.value = true;
    _processedIds.clear(); _keptIds.clear(); _trashIds.clear();
    trashItems.clear(); keptItems.clear();
    keptCount.value = 0; trashCount.value = 0;
    _history.clear(); canUndo.value = false;
    await _cache.clearAll();
    allItems.assignAll(_service.sort(allItems.toList(), currentSort.value));
    isLoading.value = false;
  }

  Future<void> resetAllStats() async {
    await resetSession(); await _cache.resetStats(); _totalFreedBytes.value = 0;
  }

  void setVideoMode(bool enabled) {
    isVideoMode.value = enabled;
    pageController.animateToPage(
      enabled ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  // ── Preload ───────────────────────────────────────────────────────────────
  Future<void> _preload() async {
    final sizeMap = Map<String, int>.from(_cache.getSizeMap());
    // Mappe indice O(1) invece di indexWhere O(n) per ogni elemento
    final allIdx   = <String, int>{for (var i = 0; i < allItems.length;   i++) allItems[i].id:   i};
    final trashIdx = <String, int>{for (var i = 0; i < trashItems.length; i++) trashItems[i].id: i};
    final keptIdx  = <String, int>{for (var i = 0; i < keptItems.length;  i++) keptItems[i].id:  i};

    await for (final resolved in _service.resolveStream(allItems.toList())) {
      // Aggiornamento silenzioso + un solo refresh() per batch (no rebuild per-item)
      for (final r in resolved) {
        final i  = allIdx[r.id];   if (i  != null) allItems[i]   = r;
        final ti = trashIdx[r.id]; if (ti != null) trashItems[ti] = r;
        final ki = keptIdx[r.id];  if (ki != null) keptItems[ki]  = r;
        if (r.sizeBytes > 0) sizeMap[r.id] = r.sizeBytes;
      }
      allItems.refresh();
      if (trashItems.isNotEmpty) trashItems.refresh();
      if (keptItems.isNotEmpty)  keptItems.refresh();
      // Cede il thread UI tra un batch e l'altro per evitare frame drop
      await Future.delayed(Duration.zero);
    }
    await _cache.saveSizeMap(sizeMap);
  }
}