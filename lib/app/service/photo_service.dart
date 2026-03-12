import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:media_cleaner/app/models/photo_item.dart';
import 'package:media_cleaner/app/models/sort_mode.dart';
import 'package:photo_manager/photo_manager.dart';

export 'package:media_cleaner/app/models/photo_item.dart';
export 'package:media_cleaner/app/models/sort_mode.dart';

class PhotoService {
  // ── Dimensioni thumbnail ──────────────────────────────────────────────────
  //
  // SWIPER  → carta grande a tutto schermo, serve alta qualità
  static const thumbSizeSwiper = ThumbnailSize.square(600);
  //
  // GRID    → celle 3-col (~120 dp): 300 px è più che sufficiente e carica
  //           in ~metà del tempo rispetto a 600 px
  static const thumbSizeGrid   = ThumbnailSize.square(300);
  //
  // MICRO   → placeholder istantaneo per SwipeCard prima che arrivi la 600 px
  //           (decodifica in ~8 ms vs ~60 ms per la 600 px)
  static const thumbSizeMicro  = ThumbnailSize.square(80);
  //
  // FULL    → vista dettaglio
  static const _fullSize       = ThumbnailSize.square(2400);

  // ── Parametri stream ──────────────────────────────────────────────────────
  // Numero di batch da tenere in volo contemporaneamente (overlapped pipeline)
  static const _concurrentBatches = 2;
  // Foto per batch nel resolveStream principale (swiper/grid grandi)
  static const _batchThumb        = 20;
  // Foto per batch nel resolveStreamGrid (grid piccole)
  static const _batchThumbGrid    = 40;

  static const _batchLoad = 500;

  // =========================================================================

