import 'dart:async';
import 'dart:typed_data';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';

/// Schermata dettaglio foto con zoom interattivo.
/// Può essere aperta sia dallo swiper che dal cestino.
///
/// [actions] — pulsanti opzionali in basso (es. "Ripristina", "Elimina")
class PhotoDetailView extends StatefulWidget {
  final PhotoItem item;
  final Future<Uint8List?> Function(PhotoItem) loadFull;
  final List<DetailAction> actions;

  const PhotoDetailView({
    super.key,
    required this.item,
    required this.loadFull,
    this.actions = const [],
  });

  /// Apre la schermata come pagina fullscreen
  static Future<void>? open({
    required PhotoItem item,
    required Future<Uint8List?> Function(PhotoItem) loadFull,
    List<DetailAction> actions = const [],
  }) =>
      Get.to(
        () => PhotoDetailView(item: item, loadFull: loadFull, actions: actions),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 200),
        fullscreenDialog: true,
      );

  @override
  State<PhotoDetailView> createState() => _PhotoDetailViewState();
}

class DetailAction {
  final String   label;
  final Color    color;
  final IconData icon;
  final VoidCallback onTap;

  const DetailAction({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class _PhotoDetailViewState extends State<PhotoDetailView> {
  final _transformController = TransformationController();
  Uint8List? _fullThumb;
  bool _loadingFull    = true;
  bool _overlayVisible = true;
  bool _showHint       = false;
  Timer? _hideTimer;
  Timer? _hintTimer;
  TapDownDetails? _lastDoubleTapDown;

  @override
  void initState() {
    super.initState();
    _loadFullThumb();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hintTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadFullThumb() async {
    final data = await widget.loadFull(widget.item);
    if (!mounted) return;
    setState(() {
      _fullThumb   = data;
      _loadingFull = false;
      _showHint    = true;
    });
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _overlayVisible) setState(() => _overlayVisible = false);
    });
  }

  void _toggleOverlay() {
    setState(() => _overlayVisible = !_overlayVisible);
    if (_overlayVisible) _startHideTimer();
  }

  bool get _isZoomed => _transformController.value != Matrix4.identity();

  void _onDoubleTap() {
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
    } else {
      final pos   = _lastDoubleTapDown?.localPosition;
      const scale = 2.8;
      final x     = pos != null ? -pos.dx * (scale - 1) : 0.0;
      final y     = pos != null ? -pos.dy * (scale - 1) : 0.0;
      _transformController.value = Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item   = widget.item;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(children: [

          // ── Foto zoomabile ──────────────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _lastDoubleTapDown = d,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                clipBehavior: Clip.hardEdge,
                minScale: 1.0,
                maxScale: 30.0,
                child: SizedBox.expand(
                  child: item.thumbnail != null || _fullThumb != null
                      ? Stack(fit: StackFit.expand, children: [
                          // Thumbnail come placeholder
                          if (item.thumbnail != null)
                            SafeMemoryImage(
                                bytes: item.thumbnail!, fit: BoxFit.cover, cacheWidth: 300),
                          // Full-res crossfade in
                          if (_fullThumb != null)
                            AnimatedOpacity(
                              opacity: _loadingFull ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 400),
                              child: SafeMemoryImage(
                                  bytes: _fullThumb!, fit: BoxFit.cover, cacheWidth: 300),
                            ),
                        ])
                      : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white38)),
                ),
              ),
            ),
          ),

          // Loading badge (full-res in arrivo)
          if (_loadingFull && item.thumbnail != null)
            Positioned(
              top: topPad + 16, right: 16,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                      color: Colors.white54, strokeWidth: 1.5),
                ),
              ),
            ),

          // ── Top bar ─────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _overlayVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(children: [
                    // Back
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(FluentIcons.arrow_left_20_filled,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const Spacer(),
                    // Data / ora
                    Column(crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      Text(_fmtDate(item.createdAt),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 1),
                      Text(_fmtTime(item.createdAt),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11)),
                    ]),
                    const SizedBox(width: 10),
                    // Badge dimensione
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: PhotoService.sizeColor(item.sizeBytes)
                            .withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: PhotoService.sizeColor(item.sizeBytes)
                                .withValues(alpha: 0.50)),
                      ),
                      child: Text(
                        PhotoService.formatBytes(item.sizeBytes),
                        style: TextStyle(
                            color: PhotoService.sizeColor(item.sizeBytes),
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // ── Bottom actions ───────────────────────────────────────────────
          if (widget.actions.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _overlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !_overlayVisible,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 36, 20, botPad + 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.80),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.actions.map((a) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: a.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: a.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      a.color.withValues(alpha: 0.40)),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Icon(a.icon, color: a.color, size: 17),
                              const SizedBox(width: 8),
                              Text(a.label,
                                  style: TextStyle(
                                      color: a.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ]),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),

          // ── Hint doppio tap ──────────────────────────────────────────────
          Positioned(
            bottom: widget.actions.isEmpty ? 28 : 116,
            left: 0, right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showHint ? 0.70 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(Icons.zoom_in_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text('Doppio tap per zoomare',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  String _fmtTime(DateTime dt) =>
      '${_p(dt.hour)}:${_p(dt.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');
}

// Esposto per creare azioni dall'esterno
DetailAction detailAction({
  required String   label,
  required Color    color,
  required IconData icon,
  required VoidCallback onTap,
}) => DetailAction(label: label, color: color, icon: icon, onTap: onTap);