import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NoyadePage extends StatelessWidget {
  final List<Map<String, dynamic>> steps = [
    {
      'icon': Icons.warning_amber,
      'textKey': 'steps_0',
      'color': Colors.lightBlueAccent
    },
    {
      'icon': Icons.phone_in_talk,
      'textKey': 'steps_1',
      'color': Colors.orangeAccent
    },
    {'icon': Icons.air, 'textKey': 'steps_2', 'color': Colors.greenAccent},
    {'icon': Icons.favorite, 'textKey': 'steps_3', 'color': Colors.pinkAccent},
    {
      'icon': Icons.access_time,
      'textKey': 'steps_4',
      'color': Colors.purpleAccent
    },
    {'icon': Icons.sos, 'textKey': 'steps_5', 'color': Colors.indigoAccent},
    {
      'icon': Icons.access_time,
      'textKey': 'steps_6',
      'color': Colors.redAccent
    },
  ];

  NoyadePage({super.key});

  Widget buildStepCard(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: step['color'],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(step['icon'], size: 30, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                (step['textKey'] as String).tr(),
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildCuteSection({
    required IconData icon,
    required String titleKey,
    required String contentKey,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  titleKey.tr(),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            contentKey.tr(),
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('noyade_title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'main_title'.tr(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...steps.map(buildStepCard),
            SizedBox(height: 24),
            buildCuteSection(
              icon: Icons.child_care,
              titleKey: 'airway_titlee',
              contentKey: 'airway_content',
              color: Colors.teal,
            ),
            buildCuteSection(
              icon: Icons.favorite,
              titleKey: 'cpr_titlee',
              contentKey: 'cpr_content',
              color: Colors.deepOrangeAccent,
            ),
          ],
        ),
      ),
    );
  }
}
