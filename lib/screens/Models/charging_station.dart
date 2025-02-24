class ChargingStation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool availability;

  ChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.availability,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'].toDouble(), // Assurer que c'est un double
      longitude: json['longitude'].toDouble(),
      availability: json['availability'],
    );
  }
}
