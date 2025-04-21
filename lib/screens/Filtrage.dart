import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehicul_charging_station/screens/Models/charging_station.dart';
import 'package:vehicul_charging_station/screens/ocpp_websocket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChargePointReservationPage extends StatefulWidget {
  final ChargePoint chargePoint;
  final String token;
  final String serverUrl; 
  const ChargePointReservationPage({
    Key? key,
    required this.chargePoint,
    required this.token,required this.serverUrl,
  }) : super(key: key);

  @override
  _ChargePointReservationPageState createState() => _ChargePointReservationPageState();
}

class _ChargePointReservationPageState extends State<ChargePointReservationPage> {
  late OcppClient? _ocppClient;
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  int? _selectedConnectorId;
  bool _isReserving = false;
 bool _isConnecting = false;
   String? _connectionError;
  @override
  void initState() {
    super.initState();
   _initializeOcppClient();
  }
  Future<void> _initializeOcppClient() async {
    setState(() {_isConnecting = true;
      _connectionError = null;}
    );
    try {
      _ocppClient = OcppClient(
        chargePointId: widget.chargePoint.chargePointId,
        serverUrl: 'ws://10.0.2.2:7080',
      );
      await _ocppClient!.connect(); // Ensure connection is established
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }
    @override
  void dispose() {
    _ocppClient?.disconnect();
    super.dispose();
  }
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year, now.month, now.day,
        pickedTime.hour, pickedTime.minute,
      );
      setState(() {
        if (isStartTime) {
          _selectedStartTime = selectedDateTime;
          if (_selectedEndTime != null && _selectedEndTime!.isBefore(selectedDateTime)) {
            _selectedEndTime = null;
          }
        } else {
          _selectedEndTime = selectedDateTime;
        }
      });
    }
  } int _retryCount = 0;
  final int _maxRetries = 3;

 


  Future<void> _confirmReservation() async {
    if (_isReserving || _isConnecting) return;
    
    if (_selectedConnectorId == null || _selectedEndTime == null) {
      _showError('Please select all required fields');
      return;
    }

    setState(() => _isReserving = true);
    
    try {
      final response = await _performReservationWithRetry();
      
      if (response['status'] == 'Accepted') {
        _showSuccess('Reservation successful!');
        Navigator.pop(context);
      } else {
        throw Exception(response['error'] ?? 'Reservation failed');
      }
    } catch (e) {
      _showError('Failed to reserve: ${e.toString()}');
    } finally {
      setState(() {
        _isReserving = false;
        _retryCount = 0;
      });
    }
  }

  Future<Map<String, dynamic>> _performReservationWithRetry() async {
    while (_retryCount < _maxRetries) {
      try {
        if (_connectionError != null || _ocppClient == null) {
          await _initializeOcppClient();
        }

        return await _ocppClient!.sendMessage(
          "ReserveNow", 
          {
            "connectorId": _selectedConnectorId,
            "expiryDate": _selectedEndTime!.toIso8601String(),
            "idTag": "user_${widget.token}",
          },
        ).timeout(const Duration(seconds: 30));
      } on TimeoutException {
        _retryCount++;
        print('Retry attempt $_retryCount/$_maxRetries');
        if (_retryCount >= _maxRetries) {
          throw TimeoutException('Server response timeout after $_maxRetries attempts');
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        _retryCount++;
        if (_retryCount >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Max retries reached');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }
Future<void> _testServerConnection() async {
  try {
    final testChannel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:7080/ocpp/${widget.chargePoint.chargePointId}'),  // Hardcoded URL
    );
    await testChannel.ready.timeout(const Duration(seconds: 5));
    await testChannel.sink.close();
    print('Server connection test successful');
  } catch (e) {
    print('Server connection test failed: $e');
    _showError('Cannot connect to server: ${e.toString()}');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chargePoint.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [ if (_isConnecting)
            const LinearProgressIndicator(),
          if (_connectionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Connection error: $_connectionError',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Select Time Slot', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text(
                            _selectedStartTime == null
                                ? 'Start Time'
                                : DateFormat('HH:mm').format(_selectedStartTime!),
                          ),
                        ),
                        const Text('to'),
                        ElevatedButton(
                          onPressed: _selectedStartTime == null 
                              ? null 
                              : () => _selectTime(context, false),
                          child: Text(
                            _selectedEndTime == null
                                ? 'End Time'
                                : DateFormat('HH:mm').format(_selectedEndTime!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.chargePoint.connectors.length,
                itemBuilder: (context, index) {
                  final connector = widget.chargePoint.connectors[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.power,
                        color: _getStatusColor(connector.status),
                      ),
                      title: Text('Connector ${connector.connectorId}'),
                      subtitle: Text(connector.status),
                      trailing: _selectedConnectorId == connector.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => setState(() => _selectedConnectorId = connector.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isReserving ? null : _confirmReservation,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isReserving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Reservation'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Occupied': return Colors.orange;
      case 'Faulted': return Colors.red;
      default: return Colors.grey;
    }
  }
}