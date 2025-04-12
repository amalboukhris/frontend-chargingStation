class Reservation {
  final int id;
  final String borneName;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final double? duration;

  Reservation({
    required this.id,
    required this.borneName,
    required this.startTime,
    this.endTime,
    required this.status,
    this.duration,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      borneName: json['borneName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'],
      duration: json['duration']?.toDouble(),
    );
  }
}