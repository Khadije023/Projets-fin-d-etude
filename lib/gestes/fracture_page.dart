import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:easy_localization/easy_localization.dart';

class FracturePage extends StatefulWidget {
  const FracturePage({super.key});

  @override
  State<FracturePage> createState() => _FracturePageState();
}

class _FracturePageState extends State<FracturePage> {
  VideoPlayerController? _controllerMaintienTete;
  Future<void>? _initializeVideoPlayerFutureMaintienTete;
  bool _showVideoMaintienTete = false;

  @override
  void initState() {
    super.initState();
    _controllerMaintienTete =
        VideoPlayerController.asset('assets/videos/maintienttete.mov');
    if (_controllerMaintienTete != null) {
      _initializeVideoPlayerFutureMaintienTete =
          _controllerMaintienTete!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controllerMaintienTete?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer(
      VideoPlayerController? controller, Future<void>? initializeFuture) {
    return controller != null
        ? FutureBuilder(
            future: initializeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          )
        : const SizedBox.shrink();
  }

  Widget _buildTechniqueCard({
    required String title,
    required List<String> steps,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .map((step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                                child: Text(step,
                                    style: const TextStyle(fontSize: 15))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCuteBand({
    required IconData icon,
    required String title,
    required Color? color,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Arial',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('fracture_title'.tr()),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildTechniqueCard(
            title: 'head_maintenance.title'.tr(),
            steps: [
              'head_maintenance.steps.step1'.tr(),
              'head_maintenance.steps.step2'.tr(),
              'head_maintenance.steps.step3'.tr(),
              'head_maintenance.steps.step4'.tr(),
            ],
            icon: Icons.accessibility,
            color: Colors.purple,
          ),
          const SizedBox(height: 2),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                setState(() {
                  _showVideoMaintienTete = !_showVideoMaintienTete;
                });
                if (_showVideoMaintienTete) {
                  if (_controllerMaintienTete != null &&
                      !_controllerMaintienTete!.value.isInitialized) {
                    await _initializeVideoPlayerFutureMaintienTete;
                    setState(() {}); // Rebuild to show the video player
                  } else if (_controllerMaintienTete != null) {
                    _controllerMaintienTete!.play();
                  }
                } else {
                  _controllerMaintienTete?.pause();
                  _controllerMaintienTete?.seekTo(Duration.zero);
                }
              },
              child: Text(_showVideoMaintienTete
                  ? 'video_buttons.hide_video'.tr()
                  : 'video_buttons.show_video'.tr()),
            ),
          ),
          if (_showVideoMaintienTete)
            _buildVideoPlayer(
              _controllerMaintienTete,
              _initializeVideoPlayerFutureMaintienTete,
            ),
          const SizedBox(height: 20),
          buildCuteBand(
            icon: Icons.self_improvement,
            title: 'advice_cards.stay_calm.title'.tr(),
            color: Colors.orange[100],
            text: 'advice_cards.stay_calm.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.warning,
            title: 'advice_cards.alert_protection.title'.tr(),
            color: Colors.purple[100],
            text: 'advice_cards.alert_protection.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.notification_important,
            title: 'advice_cards.stabilize_head.title'.tr(),
            color: Colors.blue[100],
            text: 'advice_cards.stabilize_head.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.pan_tool_alt,
            title: 'advice_cards.immobilize_area.title'.tr(),
            color: Colors.blue[100],
            text: 'advice_cards.immobilize_area.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.ac_unit,
            title: 'advice_cards.apply_cold.title'.tr(),
            color: Colors.cyan[100],
            text: 'advice_cards.apply_cold.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.block,
            title: 'advice_cards.no_massage.title'.tr(),
            color: Colors.pink[100],
            text: 'advice_cards.no_massage.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.local_hospital,
            title: 'advice_cards.consult_professional.title'.tr(),
            color: Colors.green[100],
            text: 'advice_cards.consult_professional.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.restaurant,
            title: 'advice_cards.nutrition_care.title'.tr(),
            color: Colors.yellow[100],
            text: 'advice_cards.nutrition_care.text'.tr(),
          ),
          buildCuteBand(
            icon: Icons.accessibility_new,
            title: 'advice_cards.prepare_rehabilitation.title'.tr(),
            color: Colors.purple[100],
            text: 'advice_cards.prepare_rehabilitation.text'.tr(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'final_message'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
