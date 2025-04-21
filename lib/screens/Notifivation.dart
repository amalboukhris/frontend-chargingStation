import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _requestPermission();
  runApp(MyApp());
}

// 🔐 Autorisation pour Android 13+
Future<void> _requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('Permission status: ${settings.authorizationStatus}');
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    // 📱 Récupération du token FCM
    _fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $_fcmToken');

    // 🔔 Notification reçue en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notification reçue : ${message.notification?.title}');
      _showAlertDialog(message.notification?.title, message.notification?.body);
    });

    // 🕵️ Notification cliquée
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification ouverte');
    });
  }

  void _showAlertDialog(String? title, String? body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title ?? 'Notification'),
        content: Text(body ?? ''),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Test App',
      home: Scaffold(
        appBar: AppBar(title: Text("Notifications FCM")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Token FCM :'),
              SelectableText(_fcmToken ?? 'En attente...'),
            ],
          ),
        ),
      ),
    );
  }
}
