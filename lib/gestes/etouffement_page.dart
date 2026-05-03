import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:easy_localization/easy_localization.dart';

class EtouffementPage extends StatefulWidget {
  final TextStyle stepTextStyle = TextStyle(fontSize: 16);

  EtouffementPage({super.key});

  @override
  EtouffementPageState createState() => EtouffementPageState();
}

class EtouffementPageState extends State<EtouffementPage> {
  VideoPlayerController? _controllerAdulte;
  Future<void>? _initializeVideoPlayerFutureAdulte;
  bool _showVideoAdulte = false;

  VideoPlayerController? _controllerBebe;
  Future<void>? _initializeVideoPlayerFutureBebe;
  bool _showVideoBebe = false;

  Future<void> _initializeAdulteVideo() async {
    if (_controllerAdulte == null) {
      _controllerAdulte =
          VideoPlayerController.asset('assets/videos/etouffementadulte.mov');
      _initializeVideoPlayerFutureAdulte =
          _controllerAdulte!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  Future<void> _initializeBebeVideo() async {
    if (_controllerBebe == null) {
      _controllerBebe =
          VideoPlayerController.asset('assets/videos/etouffementbb.mov');
      _initializeVideoPlayerFutureBebe =
          _controllerBebe!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controllerAdulte?.dispose();
    _controllerBebe?.dispose();
    super.dispose();
  }

  Widget buildStep(int number, String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 2)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            radius: 14,
            child: Text('$number', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: widget.stepTextStyle)),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              backgroundColor: Colors.orange.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImage(String path) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          height: 180,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              '${tr('image_not_found')} $path',
              style: TextStyle(color: Colors.red),
            );
          },
        ),
      ),
    );
  }

  Widget buildThreeImagesRow(String path1, String path2, String path3) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                path1,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    '${tr('image_not_found')} $path1',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                path2,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    '${tr('image_not_found')} $path2',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                path3,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    '${tr('image_not_found')} $path3',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSingleImageRow(String path) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              '${tr('image_not_found')} $path',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController? controller,
      Future<void>? initializeVideoPlayerFuture) {
    if (controller == null || initializeVideoPlayerFuture == null) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: FutureBuilder(
            future: initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  controller.value.isInitialized) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayer(controller),
                  ),
                );
              } else {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }
            },
          ),
        ),
        if (controller.value.isInitialized)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                },
                child: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('choking_title')),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('alert_message'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('protection_message'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            buildSectionTitle(tr('general_info_title'), Icons.info),
            buildStep(1, tr('general_info_step_1')),
            buildStep(2, tr('general_info_step_2')),
            buildSectionTitle(
                tr('partial_obstruction_title'), Icons.warning_amber_rounded),
            buildStep(1, tr('partial_obstruction_step_1')),
            buildStep(2, tr('partial_obstruction_step_2')),
            buildStep(3, tr('partial_obstruction_step_3')),
            buildStep(4, tr('partial_obstruction_step_4')),
            buildSectionTitle(tr('total_obstruction_title'), Icons.warning),
            buildStep(1, tr('total_obstruction_step_1')),
            buildStep(2, tr('total_obstruction_step_2')),
            buildStep(3, tr('total_obstruction_step_3')),
            buildStep(4, tr('total_obstruction_step_4')),
            buildSectionTitle(tr('infant_case_title'), Icons.child_friendly),
            buildStep(1, tr('infant_step_1')),
            buildStep(2, tr('infant_step_2')),
            buildStep(3, tr('infant_step_3')),
            buildStep(4, tr('infant_step_4')),
            buildStep(5, tr('infant_step_5')),
            SizedBox(height: 16),
            buildThreeImagesRow(
              'assets/img/ett1.jpeg',
              'assets/img/ett2.jpeg',
              'assets/img/ett3.jpeg',
            ),
            SizedBox(height: 8),
            buildSingleImageRow('assets/img/ett4.jpeg'),
            buildSectionTitle(tr('techniques_title'), Icons.menu_book),
            buildStep(1, tr('technique_step_1')),
            buildStep(2, tr('technique_step_2')),
            buildStep(3, tr('technique_step_3')),
            SizedBox(height: 20),
            buildSectionTitle(tr('videos_title'), Icons.play_circle_outline),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  setState(() {
                    _showVideoAdulte = !_showVideoAdulte;
                  });
                  if (_showVideoAdulte) {
                    await _initializeAdulteVideo();
                  } else {
                    _controllerAdulte?.pause();
                    _controllerAdulte?.seekTo(Duration.zero);
                  }
                },
                child: Text(_showVideoAdulte
                    ? tr('hide_video_adult')
                    : tr('show_video_adult')),
              ),
            ),
            if (_showVideoAdulte)
              _buildVideoPlayer(
                _controllerAdulte,
                _initializeVideoPlayerFutureAdulte,
              ),
            SizedBox(height: 2),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  setState(() {
                    _showVideoBebe = !_showVideoBebe;
                  });
                  if (_showVideoBebe) {
                    await _initializeBebeVideo();
                  } else {
                    _controllerBebe?.pause();
                    _controllerBebe?.seekTo(Duration.zero);
                  }
                },
                child: Text(_showVideoBebe
                    ? tr('hide_video_infant')
                    : tr('show_video_infant')),
              ),
            ),
            if (_showVideoBebe)
              _buildVideoPlayer(
                _controllerBebe,
                _initializeVideoPlayerFutureBebe,
              ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tr('final_warning'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
