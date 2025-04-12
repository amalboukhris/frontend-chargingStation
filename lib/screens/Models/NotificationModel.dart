class NotificationModel {
  final int id;
  final String message;
  final DateTime date;
  final bool isRead;
  final bool isGlobal;

  NotificationModel({
    required this.id,
    required this.message,
    required this.date,
    required this.isRead,
    required this.isGlobal,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      date: DateTime.parse(json['date']),
      isRead: json['isRead'] ?? false,
      isGlobal: json['isGlobal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'date': date.toIso8601String(),
        'isRead': isRead,
        'isGlobal': isGlobal,
      };
}
