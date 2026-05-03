import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'video_rcp_page.dart';

class ArretCardiaquePage extends StatelessWidget {
  final TextStyle stepTextStyle = TextStyle(fontSize: 16);

  ArretCardiaquePage({super.key});

  Widget buildStep(int number, String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 2)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.redAccent,
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
          Icon(icon, color: Colors.red),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              backgroundColor: Colors.red.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImage(String path) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Image.asset(
        path,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            'cardiac_arrest.image_not_found'.tr(args: [path]),
            style: TextStyle(color: Colors.red),
          );
        },
      ),
    );
  }

  Widget buildThreeImagesRow(String path1, String path2, String path3) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.asset(
              path1,
              fit: BoxFit.cover,
              height: 100,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.asset(
              path2,
              fit: BoxFit.cover,
              height: 100,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.asset(
              path3,
              fit: BoxFit.cover,
              height: 100,
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
        title: Text('cardiac_arrest.title'.tr()),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bande Alerte
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cardiac_arrest.alert_banner'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),

            // Bande Protection
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.red.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cardiac_arrest.protection_banner'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),

            // Cas Adulte
            buildSectionTitle('cardiac_arrest.adult.title'.tr(), Icons.man),
            buildStep(1, 'cardiac_arrest.adult.step1'.tr()),
            buildStep(2, 'cardiac_arrest.adult.step2'.tr()),
            buildStep(3, 'cardiac_arrest.adult.step3'.tr()),
            buildStep(4, 'cardiac_arrest.adult.step4'.tr()),
            buildStep(5, 'cardiac_arrest.adult.step5'.tr()),
            buildStep(6, 'cardiac_arrest.adult.step6'.tr()),
            buildStep(7, 'cardiac_arrest.adult.step7'.tr()),

            // Trois images côte à côte
            SizedBox(height: 16),
            buildThreeImagesRow(
              'assets/img/gestearett.jpeg',
              'assets/img/gestearet.jpeg',
              'assets/img/gesteare.jpeg',
            ),

            SizedBox(height: 16),
            buildThreeImagesRow(
              'assets/img/rs.jpeg',
              'assets/img/rs1.jpeg',
              'assets/img/rs2.jpeg',
            ),

            // Cas Enfant
            buildSectionTitle(
                'cardiac_arrest.child.title'.tr(), Icons.child_care),
            buildStep(1, 'cardiac_arrest.child.step1'.tr()),
            buildStep(2, 'cardiac_arrest.child.step2'.tr()),
            buildStep(3, 'cardiac_arrest.child.step3'.tr()),
            buildStep(4, 'cardiac_arrest.child.step4'.tr()),
            buildStep(5, 'cardiac_arrest.child.step5'.tr()),
            buildStep(6, 'cardiac_arrest.child.step6'.tr()),
            buildStep(7, 'cardiac_arrest.child.step7'.tr()),

            // Cas Nourrisson
            buildSectionTitle('cardiac_arrest.infant.title'.tr(),
                Icons.baby_changing_station),
            buildStep(1, 'cardiac_arrest.infant.step1'.tr()),
            buildStep(2, 'cardiac_arrest.infant.step2'.tr()),
            buildStep(3, 'cardiac_arrest.infant.step3'.tr()),
            buildStep(4, 'cardiac_arrest.infant.step4'.tr()),
            buildStep(5, 'cardiac_arrest.infant.step5'.tr()),
            buildStep(6, 'cardiac_arrest.infant.step6'.tr()),
            buildStep(7, 'cardiac_arrest.infant.step7'.tr()),
            buildStep(8, 'cardiac_arrest.infant.step8'.tr()),

            // Réanimation Cardio-Pulmonaire
            buildSectionTitle('cardiac_arrest.cpr.title'.tr(), Icons.favorite),
            buildStep(1, 'cardiac_arrest.cpr.step1'.tr()),
            buildStep(2, 'cardiac_arrest.cpr.step2'.tr()),
            buildStep(3, 'cardiac_arrest.cpr.step3'.tr()),

            // Utilisation du DAE
            buildSectionTitle(
                'cardiac_arrest.aed.title'.tr(), Icons.electrical_services),
            buildStep(1, 'cardiac_arrest.aed.step1'.tr()),
            buildStep(2, 'cardiac_arrest.aed.step2'.tr()),
            buildStep(3, 'cardiac_arrest.aed.step3'.tr()),
            buildStep(4, 'cardiac_arrest.aed.step4'.tr()),
            buildStep(5, 'cardiac_arrest.aed.step5'.tr()),
            buildStep(6, 'cardiac_arrest.aed.step6'.tr()),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VideoRCPPage()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('cardiac_arrest.start_cpr_button'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
