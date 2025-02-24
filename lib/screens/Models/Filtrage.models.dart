class Reservation {
  final int id;
  final int vehicleId;
  final Vehicle vehicle;
  final int borneId;
  final Borne borne;

  Reservation({
    required this.id,
    required this.vehicleId,
    required this.vehicle,
    required this.borneId,
    required this.borne,
  });
}

class Vehicle {
  final int id;
  final String modelName;
  final List<Reservation> reservations;

  Vehicle({
    required this.id,
    required this.modelName,
    this.reservations = const [],
  });
}

class Borne {
  final int id;
  final int chargingStationId;
  final ChargingStation chargingStation;
  final List<Reservation> reservations;

  Borne({
    required this.id,
    required this.chargingStationId,
    required this.chargingStation,
    this.reservations = const [],
  });
}

class ChargingStation {
  final int id;
  final String name;
  final String location;
  final String region;
  final bool availability;
  final List<Borne> bornes;

  ChargingStation({
    required this.id,
    required this.name,
    required this.location,
    required this.region,
    required this.availability,
    this.bornes = const [],
  });
}