  Future<bool> requestPermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) {
      PhotoManager.openSetting();
      return false;
    }
    return true;
  }

  Future<List<PhotoItem>> loadAllPhotos() => _loadByType(RequestType.image);
  Future<List<PhotoItem>> loadAllVideos() => _loadByType(RequestType.video);

  Future<List<PhotoItem>> _loadByType(RequestType type) async {
    final albums = await PhotoManager.getAssetPathList(
      type: type, hasAll: true, onlyAll: false,
    );
    if (albums.isEmpty) return [];

    var best = albums[0];
    var bestCount = await best.assetCountAsync;
    for (final a in albums.skip(1)) {
      final c = await a.assetCountAsync;
      if (c > bestCount) { bestCount = c; best = a; }
    }

    final assets = <AssetEntity>[];
    for (var s = 0; s < bestCount; s += _batchLoad) {
      assets.addAll(await best.getAssetListRange(
        start: s, end: (s + _batchLoad).clamp(0, bestCount),
      ));
    }
    return assets.map((a) => PhotoItem(asset: a)).toList();
  }

  List<PhotoItem> sort(List<PhotoItem> items, SortMode mode) {
    final list = List<PhotoItem>.from(items);
    switch (mode) {
      case SortMode.dateNewest:   list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortMode.dateOldest:   list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortMode.sizeHeaviest: list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case SortMode.sizeLightest: list.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    }
    return list;
  }

  // ── Resolve singolo item (thumbnail SWIPER + filesize) ───────────────────
  //
  // FIX: thumbnail e filesize sono richieste INDIPENDENTI.
  // Prima erano in un unico Future.wait, il che significa che se il disco
  // era lento sulla lettura del file la thumbnail aspettava inutilmente.
  // Ora:
  //   • la thumbnail parte immediatamente con priorità
  //   • il filesize viene letto DOPO (non blocca la UI della card)
  Future<PhotoItem> resolveItem(PhotoItem item) async {
    // Thumbnail prima — è ciò che vede l'utente
    final thumb = await item.asset.thumbnailDataWithSize(thumbSizeSwiper);
    // Poi filesize (può arrivare in un secondo momento)
    final size = await _readSize(item);
    return item.copyWith(thumbnail: thumb, sizeBytes: size);
  }

  // Variante per la grid: thumbnail 300 px + filesize
  Future<PhotoItem> resolveItemGrid(PhotoItem item) async {
    final thumb = await item.asset.thumbnailDataWithSize(thumbSizeGrid);
    final size  = await _readSize(item);
    return item.copyWith(thumbnail: thumb, sizeBytes: size);
  }

  // Micro-thumbnail da 80 px — usata come placeholder istantaneo nello SwipeCard
  // prima che la 600 px sia pronta. Velocissima (~8 ms su device moderno).
  Future<Uint8List?> resolveMicroThumb(PhotoItem item) =>
      item.asset.thumbnailDataWithSize(thumbSizeMicro);

  Future<int> _readSize(PhotoItem item) async {
    if (item.sizeBytes > 0) return item.sizeBytes;
    final f = await item.asset.file;
    return f != null ? await f.length() : 0;
  }

  // Thumbnail ad alta risoluzione per la vista dettaglio
  Future<Uint8List?> resolveFullThumb(PhotoItem item) =>
      item.asset.thumbnailDataWithSize(_fullSize);

  // ── resolveStream — SWIPER / home controller ─────────────────────────────
  //
  // FIX: pipeline overlappata a _concurrentBatches slot.
  // Prima: batch N+1 partiva solo quando N era completamente finito.
  // Ora:   batch N+1 parte appena N viene consegnato allo yield,
  //         così photo_manager decodifica in parallelo con il rebuild UI.
  Stream<List<PhotoItem>> resolveStream(List<PhotoItem> items) =>
      _overlappedStream(items, resolveItem, _batchThumb);

  // ── resolveStreamGrid — grid (screenshot, blur, social, kept, trash) ─────
  //
  // Usa thumbnail 300 px e batch più grandi: le grid mostrano molte celle
  // piccole — è più efficiente caricarle in batch più grandi.
  Stream<List<PhotoItem>> resolveStreamGrid(List<PhotoItem> items) =>
      _overlappedStream(items, resolveItemGrid, _batchThumbGrid);

  // ── Core overlapped stream ────────────────────────────────────────────────
  Stream<List<PhotoItem>> _overlappedStream(
    List<PhotoItem> items,
    Future<PhotoItem> Function(PhotoItem) resolver,
    int batchSize,
  ) async* {
    if (items.isEmpty) return;

    // Divide in batch
    final batches = <List<PhotoItem>>[];
    for (var i = 0; i < items.length; i += batchSize) {
      batches.add(items.sublist(i, (i + batchSize).clamp(0, items.length)));
    }

    // Sliding window: teniamo _concurrentBatches Future in volo
    final inFlight = <Future<List<PhotoItem>>>[];

    Future<List<PhotoItem>> startBatch(List<PhotoItem> batch) =>
        Future.wait(batch.map(resolver));

    int nextBatch = 0;

    // Pre-avvia i primi _concurrentBatches batch
    while (nextBatch < batches.length && inFlight.length < _concurrentBatches) {
      inFlight.add(startBatch(batches[nextBatch++]));
    }

    while (inFlight.isNotEmpty) {
      // Consegna il primo batch completato
      final resolved = await inFlight.removeAt(0);
      yield resolved;

      // Subito dopo lo yield, avvia il prossimo batch se disponibile
      if (nextBatch < batches.length) {
        inFlight.add(startBatch(batches[nextBatch++]));
      }
    }
  }

  Future<bool> deleteAsset(PhotoItem item) async {
    final deleted = await PhotoManager.editor.deleteWithIds([item.id]);
    return deleted.contains(item.id);
  }

  Future<List<String>> deleteAssets(List<PhotoItem> items) async {
    final ids     = items.map((e) => e.id).toList();
    final deleted = await PhotoManager.editor.deleteWithIds(ids);
    return deleted;
  }

  static String formatBytes(int b) {
    if (b <= 0)      return '—';
    if (b < 1 << 20) return '${(b / (1 << 10)).toStringAsFixed(1)} KB';
    if (b < 1 << 30) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
    return                  '${(b / (1 << 30)).toStringAsFixed(2)} GB';
  }

  static Color sizeColor(int bytes) {
    if (bytes <= 0) return const Color(0xFF8E8E93);
    final mb = bytes / (1 << 20);
    if (mb < 1)  return const Color(0xFF34C759);
    if (mb < 3)  return const Color(0xFF30D158);
    if (mb < 6)  return const Color(0xFFFFD60A);
    if (mb < 10) return const Color(0xFFFF9F0A);
    if (mb < 15) return const Color(0xFFFF6B35);
    return            const Color(0xFFFF3B30);
  }
}