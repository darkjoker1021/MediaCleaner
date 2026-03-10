import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';

class SwipeCard extends StatelessWidget {
  final PhotoItem   item;
  final double      hThreshold;
  final VoidCallback? onTap;

  const SwipeCard({
    super.key,
    required this.item,
    required this.hThreshold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leftOpacity  = (hThreshold < 0 ? -hThreshold : 0.0).clamp(0.0, 100.0) / 100.0;
    final rightOpacity = (hThreshold > 0 ?  hThreshold : 0.0).clamp(0.0, 100.0) / 100.0;
    final sizeColor    = PhotoService.sizeColor(item.sizeBytes);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [

          // Foto
          Container(
            color: const Color(0xFF111318),
            child: item.thumbnail != null
              ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover)
                : _placeholder(),
          ),

          // Gradient top
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 100,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
            ),
          ),

          // Gradient bottom
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(height: 110,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
            ),
          ),

          // ── Badge dimensione (top left, colorato per peso) ────────────────
          Positioned(top: 16, left: 16,
            child: item.sizeBytes > 0
                ? _badge(PhotoService.formatBytes(item.sizeBytes),
                    sizeColor, FluentIcons.data_usage_20_filled)
                : const SizedBox.shrink(),
          ),

          // ── Data + ora (top right) ────────────────────────────────────────
          Positioned(top: 16, right: 16,
            child: _badge(
              _fmtDateTime(item.createdAt),
              Colors.white.withValues(alpha: 0.75),
              FluentIcons.calendar_today_20_filled,
            ),
          ),

          // ── Icona zoom (bottom right, hint) ──────────────────────────────
          Positioned(bottom: 16, right: 16,
            child: Icon(FluentIcons.zoom_in_20_filled,
                color: Colors.white.withValues(alpha: 0.3), size: 16),
          ),

          // ── Overlay CESTINO ───────────────────────────────────────────────
          if (leftOpacity > 0)
            _SwipeOverlay(opacity: leftOpacity, color: const Color(0xFFFF3B30),
                align: Alignment.centerLeft,
                icon: FluentIcons.delete_20_filled, label: 'CESTINO', fromLeft: true),

          // ── Overlay MANTIENI ──────────────────────────────────────────────
          if (rightOpacity > 0)
            _SwipeOverlay(opacity: rightOpacity, color: const Color(0xFF34C759),
                align: Alignment.centerRight,
                icon: FluentIcons.heart_20_filled, label: 'MANTIENI', fromLeft: false),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 0.2)),
    ]),
  );

  Widget _placeholder() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Colors.white24, strokeWidth: 1.5),
      const SizedBox(height: 10),
      Text('Caricamento...',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
    ]),
  );

  // Data e ora sulla stessa riga: "15/03/2025  14:32"
  String _fmtDateTime(DateTime dt) =>
      '${_p(dt.day)}/${_p(dt.month)}/${dt.year}  ${_p(dt.hour)}:${_p(dt.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');
}

class _SwipeOverlay extends StatelessWidget {
  final double opacity; final Color color;
  final Alignment align; final IconData icon;
  final String label; final bool fromLeft;

  const _SwipeOverlay({required this.opacity, required this.color,
      required this.align, required this.icon,
      required this.label, required this.fromLeft});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: opacity * 0.55), Colors.transparent],
        begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
        end:   fromLeft ? Alignment.centerRight : Alignment.centerLeft,
      ),
    ),
    child: Align(alignment: align,
      child: Padding(
        padding: EdgeInsets.only(
            left: fromLeft ? 28 : 0, right: !fromLeft ? 28 : 0),
        child: Opacity(opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
            ]),
          ),
        ),
      ),
    ),
  );
}