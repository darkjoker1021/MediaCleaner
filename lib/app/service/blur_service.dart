import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum QualityIssue { blur, dark, overexposed }

class BlurService {
  static const _blurThreshold   = 60.0;
  static const _darkThreshold   = 55.0;
  static const _brightThreshold = 215.0;

  // Precomputed channel weights as integers (×1000) to avoid repeated FP muls
  static const int _wr = 299, _wg = 587, _wb = 114;

  QualityIssue? analyze(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Resize to 64×64 in-place
      final small = img.copyResize(decoded, width: 64, height: 64,
          interpolation: img.Interpolation.nearest); // fastest filter

      const n = 64 * 64;
      // Store lums as integers (×1000) → avoid 4096 FP divisions
      final lumsInt = Int32List(n);
      int sumInt = 0;
      for (int i = 0; i < n; i++) {
        final p   = small.getPixel(i % 64, i ~/ 64);
        final lum = _wr * p.r.toInt() + _wg * p.g.toInt() + _wb * p.b.toInt();
        lumsInt[i] = lum;
        sumInt    += lum;
      }

      // Mean luminance (×1000)
      final meanInt = sumInt ~/ n;
      final mean    = meanInt / 1000.0;

      if (mean < _darkThreshold)   return QualityIssue.dark;
      if (mean > _brightThreshold) return QualityIssue.overexposed;

      final lapVar = _laplacianVarianceInt(lumsInt);
      return lapVar < _blurThreshold ? QualityIssue.blur : null;
    } catch (_) {
      return null;
    }
  }

  /// Isolate-compatible batch analysis.
  static List<(String, int)> analyzeAll(List<(String, Uint8List)> input) {
    final svc     = BlurService();
    final results = <(String, int)>[];
    for (final (id, bytes) in input) {
      final issue = svc.analyze(bytes);
      if (issue != null) results.add((id, issue.index));
    }
    return results;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Integer Laplacian variance. Lums are stored ×1000, so variance is ×10^6
  /// but the threshold comparison still holds (we compare against threshold×10^6).
  double _laplacianVarianceInt(Int32List lums) {
    const w = 64, h = 64;
    // Laplacian kernel: 4×center − 4 neighbours
    final lap     = Float32List((w - 2) * (h - 2));
    int   lapIdx  = 0;
    double lapSum = 0;

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final v = (-4 * lums[y * w + x]
                 +      lums[(y - 1) * w + x]
                 +      lums[(y + 1) * w + x]
                 +      lums[y * w + (x - 1)]
                 +      lums[y * w + (x + 1)]) / 1000.0; // back to real scale
        lap[lapIdx++] = v;
        lapSum += v;
      }
    }
    if (lapIdx == 0) return 0;

    final m    = lapSum / lapIdx;
    double var_ = 0;
    for (int i = 0; i < lapIdx; i++) {
      final d = lap[i] - m;
      var_ += d * d;
    }
    return var_ / lapIdx;
  }
}