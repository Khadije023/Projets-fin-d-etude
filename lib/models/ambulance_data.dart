// lib/models/ambulance_data.dart
import 'package:latlong2/latlong.dart'; // Pour le type LatLng

class AmbulanceData {
  final int id;
  final String?
      type; // Rendu nullable pour correspondre à copyWith et aux données potentielles
  final LatLng position;
  final String? nom;
  final bool? disponible; // AJOUTÉ : Pour le statut de disponibilité
  final String? currentPhase;

  AmbulanceData({
    required this.id,
    this.type, // Rendu optionnel
    required this.position,
    this.nom,
    this.disponible, // AJOUTÉ
    this.currentPhase,
  });

  factory AmbulanceData.fromJson(Map<String, dynamic> json) {
    return AmbulanceData(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? -1, // Sécure
      type: json['type'] as String?, // Cast en String?
      position: LatLng(
        (json['latitude'] as num? ?? 0.0).toDouble(),
        (json['longitude'] as num? ?? 0.0).toDouble(),
      ),
      nom: json['nom_vehicule'] as String?,
      disponible: json['disponible'] as bool?, // AJOUTÉ
      currentPhase: json['current_phase'] as String?,
    );
  }

  // NOUVELLE MÉTHODE : copyWith pour AmbulanceData (précédemment manquante)
  AmbulanceData copyWith({
    String? nom,
    LatLng? position,
    String? type,
    bool? disponible,
    String? currentPhase,
  }) {
    return AmbulanceData(
      id: id, // L'ID ne change jamais
      nom: nom ?? this.nom,
      position: position ?? this.position,
      type: type ?? this.type,
      disponible: disponible ?? this.disponible, // Copie le champ disponible
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'nom_vehicule': nom,
      'disponible': disponible, // AJOUTÉ
      'current_phase': currentPhase,
    };
  }
}
