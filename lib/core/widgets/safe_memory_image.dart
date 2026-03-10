import 'dart:typed_data';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class SafeMemoryImage extends StatelessWidget {
  const SafeMemoryImage({
    super.key,
    required this.bytes,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final Uint8List bytes;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: fit,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) {
        return placeholder ??
            Container(
              color: const Color(0xFF1A1D26),
              alignment: Alignment.center,
              child: const Icon(
                FluentIcons.content_view_gallery_20_filled,
                color: Colors.white30,
                size: 22,
              ),
            );
      },
    );
  }
}
