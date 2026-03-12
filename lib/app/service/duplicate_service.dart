import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:media_cleaner/app/models/photo_item.dart';

class DuplicateGroup {
  final List<PhotoItem> items;
  final bool isPerceptual;
  DuplicateGroup(this.items, {this.isPerceptual = false});

  PhotoItem get best =>
      items.reduce((a, b) => a.sizeBytes >= b.sizeBytes ? a : b);
  List<PhotoItem> get duplicates =>
      items.where((i) => i.id != best.id).toList();
  int get wasteBytes => duplicates.fold(0, (s, e) => s + e.sizeBytes);
  int get totalBytes => items.fold(0, (s, e) => s + e.sizeBytes);
  int get count => items.length;
}

class DuplicateService {
  static const _phashThreshold = 8;

  // Precomputed integer channel weights (×1000)
  static const int _wr = 299, _wg = 587, _wb = 114;

  List<DuplicateGroup> findDuplicates(List<PhotoItem> items) {
    final groups       = <DuplicateGroup>[];
    final processedIds = <String>{};

    // ── Pass 1: exact match (size + truncated-minute timestamp) ──────────────
    final exactMap = <String, List<PhotoItem>>{};
    for (final item in items) {
      if (item.sizeBytes <= 0) continue;
      final dt  = item.createdAt;
      // Build key using integer arithmetic — no string interpolation per digit
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

    // ── Pass 2: perceptual hash ───────────────────────────────────────────────
    final unprocessed = items
        .where((i) => !processedIds.contains(i.id) && i.thumbnail != null)
        .toList();

    if (unprocessed.isNotEmpty) {
      // Build hash map
      final hashes = <String, int>{};
      for (final item in unprocessed) {
        final h = computeAHash(item.thumbnail!);
        if (h != 0) hashes[item.id] = h;
      }

      // Convert to parallel arrays for cache-friendly access
      final hashItems  = [for (final i in unprocessed) if (hashes.containsKey(i.id)) i];
      final hashValues = Int64List.fromList([for (final i in hashItems) hashes[i.id]!]);

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

    groups.sort((a, b) => b.wasteBytes.compareTo(a.wasteBytes));
    return groups;
  }

  /// Average Hash — 64-bit perceptual fingerprint.
  /// Uses integer arithmetic throughout to avoid repeated FP conversions.
  int computeAHash(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 0;
      final small = img.copyResize(decoded, width: 8, height: 8,
          interpolation: img.Interpolation.nearest);

      // Compute all 64 luminances as integers (×1000) in one pass
      final lums = Int32List(64);
      int sum = 0;
      for (int i = 0; i < 64; i++) {
        final p   = small.getPixel(i % 8, i ~/ 8);
        final lum = _wr * p.r.toInt() + _wg * p.g.toInt() + _wb * p.b.toInt();
        lums[i]  = lum;
        sum      += lum;
      }
      final mean = sum ~/ 64; // still ×1000

      // Build hash: bit=1 if lum >= mean
      int hash = 0;
      for (int i = 0; i < 64; i++) {
        if (lums[i] >= mean) hash |= (1 << i);
      }
      return hash;
    } catch (_) {
      return 0;
    }
  }

  /// Isolate-compatible batch hash computation.
  static Map<String, int> computeAllHashes(List<(String, Uint8List)> input) {
    final svc    = DuplicateService();
    final result = <String, int>{};
    for (final (id, bytes) in input) {
      final h = svc.computeAHash(bytes);
      if (h != 0) result[id] = h;
    }
    return result;
  }

  // Population-count via Brian Kernighan's algorithm
  static int _hamming(int a, int b) {
    int xor = a ^ b, count = 0;
    while (xor != 0) { xor &= xor - 1; count++; }
    return count;
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}