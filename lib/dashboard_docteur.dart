// lib/dashboard_docteur.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'models/ambulance_data.dart';
import 'package:provider/provider.dart';
import 'services/map_data_service.dart';
import 'main_navigation_scaffold.dart';
import 'DossierMedicalDetailPage.dart';

//import 'full_screen_map_page.dart';
class DashboardDocteur extends StatefulWidget {
  final String name;
  const DashboardDocteur({required this.name, super.key});
  @override
  State<DashboardDocteur> createState() => _DashboardDocteurState();
}

class _DashboardDocteurState extends State<DashboardDocteur> {
  final String imageBaseUrl = "http://192.168.1.122:8000";
  final MapController _mapController =
      MapController(); // Contrôleur pour la petite carte du dashboard
  Timer? _refreshTimer; // Timer pour rafraîchir la liste des urgences (statuts)
  bool _isDashboardMapReady = false;

  @override
  void initState() {
    super.initState();
    print("DashboardDocteur initState: Démarrage.");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mapDataService =
            Provider.of<MapDataService>(context, listen: false);

        // La connexion WS dans le service commencera à streamer les positions d'ambulance.
        mapDataService
            .fetchAmbulancePositions(); // Pour la liste des ambulances et leur position initiale
        mapDataService.fetchUrgences(); // Pour la liste des urgences (statuts)
      }
    });
    _startAutoRefresh(); // Démarrer le timer pour rafraîchir la liste des urgences (statuts)
  }

  @override
  void dispose() {
    print("DashboardDocteur dispose: Annulation des timers.");
    _refreshTimer?.cancel();
    _mapController.dispose(); // Disposez le contrôleur de la mini-carte
    // La connexion WebSocket est gérée par le MapDataService singleton et sera dispose avec le service.
    super.dispose();
  }

  Future<void> _fitMapToMarkers() async {
    if (!_isDashboardMapReady || !mounted) {
      print(
          "DEBUG _fitMapToMarkers (Dashboard): Carte non prête ou widget non monté.");
      return;
    }

    final mapDataService = Provider.of<MapDataService>(context, listen: false);
    List<LatLng> points = [];

    // Inclure les ambulances avec des positions valides
    for (var ambulance in mapDataService.ambulances) {
      if (ambulance.position.latitude.isFinite &&
          ambulance.position.longitude.isFinite &&
          ambulance.position.latitude >= -90 &&
          ambulance.position.latitude <= 90 &&
          ambulance.position.longitude >= -180 &&
          ambulance.position.longitude <= 180) {
        points.add(ambulance.position);
      } else {
        // print("ALERTE _fitMapToMarkers (Dashboard): Position d'ambulance invalide ignorée: ${ambulance.position}");
      }
    }
    // Inclure les urgences actives avec des positions valides
    for (var urgence in mapDataService.urgences) {
      final lat = urgence['latitude'];
      final lon = urgence['longitude'];
      if (lat is num &&
          lon is num &&
          lat.isFinite &&
          lon.isFinite &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180) {
        points.add(LatLng(lat.toDouble(), lon.toDouble()));
      } else {
        // print("ALERTE _fitMapToMarkers (Dashboard): Position d'urgence invalide ignorée: Lat $lat, Lon $lon pour urgence ID ${urgence['id']}");
      }
    }

    LatLng newCenter;
    double newZoom;
    if (points.isEmpty) {
      print(
          "DEBUG _fitMapToMarkers (Dashboard): Aucun point valide, centrage par défaut.");
      // Utiliser la dernière position connue du service ou une position par défaut
      newCenter = mapDataService.lastKnownCenter ??
          const LatLng(18.0790, -15.9650); // Nouvelle valeur par défaut
      newZoom =
          mapDataService.lastKnownZoom ?? 6.0; // Nouvelle valeur par défaut
      _mapController.move(newCenter, newZoom);
      return;
    }

    if (points.length == 1) {
      print("DEBUG _fitMapToMarkers (Dashboard): Un seul point.");
      newCenter = points.first;
      newZoom = 14.0; // Zoom plus proche pour un seul point
      _mapController.move(newCenter, newZoom);
    } else {
      // Vérifier si tous les points sont identiques
      final uniquePoints = points.toSet();
      if (uniquePoints.length == 1) {
        print(
            "DEBUG _fitMapToMarkers (Dashboard): Plusieurs points identiques.");
        newCenter = points.first;
        newZoom = 14.0; // Zoom plus proche
        _mapController.move(newCenter, newZoom);
      } else {
        print(
            "DEBUG _fitMapToMarkers (Dashboard): Ajustement caméra pour ${points.length} points distincts.");
        try {
          LatLngBounds bounds = LatLngBounds.fromPoints(points);
          // Ajuster la caméra de la mini-carte
          _mapController.fitCamera(CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(
                  50.0))); // Ajustez le padding si nécessaire
          // On ne sauvegarde pas la position de la mini-carte dans lastKnownCenter/Zoom du service
          // car c'est la FullScreenMapPage qui gère la navigation et la position "principale"
        } catch (e, s) {
          print("ERREUR _fitMapToMarkers fitCamera (Dashboard): $e\n$s");
          // Centrer sur le premier point en cas d'erreur
          newCenter = points.isNotEmpty
              ? points.first
              : const LatLng(18.0790, -15.9650);
          newZoom = 12.0;
          if (points.isNotEmpty) _mapController.move(newCenter, newZoom);
        }
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    Duration refreshInterval = const Duration(seconds: 10);

    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        print(
            "DEBUG _startAutoRefresh (Dashboard): Timer annulé car widget non monté.");
        return;
      }

      print(
          "DEBUG _startAutoRefresh (Dashboard): Timer activé, appel fetchUrgences.");
      final mapDataService =
          Provider.of<MapDataService>(context, listen: false);

      await mapDataService.fetchUrgences();

      await mapDataService.fetchAmbulancePositions(); // Optionnel

      // La logique d'ajustement de l'intervalle basée sur les urgences actives est toujours pertinente
      bool hasActiveUrgency = mapDataService.urgences.any((u) => [
            'ambulance_affectee',
            'en_route_vers_victime',
            'arrivee_sur_place',
            'prise_en_charge',
            'en_route_vers_base',
            'terminee'
          ].contains(u['statut']));

      Duration newRefreshInterval = hasActiveUrgency
          ? const Duration(
              seconds: 5) // Rafraîchir la liste urgences plus souvent
          : const Duration(seconds: 10); // Intervalle de base

      // Note: On ne change pas l'intervalle du timer ici, car on ne veut pas recréer le timer constamment.
      // On peut ajuster la logique de rafraîchissement dans le service si nécessaire,
      // ou simplement garder un intervalle fixe pour ce timer qui ne fait que fetchUrgences.
      // Laissez l'intervalle fixe à 10s pour fetchUrgences, et les updates de position viendront par WS.
      print(
          "DEBUG _startAutoRefresh (Dashboard): Intervalle de rafraîchissement urgences est de ${refreshInterval.inSeconds}s.");
    });
  }

  Future<void> accepterUrgence(int urgenceId) async {
    if (!mounted) return;
    final mapDataService = Provider.of<MapDataService>(context, listen: false);
    final String apiBaseUrl = mapDataService.apiBaseUrl;

    print("DEBUG accepterUrgence: Tentative pour urgence ID $urgenceId");
    try {
      // Faites l'appel API pour accepter l'urgence
      final response = await http.post(
        Uri.parse('$apiBaseUrl/urgences/$urgenceId/accepter/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      );
      if (!mounted) return;

      print(
          'DEBUG accepterUrgence: Réponse: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData['status'] == 'success') {
          await mapDataService.fetchUrgences();
          if (mounted) {
            final List<dynamic>? ambulances = responseData['ambulances'];
            String? assignedAmbulanceId;
            String? assignedAmbulanceType;

            if (ambulances != null && ambulances.isNotEmpty) {
              final Map<String, dynamic>? firstAmbulance = ambulances.first;
              assignedAmbulanceId = firstAmbulance?['ambulance_id']?.toString();
              assignedAmbulanceType = firstAmbulance?['type']?.toString();
            }

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Urgence ID $urgenceId acceptée. Ambulance ${assignedAmbulanceId ?? 'N/A'} (Type: ${assignedAmbulanceType ?? 'N/A'}) affectée.'),
              backgroundColor: Colors.green,
            ));
          }

          LatLng? focusPoint;
          final urgenceAcceptedData = mapDataService.urgences.firstWhere(
            (u) => u['id'] == urgenceId,
            orElse: () => null,
          );

          if (urgenceAcceptedData != null &&
              urgenceAcceptedData['latitude'] != null &&
              urgenceAcceptedData['longitude'] != null) {
            try {
              focusPoint = LatLng(
                  double.parse(urgenceAcceptedData['latitude'].toString()),
                  double.parse(urgenceAcceptedData['longitude'].toString()));
            } catch (e) {
              print("Erreur parsing LatLng pour urgence $urgenceId: $e");
            }
          }

          if (focusPoint == null) {
            final ambulanceIdAssigned =
                responseData['ambulance_id']?.toString();
            if (ambulanceIdAssigned != null) {
              AmbulanceData? affectedAmbulance;
              try {
                affectedAmbulance = mapDataService.ambulances
                    .firstWhere((a) => a.id == ambulanceIdAssigned);
              } catch (e) {
                affectedAmbulance = null;
                print(
                    "DEBUG accepterUrgence: Ambulance ID $ambulanceIdAssigned non trouvée dans mapDataService.ambulances.");
              }
              if (affectedAmbulance != null) {
                focusPoint = affectedAmbulance.position;
              }
            }
          }

          if (mounted && focusPoint != null) {
            const int mapTabIndex = 1;
            const double zoomLevel = 15.0;

            mapDataService.navigateToMainTabWithMapArgs(
                mapTabIndex, focusPoint, zoomLevel);
          } else if (mounted) {
            const int mapTabIndex = 0;
            final defaultCenter = mapDataService.lastKnownCenter ??
                const LatLng(18.0790, -15.9650);
            final defaultZoom = mapDataService.lastKnownZoom ?? 6.0;
            mapDataService.navigateToMainTabWithMapArgs(
                mapTabIndex, defaultCenter, defaultZoom);
          }
        } else {
          // Gérer les erreurs spécifiques de l'API backend même si le statut HTTP est 200
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Acceptation échouée : ${responseData['error'] ?? responseData['message'] ?? 'Réponse invalide du serveur'}'),
                backgroundColor: Colors.orange));
          }
        }
      } else {
        // Gérer les erreurs de statut HTTP (400, 404, 500, etc.)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Erreur ${response.statusCode} lors de l’acceptation : ${utf8.decode(response.bodyBytes)}'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      // Gérer les erreurs de connexion réseau, de parsing, etc.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur réseau/connexion lors de l’acceptation: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> refuserUrgence(int urgenceId) async {
    if (!mounted) return;
    final mapDataService = Provider.of<MapDataService>(context, listen: false);
    final String apiBaseUrl = mapDataService.apiBaseUrl;

    print("DEBUG refuserUrgence: Tentative pour urgence ID $urgenceId");
    try {
      // Faites l'appel API PATCH pour refuser l'urgence
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/urgences/$urgenceId/refuser/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        // Le body est peut-être {} ou { 'statut': 'refusee' } selon votre backend
      );
      if (!mounted) return;
      print(
          'DEBUG refuserUrgence: Réponse: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Rafraîchir la liste des urgences pour enlever l'urgence refusée (selon le filtre fetchUrgences)
        await mapDataService.fetchUrgences();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Urgence refusée')));
        }
      } else {
        // Gérer les erreurs
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Erreur ${response.statusCode} lors du refus : ${utf8.decode(response.bodyBytes)}'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      // Gérer les erreurs réseau
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur réseau lors du refus : $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // La fonction de discussion reste la même
  /* void discuterAvecPatient(int patientId) {
    // Implémentez la navigation vers la page de chat avec le patient
    print('Discuter avec le patient $patientId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité "Discuter avec le patient $patientId" non implémentée. patientId: $patientId')),
    );
    // Exemple de navigation (adaptez selon votre routing) :
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(patientId: patientId)));
  }*/

  // Les méthodes _buildInfoRow restent inchangées
  Widget _buildInfoRow(String label, String? value,
      {bool isCritical = false, IconData? icon}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...[
            Icon(icon,
                size: 18,
                color: isCritical
                    ? Colors.red.shade700
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ] else ...[
            // Ajoutez un SizedBox pour aligner le texte s'il n'y a pas d'icône
            const SizedBox(width: 26),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface),
                children: <TextSpan>[
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: isCritical
                          ? Colors.red.shade700
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isCritical ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Écoutez MapDataService pour les changements de données (urgences, ambulances, positions par WS)
    final mapDataService = Provider.of<MapDataService>(context);
    final String imageBaseUrl =
        mapDataService.apiBaseUrl.replaceAll('/api', '');

    // print("DEBUG build (Dashboard): Ambulances(service): ${mapDataService.ambulances.length}, Urgences(service): ${mapDataService.urgences.length}, MapReady: $_isDashboardMapReady");
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue Dr. ${widget.name}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liste des Urgences ', // Le titre reflète qu'on affiche les urgences actives
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              // Affichage conditionnel basé sur le chargement et la liste d'urgences
              child: mapDataService.isLoadingUrgences
                  ? const Center(child: CircularProgressIndicator())
                  : mapDataService.urgences.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 10),
                            Text('Aucune urgence active pour le moment.',
                                style: TextStyle(color: Colors.grey[700])),
                          ],
                        ))
                      : RefreshIndicator(
                          // Permet de rafraîchir manuellement la liste
                          onRefresh: () async {
                            print(
                                "DEBUG RefreshIndicator (Dashboard): onRefresh appelé.");
                            await mapDataService
                                .fetchUrgences(); // Rafraîchit les urgences (statuts)
                          },
                          child: ListView.builder(
                            itemCount: mapDataService.urgences.length,
                            itemBuilder: (context, index) {
                              final urgence = mapDataService.urgences[index];
                              final String? rawImageUrl =
                                  urgence['image'] as String?;
                              String? finalImageUrl;
                              if (rawImageUrl != null &&
                                  rawImageUrl.isNotEmpty) {
                                if (rawImageUrl.startsWith('http://') ||
                                    rawImageUrl.startsWith('https://')) {
                                  finalImageUrl = rawImageUrl;
                                } else {
                                  finalImageUrl = imageBaseUrl +
                                      (rawImageUrl.startsWith('/')
                                          ? rawImageUrl
                                          : '/$rawImageUrl');
                                }
                              }
                              final id = urgence['id'] as int?;
                              final patientId = urgence['patient'] as int?;
                              final urgenceStatut =
                                  urgence['statut'] as String?;
                              final String? adresseLisible =
                                  urgence['adresse_lisible'] as String?;
                              final String? nombreVictimes =
                                  urgence['nombre_total_victimes']?.toString();
                              final String? natureUrgence =
                                  urgence['type_urgence'] as String?;
                              final String? ageApproximatif =
                                  urgence['age_approximatif_victime_principale']
                                      as String?;
                              final String? consciente =
                                  urgence['victime_principale_consciente']
                                      as String?;
                              final String? respire =
                                  urgence['victime_principale_respire']
                                      as String?;
                              final String? saignementImportant = urgence[
                                      'victime_principale_saignement_important']
                                  as String?;
                              final String? notesAdditionnelles =
                                  urgence['description'] as String?;
                              final int? adultCount =
                                  urgence['adult_count'] as int?;
                              final int? childCount =
                                  urgence['child_count'] as int?;
                              final int? infantCount =
                                  urgence['infant_count'] as int?;
                              final bool inclureDossierMedical =
                                  urgence['inclure_dossier_medical'] == true;
                              final Map<String, dynamic>? dossierMedical =
                                  inclureDossierMedical
                                      ? (urgence['dossier_medical_du_patient']
                                          as Map<String, dynamic>?)
                                      : null;

                              final Widget actionButtonWidget =
                                  (inclureDossierMedical &&
                                          dossierMedical != null &&
                                          dossierMedical.isNotEmpty &&
                                          (urgenceStatut == 'ambulance_affectee' ||
                                              urgenceStatut ==
                                                  'en_route_vers_victime' ||
                                              urgenceStatut ==
                                                  'arrivee_sur_place' ||
                                              urgenceStatut ==
                                                  'prise_en_charge' ||
                                              urgenceStatut ==
                                                  'en_route_vers_base'))
                                      ? Column(
                                          children: [
                                            const SizedBox(height: 10),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.lightBlue.shade50,
                                                  foregroundColor:
                                                      Colors.blueAccent[700],
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DossierMedicalDetailPage(
                                                        dossierMedical:
                                                            dossierMedical,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                    Icons.medical_services),
                                                label: const Text(
                                                    'Voir Dossier Médical'),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink();

                              String? ambulanceIdAssigned;
                              Map<String, dynamic>?
                                  assignedAmbulanceDataInUrgence;
                              AmbulanceData? assignedAmbulance;
                              String? ambulanceDetailsString;

                              if (urgence['ambulances_assignees'] is List &&
                                  (urgence['ambulances_assignees'] as List)
                                      .isNotEmpty) {
                                assignedAmbulanceDataInUrgence =
                                    (urgence['ambulances_assignees'] as List)
                                            .first['ambulance']
                                        as Map<String, dynamic>?;
                                ambulanceIdAssigned =
                                    assignedAmbulanceDataInUrgence?['id']
                                        ?.toString();
                                print(
                                    'DEBUG Dashboard: Urgence ID $id a une ambulance assignée: ID $ambulanceIdAssigned');
                              } else {
                                print(
                                    'DEBUG Dashboard: Urgence ID $id n\'a pas d\'ambulance assignée dans les données brutes.');
                              }

                              print(
                                  'DEBUG Dashboard: Traitement urgence ID: $id, Statut: $urgenceStatut, Ambulance ID assignée (après parsing): $ambulanceIdAssigned');

                              if (ambulanceIdAssigned != null) {
                                try {
                                  assignedAmbulance =
                                      mapDataService.ambulances.firstWhere(
                                    (amb) {
                                      return amb.id.toString() ==
                                          ambulanceIdAssigned;
                                    },
                                  );
                                  print(
                                      'DEBUG Dashboard: Ambulance trouvée dans MapDataService: ID ${assignedAmbulance.id}, Nom: ${assignedAmbulance.nom}, Phase: ${assignedAmbulance.currentPhase}, Type: ${assignedAmbulance.type}');

                                  ambulanceDetailsString =
                                      '{"id":${assignedAmbulance.id},'
                                      '"lat":${assignedAmbulance.position.latitude},'
                                      '"lon":${assignedAmbulance.position.longitude},'
                                      '"type":"${assignedAmbulance.type ?? 'N/A'}",'
                                      '"nom_vehicule":"${assignedAmbulance.nom ?? 'N/A'}",'
                                      '"current_phase":"${assignedAmbulance.currentPhase ?? 'N/A'}"}';

                                  print(
                                      'DEBUG Dashboard: ambulanceDetailsString: $ambulanceDetailsString');
                                } catch (e) {
                                  print(
                                      'ERREUR Dashboard: Ambulance ID $ambulanceIdAssigned non trouvée dans la liste des ambulances du service. Erreur: $e');
                                  assignedAmbulance = null;
                                  ambulanceDetailsString = null;
                                }
                              } else {
                                print(
                                    'DEBUG Dashboard: Pas d\'ID d\'ambulance assignée pour urgence ID $id (après conditionnement).');
                                ambulanceDetailsString = null;
                              }

                              // Affiche la carte d'urgence
                              return Card(
                                elevation: 3,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Urgence Patient $patientId (ID: $id)',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[900])),
                                      const SizedBox(height: 12),
                                      // Afficher les détails structurés de l'urgence
                                      _buildInfoRow(
                                          'Nature de l\'urgence', natureUrgence,
                                          icon: Icons.warning_amber_outlined),
                                      if (nombreVictimes != null &&
                                          nombreVictimes.isNotEmpty)
                                        _buildInfoRow(
                                            'Nombre total de victimes',
                                            nombreVictimes),
                                      if (adultCount != null && adultCount > 0)
                                        _buildInfoRow(
                                            'Adultes', adultCount.toString()),
                                      if (childCount != null && childCount > 0)
                                        _buildInfoRow(
                                            'Enfants', childCount.toString()),
                                      if (infantCount != null &&
                                          infantCount > 0)
                                        _buildInfoRow('Nourrissons',
                                            infantCount.toString()),
                                      _buildInfoRow(
                                          'Âge approximatif', ageApproximatif),
                                      _buildInfoRow('Consciente', consciente,
                                          isCritical:
                                              consciente?.toLowerCase() ==
                                                  'non'),
                                      _buildInfoRow('Respire', respire,
                                          isCritical:
                                              respire?.toLowerCase() == 'non'),
                                      _buildInfoRow('Saignement important',
                                          saignementImportant,
                                          isCritical: saignementImportant
                                                  ?.toLowerCase() ==
                                              'oui'),

                                      if (notesAdditionnelles != null &&
                                          notesAdditionnelles.isNotEmpty &&
                                          (natureUrgence == null ||
                                              notesAdditionnelles
                                                      .toLowerCase() !=
                                                  natureUrgence.toLowerCase()))
                                        _buildInfoRow('Autres informations',
                                            notesAdditionnelles,
                                            icon: Icons.comment_outlined),
                                      const SizedBox(height: 8),
                                      if (adresseLisible != null &&
                                          adresseLisible.isNotEmpty)
                                        _buildInfoRow('Adresse', adresseLisible,
                                            icon: Icons.location_on_outlined),
                                      const SizedBox(height: 15),

                                      if (finalImageUrl != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8.0, bottom: 8.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              finalImageUrl,
                                              height: 160,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.9,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (ctx, child,
                                                      progress) =>
                                                  progress == null
                                                      ? child
                                                      : Container(
                                                          height: 180,
                                                          alignment:
                                                              Alignment.center,
                                                          child: CircularProgressIndicator(
                                                              value: progress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? progress
                                                                          .cumulativeBytesLoaded /
                                                                      progress
                                                                          .expectedTotalBytes!
                                                                  : null)),
                                              errorBuilder:
                                                  (ctx, error, stackTrace) {
                                                print(
                                                    'ERREUR Image.network URL "$finalImageUrl": $error');
                                                return Container(
                                                    height: 180,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 40,
                                                              color: Colors
                                                                  .grey[600]),
                                                          Text(
                                                              'Image non chargeable',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      700]))
                                                        ]));
                                              },
                                            ),
                                          ),
                                        ),

                                      actionButtonWidget,
                                      // Afficher les boutons ou le statut selon l'état de l'urgence
                                      if (urgenceStatut == 'en_attente')
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          foregroundColor:
                                                              Colors.white),
                                                  onPressed: () =>
                                                      accepterUrgence(id!),
                                                  icon: const Icon(Icons
                                                      .check_circle_outline),
                                                  label:
                                                      const Text('Accepter')),
                                              const SizedBox(width: 10),
                                              ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white),
                                                  onPressed: () =>
                                                      refuserUrgence(id!),
                                                  icon: const Icon(
                                                      Icons.cancel_outlined),
                                                  label: const Text('Refuser')),
                                            ]),
                                      // Afficher le statut si l'urgence n'est plus en attente
                                      if (urgenceStatut != 'en_attente')
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            ambulanceDetailsString !=
                                                    null // Si la chaîne JSON de l'ambulance a été construite avec succès
                                                ? 'Statut: $ambulanceDetailsString' // Affiche les détails JSON de l'ambulance
                                                : 'Statut: $urgenceStatut', // Sinon, revient à l'affichage du statut de l'urgence
                                            style: TextStyle(
                                              color: ambulanceDetailsString !=
                                                      null // Si détails ambulance, couleur spécifique
                                                  ? Colors.blue[700]
                                                  : urgenceStatut == 'terminee'
                                                      ? Colors.grey[
                                                          600] // Sinon, couleurs basées sur le statut de l'urgence
                                                      : urgenceStatut ==
                                                              'refusee'
                                                          ? Colors.redAccent
                                                          : Colors.blue[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 20),
            Text('Carte des Ambulances ',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Mini-carte
            SizedBox(
              height: 300, // Hauteur fixe pour la mini-carte
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Stack(
                    children: [
                      // Indicateur de chargement pour la carte
                      if (mapDataService.isLoadingAmbulances ||
                          mapDataService.isLoadingUrgences)
                        const Center(child: CircularProgressIndicator()),

                      // Afficher la carte si pas en chargement ou si des données sont déjà là
                      if (!mapDataService.isLoadingAmbulances ||
                          mapDataService.ambulances
                              .isNotEmpty) // Afficher même si urgences chargent

                        // DÉBUT DE LA MODIFICATION IMPORTANTE ICI
                        Consumer<MapDataService>(
                          builder: (context, mapDataService, _) {
                            print(
                                "🗺️ Mini-carte reconstruite avec ${mapDataService.ambulances.length} ambulances.");
                            return FlutterMap(
                              mapController:
                                  _mapController, // Le contrôleur de la mini-carte
                              options: MapOptions(
                                initialCenter: mapDataService.lastKnownCenter ??
                                    const LatLng(37.4225,
                                        -122.0841), // Nouakchott par défaut
                                initialZoom: mapDataService.lastKnownZoom ??
                                    6.0, // Zoom par défaut
                                onMapReady: () {
                                  print(
                                      "DEBUG FlutterMap onMapReady (Dashboard): Carte prête.");
                                  if (mounted) {
                                    setState(() {
                                      _isDashboardMapReady = true;
                                    });
                                    // Centrer la mini-carte aux marqueurs quand elle est prête
                                    _fitMapToMarkers();
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.pfe', // Utilisez un nom unique
                                ),
                                MarkerLayer(
                                  markers: [
                                    // Markers pour les ambulances (utilisent les données du service mises à jour par WS)
                                    ...mapDataService.ambulances
                                        .where((ambulance) =>
                                            ambulance.position.latitude.isFinite &&
                                            ambulance
                                                .position.longitude.isFinite &&
                                            ambulance.position.latitude >=
                                                -90 &&
                                            ambulance.position.latitude <= 90 &&
                                            ambulance.position.longitude >=
                                                -180 &&
                                            ambulance.position.longitude <= 180)
                                        .map((ambulance) {
                                      final type =
                                          ambulance.type?.toUpperCase() ??
                                              'DEFAULT';
                                      final color = mapDataService
                                              .ambulanceTypeColors[type] ??
                                          mapDataService
                                              .ambulanceTypeColors['DEFAULT']!;
                                      final icon = mapDataService
                                              .ambulanceTypeIcons[type] ??
                                          mapDataService
                                              .ambulanceTypeIcons['DEFAULT']!;
                                      return Marker(
                                        width: 80.0,
                                        height:
                                            60.0, // Taille ajustée pour la mini-carte
                                        point: ambulance.position,
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(icon,
                                                  color: color,
                                                  size: 30.0,
                                                  shadows: const [
                                                    Shadow(
                                                        color: Colors.black38,
                                                        blurRadius: 3.0,
                                                        offset: Offset(1, 1))
                                                  ]),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 4,
                                                    vertical:
                                                        1), // Padding ajusté
                                                decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.85),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 2.0,
                                                          offset: Offset(0, 1))
                                                    ]),
                                                child: Text(
                                                  ambulance.nom ??
                                                      "ID:${ambulance.id}",
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight
                                                          .bold), // Taille de texte ajustée
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ]),
                                      );
                                    }),
                                    // Markers pour les urgences (utilisent les données du service fetchées)
                                    ...mapDataService.urgences.where((u) {
                                      final lat = u['latitude'];
                                      final lon = u['longitude'];
                                      return lat is num &&
                                          lon is num &&
                                          lat.isFinite &&
                                          lon.isFinite &&
                                          lat >= -90 &&
                                          lat <= 90 &&
                                          lon >= -180 &&
                                          lon <= 180;
                                    }).map((u) {
                                      final lat = u['latitude'] as num;
                                      final lon = u['longitude'] as num;
                                      // Optionnel: Adapter l'icône/couleur selon le statut
                                      IconData urgenceIcon = Icons.location_pin;
                                      Color urgenceColor = Colors.redAccent;
                                      // ... logique de couleur/icône selon statut ...
                                      return Marker(
                                        width: 30, height: 30, // Taille ajustée
                                        point: LatLng(
                                            lat.toDouble(), lon.toDouble()),
                                        child: Icon(urgenceIcon,
                                            color: urgenceColor,
                                            size: 28,
                                            shadows: const [
                                              Shadow(
                                                  color: Colors.black38,
                                                  blurRadius: 3.0,
                                                  offset: Offset(1, 1))
                                            ]), // Taille ajustée
                                      );
                                    }),
                                  ],
                                )
                              ],
                            );
                          },
                        ),
                      // FIN DE LA MODIFICATION IMPORTANTE ICI

                      // Indicateur de connexion WebSocket pour la mini-carte aussi
                      if (!mapDataService.isWebSocketConnected)
                        const Positioned(
                          top: 8.0,
                          left: 8.0,
                          child: Chip(
                            backgroundColor: Colors.orangeAccent,
                            label: Text('WS: Déconnecté',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10)), // Taille ajustée
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity:
                                VisualDensity.compact, // Densité ajustée
                          ),
                        ),
                      if (mapDataService.isWebSocketConnected)
                        const Positioned(
                          top: 8.0,
                          left: 8.0,
                          child: Chip(
                            backgroundColor: Colors.greenAccent,
                            label: Text('WS: Connecté',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10)), // Taille ajustée
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity:
                                VisualDensity.compact, // Densité ajustée
                          ),
                        ),
                      // Bouton pour agrandir la carte (naviguer vers FullScreenMapPage)
                      // *** CE WIDGET A ÉTÉ DÉPLACÉ À LA FIN DE LA LISTE POUR ÊTRE CLICABLE ***
                      Positioned(
                        bottom: 8.0, // Position ajustée
                        right: 8.0, // Position ajustée
                        child: FloatingActionButton.small(
                          heroTag:
                              "expandMapDashboard", // Assurez-vous que ce heroTag est unique sur toute l'app
                          onPressed: () {
                            print(
                                "FloatingActionButton clicked!"); // Laissez ce print temporairement pour vérifier
                            if (mounted) {
                              final service = Provider.of<MapDataService>(
                                  context,
                                  listen: false);
                              // Utiliser la position actuelle de la mini-carte comme point de départ pour la carte principale
                              final LatLng currentCenter =
                                  _mapController.camera.center;
                              final double currentZoom =
                                  _mapController.camera.zoom;

                              print(
                                  "Dashboard FAB: Demande de navigation vers l'onglet carte principale avec Centre: $currentCenter, Zoom: $currentZoom");

                              // Dire à votre service de se préparer pour afficher le bon onglet et la bonne vue carte.
                              const int mapTabIndex =
                                  0; // Adaptez à l'index de l'onglet carte dans votre MainNavigationScaffold
                              service.navigateToMainTabWithMapArgs(
                                  mapTabIndex, currentCenter, currentZoom);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const MainNavigationScaffold()),
                              );
                              // La navigation vers l'onglet est gérée par MainNavigationScaffold
                              // via le changement dans le service. PAS besoin de Navigator.push ici.
                            }
                          },
                          backgroundColor:
                              Colors.white70, // Icône et taille ajustées
                          tooltip:
                              "Afficher la carte en plein écran", // Couleur ajustée
                          child: Icon(Icons.fullscreen,
                              color: Colors.grey.shade800,
                              size: 28), // Ajout d'un tooltip
                        ),
                      ),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
