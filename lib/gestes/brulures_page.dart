import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BruluresPage extends StatelessWidget {
  final TextStyle stepTextStyle = TextStyle(fontSize: 16);

  BruluresPage({super.key});

  Widget buildStep(int number, String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 2)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 14,
            child: Text('$number', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: stepTextStyle)),
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

  Widget buildThreeImageRows(String path1, String path2, String path3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final path in [path1, path2, path3])
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  path,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      'burns.image_not_found'.tr(args: [path]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('burns.page_title'.tr()),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionTitle('burns.definition'.tr(), Icons.whatshot),
            buildStep(1, 'burns.definition_text'.tr()),

            // Bande "Avant d'agir"
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'burns.before_acting'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  buildStep(1, 'burns.before_acting_step1'.tr()),
                  buildStep(2, 'burns.before_acting_step2'.tr()),
                ],
              ),
            ),

            buildSectionTitle('burns.simple_burns'.tr(), Icons.local_hospital),
            buildStep(1, 'burns.simple_burns_step1'.tr()),
            buildStep(2, 'burns.simple_burns_step2'.tr()),
            buildStep(3, 'burns.simple_burns_step3'.tr()),
            buildStep(4, 'burns.simple_burns_step4'.tr()),
            buildStep(5, 'burns.simple_burns_step5'.tr()),

            buildSectionTitle(
                'burns.serious_burns'.tr(), Icons.health_and_safety),
            buildStep(1, 'burns.serious_burns_step1'.tr()),
            buildStep(2, 'burns.serious_burns_step2'.tr()),
            buildStep(3, 'burns.serious_burns_step3'.tr()),
            buildStep(4, 'burns.serious_burns_step4'.tr()),
            buildStep(5, 'burns.serious_burns_step5'.tr()),
            buildStep(6, 'burns.serious_burns_step6'.tr()),

            // Bande "La règle des 15"
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade400),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'burns.rule_15_title'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: 'burns.rule_15_text'.tr()),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),
            buildThreeImageRows('assets/img/bru.jpeg', 'assets/img/brru.jpeg',
                'assets/img/vtbrulure.jpeg'),

            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'burns.warning_message'.tr(),
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
