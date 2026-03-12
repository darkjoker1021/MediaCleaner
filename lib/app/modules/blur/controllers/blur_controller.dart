import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/blur_service.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/models/photo_item.dart';
import 'package:photo_manager/photo_manager.dart';

class BlurItem {
  final PhotoItem  item;
  final QualityIssue issue;
  const BlurItem({required this.item, required this.issue});
}

class BlurController extends GetxController {
  HomeController get _home => Get.find<HomeController>();

  static const initialScanLimit   = 200;
  static const _analysisThumbSize = ThumbnailSize.square(128);
  static const _chunkSize         = 40;

  final isScanning   = true.obs;
  final hasMore      = false.obs;
  final isSelecting  = false.obs;
  final blurItems    = <BlurItem>[].obs;
  final selectedIds  = <String>{}.obs;
  final scanProgress = 0.0.obs;
  final filter       = Rxn<QualityIssue>();

  // FIX: conteggi per issue calcolati una volta a fine scan e esposti come Rx
  // → BlurFilterChips non fa più 3× O(n) .where() per ogni rebuild
  final issueCount = <QualityIssue, int>{}.obs;

  // FIX: displayed è una RxList aggiornata esplicitamente solo quando
  // filter o blurItems cambiano — non ricostruisce la lista ad ogni accesso
  final displayed = <BlurItem>[].obs;

  bool get allSelected =>
      displayed.isNotEmpty && selectedIds.length == displayed.length;

  @override
  void onReady() {
    super.onReady();
    // Aggiorna displayed ogni volta che cambia il filtro
    ever(filter, (_) => _rebuildDisplayed());
    scan();
  }

  void _rebuildDisplayed() {
    final f = filter.value;
    displayed.assignAll(
      f == null ? blurItems : blurItems.where((b) => b.issue == f),
    );
  }

  void _rebuildIssueCount() {
    final counts = <QualityIssue, int>{};
    for (final b in blurItems) {
      counts[b.issue] = (counts[b.issue] ?? 0) + 1;
    }
    issueCount.assignAll(counts);
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> scan({bool all = false}) async {
    isScanning.value   = true;
    blurItems.clear();
    displayed.clear();
    issueCount.clear();
    selectedIds.clear();
    scanProgress.value = 0;
    filter.value       = null;

    final trashSet  = {for (final p in _home.trashItems) p.id};
    final keptSet   = {for (final p in _home.keptItems)  p.id};
    final allSource = _home.allItems
        .where((p) => !trashSet.contains(p.id) && !keptSet.contains(p.id))
        .toList();

    final source = !all && allSource.length > initialScanLimit
        ? allSource.sublist(0, initialScanLimit)
        : allSource;

    await _runChunked(source);

    _rebuildIssueCount();
    _rebuildDisplayed();
    scanProgress.value = 1.0;
    hasMore.value      = !all && allSource.length > initialScanLimit;
    isScanning.value   = false;
  }

  // FIX: scanAll collassato in scan(all: true) — niente duplicazione
  Future<void> scanAll() => scan(all: true);

  Future<void> _runChunked(List<PhotoItem> source) async {
    if (source.isEmpty) return;

    final itemById = {for (final p in source) p.id: p};

    for (int i = 0; i < source.length; i += _chunkSize) {
      final end   = min(i + _chunkSize, source.length);
      final chunk = source.sublist(i, end);

      final thumbs = await Future.wait(
        chunk.map((p) => p.asset.thumbnailDataWithSize(_analysisThumbSize)),
      );

      final pairs = <(String, Uint8List)>[];
      for (int j = 0; j < chunk.length; j++) {
        final bytes = thumbs[j];
        if (bytes != null) pairs.add((chunk[j].id, bytes));
      }

      if (pairs.isNotEmpty) {
        final results  = await compute(BlurService.analyzeAll, pairs);
        final newItems = <BlurItem>[];
        for (final (id, issueIndex) in results) {
          final item = itemById[id];
          if (item != null) {
            newItems.add(BlurItem(item: item, issue: QualityIssue.values[issueIndex]));
          }
        }
        if (newItems.isNotEmpty) blurItems.addAll(newItems);
      }

      scanProgress.value = end / source.length;
    }
  }

  // ── Azioni ────────────────────────────────────────────────────────────────

  Future<PhotoItem> loadFullThumb(PhotoItem item) =>
      _home.resolveFullThumb(item);

  void moveToTrash(String id) {
    _home.moveToTrash(id);
    blurItems.removeWhere((e) => e.item.id == id);
    selectedIds.remove(id);
    // FIX: RxSet notifica da solo — nessun refresh() necessario
    _rebuildDisplayed();
    _rebuildIssueCount();
  }

  void toggleSelectionMode() {
    isSelecting.value = !isSelecting.value;
    if (!isSelecting.value) clearSelection();
  }

  void toggleSelect(String id) {
    // FIX: RxSet notifica automaticamente — rimosso selectedIds.refresh()
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
  }

  void clearSelection() => selectedIds.clear();

  void selectAll() {
    selectedIds.assignAll(displayed.map((e) => e.item.id));
    // FIX: nessun refresh() ridondante
  }

  // FIX: bulk moveToTrash — un solo removeWhere invece di O(n²) in loop
  int moveSelectedToTrash() {
    if (selectedIds.isEmpty) return 0;
    final ids = Set<String>.from(selectedIds);

    // Sposta tutti nel cestino in un colpo solo
    for (final id in ids) {
      _home.moveToTrash(id);
    }

    // Rimuovi dalla lista con un unico scan
    blurItems.removeWhere((e) => ids.contains(e.item.id));
    selectedIds.clear();
    isSelecting.value = false;

    _rebuildDisplayed();
    _rebuildIssueCount();
    return ids.length;
  }

  int moveAllToTrash() {
    selectAll();
    return moveSelectedToTrash();
  }
}