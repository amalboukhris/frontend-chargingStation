import 'dart:convert';
import 'package:http/http.dart' as http;
import './Models/reservation_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class ReservationService {
  final String baseUrl;

  ReservationService({required this.baseUrl});

  Future<List<Reservation>> getReservationHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Borne/reservations/history'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Reservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reservation history');
    }
  }
}



class ReservationHistoryPage extends StatefulWidget {
  final String token;

  const ReservationHistoryPage({Key? key, required this.token}) : super(key: key);

  @override
  _ReservationHistoryPageState createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  late Future<List<Reservation>> futureReservations;
  final ReservationService service = ReservationService(baseUrl: 'https://localhost:7081');

  @override
  void initState() {
    super.initState();
    futureReservations = service.getReservationHistory(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Réservations'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: FutureBuilder<List<Reservation>>(
        future: futureReservations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune réservation trouvée'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final reservation = snapshot.data![index];
              return _buildReservationCard(reservation);
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(Icons.ev_station, color: Colors.green),
        title: Text(reservation.borneName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Début: ${DateFormat('dd/MM/yyyy HH:mm').format(reservation.startTime)}'),
            if (reservation.endTime != null)
              Text('Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(reservation.endTime!)}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            reservation.status,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _getStatusColor(reservation.status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}