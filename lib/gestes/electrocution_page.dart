import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ElectrocutionPage extends StatelessWidget {
  const ElectrocutionPage({super.key});

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
            int index = entry.key + 1;
            String step = entry.value;
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
        title: Text('electrocution.page_title'.tr()),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'electrocution.emergency_warning'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            buildSection(
              Colors.deepPurple,
              Icons.lock,
              'electrocution.secure_zone'.tr(),
              [
                'electrocution.secure_zone_step1'.tr(),
                'electrocution.secure_zone_step2'.tr(),
                'electrocution.secure_zone_step3'.tr(),
                'electrocution.secure_zone_step4'.tr(),
              ],
            ),
            buildSection(
              Colors.blue,
              Icons.health_and_safety,
              'electrocution.evaluate_victim'.tr(),
              [
                'electrocution.evaluate_victim_step1'.tr(),
                'electrocution.evaluate_victim_step2'.tr(),
                'electrocution.evaluate_victim_step3'.tr(),
              ],
            ),
            buildSection(
              Colors.orange,
              Icons.phone,
              'electrocution.alert_emergency'.tr(),
              [
                'electrocution.alert_emergency_step1'.tr(),
                'electrocution.alert_emergency_step2'.tr(),
              ],
            ),
            buildSection(
              Colors.green,
              Icons.volunteer_activism,
              'electrocution.first_aid'.tr(),
              [
                'electrocution.first_aid_step1'.tr(),
                'electrocution.first_aid_step2'.tr(),
                'electrocution.first_aid_step3'.tr(),
                'electrocution.first_aid_step4'.tr(),
              ],
            ),
            buildSection(
              Colors.redAccent,
              Icons.favorite,
              'electrocution.cpr'.tr(),
              [
                'electrocution.cpr_step1'.tr(),
                'electrocution.cpr_step2'.tr(),
                'electrocution.cpr_step3'.tr(),
              ],
            ),
            buildSection(
              Colors.purpleAccent,
              Icons.bed,
              'electrocution.recovery_position'.tr(),
              [
                'electrocution.recovery_position_step1'.tr(),
                'electrocution.recovery_position_step2'.tr(),
                'electrocution.recovery_position_step3'.tr(),
                'electrocution.recovery_position_step4'.tr(),
                'electrocution.recovery_position_step5'.tr(),
                'electrocution.recovery_position_step6'.tr(),
                'electrocution.recovery_position_step7'.tr(),
                'electrocution.recovery_position_step8'.tr(),
                'electrocution.recovery_position_step9'.tr(),
              ],
            ),
            buildSection(
              Colors.teal,
              Icons.remove_red_eye,
              'electrocution.monitor_victim'.tr(),
              [
                'electrocution.monitor_victim_step1'.tr(),
                'electrocution.monitor_victim_step2'.tr(),
                'electrocution.monitor_victim_step3'.tr(),
              ],
            ),
            buildSection(
              Colors.grey.shade800,
              Icons.tips_and_updates,
              'electrocution.remember'.tr(),
              [
                'electrocution.remember_step1'.tr(),
                'electrocution.remember_step2'.tr(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
