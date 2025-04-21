class Borne {
  final int id;
  final String nom;
  final String etat;
  final int? connectorId;  // Utilisation de int? pour permettre la valeur null

  Borne({
    required this.id,
    required this.nom,
    required this.etat,
    this.connectorId,  // Le connectorId peut être null
  });

  factory Borne.fromJson(Map<String, dynamic> json) {
    return Borne(
      id: json['id'],
      nom: json['nom'],
      etat: json['etat'],
      connectorId: json['connectorId'] != null ? json['connectorId'] : null, // Assurer qu'on gère le null
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'etat': etat,
    'connectorId': connectorId, // Permet la sérialisation même si null
  };
}


class BorneReservationResponseDto {
  final int reservationId;
  final String message;
  final int borneId;
  final DateTime startTime;
  final DateTime endTime;

  BorneReservationResponseDto({
    required this.reservationId,
    required this.message,
    required this.borneId,
    required this.startTime,
    required this.endTime,
  });

  factory BorneReservationResponseDto.fromJson(Map<String, dynamic> json) {
    return BorneReservationResponseDto(
      reservationId: json['reservationId'],
      message: json['message'],
      borneId: json['borneId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}