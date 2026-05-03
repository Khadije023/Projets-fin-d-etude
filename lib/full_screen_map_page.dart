import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'services/map_data_service.dart';
import 'models/ambulance_data.dart';

class FullScreenMapPage extends StatefulWidget {
  final LatLng? initialCenter;
  final double? initialZoom;

  final List<AmbulanceData>? ambulancesData;
  final List<dynamic>? urgences;

  final Map<String, Color>? ambulanceTypeColors;
  final Map<String, IconData>? ambulanceTypeIcons;

  const FullScreenMapPage({
    super.key,
    this.initialCenter,
    this.initialZoom,
    this.ambulancesData,
    this.urgences,
    this.ambulanceTypeColors,
    this.ambulanceTypeIcons,
  });

  @override
  _FullScreenMapPageState createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late final MapController _mapController;
  bool _isMapActuallyReady = false;

  // --- SUPPRIMER le code de simulation frontend si vous ne l'utilisez plus ---
  // LatLng? _startPointForRoute;
  // LatLng? _endPointForRoute;
  // LatLng? _movingMarkerForRoute;
  // Timer? _routeMoveTimer;
  // final double _routeStep = 0.05;
  // ---------------------------------------------------------------------------

  String _currentNotificationMessage = "";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapDataService>(context, listen: false)
          .fetchAmbulancePositions();
      Provider.of<MapDataService>(context, listen: false).fetchUrgences();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mapDataService = Provider.of<MapDataService>(context);
    final navArgs = mapDataService.pendingMapArgs;

