// lib/services/map_data_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/ambulance_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'websocket_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapNavigationArguments {
  final LatLng center;
  final double zoom;
  MapNavigationArguments({required this.center, required this.zoom});
}

class MapDataService with ChangeNotifier {
  List<AmbulanceData> _ambulances = [];
  List<dynamic> _urgences = [];
  List<dynamic> _historiqueUrgences = [];
  bool _isLoadingHistorique = false;

  Map<String, dynamic>? _patientActiveUrgence;
  Map<String, dynamic>? get patientActiveUrgence => _patientActiveUrgence;

  final String _apiBaseUrl = 'http://192.168.1.122:8000/api';
  String get apiBaseUrl => _apiBaseUrl;

  final String _wsBaseUrl = 'ws://192.168.1.122:8000';

  List<AmbulanceData> get ambulances => _ambulances;
  List<dynamic> get urgences => _urgences;
  List<dynamic> get historiqueUrgences => _historiqueUrgences;
  bool get isLoadingHistorique => _isLoadingHistorique;

  bool _isLoadingAmbulances = false;
  bool get isLoadingAmbulances => _isLoadingAmbulances;
  bool _isLoadingUrgences = false;
  bool get isLoadingUrgences => _isLoadingUrgences;

  final Map<String, Color> ambulanceTypeColors = {
    'Type A': Colors.blue,
    'Type B': Colors.green,
    'Type C': Colors.red,
    'DEFAULT': Colors.red,
  };
  final Map<String, IconData> ambulanceTypeIcons = {
    'Type A': FontAwesomeIcons.truckMedical,
    'Type B': FontAwesomeIcons.truckMedical,
    'Type C': FontAwesomeIcons.truckMedical,
    'DEFAULT': FontAwesomeIcons.truckMedical,
  };

  final Set<int> ambulancesAttendues = {};
  final Map<int, LatLng> positionsBuffer = {};

  LatLng? lastKnownCenter;
  double? lastKnownZoom;

  int _currentMainScrenTabIndex = 0;
  int get currentMainScrenTabIndex => _currentMainScrenTabIndex;
  MapNavigationArguments? _pendingMapArgs;
  MapNavigationArguments? get pendingMapArgs => _pendingMapArgs;

  WebSocketChannel? _channel;
  StreamSubscription? _websocketSubscription;
  bool _isWebSocketConnected = false;
  bool get isWebSocketConnected => _isWebSocketConnected;
  Timer? _websocketReconnectTimer;

  static const List<String> _statutsTermines = ['terminee', 'refusee'];
  static const List<String> _statutsActifs = [
    'en_attente',
    'acceptee',
    'ambulance_affectee',
    'en_route_vers_victime',
    'arrivee_sur_place',
    'prise_en_charge',
    'en_route_vers_base'
  ];

  MapDataService() {
    print("MapDataService instance created. Connecting to WebSocket...");
    connectWebSocket();
    fetchAmbulancePositions();
    fetchUrgences();
    fetchHistoriqueUrgences();
  }

  void connectWebSocket() {
    if (_channel != null && _isWebSocketConnected) {
      print("WebSocket: Déjà connecté.");
      return;
    }
    _websocketReconnectTimer?.cancel();
    _websocketReconnectTimer = null;

    try {
      final uri = Uri.parse('$_wsBaseUrl/ws/map_updates/');
      print("WebSocket: Tentative de connexion à $uri");

      _channel = connectPlatformWebSocket(uri);

      _websocketSubscription = _channel!.stream.listen(
        (message) {
          processWebSocketMessage(message);
        },
        onError: (error) {
          print("WebSocket Error: $error");
          _isWebSocketConnected = false;
          disconnectWebSocket();
          _websocketReconnectTimer =
              Timer(const Duration(seconds: 5), () => connectWebSocket());
          notifyListeners();
        },
        onDone: () {
          print("WebSocket Done. Connection closed.");
          _isWebSocketConnected = false;
          disconnectWebSocket();
          _websocketReconnectTimer =
              Timer(const Duration(seconds: 5), () => connectWebSocket());
          notifyListeners();
        },
      );

      _channel!.ready.then((_) {
        _isWebSocketConnected = true;
        print("WebSocket: Connexion établie !");
        notifyListeners();
      }).catchError((e) {
        print("WebSocket: Échec de l'établissement de la connexion: $e");
        _isWebSocketConnected = false;
        notifyListeners();
        disconnectWebSocket();
        _websocketReconnectTimer =
            Timer(const Duration(seconds: 5), () => connectWebSocket());
      });
    } catch (e) {
      print("WebSocket Exception: $e");
      _isWebSocketConnected = false;
      notifyListeners();
      _websocketReconnectTimer =
          Timer(const Duration(seconds: 5), () => connectWebSocket());
    }
  }

