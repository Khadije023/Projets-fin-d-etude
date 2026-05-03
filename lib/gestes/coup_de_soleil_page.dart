import 'package:flutter/material.dart';

class CoupDeSoleilPage extends StatelessWidget {
  const CoupDeSoleilPage({super.key});

  Widget buildStep(String text, {int? number}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (number != null)
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.orange,
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          if (number != null) const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBandeTitle(String title, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
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
        title: const Text('Coup de Soleil'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Image illustrative en haut

            buildBandeTitle("☀️ Symptômes du coup de soleil", Icons.warning,
                Colors.deepOrange),
            buildStep("Peau rouge et sensible au toucher."),
            buildStep("Cloques apparaissant après quelques heures ou jours."),
            buildStep("Fièvre, frissons, nausées ou éruptions cutanées."),
            buildStep("Peau qui pèle quelques jours plus tard."),

            buildBandeTitle("🩺 Que faire en cas de coup de soleil",
                Icons.health_and_safety, Colors.orange),
            buildStep("Mettre à l’abri du soleil.", number: 1),
            buildStep("Douche ou compresses tièdes.", number: 2),
            buildStep("Éviter les savons ultra-doux.", number: 3),
            buildStep("Boire beaucoup d’eau pendant 2-3 jours.", number: 4),
            buildStep("Couvrir les zones touchées du soleil.", number: 6),

            buildBandeTitle("🚨 Quand consulter un médecin ?",
                Icons.medical_services, Colors.red),
            buildStep("Cloques ou douleurs extrêmes."),
            buildStep("Gonflement au visage."),
            buildStep("Fièvre ou frissons graves."),
            buildStep("Peau moite, pâle ou froide."),
            buildStep("Pouls ou respiration rapide."),
            buildStep("Confusion, étourdissement ou évanouissement."),
            buildStep("Déshydratation ou infection cutanée."),
            buildStep("Yeux douloureux ou sensibles à la lumière."),

            buildBandeTitle("🔥 Coup de chaleur : URGENCE",
                Icons.local_hospital, Colors.redAccent),
            buildStep("Appeler les secours (101)."),
            buildStep(
                "Température corporelle élevée, inconscience, confusion."),
            buildStep("Absence de transpiration."),
            buildStep("Rafraîchir avec eau froide et éventer."),

            buildBandeTitle(
                "🔒 Prévention du coup de soleil", Icons.shield, Colors.orange),
            buildStep("Le bronzage santé n’existe pas.", number: 1),
            buildStep("Évitez le soleil entre 11h et 16h.", number: 2),
            buildStep("Porter un chapeau et des vêtements couvrants.",
                number: 3),
            buildStep("Utiliser un écran solaire FPS 30+ toutes les 2h.",
                number: 4),
            buildStep("Protéger les yeux avec des lunettes anti-UV.",
                number: 5),
            buildStep("Boire de l’eau régulièrement, même sans soif.",
                number: 6),
            buildStep("Surveiller les enfants : peau plus sensible.",
                number: 7),
          ],
        ),
      ),
    );
  }
}
