// lib/carte_patient_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:pfe/services/map_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CartePatientPage extends StatefulWidget {
  final int? activeUrgenceId;
  final double? activeUrgenceLatitude;
  final double? activeUrgenceLongitude;
  final String? activeInitialStatut;
  final String? activeAmbulanceContactNumber;

  const CartePatientPage({
    super.key,
    this.activeUrgenceId,
    this.activeUrgenceLatitude,
    this.activeUrgenceLongitude,
    this.activeInitialStatut,
    this.activeAmbulanceContactNumber,
  });

  @override
  State<CartePatientPage> createState() => _CartePatientPageState();
}

class _CartePatientPageState extends State<CartePatientPage> {
  static const LatLng _initialCenter = LatLng(18.0790, -15.9650);
  static const double _initialZoom = 6.0;

  final MapController _mapController = MapController();

  int? _activeUrgenceId;
  LatLng? _activePatientPosition;
  String _activeAmbulanceStatus =
      'En attente des informations de l\'ambulance...';
  String? _activeAmbulanceContactNumber;
  List<Map<String, dynamic>> _activeDisplayAmbulances = [];

  bool _hasShownActiveArrivalDialog = false;
  bool _hasShownActivePriseEnChargeEndedDialog = false;

  WebSocketChannel? _activeChannel;
  StreamSubscription? _activeWebsocketSubscription;
  Timer? _activeReconnectTimer;

  bool _showNoActiveUrgenceOverlay =
      true; // Default to true, set to false when active urgency found
  int? _loggedInPatientId;

