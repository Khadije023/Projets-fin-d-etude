// lib/hopitaux_page.dart
import 'package:flutter/material.dart';

class HopitauxPage extends StatelessWidget {
  const HopitauxPage({super.key});

  final List<HopitalDisplayData> _hopitaux = const [
    HopitalDisplayData(
      nom: 'Hôpital National de Nouakchott',
      adresse: 'Avenue Gamal Abdel Nasser',
      telephone: '+222 46413300',
    ),
    HopitalDisplayData(
      nom: 'Centre Hospitalier Mère et Enfant',
      adresse: 'Carrefour BMD',
      telephone: '+222 46414400',
    ),
    HopitalDisplayData(
      nom: 'Clinique Chiva',
      adresse: 'Tevragh Zeina',
      telephone: '+222 36303300',
    ),
    HopitalDisplayData(
      nom: 'Clinique Kairouan',
      adresse: 'Ilot K, Tevragh Zeina',
      telephone: '+222 45294455',
    ),
    HopitalDisplayData(
      nom: 'Clinique Pro Santé',
      adresse: 'Arafat, Route de Nouadhibou',
      telephone: '+222 22441122',
    ),
    HopitalDisplayData(
      nom: 'Clinique Al Farabi',
      adresse: 'Dar Naïm',
      telephone: '+222 46415500',
    ),
    HopitalDisplayData(
      nom: 'Centre Hospitalier Zayed',
      adresse: 'Sebkha',
      telephone: '+222 46416600',
    ),
    HopitalDisplayData(
      nom: 'Clinique Ibn Sina',
      adresse: 'Ksar',
      telephone: '+222 45291100',
    ),
    HopitalDisplayData(
      nom: 'Hôpital Cheikh Zayed',
      adresse: 'El Mina',
      telephone: '+222 45293344',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hôpitaux à Proximité'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: _hopitaux.length,
        itemBuilder: (context, index) {
          final hopital = _hopitaux[index];
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: ListTile(
              leading: Icon(Icons.local_hospital,
                  color: Colors.teal.shade700, size: 40),
              title: Text(
                hopital.nom,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                  'Adresse: ${hopital.adresse}\nTél: ${hopital.telephone ?? 'Non disponible'}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class HopitalDisplayData {
  final String nom;
  final String adresse;
  final String? telephone;

  const HopitalDisplayData({
    required this.nom,
    required this.adresse,
    this.telephone,
  });
}
