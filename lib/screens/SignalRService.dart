// SignalRService.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/material.dart';
import 'package:vehicul_charging_station/screens/Models/NotificationModel.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final BuildContext context;
  final String hubUrl;
  final Function(Map<String, dynamic>) onNotificationReceived;

  SignalRService(this.context, {
    required this.hubUrl,
    required this.onNotificationReceived,
  });

  Future<void> startConnection() async {
    final token = await _getToken();
    final userId = await _getUserId();
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '$hubUrl/notifications?userId=$userId',
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            accessTokenFactory: () => Future.value(token),
          ),
        )
        .build();

_hubConnection.on('ReceiveGlobalNotification', (arguments) {
  print('Notification reçue: $arguments'); // Log de débogage
  
  try {
    if (arguments != null && arguments.isNotEmpty) {
      // Gestion différente selon le type d'argument
      dynamic notificationData;
      if (arguments is List) {
        notificationData = arguments.first;
      } else {
        notificationData = arguments;
      }

      final notification = {
        'id': notificationData['Id'] ?? notificationData['id'] ?? 0,
        'message': notificationData['Message'] ?? notificationData['message'] ?? 'Notification sans message',
        'date': notificationData['Date'] ?? notificationData['date'] ?? DateTime.now().toString(),
        'isGlobal': notificationData['IsGlobal'] ?? notificationData['isGlobal'] ?? false,
      };
      
      print('Notification parsée: $notification'); // Log de débogage
      onNotificationReceived(notification);
    }
  } catch (e) {
    print('Erreur lors du traitement de la notification: $e');
  }
});

    try {
      await _hubConnection.start();
      print('SignalR connection established');
    } catch (e) {
      print('Error establishing SignalR connection: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> joinNotificationGroup(String groupName) async {
    try {
      await _hubConnection.invoke('JoinNotificationGroup', args: [groupName]);
    } catch (e) {
      print('Error joining group: $e');
    }
  }

  Future<void> leaveNotificationGroup(String groupName) async {
    try {
      await _hubConnection.invoke('LeaveNotificationGroup', args: [groupName]);
    } catch (e) {
      print('Error leaving group: $e');
    }
  }

  Future<void> sendGlobalNotification(String message) async {
    try {
      await _hubConnection.invoke('SendGlobalNotification', args: [message]);
    } catch (e) {
      print('Error sending global notification: $e');
    }
  }

  Future<void> stopConnection() async {
    await _hubConnection.stop();
  }
}


class NotificationService {
  final SharedPreferences _prefs;
  final String _notificationsKey = 'cached_notifications';

  NotificationService(this._prefs);

  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await _prefs.setString(_notificationsKey, jsonEncode(jsonList));
  }

  Future<List<NotificationModel>> getCachedNotifications() async {
    final jsonString = _prefs.getString(_notificationsKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing cached notifications: $e');
      return [];
    }
  }

  Future<void> clearAllNotifications() async {
    await _prefs.remove(_notificationsKey);
  }
}