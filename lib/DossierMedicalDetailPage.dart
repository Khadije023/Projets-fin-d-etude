// Fichier: lib/DossierMedicalDetailPage.dart
import 'package:flutter/material.dart';

class DossierMedicalDetailPage extends StatelessWidget {
  final Map<String, dynamic> dossierMedical;

  const DossierMedicalDetailPage({super.key, required this.dossierMedical});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier Médical du Patient'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du Dossier Médical:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Afficher chaque paire clé-valeur du dossier médical
            ...dossierMedical.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key.replaceAll('_', ' ')}: ', // Remplacer les underscores par des espaces pour une meilleure lecture
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (dossierMedical.isEmpty)
              const Text('Aucune information de dossier médical disponible.',
                  style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