    if (navArgs != null && _isMapActuallyReady) {
      print(
          "FullScreenMapPage: Applying map args: Center ${navArgs.center}, Zoom ${navArgs.zoom}");

      _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds(navArgs.center, navArgs.center),
          minZoom: navArgs.zoom,
          maxZoom: navArgs.zoom,
          padding: EdgeInsets.zero));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // On revérifie car l'état du service a pu changer
        if (Provider.of<MapDataService>(context, listen: false)
                .pendingMapArgs !=
            null) {
          Provider.of<MapDataService>(context, listen: false).consumeMapArgs();
        }
      });
    }
  }

  void _showTemporaryMessage(String message, {int seconds = 3}) {
    if (!mounted) return;
    setState(() {
      _currentNotificationMessage = message;
    });
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted && _currentNotificationMessage == message) {
        setState(() {
          _currentNotificationMessage = "";
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();

    super.dispose();
  }

  void _fitMapToMarkers(
      List<AmbulanceData> ambulances, List<dynamic> urgencesList) {
    if (!mounted || !_isMapActuallyReady) {
      print(
          "FitMapToMarkers (FullScreen): Carte non prête ou widget non monté.");
      return;
    }

    List<LatLng> allMarkersPoints = [];
    ambulances
        .where((a) =>
            a.position.latitude.isFinite && a.position.longitude.isFinite)
        .forEach((ambulance) => allMarkersPoints.add(ambulance.position));

    urgencesList.where((u) {
      final lat = u is Map ? u['latitude'] : null;
      final lon = u is Map ? u['longitude'] : null;
      return lat is num &&
          lon is num &&
          lat.isFinite &&
          lon.isFinite &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180;
    }).forEach((u) => allMarkersPoints.add(LatLng(
        (u['latitude'] as num).toDouble(),
        (u['longitude'] as num).toDouble())));

    if (allMarkersPoints.isEmpty) {
      print("FitMapToMarkers (FullScreen): No valid markers to fit.");
      final defaultCenter = widget.initialCenter ??
          Provider.of<MapDataService>(context, listen: false).lastKnownCenter ??
          const LatLng(18.0790, -15.9650);
      final defaultZoom = widget.initialZoom ??
          Provider.of<MapDataService>(context, listen: false).lastKnownZoom ??
          6.0;
      _mapController.move(defaultCenter, defaultZoom);
      return;
    }

    if (allMarkersPoints.length == 1) {
      print("FitMapToMarkers (FullScreen): One marker.");
      _mapController.move(allMarkersPoints.first, 14.0);
      return;
    }

    try {
      LatLngBounds bounds = LatLngBounds.fromPoints(allMarkersPoints);
      _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds, padding: const EdgeInsets.all(40.0)));
      print(
          "FitMapToMarkers (FullScreen): Fitted map to ${allMarkersPoints.length} points.");
    } catch (e) {
      print("Error fitting map to markers (FullScreen): $e");
      if (allMarkersPoints.isNotEmpty) {
        _mapController.move(allMarkersPoints.first, 12.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapDataService = Provider.of<MapDataService>(context);

    final List<AmbulanceData> ambulancesToDisplay =
        widget.ambulancesData ?? mapDataService.ambulances;
    final List<dynamic> urgencesToDisplay =
        widget.urgences ?? mapDataService.urgences;
    final Map<String, Color> colorsToUse =
        widget.ambulanceTypeColors ?? mapDataService.ambulanceTypeColors;
    final Map<String, IconData> iconsToUse =
        widget.ambulanceTypeIcons ?? mapDataService.ambulanceTypeIcons;

    LatLng mapInitialCenter = widget.initialCenter ??
        mapDataService.lastKnownCenter ??
        const LatLng(18.0790, -15.9650);
    double mapInitialZoom =
        widget.initialZoom ?? mapDataService.lastKnownZoom ?? 6.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte Détaillée'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 2.0,
        // Affichage du message temporaire dans l'AppBar
        bottom: (_currentNotificationMessage.isNotEmpty)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(30.0),
                child: Container(
                  height: 30.0,
                  color: mapDataService.isLoadingAmbulances ||
                          mapDataService.isLoadingUrgences
                      ? Colors.orange.shade300
                      : Colors.red.shade200,
                  alignment: Alignment.center,
                  child: Text(_currentNotificationMessage,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontSize: 13)),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapInitialCenter,
              initialZoom: mapInitialZoom,
              onMapReady: () {
                if (mounted) {
                  setState(() {
                    _isMapActuallyReady = true;
                  });
                  print("DEBUG FullScreenMapPage onMapReady: Carte prête.");

                  final service =
                      Provider.of<MapDataService>(context, listen: false);

                  final currentPendingArgs = service.pendingMapArgs;
                  if (currentPendingArgs != null) {
                    _mapController.move(
                        currentPendingArgs.center, currentPendingArgs.zoom);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      service.consumeMapArgs();
                    });
                  } else {
                    _fitMapToMarkers(ambulancesToDisplay, urgencesToDisplay);
                  }
                  service.lastKnownCenter = _mapController.camera.center;
                  service.lastKnownZoom = _mapController.camera.zoom;
                }
              },
              onPositionChanged: (MapPosition position, bool hasGesture) {
                if (hasGesture && mounted) {
                  final service =
                      Provider.of<MapDataService>(context, listen: false);
                  service.lastKnownCenter = position.center;
                  service.lastKnownZoom = position.zoom;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.pfe_khadija',
              ),
              MarkerLayer(
                markers: [
                  ...ambulancesToDisplay
                      .where((a) =>
                          a.position.latitude.isFinite &&
                          a.position.longitude.isFinite &&
                          a.position.latitude >= -90 &&
                          a.position.latitude <= 90 &&
                          a.position.longitude >= -180 &&
                          a.position.longitude <= 180)
                      .map((ambulance) {
                    final type = ambulance.type?.toUpperCase() ??
                        'DEFAULT'; // Gérer les types null
                    final color = colorsToUse[type] ??
                        colorsToUse['DEFAULT'] ??
                        Colors.grey;
                    final icon = iconsToUse[type] ??
                        iconsToUse['DEFAULT'] ??
                        Icons.local_hospital;
                    return Marker(
                      width: 100.0,
                      height: 70.0,
                      point: ambulance.position,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, color: color, size: 35.0, shadows: const [
                          Shadow(
                              color: Colors.black45,
                              blurRadius: 3.0,
                              offset: Offset(1, 1))
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 3.0,
                                    offset: Offset(0, 1))
                              ]),
                          child: Text(ambulance.nom ?? "ID:${ambulance.id}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    );
                  }),
                  ...urgencesToDisplay.where((u) {
                    final lat = u is Map ? u['latitude'] : null;
                    final lon = u is Map ? u['longitude'] : null;
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
                    IconData urgenceIcon = Icons.location_pin;
                    Color urgenceColor = Colors.redAccent;
                    // if (u['statut'] == 'en_attente') { urgenceColor = Colors.yellow; }
                    // else if (u['statut'] == 'en_route_vers_victime') { urgenceColor = Colors.blue; }
                    // else if (u['statut'] == 'arrivee_sur_place') { urgenceColor = Colors.green; }
                    // ... etc.

                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(lat.toDouble(), lon.toDouble()),
                      child: Icon(urgenceIcon,
                          color: urgenceColor,
                          size: 35,
                          shadows: const [
                            Shadow(
                                color: Colors.black45,
                                blurRadius: 3.0,
                                offset: Offset(1, 1))
                          ]),
                    );
                  }),
                ],
              ),
            ],
          ),
          // Boutons de contrôle de la carte (zoom, recentrer) - peuvent être conservés
          Positioned(
            top: 16.0,
            right: 16.0,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FloatingActionButton.small(
                  backgroundColor: Colors.white70,
                  heroTag: "mapRecenterFSM",
                  onPressed: () =>
                      _fitMapToMarkers(ambulancesToDisplay, urgencesToDisplay),
                  tooltip: "Recentrer",
                  child: Icon(Icons.my_location_rounded,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 8.0),
              FloatingActionButton.small(
                  backgroundColor: Colors.white70,
                  heroTag: "mapZoomInFSM",
                  onPressed: () {
                    if (_isMapActuallyReady) {
                      _mapController.move(_mapController.camera.center,
                          _mapController.camera.zoom + 1);
                    }
                  },
                  child: Icon(Icons.add_rounded, color: Colors.grey.shade800)),
              const SizedBox(height: 8.0),
              FloatingActionButton.small(
                  backgroundColor: Colors.white70,
                  heroTag: "mapZoomOutFSM",
                  onPressed: () {
                    if (_isMapActuallyReady) {
                      _mapController.move(_mapController.camera.center,
                          _mapController.camera.zoom - 1);
                    }
                  },
                  child:
                      Icon(Icons.remove_rounded, color: Colors.grey.shade800)),
            ]),
          ),
          if (mapDataService.isLoadingAmbulances ||
              mapDataService.isLoadingUrgences)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Colors.blueAccent),
            ),
          if (!mapDataService.isLoadingAmbulances &&
              !mapDataService.isLoadingUrgences &&
              !mapDataService.isWebSocketConnected)
            const Positioned(
              bottom: 16.0,
              left: 16.0,
              child: Chip(
                backgroundColor: Colors.orangeAccent,
                label: Text('Connexion WS en cours...',
                    style: TextStyle(color: Colors.white)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (mapDataService.isWebSocketConnected &&
              !mapDataService.isLoadingAmbulances &&
              !mapDataService.isLoadingUrgences)
            const Positioned(
              bottom: 16.0,
              left: 16.0,
              child: Chip(
                backgroundColor: Colors.greenAccent,
                label:
                    Text('WS Connecté', style: TextStyle(color: Colors.white)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}
