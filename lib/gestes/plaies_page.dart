import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PlaiesPage extends StatelessWidget {
  const PlaiesPage({super.key});

  Widget buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title.tr(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "• ${line.tr()}",
                  style: const TextStyle(fontSize: 16),
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('wounds_title'.tr()),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          buildSection(
            icon: Icons.warning_amber_rounded,
            title: 'definition_title',
            color: Colors.deepOrange,
            content: [
              'definition_1',
              'definition_2',
              'definition_3',
            ],
          ),
          buildSection(
            icon: Icons.favorite_rounded,
            title: 'actions_title',
            color: Colors.green,
            content: [
              'actions_1',
              'actions_2',
              'actions_3',
              'actions_4',
              'actions_5',
              'actions_6',
              'actions_7',
            ],
          ),
          buildSection(
            icon: Icons.check_circle_rounded,
            title: 'dont_do_title',
            color: Colors.red,
            content: [
              'dont_do_1',
              'dont_do_2',
              'dont_do_3',
            ],
          ),
        ],
      ),
    );
  }
}
