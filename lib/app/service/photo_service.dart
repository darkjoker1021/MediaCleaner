import 'dart:typed_data';
import 'dart:ui';
import 'package:media_cleaner/app/models/photo_item.dart';
import 'package:media_cleaner/app/models/sort_mode.dart';
import 'package:photo_manager/photo_manager.dart';

export 'package:media_cleaner/app/models/photo_item.dart';
export 'package:media_cleaner/app/models/sort_mode.dart';

class PhotoService {
  // Thumbnail piccolo per la card (caricamento veloce)
  static const _thumbSize  = ThumbnailSize.square(600); // bilanciamento qualità/RAM
  // Thumbnail grande per il dettaglio
  static const _fullSize   = ThumbnailSize.square(2400);
  static const _batchLoad  = 500;
  static const _batchThumb = 16; // era 8: caricamento più veloce

  Future<bool> requestPermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) {
      PhotoManager.openSetting();
      return false;
    }
    return true;
  }

  Future<List<PhotoItem>> loadAllPhotos() async {
    return _loadByType(RequestType.image);
  }

  Future<List<PhotoItem>> loadAllVideos() async {
    return _loadByType(RequestType.video);
  }

  Future<List<PhotoItem>> _loadByType(RequestType type) async {
    final albums = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: true,
      onlyAll: false,
    );
    if (albums.isEmpty) return [];

    var best      = albums[0];
    var bestCount = await best.assetCountAsync;
    for (final a in albums.skip(1)) {
      final c = await a.assetCountAsync;
      if (c > bestCount) { bestCount = c; best = a; }
    }

    final assets = <AssetEntity>[];
    for (var s = 0; s < bestCount; s += _batchLoad) {
      assets.addAll(await best.getAssetListRange(
        start: s,
        end:   (s + _batchLoad).clamp(0, bestCount),
      ));
    }
    return assets.map((a) => PhotoItem(asset: a)).toList();
  }

  Future<List<PhotoItem>> sort(List<PhotoItem> items, SortMode mode) async {
    final list = List<PhotoItem>.from(items);
    switch (mode) {
      case SortMode.dateNewest:   list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortMode.dateOldest:   list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortMode.sizeHeaviest: list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case SortMode.sizeLightest: list.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    }
    return list;
  }

  // Risolve solo thumbnail + size (NO calcolo totale libreria)
  Future<PhotoItem> resolveItem(PhotoItem item) async {
    final results = await Future.wait([
      item.asset.thumbnailDataWithSize(_thumbSize),
      item.asset.file.then((f) async => f != null ? await f.length() : 0),
    ]);
    return item.copyWith(
      thumbnail: results[0] as Uint8List?,
      sizeBytes: results[1] as int,
    );
  }

  // Thumbnail ad alta risoluzione per la vista dettaglio
  Future<Uint8List?> resolveFullThumb(PhotoItem item) async {
    return item.asset.thumbnailDataWithSize(_fullSize);
  }

  Stream<List<PhotoItem>> resolveStream(List<PhotoItem> items) async* {
    for (var i = 0; i < items.length; i += _batchThumb) {
      final batch    = items.sublist(i, (i + _batchThumb).clamp(0, items.length));
      final resolved = await Future.wait(batch.map(resolveItem));
      yield resolved;
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
    if (b <= 0)       return '—';
    if (b < 1 << 20)  return '${(b / (1 << 10)).toStringAsFixed(1)} KB';
    if (b < 1 << 30)  return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
    return                   '${(b / (1 << 30)).toStringAsFixed(2)} GB';
  }

  // Colore basato sulla dimensione del file: verde(<1MB) → giallo(5MB) → rosso(>15MB)
  static Color sizeColor(int bytes) {
    if (bytes <= 0) return const Color(0xFF8E8E93);
    final mb = bytes / (1 << 20);
    if (mb < 1)   return const Color(0xFF34C759); // verde
    if (mb < 3)   return const Color(0xFF30D158); // verde chiaro
    if (mb < 6)   return const Color(0xFFFFD60A); // giallo
    if (mb < 10)  return const Color(0xFFFF9F0A); // arancione
    if (mb < 15)  return const Color(0xFFFF6B35); // arancione scuro
    return              const Color(0xFFFF3B30); // rosso
  }
}