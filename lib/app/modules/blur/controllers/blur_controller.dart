import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/blur_service.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';
import 'package:media_cleaner/app/models/photo_item.dart';
import 'package:photo_manager/photo_manager.dart';

class BlurItem {
  final PhotoItem item;
  final QualityIssue issue;
  const BlurItem({required this.item, required this.issue});
}

class BlurController extends GetxController {
  HomeController get _home => Get.find<HomeController>();

  static const initialScanLimit = 200;
  static const _analysisThumbSize = ThumbnailSize.square(128);
  // Larger chunk → fewer isolate round-trips (each compute() has ~5 ms overhead)
  static const _chunkSize = 40;

  final isScanning   = true.obs;
  final hasMore      = false.obs;
  final isSelecting  = false.obs;
  final blurItems    = <BlurItem>[].obs;
  final selectedIds  = <String>{}.obs;
  final scanProgress = 0.0.obs;
  final filter       = Rxn<QualityIssue>();

  List<BlurItem> get displayed => filter.value == null
      ? blurItems
      : blurItems.where((b) => b.issue == filter.value).toList();

  bool get allSelected =>
      displayed.isNotEmpty && selectedIds.length == displayed.length;

  @override
  void onReady() {
    super.onReady();
    scan();
  }

  Future<void> scan() async {
    isScanning.value   = true;
    blurItems.clear();
    selectedIds.clear();
    scanProgress.value = 0;
    filter.value       = null;

    final trashSet = {for (final p in _home.trashItems) p.id};
    final keptSet  = {for (final p in _home.keptItems)  p.id};
    final allSource = _home.allItems
        .where((p) => !trashSet.contains(p.id) && !keptSet.contains(p.id))
        .toList();

    final source = allSource.length > initialScanLimit
        ? allSource.sublist(0, initialScanLimit)
        : allSource;

    await _runChunked(source);

    scanProgress.value = 1.0;
    hasMore.value      = allSource.length > initialScanLimit;
    isScanning.value   = false;
  }

  Future<void> scanAll() async {
    isScanning.value   = true;
    blurItems.clear();
    selectedIds.clear();
    scanProgress.value = 0;
    filter.value       = null;

    final trashSet = {for (final p in _home.trashItems) p.id};
    final keptSet  = {for (final p in _home.keptItems)  p.id};
    final source = _home.allItems
        .where((p) => !trashSet.contains(p.id) && !keptSet.contains(p.id))
        .toList();

    await _runChunked(source);

    scanProgress.value = 1.0;
    hasMore.value      = false;
    isScanning.value   = false;
  }

  /// Processes [source] in chunks: loads small thumbnails concurrently,
  /// then offloads analysis to an isolate. Larger chunks reduce isolate
  /// overhead; progress is still updated after each chunk.
  Future<void> _runChunked(List<PhotoItem> source) async {
    if (source.isEmpty) return;

    // Build an id→item lookup once (avoids O(n) firstWhereOrNull per result)
    final itemById = {for (final p in source) p.id: p};

    for (int i = 0; i < source.length; i += _chunkSize) {
      final end   = min(i + _chunkSize, source.length);
      final chunk = source.sublist(i, end);

      // Load all thumbnails in parallel
      final thumbFutures =
          chunk.map((p) => p.asset.thumbnailDataWithSize(_analysisThumbSize));
      final thumbs = await Future.wait(thumbFutures);

      final pairs = <(String, Uint8List)>[];
      for (int j = 0; j < chunk.length; j++) {
        final bytes = thumbs[j];
        if (bytes != null) pairs.add((chunk[j].id, bytes));
      }

      if (pairs.isNotEmpty) {
        final results = await compute(BlurService.analyzeAll, pairs);
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

  Future<PhotoItem> loadFullThumb(PhotoItem item) =>
      _home.resolveFullThumb(item);

  void moveToTrash(String id) {
    _home.moveToTrash(id);
    blurItems.removeWhere((e) => e.item.id == id);
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

  void clearSelection()  { selectedIds.clear(); selectedIds.refresh(); }

  void selectAll() {
    selectedIds.assignAll(displayed.map((e) => e.item.id));
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
}