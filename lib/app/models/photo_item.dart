import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// Lightweight wrapper around [AssetEntity] that adds a resolved thumbnail
/// and a cached file size. Pure data class — no Flutter UI imports.
class PhotoItem {
  final AssetEntity asset;
  final int         sizeBytes;
  final Uint8List?  thumbnail;

  const PhotoItem({
    required this.asset,
    this.sizeBytes = 0,
    this.thumbnail,
  });

  String   get id        => asset.id;
  DateTime get createdAt => asset.createDateTime;

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
