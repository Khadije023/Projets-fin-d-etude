import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SaignementPage extends StatelessWidget {
  const SaignementPage({super.key});

  Widget buildSection(
    BuildContext context,
    Color color,
    IconData icon,
    String titleKey,
    List<Widget> contentWidgets,
  ) {
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
              Text(
                titleKey.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...contentWidgets,
        ],
      ),
    );
  }

  /// ✅ CORRECT : ne pas faire `context.tr` sur une liste
  Widget buildLightBand(
    BuildContext context,
    String titleKey,
    List<String> itemKeys,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleKey.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...itemKeys.map(
            (key) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "• ${key.tr()}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
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
        title: Text('bleeding_title'.tr()),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'bleeding_subtitle'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            buildSection(
              context,
              Colors.red[700]!,
              Icons.bloodtype,
              'definition_title',
              [
                Text(
                  'definition_contentt'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            buildSection(
              context,
              Colors.orange[700]!,
              Icons.warning,
              'before_action_title',
              [
                buildLightBand(
                  context,
                  "alert_protection_title",
                  [
                    "alert_protection_points.0",
                    "alert_protection_points.1",
                    "alert_protection_points.2",
                    "alert_protection_points.3",
                    "alert_protection_points.4",
                    "alert_protection_points.5",
                    "alert_protection_points.6",
                    "alert_protection_points.7",
                  ],
                ),
              ],
            ),
            buildSection(
              context,
              Colors.green[700]!,
              Icons.healing,
              'actions_titlee',
              [
                buildLightBand(
                  context,
                  "direct_compression_title",
                  [
                    "direct_compression_points.0",
                    "direct_compression_points.1",
                    "direct_compression_points.2",
                    "direct_compression_points.3",
                  ],
                ),
                buildLightBand(
                  context,
                  "tourniquet_title",
                  [
                    "tourniquet_points.0",
                    "tourniquet_points.1",
                    "tourniquet_points.2",
                    "tourniquet_points.3",
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'warning_text'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
