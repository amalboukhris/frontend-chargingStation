import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReservationHistoryPage extends StatefulWidget {
  const ReservationHistoryPage({Key? key, required String token}) : super(key: key);

  @override
  _ReservationHistoryPageState createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  List<dynamic> _reservations = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:7080/api/chargepoints/reservations/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_AUTH_TOKEN', // Add your auth token
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _reservations = json.decode(response.body);
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load reservations'),
                      ElevatedButton(
                        onPressed: _fetchReservations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reservations.isEmpty
                  ? const Center(child: Text('No reservations found'))
                  : ListView.builder(
                      itemCount: _reservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _reservations[index];
                        final startTime = DateTime.parse(reservation['startTime']);
                        final endTime = DateTime.parse(reservation['endTime']);
                        final status = reservation['status'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(
                                'Charge Point ${reservation['chargePointId']} - Connector ${reservation['connectorId']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${DateFormat('MMM dd, yyyy').format(startTime)}'),
                                Text(
                                    '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}'),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                status,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getStatusColor(status),
                            ),
                            onTap: () {
                              // You can add navigation to reservation details here
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}