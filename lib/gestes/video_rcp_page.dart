import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class VideoRCPPage extends StatefulWidget {
  const VideoRCPPage({super.key});

  @override
  State<VideoRCPPage> createState() => _VideoRCPPageState();
}

class _VideoRCPPageState extends State<VideoRCPPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/DAE.mov')
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(1.0);
        _controller.play();
      }).catchError((error) {
        logger.d("Error initializing video: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démonstration RCP'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.8, // Contrôle de la largeur maximale (80% de l'écran)
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Force un format rectangulaire 16:9
                  child: VideoPlayer(_controller),
                ),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade700,
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
