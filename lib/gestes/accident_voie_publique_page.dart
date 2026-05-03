import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AccidentVoiePubliquePage extends StatelessWidget {
  const AccidentVoiePubliquePage({super.key});

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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('accident_page.title'.tr()),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'accident_page.warning'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            buildSection(
              Colors.green[700]!,
              Icons.security,
              'accident_page.protect.title'.tr(),
              [
                'accident_page.protect.step1'.tr(),
                'accident_page.protect.step2'.tr(),
              ],
            ),
            buildSection(
              Colors.orange[700]!,
              Icons.phone,
              'accident_page.alert.title'.tr(),
              [
                'accident_page.alert.step1'.tr(),
                'accident_page.alert.step2'.tr(),
              ],
            ),
            buildSection(
              Colors.redAccent,
              Icons.healing,
              'accident_page.rescue.title'.tr(),
              [
                'accident_page.rescue.step1'.tr(),
                'accident_page.rescue.step2'.tr(),
                'accident_page.rescue.step3'.tr(),
                'accident_page.rescue.step4'.tr(),
              ],
            ),
            buildSection(
              Colors.yellow[700]!,
              Icons.sentiment_satisfied_alt,
              'accident_page.reassure.title'.tr(),
              [
                'accident_page.reassure.step1'.tr(),
              ],
            ),
            buildSection(
              Colors.redAccent,
              Icons.favorite,
              'accident_page.cpr.title'.tr(),
              [
                'accident_page.cpr.step1'.tr(),
                'accident_page.cpr.step2'.tr(),
                'accident_page.cpr.step3'.tr(),
              ],
            ),
            buildSection(
              Colors.purpleAccent,
              Icons.bed,
              'accident_page.pls.title'.tr(),
              [
                'accident_page.pls.step1'.tr(),
                'accident_page.pls.step2'.tr(),
                'accident_page.pls.step3'.tr(),
                'accident_page.pls.step4'.tr(),
                'accident_page.pls.step5'.tr(),
                'accident_page.pls.step6'.tr(),
                'accident_page.pls.step7'.tr(),
                'accident_page.pls.step8'.tr(),
                'accident_page.pls.step9'.tr(),
              ],
            ),
            buildSection(
              Colors.purple[700]!,
              Icons.info_outline,
              'accident_page.additional_info.title'.tr(),
              [
                'accident_page.additional_info.step1'.tr(),
                'accident_page.additional_info.step2'.tr(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
