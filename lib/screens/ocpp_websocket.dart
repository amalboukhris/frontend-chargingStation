import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OcppClient {
  final String chargePointId;
  final String serverUrl;
  late WebSocketChannel _channel;
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  OcppClient({
    required this.chargePointId,
    required this.serverUrl,
  });

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$serverUrl/ocpp/$chargePointId'),
      );
      await _channel.ready.timeout(const Duration(seconds: 10));
      _channel.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnection(),
      );
      
   _isConnected = true;
    } on TimeoutException {
      _isConnected = false;
      throw Exception('Connection timeout. Please check your network connection.');
    } catch (e) {
      _isConnected = false;
      throw Exception('Failed to connect: ${e.toString()}');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      print('[OCPP] Received raw: $data');
      final message = jsonDecode(data);
      print('[OCPP] Received parsed: $message');

      if (message['messageId'] != null && _pendingRequests.containsKey(message['messageId'])) {
        print('[OCPP] Completing request for ${message['messageId']}');
        _pendingRequests[message['messageId']]!.complete(message);
        _pendingRequests.remove(message['messageId']);
      } else {
        print('[OCPP] Adding to message stream');
        _messageController.add(message);
      }
    } catch (e) {
      print('[OCPP] Error handling message: $e');
      _messageController.addError(e);
    }print('[OCPP] Réponse reçue: $data');
  }

  void _handleError(dynamic error) {
    _messageController.addError(error);
    _cancelPendingRequests('Connection error: $error');
  }

  void _handleDisconnection() {
    _isConnected = false;
    _cancelPendingRequests('Connection closed');
    _messageController.close();
  }

  void _cancelPendingRequests(String error) {
    for (final entry in _pendingRequests.entries) {
      entry.value.completeError(Exception(error));
    }
    _pendingRequests.clear();
  }

   Future<Map<String, dynamic>> sendMessage(
    String messageType, 
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      if (!_isConnected || _channel.closeCode != null) {
        await connect();
      }

      final messageId = const Uuid().v4();
      final completer = Completer<Map<String, dynamic>>();
      _pendingRequests[messageId] = completer;

      final message = {
        "messageType": messageType,
        "messageId": messageId,
        "payload": payload,
      };

print('[OCPP] Envoi du message: ${jsonEncode(message)}');
    _channel.sink.add(jsonEncode(message));

    return await completer.future.timeout(timeout, onTimeout: () {
      _pendingRequests.remove(messageId);
      print('[OCPP DEBUG] Timeout waiting for response');
      throw TimeoutException('Server did not respond in time');
    });
  } catch (e) {
    print('[OCPP ERROR] Send message failed: $e');
    rethrow;
  }
  }

  Future<void> disconnect() async {
    _cancelPendingRequests('Client disconnected');
    await _channel.sink.close();
    await _messageController.close();
    _isConnected = false;
  }
}