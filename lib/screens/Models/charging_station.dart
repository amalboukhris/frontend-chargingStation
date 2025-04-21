class ChargePoint {
  final int id;
  final String chargePointId;
  final String name;
  final String status;
  final double latitude;
  final double longitude;
  final String description;
  final List<Connector> connectors;
 final int availableConnectors;
  final DateTime? nextAvailableTime;
  final bool isAvailable; 
  ChargePoint({
    required this.id,
    required this.chargePointId,
    required this.name,
    required this.status,
    required this.latitude,
    required this.longitude,    required this.isAvailable,

    required this.description,
    required this.connectors,
      required this.availableConnectors,
    this.nextAvailableTime,
  });

factory ChargePoint.fromJson(Map<String, dynamic> json) {
  return ChargePoint(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    chargePointId: json['chargePointId'].toString(),
    name: json['name'].toString(),
    status: json['status'].toString(),
    latitude: json['latitude'] is double 
        ? json['latitude'] 
        : double.tryParse(json['latitude'].toString()) ?? 0.0,isAvailable: json['isAvailable'] ?? false,
    longitude: json['longitude'] is double 
        ? json['longitude'] 
        : double.tryParse(json['longitude'].toString()) ?? 0.0,
    description: json['description']?.toString() ?? '',
    connectors: (json['connectors'] as List?)
        ?.map((connector) => Connector.fromJson(connector))
        ?.toList() ?? [],
    availableConnectors: json['availableConnectors'] ?? 0,
      nextAvailableTime: json['nextAvailableTime'] != null 
          ? DateTime.parse(json['nextAvailableTime'])
          : null,
  );
}

}

class Connector {
  final int id;
  final int connectorId;
  final String status;

  Connector({
    required this.id,
    required this.connectorId,
    required this.status,
  });

factory Connector.fromJson(Map<String, dynamic> json) {
  return Connector(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    connectorId: json['connectorId'] is int 
        ? json['connectorId'] 
        : int.tryParse(json['connectorId'].toString()) ?? 0,
    status: json['status'].toString(),
  );
}
}