  @override
  void initState() {
    super.initState();
    _loadPatientInfoAndCheckActiveUrgence();
    _getPatientLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _activeWebsocketSubscription?.cancel();
    _activeChannel?.sink.close();
    _activeReconnectTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPatientInfoAndCheckActiveUrgence() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedInPatientId = prefs.getInt('loggedInPatientId');

    final storedUrgenceId = prefs.getInt('currentUrgenceId');
    final storedStatut = prefs.getString('currentUrgenceStatut');
    final storedUrgencePatientId = prefs.getInt('currentUrgencePatientId');
    final storedUrgenceLatitude = prefs.getDouble('currentUrgenceLatitude');
    final storedUrgenceLongitude = prefs.getDouble('currentUrgenceLongitude');
    final storedAmbulanceContactNumber =
        prefs.getString('currentAmbulanceContactNumber');

    bool activeUrgenceFound = false;

    if (widget.activeUrgenceId != null) {
      setState(() {
        _activeUrgenceId = widget.activeUrgenceId;
        _activePatientPosition = (widget.activeUrgenceLatitude != null &&
                widget.activeUrgenceLongitude != null)
            ? LatLng(
                widget.activeUrgenceLatitude!, widget.activeUrgenceLongitude!)
            : null;
        _activeAmbulanceStatus =
            _translateStatus(widget.activeInitialStatut ?? 'en_attente');
        _activeAmbulanceContactNumber = widget.activeAmbulanceContactNumber;
        // _showNoActiveUrgenceOverlay = false; // This will be set below
      });
      activeUrgenceFound = true;
      print(
          "DEBUG CartePatientPage: Arguments reçus via widget: ID ${_activeUrgenceId}, Statut: $_activeAmbulanceStatus");
    } else if (storedUrgenceId != null &&
        storedStatut != null &&
        storedUrgencePatientId == _loggedInPatientId) {
      // Check for statuses that indicate an ongoing urgency
      if ([
        'en_attente',
        'acceptee',
        'ambulance_affectee',
        'en_route_vers_victime',
        'arrivee_sur_place',
        'prise_en_charge',
        'en_route_vers_base'
      ].contains(storedStatut)) {
        setState(() {
          _activeUrgenceId = storedUrgenceId;
          _activePatientPosition =
              (storedUrgenceLatitude != null && storedUrgenceLongitude != null)
                  ? LatLng(storedUrgenceLatitude, storedUrgenceLongitude)
                  : null;
          _activeAmbulanceStatus = _translateStatus(storedStatut);
          _activeAmbulanceContactNumber = storedAmbulanceContactNumber;
          // _showNoActiveUrgenceOverlay = false; // This will be set below
        });
        activeUrgenceFound = true;
        print(
            "DEBUG CartePatientPage: Urgence chargée depuis prefs: ID ${_activeUrgenceId}, Statut: $_activeAmbulanceStatus");
      } else {
        _clearUrgenceStatusFromPrefs();
        print(
            "DEBUG CartePatientPage: Statut urgence stocké est final, effacement.");
      }
    }

    if (mounted) {
      setState(() {
        _showNoActiveUrgenceOverlay = !activeUrgenceFound;
      });
    }

    if (activeUrgenceFound) {
      _connectActiveUrgenceWebSocket();
      _fitMapToMarkers();
    } else {
      print(
          "DEBUG CartePatientPage: Aucune urgence active à charger. Affichage de l'overlay.");
    }

    // Always fetch all ambulances and urgencies for the background map if no active urgency
    Provider.of<MapDataService>(context, listen: false)
        .fetchAmbulancePositions();
    Provider.of<MapDataService>(context, listen: false).fetchUrgences();
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente d\'affectation';
      case 'acceptee':
        return 'Acceptée, l\'ambulance se prépare';
      case 'ambulance_affectee':
        return 'Ambulance affectée';
      case 'en_route_vers_victime':
        return 'En route vers vous';
      case 'arrivee_sur_place':
        return 'Arrivée sur place';
      case 'prise_en_charge':
        return 'Prise en charge';
      case 'en_route_vers_base':
        return 'Prise en charge'; // Patient should still see it as "en charge"
      case 'terminee':
        return 'Urgence Terminée';
      case 'refusee':
        return 'Urgence refusée';
      case 'annulee_patient':
        return 'Urgence annulée par vous';
      default:
        return status;
    }
  }

  Future<void> _getPatientLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Localisation désactivée. Veuillez l'activer.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permission de localisation refusée.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            'Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        if (position.latitude.isFinite && position.longitude.isFinite) {
          if (_activePatientPosition == null) {
            setState(() {
              _activePatientPosition =
                  LatLng(position.latitude, position.longitude);
            });
            _fitMapToMarkers();
          }
          print(
              "DEBUG Patient: Position actuelle du patient récupérée: ${_activePatientPosition}");
        }
      }
    } catch (e) {
      print(
          "DEBUG Erreur lors de la récupération de la position du patient: $e");
    }
  }

  void _connectActiveUrgenceWebSocket() {
    _activeReconnectTimer?.cancel();
    _activeReconnectTimer = null;
    try {
      _activeChannel = WebSocketChannel.connect(
          Uri.parse('ws://192.168.1.122:8000/ws/map_updates/'));
      print(
          'DEBUG Patient [CartePatientPage]: Tentative de connexion WebSocket pour urgence active à ws://192.168.1.122:8000/ws/map_updates/');

      _activeWebsocketSubscription = _activeChannel!.stream.listen(
        (message) {
          print(
              'DEBUG Patient [CartePatientPage] WebSocket raw message received: $message');
          try {
            final data = json.decode(message) as Map<String, dynamic>;
            final String? messageType = data['type'] as String?;

            if (messageType == 'multi_position_update') {
              print(
                  'DEBUG NOUVELLE LOGIQUE ACTIVE: multi_position_update détecté.');
              final int? messageUrgenceId = data['urgence_id'] as int?;
              final List<dynamic>? ambulances =
                  data['ambulances'] as List<dynamic>?;

              print(
                  'DEBUG CartePatientPage WS: Top-level messageUrgenceId: $messageUrgenceId, _activeUrgenceId: $_activeUrgenceId');

              // Only process this multi_position_update if it's for the currently active urgency
              if (ambulances != null && messageUrgenceId == _activeUrgenceId) {
                List<Map<String, dynamic>> updatedAmbulances = [];
                for (var amb in ambulances) {
                  String? currentPhase = amb['current_phase'] as String?;

                  print(
                      'DEBUG CartePatientPage WS: Processing ambulance ID: ${amb['id']}, Phase: $currentPhase');

                  // Filter ambulances based on their phase for the patient's view
                  // Only show ambulances en route to the victim.
                  // If "en_route_vers_base" means they have already handled the victim and are leaving,
                  // then they should no longer be displayed as "active" for this patient.
                  if (currentPhase == 'en_route_vers_victime' ||
                      currentPhase == 'arrivee_sur_place' ||
                      currentPhase == 'prise_en_charge') {
                    double? lat = (amb['lat'] as num?)?.toDouble();
                    double? lon = (amb['lon'] as num?)?.toDouble();
                    String? nomVehicule = amb['nom_vehicule'] as String?;
                    String? numeroTelephone =
                        amb['numero_telephone'] as String?;

                    if (lat != null &&
                        lon != null &&
                        lat.isFinite &&
                        lon.isFinite) {
                      updatedAmbulances.add({
                        'id': amb['id'],
                        'lat': lat,
                        'lon': lon,
                        'nom_vehicule': nomVehicule,
                        'current_phase': currentPhase,
                        'numero_telephone': numeroTelephone,
                      });
                      print(
                          'DEBUG CartePatientPage WS: Ambulance ${amb['id']} (${nomVehicule}) ajoutée à updatedAmbulances. Phase: $currentPhase');
                      // Update overall status if this is the first assigned ambulance or main one
                      if (mounted) {
                        setState(() {
                          _activeAmbulanceStatus =
                              _translateStatus(currentPhase!);
                          _activeAmbulanceContactNumber =
                              numeroTelephone; // Use the first assigned ambulance's number as primary
                        });
                      }
                    }
                  } else {
                    print(
                        'DEBUG CartePatientPage WS: Ambulance ${amb['id']} (${amb['nom_vehicule']}) filtrée par phase: $currentPhase (pas pertinent pour le patient à ce stade)');
                  }
                }
                if (mounted) {
                  setState(() {
                    _activeDisplayAmbulances = updatedAmbulances;
                    // Ensure overlay is hidden if ambulances are being displayed
                    _showNoActiveUrgenceOverlay =
                        _activeDisplayAmbulances.isEmpty;
                  });
                  print(
                      'DEBUG CartePatientPage WS: _activeDisplayAmbulances mis à jour. Nombre d\'ambulances affichées : ${_activeDisplayAmbulances.length}');
                  if (_activeDisplayAmbulances.isNotEmpty) {
                    _fitMapToMarkers();
                  }
                }
              } else {
                if (ambulances == null) {
                  print(
                      'DEBUG CartePatientPage WS: La liste des ambulances est nulle dans multi_position_update.');
                }
                if (messageUrgenceId != _activeUrgenceId) {
                  print(
                      'DEBUG CartePatientPage WS: Urgence ID du message ($messageUrgenceId) ne correspond pas à l\'Urgence ID active ($_activeUrgenceId).');
                }
              }
            } else if (messageType == 'urgence_update') {
              final int? urgenceId = data['id'] as int?;
              print(
                  'DEBUG CartePatientPage WS: Message urgence_update - Urgence ID (du WS): $urgenceId, Statut: ${data['statut']}, _activeUrgenceId local: $_activeUrgenceId');
              if (urgenceId == _activeUrgenceId) {
                final String? statut = data['statut'] as String?;
                if (statut != null) {
                  if (mounted) {
                    setState(() {
                      _activeAmbulanceStatus = _translateStatus(statut);
                    });
                  }
                  _saveUrgenceStatusToPrefs(
                      _activeUrgenceId!, statut, _loggedInPatientId!,
                      latitude: _activePatientPosition?.latitude,
                      longitude: _activePatientPosition?.longitude,
                      ambulanceContactNumber: _activeAmbulanceContactNumber);

                  if (statut == 'terminee' ||
                      statut == 'annulee_patient' ||
                      statut == 'refusee') {
                    if (!_hasShownActivePriseEnChargeEndedDialog) {
                      _showActiveUrgenceEndedDialog();
                      _hasShownActivePriseEnChargeEndedDialog = true;
                      _clearUrgenceStatusFromPrefs();
                      if (mounted) {
                        setState(() {
                          _activeUrgenceId = null;
                          _activeDisplayAmbulances =
                              []; // Clear ambulances on map
                          _showNoActiveUrgenceOverlay =
                              true; // Show no active urgency overlay
                        });
                      }
                    }
                  } else if (statut == 'arrivee_sur_place' &&
                      !_hasShownActiveArrivalDialog) {
                    _showActiveArrivalDialog();
                    _hasShownActiveArrivalDialog = true;
                  }
                }
              }
            }
          } catch (e) {
            print(
                'DEBUG Patient [CartePatientPage] WebSocket message parsing error: $e');
          }
        },
        onError: (error) {
          print('DEBUG Patient [CartePatientPage] WebSocket Error: $error');
          if (mounted) {
            setState(() {
              _activeAmbulanceStatus =
                  'Erreur de connexion WebSocket. Tentative de reconnexion...';
            });
          }
          _activeReconnectTimer?.cancel();
          _activeReconnectTimer = Timer(const Duration(seconds: 5),
              () => _connectActiveUrgenceWebSocket());
        },
        onDone: () {
          print('DEBUG Patient [CartePatientPage] WebSocket Closed.');
          if (mounted) {
            setState(() {
              _activeAmbulanceStatus =
                  'Connexion WebSocket fermée. Tentative de reconnexion...';
            });
          }
          _activeReconnectTimer?.cancel();
          _activeReconnectTimer = Timer(const Duration(seconds: 5),
              () => _connectActiveUrgenceWebSocket());
        },
      );
    } catch (e) {
      print('DEBUG Patient [CartePatientPage] WebSocket connection failed: $e');
      if (mounted) {
        setState(() {
          _activeAmbulanceStatus = 'Échec de la connexion WebSocket initiale.';
        });
      }
      _activeReconnectTimer?.cancel();
      _activeReconnectTimer = Timer(
          const Duration(seconds: 5), () => _connectActiveUrgenceWebSocket());
    }
  }

  void _fitMapToMarkers() {
    List<LatLng> points = [];
    if (_activePatientPosition != null) {
      points.add(_activePatientPosition!);
    }
    for (var amb in _activeDisplayAmbulances) {
      points.add(LatLng(amb['lat'], amb['lon']));
    }

    if (points.isEmpty) {
      _mapController.move(_initialCenter, _initialZoom);
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 15.0);
    } else {
      var bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(90.0),
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Impossible de lancer l\'appel à $phoneNumber')),
        );
      }
    }
  }

  void _showActiveArrivalDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Ambulance Arrivée !'),
            content: const Text('Votre ambulance est arrivée sur place.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showActiveUrgenceEndedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Urgence terminée !'),
            content: const Text(
                'La prise en charge est terminée. Vous pouvez maintenant fermer cette page.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _saveUrgenceStatusToPrefs(int id, String statut, int patientDbId,
      {double? latitude,
      double? longitude,
      String? ambulanceContactNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentUrgenceId', id);
    await prefs.setString('currentUrgenceStatut', statut);
    await prefs.setInt('currentUrgencePatientId', patientDbId);
    if (latitude != null && latitude.isFinite) {
      await prefs.setDouble('currentUrgenceLatitude', latitude);
    } else {
      await prefs.remove('currentUrgenceLatitude');
    }
    if (longitude != null && longitude.isFinite) {
      await prefs.setDouble('currentUrgenceLongitude', longitude);
    } else {
      await prefs.remove('currentUrgenceLongitude');
    }
    if (ambulanceContactNumber != null) {
      await prefs.setString(
          'currentAmbulanceContactNumber', ambulanceContactNumber);
    } else {
      await prefs.remove('currentAmbulanceContactNumber');
    }
    print(
        "DEBUG Statut urgence ID $id sauvegardé pour patient $patientDbId: $statut (Lat: $latitude, Lon: $longitude, Tel: $ambulanceContactNumber)");
  }

  Future<void> _clearUrgenceStatusFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUrgenceId');
    await prefs.remove('currentUrgenceStatut');
    await prefs.remove('currentUrgencePatientId');
    await prefs.remove('currentUrgenceLatitude');
    await prefs.remove('currentUrgenceLongitude');
    await prefs.remove('currentAmbulanceContactNumber');
    print("DEBUG Statut urgence effacé des SharedPreferences.");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carte des Urgences'),
          backgroundColor: Colors.redAccent,
        ),
        body: Consumer<MapDataService>(
          builder: (context, mapDataService, child) {
            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _activePatientPosition ?? _initialCenter,
                    initialZoom: _activeUrgenceId != null ? 14.0 : _initialZoom,
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    onMapReady: () {
                      _fitMapToMarkers();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.pfe',
                    ),
                    if (_activePatientPosition != null &&
                        _activePatientPosition!.latitude.isFinite &&
                        _activePatientPosition!.longitude.isFinite)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _activePatientPosition!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on,
                                color: Colors.blue, size: 40),
                          ),
                        ],
                      ),
                    // Condition pour afficher UNIQUEMENT les ambulances assignées à l'urgence active
                    if (_activeUrgenceId != null &&
                        _activeDisplayAmbulances.isNotEmpty)
                      MarkerLayer(
                        markers: _activeDisplayAmbulances.map((amb) {
                          final LatLng ambLatLng =
                              LatLng(amb['lat'], amb['lon']);
                          final String ambName =
                              amb['nom_vehicule'] ?? 'Ambulance';
                          final String ambPhase =
                              amb['current_phase'] ?? 'inconnu';
                          final String translatedPhase =
                              _translateStatus(ambPhase);
                          final String? ambPhoneNumber =
                              amb['numero_telephone'];

                          return Marker(
                            point: ambLatLng,
                            width: 120, // Ajuster la largeur pour le texte
                            height: 120, // Ajuster la hauteur pour le texte
                            child: GestureDetector(
                              onTap: () {
                                if (ambPhoneNumber != null &&
                                    ambPhoneNumber.isNotEmpty) {
                                  _makePhoneCall(ambPhoneNumber);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Numéro de téléphone non disponible pour cette ambulance')),
                                  );
                                }
                              },
                              child: Column(
                                children: [
                                  const Icon(FontAwesomeIcons.truckMedical,
                                      color: Colors.red, size: 40),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '$ambName\n($translatedPhase)',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    // Condition pour afficher TOUTES les ambulances quand il n'y a PAS d'urgence active
                    else if (_activeUrgenceId == null)
                      MarkerLayer(
                        markers: mapDataService.ambulances
                            .where((amb) =>
                                amb.position != null &&
                                amb.position!.latitude.isFinite &&
                                amb.position!.longitude.isFinite)
                            .map((amb) => Marker(
                                  point: LatLng(amb.position!.latitude,
                                      amb.position!.longitude),
                                  width: 80,
                                  height: 80,
                                  child: Column(
                                    children: [
                                      const Icon(FontAwesomeIcons.truckMedical,
                                          color: Colors.grey, size: 30),
                                      Text(amb.nom ?? 'Ambulance',
                                          style: const TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),

                // Overlay pour "Pas d'urgence active"
                if (_showNoActiveUrgenceOverlay)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Pas d\'urgence active pour le moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else // Ceci est le panneau d'information de l'urgence active
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Urgence acceptée',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Statut : $_activeAmbulanceStatus',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.blueGrey),
                            ),
                            if (_activeAmbulanceContactNumber != null &&
                                _activeAmbulanceContactNumber!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => _makePhoneCall(
                                      _activeAmbulanceContactNumber!),
                                  icon: const Icon(Icons.phone,
                                      color: Colors.white),
                                  label: Text(
                                      'Appeler l\'ambulance (${_activeAmbulanceContactNumber!})',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Loading indicator
                if (mapDataService.isLoadingAmbulances ||
                    mapDataService.isLoadingUrgences)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
