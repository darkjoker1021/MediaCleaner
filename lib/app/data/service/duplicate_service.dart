import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:media_cleaner/app/models/photo_item.dart';

/// Gruppo di foto considerate duplicate
class DuplicateGroup {
  final List<PhotoItem> items;
  /// true = trovato via hash percettivo (foto simili ma non identiche)
  final bool isPerceptual;
  DuplicateGroup(this.items, {this.isPerceptual = false});

  PhotoItem get best => items.reduce((a, b) => a.sizeBytes >= b.sizeBytes ? a : b);
  List<PhotoItem> get duplicates => items.where((i) => i.id != best.id).toList();
  int get wasteBytes => duplicates.fold(0, (s, e) => s + e.sizeBytes);
  int get totalBytes => items.fold(0, (s, e) => s + e.sizeBytes);
  int get count => items.length;
}

class DuplicateService {
  static const _phashThreshold = 8; // Hamming distance

  List<DuplicateGroup> findDuplicates(List<PhotoItem> items) {
    final groups      = <DuplicateGroup>[];
    final processedIds = <String>{};

    // ── Pass 1: exact match by size + date (fast, no image decode) ───────────
    final exactMap = <String, List<PhotoItem>>{};
    for (final item in items) {
      if (item.sizeBytes <= 0) continue;
      final dt  = item.createdAt;
      final key = '${item.sizeBytes}_'
          '${dt.year}-${_p(dt.month)}-${_p(dt.day)}_'
          '${_p(dt.hour)}:${_p(dt.minute)}';
      exactMap.putIfAbsent(key, () => []).add(item);
    }
    for (final g in exactMap.values) {
      if (g.length < 2) continue;
      groups.add(DuplicateGroup(g));
      for (final i in g) {
        processedIds.add(i.id);
      }
    }

    // ── Pass 2: perceptual hash on thumbnails ────────────────────────────────
    final unprocessed = items
        .where((i) => !processedIds.contains(i.id) && i.thumbnail != null)
        .toList();

    if (unprocessed.isNotEmpty) {
      final hashes = <String, int>{};
      for (final item in unprocessed) {
        final h = computeAHash(item.thumbnail!);
        if (h != 0) hashes[item.id] = h;
      }

      final phashUsed = <String>{};
      for (int i = 0; i < unprocessed.length; i++) {
        final item = unprocessed[i];
        if (phashUsed.contains(item.id) || !hashes.containsKey(item.id)) continue;

        final group = [item];
        for (int j = i + 1; j < unprocessed.length; j++) {
          final other = unprocessed[j];
          if (phashUsed.contains(other.id) || !hashes.containsKey(other.id)) continue;
          if (_hamming(hashes[item.id]!, hashes[other.id]!) <= _phashThreshold) {
            group.add(other);
            phashUsed.add(other.id);
          }
        }
        if (group.length >= 2) {
          phashUsed.add(item.id);
          groups.add(DuplicateGroup(group, isPerceptual: true));
        }
      }
    }

    groups.sort((a, b) => b.wasteBytes.compareTo(a.wasteBytes));
    return groups;
  }

  /// Average Hash (aHash) — 64-bit perceptual fingerprint.
  int computeAHash(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 0;
      final small = img.copyResize(decoded, width: 8, height: 8);

      int sum = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final p = small.getPixel(x, y);
          sum += (0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble()).round();
        }
      }
      final mean = sum ~/ 64;

      int hash = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final p   = small.getPixel(x, y);
          final lum = (0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble()).round();
          if (lum >= mean) hash |= (1 << (y * 8 + x));
        }
      }
      return hash;
    } catch (_) {
      return 0;
    }
  }

  int _hamming(int a, int b) {
    int xor = a ^ b, count = 0;
    while (xor != 0) { count += xor & 1; xor = xor >>> 1; }
    return count;
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  /// Isolate-compatible: computes aHash for a batch of (id, bytes) pairs.
  static Map<String, int> computeAllHashes(List<(String, Uint8List)> input) {
    final svc = DuplicateService();
    final result = <String, int>{};
    for (final (id, bytes) in input) {
      final h = svc.computeAHash(bytes);
      if (h != 0) result[id] = h;
    }
    return result;
  }
}
