import 'dart:typed_data';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';
import 'package:media_cleaner/core/widgets/shimmer_box.dart';

/// Carta swipeable per foto e video.
///
/// STRATEGIA THUMBNAIL (3 livelli):
///
///  1. MICRO (80 px) — caricata in ~8 ms al mount, mostra immediatamente
///     qualcosa invece dello shimmer bianco. Viene avviata in parallelo
///     con il caricamento LARGE nel controller.
///
///  2. LARGE (600 px, via resolveStream) — arriva via `didUpdateWidget`
///     quando il controller aggiorna `item.thumbnail`. Fa crossfade in
///     sopra alla micro in modo impercettibile.
///
///  3. Se l'item ha già la thumbnail (visita successiva o cache), salta
///     direttamente al livello LARGE senza mostrare la micro.
class SwipeCard extends StatefulWidget {
  final PhotoItem     item;
  final double        hThreshold;
  final VoidCallback? onTap;

  const SwipeCard({
    super.key,
    required this.item,
    required this.hThreshold,
    this.onTap,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  // thumbnail grande (600 px) — arriva dal controller via resolveStream
  Uint8List? _large;
  // micro-thumbnail (80 px) — caricata subito al mount come placeholder
  Uint8List? _micro;

  @override
  void initState() {
    super.initState();
    if (widget.item.thumbnail != null) {
      // Già pronta (dal controller) — usa subito senza caricare nulla
      _large = widget.item.thumbnail;
    } else {
      // Non ancora pronta: carica micro immediatamente come placeholder
      _loadMicro();
    }
  }

  @override
  void didUpdateWidget(SwipeCard old) {
    super.didUpdateWidget(old);

    if (old.item.id != widget.item.id) {
      // Nuova carta: resetta tutto e ricomincia
      _large = widget.item.thumbnail;
      _micro = null;
      if (_large == null) _loadMicro();
    } else if (_large == null && widget.item.thumbnail != null) {
      // La thumbnail LARGE è arrivata via controller: crossfade in
      setState(() => _large = widget.item.thumbnail);
    }
  }

  Future<void> _loadMicro() async {
    // 80 px: decodifica ~8 ms, quasi istantaneo
    final bytes = await PhotoService().resolveMicroThumb(widget.item);
    if (mounted && _large == null) {
      // Mostra la micro solo se la large non è ancora arrivata
      setState(() => _micro = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leftOpacity  = (widget.hThreshold < 0 ? -widget.hThreshold : 0.0).clamp(0.0, 100.0) / 100.0;
    final rightOpacity = (widget.hThreshold > 0 ?  widget.hThreshold : 0.0).clamp(0.0, 100.0) / 100.0;
    final sizeColor    = PhotoService.sizeColor(widget.item.sizeBytes);

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [

          // ── Layer 0: shimmer (se non abbiamo ancora nulla) ─────────────
          if (_large == null && _micro == null)
            const ShimmerBox(),

          // ── Layer 1: micro-thumbnail (80 px, blur+upscale automatici) ──
          // Rimane visibile come placeholder finché la large non è pronta.
          // filterQuality.medium per bilinear upscale che non fa sembrare
          // pixelosa la foto piccola.
          if (_micro != null && _large == null)
            Image.memory(
              _micro!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              // nessun cacheWidth: è già 80 px, decodifica istantanea
            ),

          // ── Layer 2: large thumbnail (600 px) — crossfade in ───────────
          if (_large != null)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: SafeMemoryImage(
                bytes: _large!,
                fit: BoxFit.cover,
                // Limita la decodifica alla dimensione reale su schermo.
                // Su un iPhone 14 Pro la carta occupa ~390×720 logical px
                // → 390*3 = 1170 physical px; 600 px è sufficiente.
                // Senza questo Flutter decodifica a 600×600 ma alloca
                // la texture completa; con questo alloca solo quanto serve.
                cacheWidth: 600,
              ),
            ),

          // ── Gradients ─────────────────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 100,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(height: 110,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
            ),
          ),

          // ── Badge dimensione (top left) ────────────────────────────────
          Positioned(top: 16, left: 16,
            child: widget.item.sizeBytes > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      PhotoService.formatBytes(widget.item.sizeBytes),
                      style: TextStyle(
                        color: sizeColor, fontSize: 11, fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Swipe overlay: SCARTA (rosso, sinistra) ────────────────────
          if (leftOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: leftOpacity.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(FluentIcons.delete_20_filled,
                      color: Colors.white, size: 64),
                ),
              ),
            ),

          // ── Swipe overlay: MANTIENI (verde, destra) ────────────────────
          if (rightOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: rightOpacity.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(FluentIcons.heart_20_filled,
                      color: Colors.white, size: 64),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}