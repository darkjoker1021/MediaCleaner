import 'dart:typed_data';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// Image widget per thumbnail in memoria con gestione errori.
///
/// OTTIMIZZAZIONI:
/// • [cacheWidth] / [cacheHeight] limitano la decodifica alla dimensione
///   reale del widget — Flutter non alloca texture più grandi del necessario.
///   Usare sempre [cacheWidth] nelle grid! Default conveniente: 300 px
///   per le celle 3-col (~120 dp × max 3× DPR = 360 px fisici).
/// • [filterQuality] = low per le grid (bilinear è sufficiente a ~120 dp);
///   medium/high opzionali per contesti più grandi.
class SafeMemoryImage extends StatelessWidget {
  const SafeMemoryImage({
    super.key,
    required this.bytes,
    this.fit         = BoxFit.cover,
    this.placeholder,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.low,
  });

  final Uint8List      bytes;
  final BoxFit         fit;
  final Widget?        placeholder;
  final int?           cacheWidth;
  final int?           cacheHeight;
  final FilterQuality  filterQuality;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit:           fit,
      filterQuality: filterQuality,
      cacheWidth:    cacheWidth,
      cacheHeight:   cacheHeight,
      gaplessPlayback: true, // evita il flash bianco quando i bytes cambiano
      errorBuilder: (_, _, _) =>
          placeholder ??
          Container(
            color: const Color(0xFF1A1D26),
            alignment: Alignment.center,
            child: const Icon(
              FluentIcons.content_view_gallery_20_filled,
              color: Colors.white30,
              size: 22,
            ),
          ),
    );
  }
}