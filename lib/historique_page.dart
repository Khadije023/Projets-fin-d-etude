// lib/historique_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'services/map_data_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoriqueItemData {
  final int id;
  final String? ambulanceNom;
  final String? ambulanceId;
  final String date;
  final String typeUrgence;
  final String description;
  final String adresseLisible;
  final String statut;

  final String? patientNomComplet;
  final String? patientNumeroTelephone;

  final int? nombreTotalVictimes;
  final String? ageApproximatifVictimePrincipale;
  final String? victimePrincipaleConsciente;
  final String? victimePrincipaleRespire;
  final String? victimePrincipaleSaignementImportant;

  const HistoriqueItemData({
    required this.id,
    this.ambulanceNom,
    this.ambulanceId,
    required this.date,
    required this.typeUrgence,
    required this.description,
    required this.adresseLisible,
    required this.statut,
    this.patientNomComplet,
    this.patientNumeroTelephone,
    this.nombreTotalVictimes,
    this.ageApproximatifVictimePrincipale,
    this.victimePrincipaleConsciente,
    this.victimePrincipaleRespire,
    this.victimePrincipaleSaignementImportant,
  });

  factory HistoriqueItemData.fromUrgenceJson(Map<String, dynamic> json) {
    final DateTime dateTime = json['date_signalee'] != null
        ? DateTime.parse(json['date_signalee'])
        : DateTime.now();

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    final String formattedDate = formatter.format(dateTime);

    String? ambulanceNom;
    String? ambulanceId;
    if (json['ambulance_details'] is Map) {
      ambulanceNom = json['ambulance_details']['nom_vehicule'] as String?;
      ambulanceId = (json['ambulance_details']['id'] as int?)?.toString();
    } else if (json['ambulance'] != null) {
      ambulanceId = json['ambulance'].toString();

      ambulanceNom = 'Ambulance $ambulanceId';
    }

    String? patientNomComplet;
    String? patientNumeroTelephone;
    if (json['patient_details'] is Map) {
      final String? nom = json['patient_details']['nom'] as String?;
      final String? prenom = json['patient_details']['prenom'] as String?;
      patientNomComplet =
          (nom != null && prenom != null) ? '$prenom $nom' : null;
      patientNumeroTelephone =
          json['patient_details']['numero_telephone'] as String?;
    }

    final String typeUrgence = json['type_urgence'] ?? 'Urgence inconnue';
    final String description = json['description'] ?? '';

    return HistoriqueItemData(
      id: json['id'],
      ambulanceNom: ambulanceNom,
      ambulanceId: ambulanceId,
      date: formattedDate,
      typeUrgence: typeUrgence,
      description: description,
      adresseLisible: json['adresse_lisible'] ?? 'Adresse non spécifiée',
      statut: json['statut'],
      patientNomComplet: patientNomComplet,
      patientNumeroTelephone: patientNumeroTelephone,
      nombreTotalVictimes: json['nombre_total_victimes'] as int?,
      ageApproximatifVictimePrincipale:
          json['age_approximatif_victime_principale'] as String?,
      victimePrincipaleConsciente:
          json['victime_principale_consciente'] as String?,
      victimePrincipaleRespire: json['victime_principale_respire'] as String?,
      victimePrincipaleSaignementImportant:
          json['victime_principale_saignement_important'] as String?,
    );
  }
}

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<HistoriqueItemData> _currentHistoriqueItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapDataService>(context, listen: false)
          .fetchHistoriqueUrgences()
          .then((_) {
        _updateLocalHistoriqueItems();
      });
    });
  }

  void _updateLocalHistoriqueItems() {
    setState(() {
      _currentHistoriqueItems = Provider.of<MapDataService>(context,
              listen: false)
          .historiqueUrgences
          .map((urgenceJson) => HistoriqueItemData.fromUrgenceJson(urgenceJson))
          .toList();
    });
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'terminee':
        return Colors.green.shade700;
      case 'refusee':
        return Colors.red.shade700;
      case 'annulee':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _deleteHistoriqueItem(int urgenceId, int indexToRemove) async {
    final mapDataService = Provider.of<MapDataService>(context, listen: false);
    final String apiBaseUrl = mapDataService.apiBaseUrl;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression de l\'urgence ID $urgenceId...')),
      );

      setState(() {
        _currentHistoriqueItems.removeAt(indexToRemove);
      });
    }

    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/urgences/$urgenceId/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Urgence supprimée de l\'historique.',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
        mapDataService.fetchHistoriqueUrgences();
        mapDataService.fetchUrgences();
      } else {
        String errorMessage =
            'Échec de la suppression. Erreur ${response.statusCode}';
        try {
          final errorBody = json.decode(utf8.decode(response.bodyBytes));
          if (errorBody['detail'] != null) {
            errorMessage += ': ${errorBody['detail']}';
          } else if (errorBody['message'] != null) {
            errorMessage += ': ${errorBody['message']}';
          }
        } catch (e) {
          print('Failed to parse error response body: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(errorMessage, style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
        mapDataService.fetchHistoriqueUrgences();
        mapDataService.fetchUrgences();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur réseau lors de la suppression : $e',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
      }
      mapDataService.fetchHistoriqueUrgences();
      mapDataService.fetchUrgences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Interventions'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<MapDataService>(
        builder: (context, mapDataService, child) {
          if (mapDataService.historiqueUrgences.length !=
                  _currentHistoriqueItems.length ||
              _currentHistoriqueItems.any((item) => !mapDataService
                  .historiqueUrgences
                  .any((json) => json['id'] == item.id))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateLocalHistoriqueItems();
            });
          }

          if (mapDataService.isLoadingHistorique &&
              _currentHistoriqueItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_currentHistoriqueItems.isEmpty &&
              !mapDataService.isLoadingHistorique) {
            return const Center(
                child: Text("Aucun historique d'intervention disponible.",
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.separated(
            itemCount: _currentHistoriqueItems.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final item = _currentHistoriqueItems[index];
              return Dismissible(
                key: Key(item.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirmer la suppression"),
                        content: Text(
                            "Voulez-vous vraiment supprimer l'urgence ID ${item.id} de l'historique ?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Supprimer",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  _deleteHistoriqueItem(item.id, index);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getStatutColor(item.statut).withOpacity(0.2),
                    child: Icon(
                      item.statut == 'terminee'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: _getStatutColor(item.statut),
                    ),
                  ),
                  title: Text(
                    'Urgence ID: ${item.id} - ${item.date}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type d\'urgence: ${item.typeUrgence}'),
                      if (item.description.isNotEmpty)
                        Text('Description: ${item.description}'),

                      // Affichage des détails du patient
                      if (item.patientNomComplet != null &&
                          item.patientNomComplet!.isNotEmpty)
                        Text('Patient: ${item.patientNomComplet}'),
                      if (item.patientNumeroTelephone != null &&
                          item.patientNumeroTelephone!.isNotEmpty)
                        Text('Tel. patient: ${item.patientNumeroTelephone}'),

                      // Affichage des nouveaux champs structurés
                      if (item.nombreTotalVictimes != null &&
                          item.nombreTotalVictimes! > 0)
                        Text('Victimes: ${item.nombreTotalVictimes}'),
                      if (item.ageApproximatifVictimePrincipale != null &&
                          item.ageApproximatifVictimePrincipale!.isNotEmpty)
                        Text(
                            'Âge victime: ${item.ageApproximatifVictimePrincipale}'),

                      // Utilisation des valeurs textuelles des choix Django pour la lisibilité
                      if (item.victimePrincipaleConsciente != null &&
                          item.victimePrincipaleConsciente!.isNotEmpty)
                        Text(
                            'Consciente: ${_mapVictimeEtat(item.victimePrincipaleConsciente!)}'),
                      if (item.victimePrincipaleRespire != null &&
                          item.victimePrincipaleRespire!.isNotEmpty)
                        Text(
                            'Respire: ${_mapVictimeEtat(item.victimePrincipaleRespire!)}'),
                      if (item.victimePrincipaleSaignementImportant != null &&
                          item.victimePrincipaleSaignementImportant!.isNotEmpty)
                        Text(
                            'Saignement: ${_mapVictimeEtat(item.victimePrincipaleSaignementImportant!)}'),

                      const SizedBox(height: 4),
                      Text('Adresse: ${item.adresseLisible}'),
                      if (item.ambulanceNom != null &&
                          item.ambulanceNom!.isNotEmpty)
                        Text(
                            'Ambulance: ${item.ambulanceNom} (ID: ${item.ambulanceId ?? 'N/A'})'),

                      const SizedBox(height: 4),
                      Text('Statut: ${item.statut}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatutColor(item.statut))),
                    ],
                  ),
                  isThreeLine: false,
                  dense: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Petite fonction utilitaire pour mapper les codes 'oui', 'non', 'nsp' à des textes lisibles
  String _mapVictimeEtat(String code) {
    switch (code) {
      case 'oui':
        return 'Oui';
      case 'non':
        return 'Non';
      case 'nsp':
        return 'Ne sait pas';
      default:
        return code; // Retourne le code si non reconnu
    }
  }
}