  void disconnectWebSocket() {
    if (_channel == null) {
      print("WebSocket: Déjà déconnecté.");
      return;
    }
    print("WebSocket: Déconnexion...");
    _websocketSubscription?.cancel();
    _channel?.sink.close(1000, 'Client disconnect');
    _channel = null;
    _isWebSocketConnected = false;
    _websocketReconnectTimer?.cancel();
    _websocketReconnectTimer = null;
    notifyListeners();
    print("WebSocket: Déconnecté.");
  }

  void processWebSocketMessage(dynamic message) {
    print("WebSocket raw message received: $message");
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      print('🧠 WebSocket data décodé: ${jsonEncode(data)}');

      final String? messageType = data['type'] as String?;

      if (messageType == 'multi_position_update') {
        final List<dynamic>? ambs = data['ambulances'] as List<dynamic>?;
        if (ambs != null) {
          for (var amb in ambs) {
            int? ambId = amb['id'] is int
                ? amb['id'] as int
                : int.tryParse(amb['id'].toString());
            double? lat = (amb['lat'] as num?)?.toDouble();
            double? lon = (amb['lon'] as num?)?.toDouble();

            if (ambId != null &&
                lat != null &&
                lon != null &&
                lat.isFinite &&
                lon.isFinite) {
              int index = _ambulances.indexWhere((a) => a.id == ambId);
              if (index != -1) {
                _ambulances[index] = _ambulances[index].copyWith(
                  position: LatLng(lat, lon),
                  type: amb['type'] as String?,
                  nom: amb['nom_vehicule']
                      as String?, // CHANGEMENT ICI: Utilise 'nom_vehicule'
                  currentPhase: amb['current_phase'] as String?,
                );
              } else {
                print(
                    "WebSocket: Nouvelle ambulance détectée via multi_position_update: ID $ambId. Ajout minimal.");
                _ambulances.add(AmbulanceData(
                  id: ambId,
                  position: LatLng(lat, lon),
                  nom: amb['nom_vehicule'] as String? ??
                      'AMBU-$ambId', // CHANGEMENT ICI: Utilise 'nom_vehicule'
                  type: amb['type'] as String? ?? 'DEFAULT',
                  currentPhase: amb['current_phase'] as String?,
                ));
              }
            }
          }
          final int? urgenceIdFromMultiPos = data['urgence_id']
              as int?; // CHANGEMENT ICI: Utilise 'urgence_id'
          if (urgenceIdFromMultiPos != null) {
            _handleUrgenceDataMerge(urgenceIdFromMultiPos, data);
          }
          notifyListeners();
        }
        return;
      }

      if (messageType == 'urgence_update') {
        int? urgenceId = data['id'] as int?;
        if (urgenceId == null) {
          print("WebSocket: urgence_update message sans 'id'. Ignoré.");
          return;
        }

        _handleUrgenceDataMerge(urgenceId, data);
        notifyListeners();
      }
    } catch (e) {
      print("WebSocket Error processing message: $e. Message was: $message");
    }
  }

  void _handleUrgenceDataMerge(int urgenceId, Map<String, dynamic> newData) {
    int activeUrgenceIndex = _urgences.indexWhere((u) => u['id'] == urgenceId);
    int historiqueUrgenceIndex =
        _historiqueUrgences.indexWhere((u) => u['id'] == urgenceId);

    String? newStatut = newData['statut'] as String?;
    if (newStatut == null && activeUrgenceIndex != -1) {
      newStatut = _urgences[activeUrgenceIndex]['statut'] as String?;
    } else if (newStatut == null && historiqueUrgenceIndex != -1) {
      newStatut =
          _historiqueUrgences[historiqueUrgenceIndex]['statut'] as String?;
    }

    if (activeUrgenceIndex != -1) {
      (_urgences[activeUrgenceIndex] as Map<String, dynamic>).addAll(newData);
      print(
          "WebSocket: Urgence ID $urgenceId mise à jour dans la liste active (fusion). Statut: ${_urgences[activeUrgenceIndex]['statut']}");
    } else {
      if (newStatut != null && !_statutsTermines.contains(newStatut)) {
        _urgences.add(newData);
        print(
            "WebSocket: Nouvelle urgence ID $urgenceId ajoutée à la liste active. Statut: $newStatut");
      }
    }

    if (newStatut != null && _statutsTermines.contains(newStatut)) {
      if (activeUrgenceIndex != -1) {
        _urgences.removeAt(activeUrgenceIndex);
        print(
            "WebSocket: Urgence ID $urgenceId retirée de la liste active (statut terminé/refusé).");
      }
      if (historiqueUrgenceIndex != -1) {
        (_historiqueUrgences[historiqueUrgenceIndex] as Map<String, dynamic>)
            .addAll(newData);
        print(
            "WebSocket: Urgence ID $urgenceId mise à jour dans l'historique (fusion). Statut: $newStatut");
      } else {
        _historiqueUrgences.add(newData);
        print(
            "WebSocket: Urgence ID $urgenceId ajoutée à l'historique. Statut: $newStatut");
      }
    }

    if (_patientActiveUrgence != null &&
        _patientActiveUrgence!['id'] == urgenceId) {
      _patientActiveUrgence!.addAll(newData);
      if (newStatut != null && _statutsTermines.contains(newStatut)) {
        _patientActiveUrgence = null;
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('currentUrgenceId');
        });
        print(
            "✅ _patientActiveUrgence mis à null car urgence ID $urgenceId terminée.");
      }
    }

    if (newData.containsKey('ambulance_id') &&
        newData.containsKey('latitude') &&
        newData.containsKey('longitude')) {
      int? ambId = newData['ambulance_id'] is int
          ? newData['ambulance_id'] as int
          : int.tryParse(newData['ambulance_id'].toString());
      double? lat = (newData['latitude'] as num?)?.toDouble();
      double? lon = (newData['longitude'] as num?)?.toDouble();
      String? ambType = newData['ambulance_type'] as String?;
      String? ambNom = newData['ambulance_number'] as String? ?? 'AMBU-$ambId';

      if (ambId != null && lat != null && lon != null) {
        int ambIndex = _ambulances.indexWhere((a) => a.id == ambId);
        if (ambIndex != -1) {
          _ambulances[ambIndex] = _ambulances[ambIndex].copyWith(
            position: LatLng(lat, lon),
            type: ambType ?? _ambulances[ambIndex].type,
            nom: ambNom,
          );
          print(
              "WebSocket: Position/Type ambulance ID $ambId mis à jour via urgence_update.");
        } else {
          print("WebSocket: Ajout d'ambulance ID $ambId (via urgence_update).");
          _ambulances.add(AmbulanceData(
            id: ambId,
            position: LatLng(lat, lon),
            type: ambType ?? 'DEFAULT',
            nom: ambNom,
          ));
        }
      }
    }
  }

  Future<void> fetchAmbulancePositions() async {
    if (_isLoadingAmbulances) return;
    _isLoadingAmbulances = true;
    notifyListeners();
    print("DEBUG MapDataService: Fetching initial ambulances list...");
    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/ambulances/'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> decodedAmbulances = json.decode(responseBody);
        _ambulances = decodedAmbulances
            .map((jsonItem) => AmbulanceData.fromJson(jsonItem))
            .toList();
        print(
            'DEBUG MapDataService: Initial ambulances list loaded: ${_ambulances.length}');
      } else {
        print(
            'DEBUG MapDataService: Error loading initial ambulances - Code: ${response.statusCode}');
        _ambulances = [];
      }
    } catch (e) {
      print('DEBUG MapDataService: Exception loading initial ambulances: $e');
      _ambulances = [];
    } finally {
      _isLoadingAmbulances = false;
      notifyListeners();
    }
  }

  Future<void> fetchUrgences() async {
    if (_isLoadingUrgences) return;
    _isLoadingUrgences = true;
    notifyListeners();
    print("DEBUG MapDataService: Fetching urgences...");
    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/urgences/'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> decodedUrgences = json.decode(responseBody);

        _urgences.clear();
        _urgences = decodedUrgences.where((u) {
          return u['id'] != null &&
              u['statut'] != null &&
              u['latitude'] != null &&
              u['longitude'] != null &&
              _statutsActifs.contains(u['statut']);
        }).toList();

        final prefs = await SharedPreferences.getInstance();
        final storedUrgenceId = prefs.getInt('currentUrgenceId');

        if (storedUrgenceId != null) {
          Map<String, dynamic>? foundUrgence;
          for (var u in _urgences) {
            if (u is Map<String, dynamic> && u['id'] == storedUrgenceId) {
              foundUrgence = u;
              break;
            }
          }
          _patientActiveUrgence = foundUrgence;

          if (foundUrgence == null) {
            print(
                "DEBUG MapDataService: Patient's stored urgency ID $storedUrgenceId not found in active urgences list. It might be completed or refused.");
            prefs.remove('currentUrgenceId');
          }
        } else {
          _patientActiveUrgence = null;
        }
        print(
            'DEBUG MapDataService: Active urgences filtered: ${_urgences.length}');
        for (var i = 0; i < _urgences.length; i++) {
          print('👉 Urgence active $i: ${jsonEncode(_urgences[i])}');
        }
      } else {
        print(
            'DEBUG MapDataService: Error loading urgences - Code: ${response.statusCode}');
        _urgences = [];
        _patientActiveUrgence = null;
      }
    } catch (e) {
      print('DEBUG MapDataService: Exception loading urgences: $e');
      _urgences = [];
      _patientActiveUrgence = null;
    } finally {
      _isLoadingUrgences = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistoriqueUrgences() async {
    if (_isLoadingHistorique) return;
    _isLoadingHistorique = true;
    notifyListeners();
    print(
        "DEBUG MapDataService: Fetching historical urgences from dedicated endpoint...");
    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/historique_urgences/'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        _historiqueUrgences = json.decode(responseBody) as List<dynamic>;
        print(
            'DEBUG MapDataService: Historical urgences loaded from /historique_urgences/: ${_historiqueUrgences.length}');
      } else {
        print(
            'DEBUG MapDataService: Error loading historical urgences from /historique_urgences/ - Code: ${response.statusCode}');
        _historiqueUrgences = [];
      }
    } catch (e) {
      print(
          'DEBUG MapDataService: Exception loading historical urgences from /historique_urgences/: $e');
      _historiqueUrgences = [];
    } finally {
      _isLoadingHistorique = false;
      notifyListeners();
    }
  }

  Future<void> refreshUrgencesAfterAction() async {
    await fetchUrgences();
    await fetchHistoriqueUrgences();
    await fetchAmbulancePositions();
  }

  void navigateToMainTabWithMapArgs(int tabIndex, LatLng center, double zoom) {
    _currentMainScrenTabIndex = tabIndex;
    _pendingMapArgs = MapNavigationArguments(center: center, zoom: zoom);
    print(
        "MapDataService: Navigating to tab $tabIndex with map args: Center $center, Zoom $zoom");
    notifyListeners();
  }

  void setCurrentMainScreenTab(int tabIndex) {
    if (_currentMainScrenTabIndex != tabIndex) {
      _currentMainScrenTabIndex = tabIndex;
      print("MapDataService: Current tab set to $tabIndex by user tap.");
      notifyListeners();
    }
  }

  void consumeMapArgs() {
    if (_pendingMapArgs != null) {
      _pendingMapArgs = null;
      print("MapDataService: Map arguments consumed.");
    }
  }

  @override
  void dispose() {
    print("MapDataService dispose. Disconnecting WebSocket.");
    disconnectWebSocket();
    _websocketReconnectTimer?.cancel();
    _websocketReconnectTimer = null;
    super.dispose();
  }
}
