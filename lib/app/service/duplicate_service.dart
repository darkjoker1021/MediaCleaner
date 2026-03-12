import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:media_cleaner/app/models/photo_item.dart';

/// Gruppo di foto considerate duplicate.
/// Tutti i campi derivati sono calcolati UNA SOLA VOLTA nel costruttore
/// (late final) invece di rieseguire reduce/where/fold ad ogni lettura.
class DuplicateGroup {
  DuplicateGroup(this.items, {this.isPerceptual = false})
      : best = items.reduce((a, b) => a.sizeBytes >= b.sizeBytes ? a : b) {
    // late final calcolati subito — mai più di una volta per istanza
    duplicates = List.unmodifiable(items.where((i) => i.id != best.id));
    wasteBytes = duplicates.fold(0, (s, e) => s + e.sizeBytes);
    totalBytes = items.fold(0, (s, e) => s + e.sizeBytes);
  }

  final List<PhotoItem> items;
  final bool            isPerceptual;
  final PhotoItem       best;
  late final List<PhotoItem> duplicates;
  late final int wasteBytes;
  late final int totalBytes;
  int get count => items.length;
}

class DuplicateService {
  static const _phashThreshold = 8;

  // Pesi canale pre-calcolati come interi (×1000) — evita moltiplicazioni FP ripetute
  static const int _wr = 299, _wg = 587, _wb = 114;

  List<DuplicateGroup> findDuplicates(List<PhotoItem> items) {
    final groups       = <DuplicateGroup>[];
    final processedIds = <String>{};

    // ── Pass 1: exact match (size + timestamp al minuto) ─────────────────────
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

    // ── Pass 2: perceptual hash ───────────────────────────────────────────────
    final unprocessed = items
        .where((i) => !processedIds.contains(i.id) && i.thumbnail != null)
        .toList();

    if (unprocessed.isNotEmpty) {
      final hashes = <String, int>{};
      for (final item in unprocessed) {
        final h = computeAHash(item.thumbnail!);
        if (h != 0) hashes[item.id] = h;
      }

      // Array paralleli cache-friendly per il loop O(n²)
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

  /// Average Hash (aHash) — fingerprint percettivo a 64 bit.
  /// Usa aritmetica intera per evitare conversioni FP ripetute.
  int computeAHash(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 0;
      final small = img.copyResize(decoded, width: 8, height: 8,
          interpolation: img.Interpolation.nearest);

      final lums = Int32List(64);
      int sum = 0;
      for (int i = 0; i < 64; i++) {
        final p   = small.getPixel(i % 8, i ~/ 8);
        final lum = _wr * p.r.toInt() + _wg * p.g.toInt() + _wb * p.b.toInt();
        lums[i]  = lum;
        sum      += lum;
      }
      final mean = sum ~/ 64;

      int hash = 0;
      for (int i = 0; i < 64; i++) {
        if (lums[i] >= mean) hash |= (1 << i);
      }
      return hash;
    } catch (_) {
      return 0;
    }
  }

  /// Batch hash computation per isolate.
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