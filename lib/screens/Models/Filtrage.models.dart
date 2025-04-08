class Borne {
  final int id;
  final String nom;
  final String etat;
  final String? chargingStationName;

  Borne({
    required this.id,
    required this.nom,
    required this.etat,
    this.chargingStationName,
  });

  factory Borne.fromJson(Map<String, dynamic> json) {
    return Borne(
      id: json['id'],
      nom: json['nom'],
      etat: json['etat'],
      chargingStationName: json['chargingStation']?['name'], // Si vous avez un champ ChargingStation dans votre API
    );
  }
}
