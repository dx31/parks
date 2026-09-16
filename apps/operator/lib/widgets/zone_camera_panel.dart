import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ZoneCameraPanel extends StatefulWidget {
  const ZoneCameraPanel({
    super.key,
    required this.url,
    this.headers = const {},
  });

  final String url;
  final Map<String, String> headers;

  @visibleForTesting
  static bool disablePlayer = false;

  @override
  State<ZoneCameraPanel> createState() => _ZoneCameraPanelState();
}

class _ZoneCameraPanelState extends State<ZoneCameraPanel> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void didUpdateWidget(ZoneCameraPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        !_sameHeaders(oldWidget.headers, widget.headers)) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    if (ZoneCameraPanel.disablePlayer) {
      return;
    }
    final previous = _controller;
    _controller = null;
    _error = null;
    await previous?.dispose();
    if (!mounted) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers,
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    }
  }

  static bool _sameHeaders(
    Map<String, String> left,
    Map<String, String> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            Center(
              child: _error == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Cámara no disponible',
                      style: TextStyle(color: Colors.white70),
                    ),
            ),
          const Positioned(left: 12, top: 12, child: _LiveBadge()),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Cámara en vivo',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
