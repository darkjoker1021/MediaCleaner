import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/core/widgets/safe_memory_image.dart';

/// Schermata dettaglio foto con zoom interattivo.
/// Può essere aperta sia dallo swiper che dal cestino.
///
/// [actions] — pulsanti opzionali in basso (es. "Ripristina", "Elimina")
class PhotoDetailView extends StatefulWidget {
  final PhotoItem item;
  final Future<Uint8List?> Function(PhotoItem) loadFull;
  final List<_DetailAction> actions;

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
    List<_DetailAction> actions = const [],
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

class _DetailAction {
  final String   label;
  final Color    color;
  final IconData icon;
  final VoidCallback onTap;

  const _DetailAction({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class _PhotoDetailViewState extends State<PhotoDetailView> {
  final _transformController = TransformationController();
  Uint8List? _fullThumb;
  bool       _loadingFull = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadFullThumb();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadFullThumb() async {
    final data = await widget.loadFull(widget.item);
    if (mounted) setState(() { _fullThumb = data; _loadingFull = false; });
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final item    = widget.item;
    final display = _fullThumb ?? item.thumbnail;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // ── Foto zoomabile ─────────────────────────────────────────────────
        GestureDetector(
          onDoubleTap: () {
            if (_transformController.value != Matrix4.identity()) {
              _resetZoom();
            } else {
              _transformController.value = Matrix4.identity()
                ..scale(2.5)
                ..translate(-100.0, -200.0);
            }
          },
          child: Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 5.0,
              child: display != null
                  ? SafeMemoryImage(bytes: display, fit: BoxFit.contain)
                  : const CircularProgressIndicator(color: Colors.white38),
            ),
          ),
        ),

        // Loading overlay mentre carica full-res
        if (_loadingFull && display != null)
          Positioned(
            top: 16, right: 16,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 1.5),
              ),
            ),
          ),

        // ── Top bar ────────────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 12, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(children: [
              // Torna indietro
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
              // Info
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmtDate(item.createdAt),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(_fmtTime(item.createdAt),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11)),
              ]),
              const SizedBox(width: 10),
              // Dimensione con colore
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PhotoService.sizeColor(item.sizeBytes).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: PhotoService.sizeColor(item.sizeBytes).withValues(alpha: 0.5)),
                ),
                child: Text(
                  PhotoService.formatBytes(item.sizeBytes),
                  style: TextStyle(
                      color: PhotoService.sizeColor(item.sizeBytes),
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),
        ),

        // ── Bottom actions ─────────────────────────────────────────────────
        if (widget.actions.isNotEmpty)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.actions.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: a.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 13),
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: a.color.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(a.icon, color: a.color, size: 17),
                        const SizedBox(width: 8),
                        Text(a.label, style: TextStyle(
                            color: a.color, fontWeight: FontWeight.w700,
                            fontSize: 14)),
                      ]),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),

        // ── Hint doppio tap ────────────────────────────────────────────────
        Positioned(
          bottom: widget.actions.isEmpty ? 24 : 100,
          left: 0, right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _loadingFull ? 0 : 0.4,
              duration: const Duration(milliseconds: 600),
              child: const Text('Doppio tap per zoomare',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ),
      ]),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  String _fmtTime(DateTime dt) =>
      '${_p(dt.hour)}:${_p(dt.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');
}

// Esposto per creare azioni dall'esterno
_DetailAction detailAction({
  required String   label,
  required Color    color,
  required IconData icon,
  required VoidCallback onTap,
}) => _DetailAction(label: label, color: color, icon: icon, onTap: onTap);
