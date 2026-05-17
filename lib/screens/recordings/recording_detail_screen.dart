import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../services/recordings_repository.dart';

class RecordingDetailScreen extends StatefulWidget {
  const RecordingDetailScreen({super.key, this.file});

  final File? file;

  @override
  State<RecordingDetailScreen> createState() => _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends State<RecordingDetailScreen> {
  VideoPlayerController? _controller;
  bool _isVideo = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final file = widget.file;
    if (file == null || !file.existsSync()) return;

    _isVideo = file.path.endsWith('.mp4');
    if (!_isVideo) {
      setState(() {});
      return;
    }

    _controller = VideoPlayerController.file(file);
    await _controller!.initialize();
    _controller!.setLooping(true);
    await _controller!.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final name = file?.path.split('/').last ?? 'Recording';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideo && _controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (file != null && file.path.endsWith('.jpg'))
            Center(child: Image.file(file, fit: BoxFit.contain))
          else
            const Center(
              child: Icon(Icons.play_circle_outline_rounded, size: 72, color: AppColors.textMuted),
            ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    if (_controller != null && _controller!.value.isInitialized)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                          });
                        },
                        icon: Icon(
                          _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (file != null)
                    Text(
                      '${(file.statSync().size / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 20),
                  if (file != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await RecordingsRepository.instance.deleteRecording(file);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
