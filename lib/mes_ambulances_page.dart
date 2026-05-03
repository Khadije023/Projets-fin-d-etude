// lib/mes_ambulances_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ambulance_data.dart';
import '../services/map_data_service.dart';

class MesAmbulancesPage extends StatelessWidget {
  const MesAmbulancesPage({super.key});

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'disponible':
        return Colors.green.shade700;
      case 'en route vers victime':
      case 'en route vers base':
        return Colors.deepPurple.shade700;
      case 'arrivee sur place':
      case 'prise en charge':
        return Colors.orange.shade700;
      case 'en attente':
      case 'acceptée':
      case 'ambulance affectée':
        return Colors.blue.shade700;
      case 'terminée':
        return Colors.grey.shade500;
      case 'refusée':
        return Colors.red.shade700;
      case 'occupée (non disponible)':
        return Colors.red.shade900;
      case 'maintenance':
        return Colors.blueGrey.shade700;
      default:
        return Colors.black87;
    }
  }

  String _getAmbulanceStatus(AmbulanceData ambulance, List<dynamic> urgences) {
    final List<String> interventionStatuses = [
      'en_attente',
      'acceptee',
      'ambulance_affectee',
      'en_route_vers_victime',
      'arrivee_sur_place',
      'prise_en_charge',
      'en_route_vers_base',
      'terminee',
    ];

    final activeUrgence = urgences.firstWhere(
      (u) {
        int? urgenceAmbulanceId;

        if (u['ambulances_assignees'] is List &&
            (u['ambulances_assignees'] as List).isNotEmpty) {
          final assignedAmbulanceData = (u['ambulances_assignees'] as List)
              .first['ambulance'] as Map<String, dynamic>?;
          if (assignedAmbulanceData != null) {
            urgenceAmbulanceId = assignedAmbulanceData['id'] is int
                ? assignedAmbulanceData['id']
                : int.tryParse(assignedAmbulanceData['id'].toString());
          }
        } else if (u['ambulance'] is Map) {
          urgenceAmbulanceId = u['ambulance']['id'] is int
              ? u['ambulance']['id']
              : int.tryParse(u['ambulance']['id'].toString());
        } else if (u['ambulance'] is int) {
          urgenceAmbulanceId = u['ambulance'] as int;
        } else if (u['ambulance'] != null) {
          urgenceAmbulanceId = int.tryParse(u['ambulance'].toString());
        }

        final isAmbulanceAssigned =
            urgenceAmbulanceId != null && urgenceAmbulanceId == ambulance.id;
        final String? urgenceStatut = u['statut'] as String?;
        final isUrgenceRelevant = urgenceStatut != null &&
            interventionStatuses.contains(urgenceStatut);

        return isAmbulanceAssigned && isUrgenceRelevant;
      },
      orElse: () => null,
    );

    if (activeUrgence != null) {
      final String urgenceStatut = activeUrgence['statut'];
      return _mapUrgenceStatusToDisplay(urgenceStatut);
    } else {
      if (ambulance.disponible == false) {
        return 'Occupée (non disponible)';
      }
      return 'Disponible';
    }
  }

  String _mapUrgenceStatusToDisplay(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'ambulance_affectee':
        return 'Ambulance affectée';
      case 'en_route_vers_victime':
        return 'En route vers victime';
      case 'arrivee_sur_place':
        return 'Arrivée sur place';
      case 'prise_en_charge':
        return 'Prise en charge';
      case 'en_route_vers_base':
        return 'En route vers base';
      case 'terminee':
        return 'Terminée';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Ambulances'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<MapDataService>(
        builder: (context, mapDataService, child) {
          if (mapDataService.isLoadingAmbulances ||
              mapDataService.isLoadingUrgences) {
            return const Center(child: CircularProgressIndicator());
          }

          if (mapDataService.ambulances.isEmpty) {
            return const Center(child: Text('Aucune ambulance trouvée.'));
          }

          return ListView.builder(
            itemCount: mapDataService.ambulances.length,
            itemBuilder: (context, index) {
              final ambulance = mapDataService.ambulances[index];
              final String statutAmbulance =
                  _getAmbulanceStatus(ambulance, mapDataService.urgences);

              return Card(
                elevation: 3.0,
                margin:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping,
                              color: Colors.red.shade700, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ambulance #${ambulance.id}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          'Immatriculation:', ambulance.nom ?? 'N/A'),
                      _buildDetailRow('Type:', ambulance.type ?? 'N/A'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Statut: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Expanded(
                            child: Text(
                              statutAmbulance,
                              style: TextStyle(
                                fontSize: 16,
                                color: _getStatutColor(statutAmbulance),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
