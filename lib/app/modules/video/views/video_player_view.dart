import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.item});

  final PhotoItem item;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _ctrl;
  bool _isLoading = true;
  bool _hasError  = false;
  bool _overlayVisible = true;
  bool _isMuted   = false;
  bool _isSeeking = false;
  double _seekValue = 0.0; // 0.0–1.0 ratio
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startHideTimer();
    _init();
  }

  Future<void> _init() async {
    final file = await widget.item.asset.file;
    if (file == null || !await file.exists()) {
      if (!mounted) return;
      setState(() { _hasError = true; _isLoading = false; });
      return;
    }

    final ctrl = VideoPlayerController.file(File(file.path));
    try {
      await ctrl.initialize();
      await ctrl.setLooping(false);
      await ctrl.play();
      ctrl.addListener(_onCtrlUpdate);
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _ctrl = ctrl; _isLoading = false; });
    } catch (_) {
      await ctrl.dispose();
      if (!mounted) return;
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  void _onCtrlUpdate() {
    if (!mounted) return;
    final c = _ctrl!;
    final ended = c.value.position >= c.value.duration && !c.value.isPlaying;
    if (ended && !_overlayVisible) {
      setState(() => _overlayVisible = true);
      _hideTimer?.cancel();
    } else {
      setState(() {});
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _overlayVisible && (_ctrl?.value.isPlaying ?? false)) {
        setState(() => _overlayVisible = false);
      }
    });
  }

  void _toggleOverlay() {
    setState(() => _overlayVisible = !_overlayVisible);
    if (_overlayVisible) _startHideTimer();
  }

  void _togglePlay() {
    final c = _ctrl;
    if (c == null) return;
    final ended = c.value.position >= c.value.duration;
    if (ended) {
      c.seekTo(Duration.zero);
      c.play();
      _startHideTimer();
    } else if (c.value.isPlaying) {
      c.pause();
      _hideTimer?.cancel();
    } else {
      c.play();
      _startHideTimer();
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _ctrl?.setVolume(_isMuted ? 0.0 : 1.0);
    _startHideTimer();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideTimer?.cancel();
    _ctrl?.removeListener(_onCtrlUpdate);
    _ctrl?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final item      = widget.item;
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final ctrl      = _ctrl;

    final duration = ctrl?.value.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? _isSeeking
            ? _seekValue
            : ((ctrl?.value.position.inMilliseconds ?? 0) /
                    duration.inMilliseconds)
                .clamp(0.0, 1.0)
        : 0.0;
    final displayedPos = _isSeeking
        ? Duration(milliseconds: (_seekValue * duration.inMilliseconds).round())
        : (ctrl?.value.position ?? Duration.zero);
    final isPlaying = ctrl?.value.isPlaying ?? false;
    final isEnded   = ctrl != null && !isPlaying &&
        ctrl.value.position >= ctrl.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Video ─────────────────────────────────────────────────────
            Center(
              child: _isLoading
                  ? _loadingWidget()
                  : _hasError || ctrl == null
                      ? _errorWidget()
                      : AspectRatio(
                          aspectRatio: ctrl.value.aspectRatio,
                          child: VideoPlayer(ctrl),
                        ),
            ),

            // ── Center play/pause button ───────────────────────────────────
            if (!_isLoading && !_hasError)
              Center(
                child: AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: !_overlayVisible,
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.5),
                        ),
                        child: Icon(
                          isEnded
                              ? FluentIcons.replay_20_filled
                              : isPlaying
                                  ? FluentIcons.pause_20_filled
                                  : FluentIcons.play_20_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Top bar ───────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _overlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !_overlayVisible,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.80),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 28),
                    child: Row(children: [
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.asset.title ?? 'Video',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _fmt(duration),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Mute toggle
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Size badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: PhotoService.sizeColor(item.sizeBytes)
                              .withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PhotoService.sizeColor(item.sizeBytes)
                                .withValues(alpha: 0.50),
                          ),
                        ),
                        child: Text(
                          PhotoService.formatBytes(item.sizeBytes),
                          style: TextStyle(
                            color: PhotoService.sizeColor(item.sizeBytes),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Bottom seek bar ────────────────────────────────────────────
            if (!_isLoading && !_hasError)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: !_overlayVisible,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding:
                          EdgeInsets.fromLTRB(16, 28, 16, bottomPad + 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(displayedPos),
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                                Text(_fmt(duration),
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.40),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            // absorb taps so outer GD doesn't toggle overlay
                            onTap: () {},
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor:
                                    Colors.white.withValues(alpha: 0.25),
                                thumbColor: Colors.white,
                                overlayColor:
                                    Colors.white.withValues(alpha: 0.15),
                              ),
                              child: Slider(
                                value: progress.toDouble(),
                                onChangeStart: (_) {
                                  _isSeeking = true;
                                  _hideTimer?.cancel();
                                  _ctrl?.pause();
                                },
                                onChanged: (v) =>
                                    setState(() => _seekValue = v),
                                onChangeEnd: (v) async {
                                  final target = Duration(
                                      milliseconds: (v *
                                              duration.inMilliseconds)
                                          .round());
                                  await _ctrl?.seekTo(target);
                                  await _ctrl?.play();
                                  _isSeeking = false;
                                  _startHideTimer();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _loadingWidget() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
              color: Colors.white60, strokeWidth: 2),
        ),
      );

  Widget _errorWidget() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.video_off_20_filled,
              color: Colors.white30, size: 52),
          const SizedBox(height: 12),
          const Text(
            'Impossibile riprodurre il video',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      );
}

