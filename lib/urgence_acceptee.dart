// UrgenceAcceptee.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:easy_localization/easy_localization.dart';

class UrgenceAccepteePage extends StatefulWidget {
  final int urgenceId;
  final double? urgenceLatitude;
  final double? urgenceLongitude;
  final String initialStatut;

  const UrgenceAccepteePage({
    super.key,
    required this.urgenceId,
    this.urgenceLatitude,
    this.urgenceLongitude,
    this.initialStatut = 'acceptee',
  });

  @override
  State<UrgenceAccepteePage> createState() => _UrgenceAccepteePageState();
}

class _UrgenceAccepteePageState extends State<UrgenceAccepteePage> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _displayAmbulances = [];
  LatLng? _patientPosition;
  String _ambulanceStatus = '';
  String? _ambulanceContactNumber;

  final String _websocketUrl = 'ws://192.168.1.122:8000/ws/map_updates/';
  WebSocketChannel? _channel;
  StreamSubscription? _websocketSubscription;
  Timer? _reconnectTimer;

  static const LatLng _defaultMapCenter = LatLng(18.0790, -15.9650);
  static const double _defaultMapZoom = 6.0;

  bool _hasShownArrivalDialog = false;
  bool _hasShownPriseEnChargeEndedDialog = false;

  @override
  void initState() {
    super.initState();
    _ambulanceStatus = 'ambulance_status.waiting_info'.tr();
    _getPatientLocation();
    _connectWebSocket();
    _updateStatusDisplay(widget.initialStatut);
  }

  @override
  void dispose() {
    _websocketSubscription?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  void _updateStatusDisplay(String status) {
    String translatedStatus;
    switch (status) {
      case 'en_attente':
        translatedStatus = 'ambulance_status.waiting_assignment'.tr();
        break;
      case 'acceptee':
        translatedStatus = 'ambulance_status.accepted_preparing'.tr();
        break;
      case 'ambulance_affectee':
        translatedStatus = 'ambulance_status.ambulance_assigned'.tr();
        break;
      case 'en_route_vers_victime':
        translatedStatus = 'ambulance_status.en_route_to_victim'.tr();
        break;
      case 'arrivee_sur_place':
        translatedStatus = 'ambulance_status.arrived_on_scene'.tr();
        break;
      case 'prise_en_charge':
        translatedStatus = 'ambulance_status.patient_care'.tr();
        break;
      case 'en_route_vers_base':
        translatedStatus = 'ambulance_status.patient_care'.tr();
        break;
      case 'terminee':
        translatedStatus = 'ambulance_status.patient_care'.tr();
        break;
      case 'refusee':
        translatedStatus = 'ambulance_status.emergency_refused'.tr();
        break;
      case 'annulee_patient':
        translatedStatus = 'ambulance_status.emergency_cancelled'.tr();
        break;
      default:
        translatedStatus = status;
        break;
    }
    if (mounted) {
      setState(() {
        _ambulanceStatus = '${'ambulance_prefix'.tr()}$translatedStatus';
      });
    }
  }

  Future<void> _getPatientLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('location_disabled'.tr());
        if (mounted &&
            widget.urgenceLatitude != null &&
            widget.urgenceLongitude != null &&
            widget.urgenceLatitude!.isFinite &&
            widget.urgenceLongitude!.isFinite) {
          setState(() {
            _patientPosition =
                LatLng(widget.urgenceLatitude!, widget.urgenceLongitude!);
          });
          print('patient_position_retrieved'
              .tr()
              .replaceAll('{}', _patientPosition.toString()));
          _fitMapToMarkers();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('location_permission_denied'.tr());
          if (mounted &&
              widget.urgenceLatitude != null &&
              widget.urgenceLongitude != null &&
              widget.urgenceLatitude!.isFinite &&
              widget.urgenceLongitude!.isFinite) {
            setState(() {
              _patientPosition =
                  LatLng(widget.urgenceLatitude!, widget.urgenceLongitude!);
            });
            print('patient_position_retrieved'
                .tr()
                .replaceAll('{}', _patientPosition.toString()));
            _fitMapToMarkers();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('location_permission_forever_denied'.tr());
        if (mounted &&
            widget.urgenceLatitude != null &&
            widget.urgenceLongitude != null &&
            widget.urgenceLatitude!.isFinite &&
            widget.urgenceLongitude!.isFinite) {
          setState(() {
            _patientPosition =
                LatLng(widget.urgenceLatitude!, widget.urgenceLongitude!);
          });
          print('patient_position_retrieved'
              .tr()
              .replaceAll('{}', _patientPosition.toString()));
          _fitMapToMarkers();
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        if (position.latitude.isFinite && position.longitude.isFinite) {
          setState(() {
            _patientPosition = LatLng(position.latitude, position.longitude);
          });
          _fitMapToMarkers();
          print('patient_position_retrieved'
              .tr()
              .replaceAll('{}', _patientPosition.toString()));
        } else {
          if (mounted &&
              widget.urgenceLatitude != null &&
              widget.urgenceLongitude != null &&
              widget.urgenceLatitude!.isFinite &&
              widget.urgenceLongitude!.isFinite) {
            setState(() {
              _patientPosition =
                  LatLng(widget.urgenceLatitude!, widget.urgenceLongitude!);
            });
            print('patient_position_retrieved'
                .tr()
                .replaceAll('{}', _patientPosition.toString()));
            _fitMapToMarkers();
          }
        }
      }
    } catch (e) {
      print('patient_position_error'.tr().replaceAll('{}', e.toString()));
      if (mounted &&
          widget.urgenceLatitude != null &&
          widget.urgenceLongitude != null &&
          widget.urgenceLatitude!.isFinite &&
          widget.urgenceLongitude!.isFinite) {
        setState(() {
          _patientPosition =
              LatLng(widget.urgenceLatitude!, widget.urgenceLongitude!);
        });
        print('patient_position_retrieved'
            .tr()
            .replaceAll('{}', _patientPosition.toString()));
        _fitMapToMarkers();
      }
    }
  }

  void _connectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_websocketUrl));

      _websocketSubscription = _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message) as Map<String, dynamic>;
            final String? messageType = data['type'] as String?;

            if (messageType == 'multi_position_update') {
              final List<dynamic>? ambulances =
                  data['ambulances'] as List<dynamic>?;
              if (ambulances != null) {
                List<Map<String, dynamic>> updatedAmbulances = [];
                for (var amb in ambulances) {
                  int? ambUrgenceId = amb['urgence_id'] is int
                      ? amb['urgence_id'] as int
                      : int.tryParse(amb['urgence_id'].toString());
                  String? currentPhase = amb['current_phase'] as String?;

                  if (ambUrgenceId == widget.urgenceId &&
                      currentPhase != 'en_route_vers_base') {
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
                      if (updatedAmbulances.length == 1) {
                        _updateStatusDisplay(currentPhase!);
                        _ambulanceContactNumber = numeroTelephone;
                      }
                    }
                  }
                }
                if (mounted) {
                  setState(() {
                    _displayAmbulances = updatedAmbulances;
                  });
                  if (_displayAmbulances.isNotEmpty) {
                    _fitMapToMarkers();
                  }
                }
              }
            } else if (messageType == 'urgence_update') {
              final int? urgenceId = data['id'] as int?;
              if (urgenceId == widget.urgenceId) {
                final String? statut = data['statut'] as String?;
                if (statut != null) {
                  if (statut == 'terminee') {
                    if (!_hasShownPriseEnChargeEndedDialog) {
                      _showUrgenceEndedDialog();
                      _hasShownPriseEnChargeEndedDialog = true;
                    }
                    _updateStatusDisplay('prise_en_charge');
                  } else {
                    _updateStatusDisplay(statut);
                  }

                  if (statut == 'arrivee_sur_place' &&
                      !_hasShownArrivalDialog) {
                    _showArrivalDialog();
                    _hasShownArrivalDialog = true;
                  }
                }
              }
            }
          } catch (e) {
            print('WebSocket message parsing error: $e');
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          if (mounted) {
            setState(() {
              _ambulanceStatus = 'websocket_connection_error'.tr();
            });
          }
          _reconnectTimer?.cancel();
          _reconnectTimer =
              Timer(const Duration(seconds: 5), () => _connectWebSocket());
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _ambulanceStatus = 'websocket_closed'.tr();
            });
          }
          _reconnectTimer?.cancel();
          _reconnectTimer =
              Timer(const Duration(seconds: 5), () => _connectWebSocket());
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      if (mounted) {
        setState(() {
          _ambulanceStatus = 'websocket_failed'.tr();
        });
      }
      _reconnectTimer?.cancel();
      _reconnectTimer =
          Timer(const Duration(seconds: 5), () => _connectWebSocket());
    }
  }

  void _fitMapToMarkers() {
    List<LatLng> points = [];
    if (_patientPosition != null) {
      points.add(_patientPosition!);
    }
    for (var amb in _displayAmbulances) {
      points.add(LatLng(amb['lat'], amb['lon']));
    }

    if (points.isEmpty) {
      _mapController.move(_defaultMapCenter, _defaultMapZoom);
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
              content: Text('call_failed'.tr().replaceAll('{}', phoneNumber))),
        );
      }
    }
  }

  void _showArrivalDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ambulance_arrived_title'.tr()),
            content: Text('ambulance_arrived_message'.tr()),
            actions: <Widget>[
              TextButton(
                child: Text('ok'.tr()),
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

  void _showUrgenceEndedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('emergency_ended_title'.tr()),
            content: Text('emergency_ended_message'.tr()),
            actions: <Widget>[
              TextButton(
                child: Text('ok'.tr()),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('emergency_tracking'.tr()),
          backgroundColor: Colors.redAccent,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'emergency_accepted'.tr(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ambulanceStatus,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.blueGrey),
                      ),
                      if (_ambulanceContactNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(_ambulanceContactNumber!),
                            icon: const Icon(Icons.phone, color: Colors.white),
                            label: Text(
                                'call_ambulance_number'
                                    .tr()
                                    .replaceAll('{}', _ambulanceContactNumber!),
                                style: const TextStyle(color: Colors.white)),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _patientPosition ?? _defaultMapCenter,
                    initialZoom: _defaultMapZoom,
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
                    if (_patientPosition != null &&
                        _patientPosition!.latitude.isFinite &&
                        _patientPosition!.longitude.isFinite)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _patientPosition!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on,
                                color: Colors.blue, size: 40),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _displayAmbulances.map((amb) {
                        final LatLng ambLatLng = LatLng(amb['lat'], amb['lon']);
                        final String ambName =
                            amb['nom_vehicule'] ?? 'ambulance_label'.tr();
                        return Marker(
                          point: ambLatLng,
                          width: 100,
                          height: 100,
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
                                  ambName,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
