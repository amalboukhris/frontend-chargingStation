import 'package:vehicul_charging_station/screens/Models/Filtrage.models.dart';

class ChargingStation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final bool availability;
final List<Borne> bornes;
  ChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
     required this.description,
    required this.availability,
    required this.bornes,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'],
      name: json['name']?? 'Nom inconnu',
      latitude: json['latitude'].toDouble(), // Assurer que c'est un double
      longitude: json['longitude'].toDouble(),
      description: json['description']?? 'desc inconnu',
      availability: json['availability'],
       bornes: (json['bornes'] as List)
          .map((e) => Borne.fromJson(e))
          .toList(),
    
    );
  }
}
