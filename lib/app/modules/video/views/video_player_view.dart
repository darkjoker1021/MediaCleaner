import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.item});

  final PhotoItem item;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = await widget.item.asset.file;
    if (file == null || !await file.exists()) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    final ctrl = VideoPlayerController.file(File(file.path));
    try {
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _isLoading = false;
      });
    } catch (_) {
      await ctrl.dispose();
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Riproduzione video', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white70)
            : _hasError || _controller == null
                ? const Text(
                    'Impossibile riprodurre questo video',
                    style: TextStyle(color: Colors.white70),
                  )
                : GestureDetector(
                    onTap: () {
                      final c = _controller!;
                      if (c.value.isPlaying) {
                        c.pause();
                      } else {
                        c.play();
                      }
                      setState(() {});
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                        if (!_controller!.value.isPlaying)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              FluentIcons.play_20_filled,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

