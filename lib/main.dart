import 'package:flutter/material.dart';

import 'package:vehicul_charging_station/screens/WelcomeScreen.dart';
import 'package:vehicul_charging_station/screens/mapScreen.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicul Charging Station',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      home: WelcomeScreen
       (),
    );
  }
}
