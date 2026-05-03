import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MalaiseCardiaquePage extends StatelessWidget {
  const MalaiseCardiaquePage({super.key});

  Widget buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Container(
          color: Colors.amber[100],
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget buildStep(int number, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            radius: 14,
            child: Text(
              number.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('malaise_title'.tr()),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildSectionTitle(
              Icons.info, 'sections.definition.title'.tr(), Colors.blue),
          buildStep(1, 'sections.definition.steps.step1'.tr()),
          buildStep(2, 'sections.definition.steps.step2'.tr()),
          const SizedBox(height: 12),
          buildSectionTitle(Icons.medical_services,
              'sections.conduct.title'.tr(), Colors.green),
          buildStep(1, 'sections.conduct.steps.step1'.tr()),
          buildStep(2, 'sections.conduct.steps.step2'.tr()),
          buildStep(3, 'sections.conduct.steps.step3'.tr()),
          buildStep(4, 'sections.conduct.steps.step4'.tr()),
          buildStep(5, 'sections.conduct.steps.step5'.tr()),
          buildStep(6, 'sections.conduct.steps.step6'.tr()),
          buildStep(7, 'sections.conduct.steps.step7'.tr()),
          buildStep(8, 'sections.conduct.steps.step8'.tr()),
          buildStep(9, 'sections.conduct.steps.step9'.tr()),
          const SizedBox(height: 12),
          buildSectionTitle(Icons.warning_amber,
              'sections.alert_protection.title'.tr(), Colors.redAccent),
          buildStep(1, 'sections.alert_protection.steps.step1'.tr()),
          buildStep(2, 'sections.alert_protection.steps.step2'.tr()),
          buildStep(3, 'sections.alert_protection.steps.step3'.tr()),
        ],
      ),
    );
  }
}
