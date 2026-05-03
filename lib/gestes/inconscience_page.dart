import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:easy_localization/easy_localization.dart';

import 'video_rcp_page.dart';

class InconsciencePage extends StatefulWidget {
  const InconsciencePage({super.key});

  @override
  State<InconsciencePage> createState() => _InconsciencePageState();
}

class _InconsciencePageState extends State<InconsciencePage> {
  VideoPlayerController? _controllerPLS;
  Future<void>? _initializeVideoPlayerFuturePLS;
  bool _showVideoPLS = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controllerPLS?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer(VideoPlayerController? controller,
      Future<void>? initializeVideoPlayerFuture) {
    if (controller == null || initializeVideoPlayerFuture == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
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
                    return const SizedBox(
                      height: 200,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.blueAccent)),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        if (controller.value.isInitialized)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
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

  Widget buildSection(
      Color color, IconData icon, String title, List<String> steps) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize:
                        18, // Réduction de la taille du titre pour plus de clarté
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "$index. $step",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15), // Taille du texte des étapes
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildLightSection(
      Color color, IconData icon, String title, List<String> steps) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17, // Légère réduction pour la clarté
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "$index. $step",
                style: TextStyle(
                    color: color, fontSize: 14), // Taille du texte des étapes
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildCuteSection(String title, List<String> steps,
      {IconData? icon, Color? color, VoidCallback? onTap}) {
    final sectionColor = color ?? Colors.red.shade100;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sectionColor.withAlpha((0.8 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, color: Colors.white),
                if (icon != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17, // Légère réduction pour la clarté
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "$index. $step",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14), // Taille du texte des étapes
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildFourImageRows(
      String img1, String img2, String img3, String img4) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset(img1, width: 150, height: 120, fit: BoxFit.cover),
              Image.asset(img2, width: 150, height: 120, fit: BoxFit.cover),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset(img3, width: 150, height: 120, fit: BoxFit.cover),
              Image.asset(img4, width: 150, height: 120, fit: BoxFit.cover),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _initializePLSVideo() async {
    if (_controllerPLS == null) {
      _controllerPLS = VideoPlayerController.asset(
          'assets/videos/PLSS.mp4'); // Replace with your PLS video path
      _initializeVideoPlayerFuturePLS = _controllerPLS!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('page_title'.tr()),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'main_description'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            buildSection(
              Colors.blue[700]!,
              Icons.sick,
              'definition_title'.tr(),
              [
                'definition_content'.tr(),
              ],
            ),
            buildCuteSection(
              'immediate_action_title'.tr(),
              [
                'immediate_action_1'.tr(),
                'immediate_action_2'.tr(),
                'immediate_action_3'.tr(),
                'immediate_action_4'.tr(),
                'immediate_action_5'.tr(),
              ],
              icon: Icons.phone_in_talk,
              color: Colors.orange.shade600,
            ),
            buildSection(
              Colors.green[700]!,
              Icons.healing,
              'conduct_title'.tr(),
              [
                'conduct_1'.tr(),
                'conduct_2'.tr(),
                'conduct_3'.tr(),
                'conduct_4'.tr(),
                'conduct_5'.tr(),
                'conduct_6'.tr(),
                'conduct_7'.tr(),
                'conduct_8'.tr(),
              ],
            ),
            buildLightSection(
              Colors.teal,
              Icons.airline_seat_flat,
              'airway_title'.tr(),
              [
                'airway_1'.tr(),
                'airway_2'.tr(),
                'airway_3'.tr(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset(
                'assets/img/LVA.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            buildLightSection(
              Colors.deepPurple,
              Icons.bed,
              'pls_title'.tr(),
              [
                'pls_1'.tr(),
                'pls_2'.tr(),
                'pls_3'.tr(),
                'pls_4'.tr(),
                'pls_5'.tr(),
                'pls_6'.tr(),
                'pls_7'.tr(),
                'pls_8'.tr(),
                'pls_9'.tr(),
              ],
            ),
            buildFourImageRows(
              'assets/img/p1.jpg',
              'assets/img/p2.jpg',
              'assets/img/p3.jpg',
              'assets/img/p4.jpg',
            ),
            const SizedBox(height: 20),
            buildCuteSection(
              "cpr_title".tr(),
              [
                "cpr_1".tr(),
                "cpr_2".tr(),
                "cpr_3".tr(),
                "cpr_4".tr(),
                "cpr_5".tr(),
                "cpr_6".tr(),
                "cpr_7".tr(),
                "cpr_8".tr(),
              ],
              icon: Icons.favorite,
              color: Colors.pink.shade200,
              onTap: () {
                // Logique pour scroller directement à cette section (à implémenter)
              },
            ),
            buildCuteSection(
              "aed_title".tr(),
              [
                "aed_1".tr(),
                "aed_2".tr(),
                "aed_3".tr(),
              ],
              icon: Icons.bolt,
              color: Colors.blue.shade400,
            ),
            buildCuteSection(
              "dont_stop_title".tr(),
              [
                "dont_stop_1".tr(),
                "dont_stop_2".tr(),
              ],
              icon: Icons.access_time_filled,
              color: Colors.green.shade400,
            ),
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  icon: Icon(
                    _showVideoPLS
                        ? Icons.visibility_off
                        : Icons.play_circle_fill,
                  ),
                  label: Text(
                    _showVideoPLS
                        ? "hide_pls_video".tr()
                        : "show_pls_video".tr(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showVideoPLS = !_showVideoPLS;
                      if (_showVideoPLS && _controllerPLS == null) {
                        _initializePLSVideo();
                      } else if (!_showVideoPLS) {
                        _controllerPLS?.pause();
                        _controllerPLS?.seekTo(Duration.zero);
                      }
                    });
                  },
                ),
              ),
            ),
            if (_showVideoPLS)
              _buildVideoPlayer(
                  _controllerPLS, _initializeVideoPlayerFuturePLS),
            const SizedBox(height: 5),
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoRCPPage()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text("start_cpr".tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
