import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// Wrapper leggero su [AssetEntity] con thumbnail e dimensione file cached.
/// Pure data class — zero import Flutter UI.
///
/// FIX: createdAt è memoizzato nel costruttore (late final) anziché delegare
/// ad asset.createDateTime ad ogni lettura. Questo campo è usato pesantemente
/// in sort, burst detection e duplicate key generation.
class PhotoItem {
  PhotoItem({
    required this.asset,
    this.sizeBytes = 0,
    this.thumbnail,
  }) : createdAt = asset.createDateTime;

  final AssetEntity asset;
  final int         sizeBytes;
  final Uint8List?  thumbnail;

  /// Memoizzato nel costruttore — nessun accesso ripetuto ad asset.createDateTime.
  final DateTime createdAt;

  String get id => asset.id;

  PhotoItem copyWith({int? sizeBytes, Uint8List? thumbnail}) => PhotoItem(
    asset:     asset,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    thumbnail: thumbnail ?? this.thumbnail,
  );

  @override
  bool operator ==(Object other) => other is PhotoItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}