import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:vehicul_charging_station/screens/Models/Filtrage.models.dart';
import 'package:vehicul_charging_station/screens/Models/NotificationModel.dart';
import 'package:vehicul_charging_station/screens/Models/charging_station.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicul_charging_station/screens/SignalRService.dart';
import './Models/Filtrage.models.dart';

class BorneService {
  static const String apiUrl = "https://localhost:7081/api/Borne";

  BuildContext get context => context;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fonction de récupération des bornes
  Future<List<Borne>> getBornes() async {
    final response =
        await http.get(Uri.parse(apiUrl), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Borne.fromJson(item)).toList();
    } else {
      throw Exception('Échec de chargement des bornes');
    }
  }

  Future<void> reserveBorne(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse("$apiUrl/reserve/$id"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Réservation réussie.")),
        );
      } else {
        throw Exception('Échec de la réservation de la borne');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  // Fonction de libération d'une borne
  Future<void> releaseBorne(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse("$apiUrl/release/$id"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Liberation réussie.")),
        );
      } else {
        throw Exception('Échec de la Liberation de la borne');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }
  Future<void> markAllAsRead(int userId) async {
  try {
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$apiUrl/mark-all-read/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  } catch (e) {
    throw Exception('Error marking notifications: $e');
  }
}

  Future<List<NotificationModel>> getUnreadNotifications(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$apiUrl/user/$userId/unread-notifications'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('Notifications')) {
          final notifications = data['Notifications'] as List;
          return notifications
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fonction pour récupérer les bornes disponibles d'une station
  Future<List<Borne>> fetchAvailableBornes(int stationId) async {
    final response = await http.get(
      Uri.parse('$apiUrl/station/$stationId/available'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return parseBornes(response.body);
    } else {
      throw Exception('Failed to load available bornes');
    }
  }

  // Fonction pour parser les bornes depuis le JSON
  List<Borne> parseBornes(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Borne>((json) => Borne.fromJson(json)).toList();
  }
}

class BorneReservationPage extends StatefulWidget {
  final ChargingStation station;

  const BorneReservationPage({Key? key, required this.station})
      : super(key: key);

  @override
  State<BorneReservationPage> createState() => _BorneReservationPageState();
}

class _BorneReservationPageState extends State<BorneReservationPage> {
  late Future<List<Borne>> bornes;
  bool isLoading = false;
  late SignalRService signalRService;
  late NotificationService _notificationService;

  final List<NotificationModel> _notifications = [];
  bool _isDisposed = false;
  @override
  void initState() {
    super.initState();
    _initServices();
    bornes = BorneService().fetchAvailableBornes(widget.station.id);
    _loadNotifications();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationService = NotificationService(prefs);

    signalRService = SignalRService(
      context,
      hubUrl: 'https://localhost:7081',
      onNotificationReceived: _handleNotification,
    );
    signalRService.startConnection();
  }

  Future<void> _loadNotifications() async {
    try {
      // Charger depuis le cache local
      final cached = await _notificationService.getCachedNotifications();
      
      // Charger depuis l'API si connecté
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        try {
          final userId = prefs.getString('user_id');
          if (userId != null) {
            final apiNotifications = await BorneService().getUnreadNotifications(int.parse(userId));
            if (!_isDisposed) {
              setState(() {
                _notifications
                  ..clear()
                  ..addAll(apiNotifications)
                  ..addAll(cached.where((n) => !apiNotifications.any((an) => an.id == n.id)));
              });
              await _notificationService.cacheNotifications(_notifications);
            }
          }
        } catch (e) {
          print('API error: $e');
          if (!_isDisposed) {
            setState(() => _notifications.addAll(cached));
          }
        }
      } else {
        if (!_isDisposed) {
          setState(() => _notifications.addAll(cached));
        }
      }
    } catch (e) {
      print('Notification load error: $e');
    }
  }

  void _handleNotification(Map<String, dynamic> notification) {
     if (_isDisposed) return;
    final notificationModel = NotificationModel.fromJson(notification);

    setState(() {
      _notifications.insert(0, notificationModel);
    });
_notificationService.cacheNotifications(_notifications);
    // Afficher uniquement les notifications globales
    if (notificationModel.isGlobal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notificationModel.message),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
    Future<void> _clearAllNotifications() async {
    // Effacer le cache local
    await _notificationService.clearAllNotifications();
    
    // Marquer comme lues dans l'API si connecté
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      try {
        final userId = prefs.getString('user_id');
        if (userId != null) {
          await BorneService().markAllAsRead(int.parse(userId));
        }
      } catch (e) {
        print("API error: $e");
      }
    }
    
    if (!_isDisposed) {
      setState(() => _notifications.clear());
    }
  }

  @override
  void dispose() {
    signalRService.stopConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bornes de ${widget.station.name}'),
        backgroundColor: Colors.green,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () => _showNotificationsDialog(),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        _notifications.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Borne>>(
        future: bornes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aucune borne disponible.'));
          }

          var bornesList = snapshot.data!;

          return ListView.builder(
            itemCount: bornesList.length,
            itemBuilder: (context, index) {
              var borne = bornesList[index];
              bool isDisponible = borne.etat.toLowerCase() == "disponible";

              return ListTile(
                leading: Icon(
                  Icons.bolt,
                  color: isDisponible ? Colors.green : Colors.red,
                ),
                title: Text(borne.nom),
                trailing: Text(
                  borne.etat,
                  style: TextStyle(
                    color: isDisponible ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showReservationDialog(borne),
                tileColor: isDisponible
                    ? Colors.green.withOpacity(0.05)
                    : Colors.red.withOpacity(0.05),
              );
            },
          );
        },
      ),
    );
  }

void _showNotificationsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Notifications'),
      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: _notifications.isEmpty
            ? Center(child: Text('Aucune notification'))
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Dismissible(
                    key: Key(notification.id.toString()),
                    background: Container(color: Colors.red),
                    onDismissed: (direction) {
                      setState(() => _notifications.removeAt(index));
                      _notificationService.cacheNotifications(_notifications);
                    },
                    child: ListTile(
                      leading: Icon(
                        notification.isGlobal ? Icons.public : Icons.person,
                        color: notification.isGlobal ? Colors.green : Colors.blue,
                      ),
                      title: Text(notification.message),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(notification.date),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          child: Text('Fermer'),
          onPressed: () => Navigator.pop(context),
        ),
        if (_notifications.isNotEmpty)
          TextButton(
            child: Text('Tout effacer', style: TextStyle(color: Colors.red)),
            onPressed: () {
              _clearAllNotifications();
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

  void _showReservationDialog(Borne borne) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(borne.nom),
          content: Text('État actuel: ${borne.etat}'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (borne.etat.toLowerCase() == "disponible") {
                  setState(() => isLoading = true);
                  try {
                    await BorneService().reserveBorne(borne.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Réservation réussie.")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Erreur lors de la réservation.")));
                  }
                  _refreshBornes();
                  setState(() => isLoading = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("La borne est déjà occupée.")));
                }
              },
              child: isLoading ? CircularProgressIndicator() : Text('Réserver'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (borne.etat.toLowerCase() == "occupée") {
                  setState(() => isLoading = true);
                  try {
                    await BorneService().releaseBorne(borne.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Borne libérée.")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Erreur lors de la libération.")));
                  }
                  _refreshBornes();
                  setState(() => isLoading = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("La borne est déjà disponible.")));
                }
              },
              child: isLoading ? CircularProgressIndicator() : Text('Libérer'),
            ),
          ],
        );
      },
    );
  }

  void _refreshBornes() {
    setState(() {
      bornes = BorneService().fetchAvailableBornes(widget.station.id);
    });
  }
}
