import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/duplicate_service.dart';
import 'package:media_cleaner/app/models/photo_item.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

class DuplicatesController extends GetxController {
  HomeController get _home => Get.find<HomeController>();

  static const initialScanLimit = 400;
  // Larger chunk → fewer isolate spawns (each has ~5 ms fixed overhead)
  static const _phashChunkSize  = 80;
  static const _phashThreshold  = 8;

  final groups       = <DuplicateGroup>[].obs;
  final isScanning   = false.obs;
  final hasMore      = false.obs;
  final selectedIds  = <String>{}.obs;
  final scanProgress = 0.0.obs;

  // ── Derived ───────────────────────────────────────────────────────────────

  int get totalWasteBytes     => groups.fold(0, (s, g) => s + g.wasteBytes);
  int get totalDuplicateCount => groups.fold(0, (s, g) => s + g.duplicates.length);

  int get selectedWasteBytes {
    // Build lookup from allItems once
    final index = {for (final p in _home.allItems) p.id: p.sizeBytes};
    return selectedIds.fold(0, (s, id) => s + (index[id] ?? 0));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    scan();
  }

  @override
  void onClose() {
    selectedIds.clear();
    super.onClose();
  }

  // ── Scan ─────────────────────────────────────────────────────────────────

  Future<void> scan() async {
    isScanning.value   = true;
    scanProgress.value = 0;
    selectedIds.clear();
    await Future.delayed(Duration.zero);

    final allCandidates = _home.allItems.where((p) => p.sizeBytes > 0).toList();
    final items = allCandidates.length > initialScanLimit
        ? allCandidates.sublist(0, initialScanLimit)
        : allCandidates;

    final found = await _runDuplicateScan(items);
    groups.assignAll(found);
    _autoSelectDuplicates(found);

    hasMore.value    = allCandidates.length > initialScanLimit;
    isScanning.value = false;
  }

  Future<void> scanAll() async {
    isScanning.value   = true;
    scanProgress.value = 0;
    selectedIds.clear();
    await Future.delayed(Duration.zero);

    final allCandidates = _home.allItems.where((p) => p.sizeBytes > 0).toList();
    final found = await _runDuplicateScan(allCandidates);
    groups.assignAll(found);
    _autoSelectDuplicates(found);

    hasMore.value    = false;
    isScanning.value = false;
  }

  void _autoSelectDuplicates(List<DuplicateGroup> found) {
    for (final g in found) {
      for (final dup in g.duplicates) {
        selectedIds.add(dup.id);
      }
    }
  }

  Future<List<DuplicateGroup>> _runDuplicateScan(List<PhotoItem> items) async {
    scanProgress.value = 0.0;
    final processedIds = <String>{};
    final groups       = <DuplicateGroup>[];

    // ── Pass 1: exact match (size + minute-resolution timestamp) ─────────────
    final exactMap = <String, List<PhotoItem>>{};
    for (final item in items) {
      if (item.sizeBytes <= 0) continue;
      final dt  = item.createdAt;
      final key =
          '${item.sizeBytes}_${dt.year}${_p(dt.month)}${_p(dt.day)}${_p(dt.hour)}${_p(dt.minute)}';
      exactMap.putIfAbsent(key, () => []).add(item);
    }
    for (final g in exactMap.values) {
      if (g.length < 2) continue;
      groups.add(DuplicateGroup(g));
      for (final i in g) {
        processedIds.add(i.id);
      }
    }
    scanProgress.value = 0.2;

    // ── Pass 2: perceptual hash in isolate chunks ─────────────────────────────
    final unprocessed = items
        .where((i) => !processedIds.contains(i.id) && i.thumbnail != null)
        .toList();

    if (unprocessed.isNotEmpty) {
      final allHashes = <String, int>{};

      for (int i = 0; i < unprocessed.length; i += _phashChunkSize) {
        final end   = min(i + _phashChunkSize, unprocessed.length);
        final chunk = unprocessed.sublist(i, end);
        final input = [for (final item in chunk) (item.id, item.thumbnail!)];
        final hashes = await compute(DuplicateService.computeAllHashes, input);
        allHashes.addAll(hashes);
        scanProgress.value = 0.2 + 0.7 * (end / unprocessed.length);
      }

      // Convert to parallel arrays for cache-friendly inner loop
      final hashItems  = [for (final i in unprocessed) if (allHashes.containsKey(i.id)) i];
      final hashValues = Int64List.fromList(
          [for (final i in hashItems) allHashes[i.id]!]);

      final used = <String>{};
      for (int i = 0; i < hashItems.length; i++) {
        final item = hashItems[i];
        if (used.contains(item.id)) continue;

        final group = [item];
        final ha    = hashValues[i];
        for (int j = i + 1; j < hashItems.length; j++) {
          final other = hashItems[j];
          if (used.contains(other.id)) continue;
          if (_hamming(ha, hashValues[j]) <= _phashThreshold) {
            group.add(other);
            used.add(other.id);
          }
        }
        if (group.length >= 2) {
          used.add(item.id);
          groups.add(DuplicateGroup(group, isPerceptual: true));
        }
      }
    }

    scanProgress.value = 1.0;
    groups.sort((a, b) => b.wasteBytes.compareTo(a.wasteBytes));
    return groups;
  }

  // Population-count via Brian Kernighan's algorithm (faster than shift loop)
  static int _hamming(int a, int b) {
    int xor = a ^ b, count = 0;
    while (xor != 0) { xor &= xor - 1; count++; }
    return count;
  }

  static String _p(int n) => n.toString().padLeft(2, '0');

  // ── Selection ─────────────────────────────────────────────────────────────

  void toggleSelect(String id, DuplicateGroup group) {
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
    // no need to call refresh() — RxSet notifies automatically
  }

  void selectAllDuplicates() {
    for (final g in groups) {
      for (final dup in g.duplicates) {
        selectedIds.add(dup.id);
      }
    }
  }

  void clearSelection() => selectedIds.clear();

  // ── Actions ───────────────────────────────────────────────────────────────

  void moveSelectedToTrash() {
    final trashSet = {for (final t in _home.trashItems) t.id};
    final keptSet  = {for (final k in _home.keptItems)  k.id};
    for (final id in selectedIds.toList()) {
      if (trashSet.contains(id) || keptSet.contains(id)) continue;
      _home.moveToTrash(id);
    }
    scan();
  }

  Future<Uint8List?> loadFull(PhotoItem item) =>
      _home.resolveFullThumb(item).then((p) => p.thumbnail);
}