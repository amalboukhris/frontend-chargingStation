import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReservationFilterPage extends StatefulWidget {
  @override
  _ReservationFilterPageState createState() => _ReservationFilterPageState();
}

class _ReservationFilterPageState extends State<ReservationFilterPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> stations = [];
  List<Map<String, dynamic>> bornes = [
    {"Id": 1, "ModelName": "CCS1"},
    {"Id": 2, "ModelName": "CCS2"},
    {"Id": 6, "ModelName": "Wall"},
  ];

  int? selectedVehicleId;
  int? selectedBorneId;
  int? selectedStationId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Helper function to load data
  Future<void> _loadData() async {
    await Future.wait([_loadVehicles(), _loadStations()]);
  }

  Future<void> _loadVehicles() async {
    try {
      final response = await http.get(Uri.parse('https://localhost:7221/api/Vehicle/vehicles'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          vehicles = data.map((v) => {
            "Id": v["Id"] ?? 0,
            "ModelName": v["ModelName"] ?? "Modèle inconnu"
          }).toList();
        });
      } else {
        throw Exception("Erreur lors du chargement des véhicules");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  Future<void> _loadStations() async {
    try {
      final response = await http.get(Uri.parse('https://localhost:7221/api/ChargingStation'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          stations = data.map((s) => {
            "Id": s["id"] ?? 0,
            "Name": s["name"] ?? "Station inconnue"
          }).toList();
        });
      } else {
        throw Exception("Erreur lors du chargement des stations");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void _createReservation() async {
    if (selectedVehicleId == null || selectedBorneId == null || selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez sélectionner un véhicule, une borne et une station.")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://localhost:7221/api/Reservation/reserve'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "vehicleId": selectedVehicleId,
        "borneId": selectedBorneId,
        "stationId": selectedStationId,
        "date": _dateController.text.isNotEmpty ? _dateController.text : "2025-01-01",
        "time": _timeController.text.isNotEmpty ? _timeController.text : "12:00",
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Réservation effectuée avec succès !")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la réservation.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réservez une station de recharge")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sélectionnez une station :"),
            DropdownButton<int>(
              value: selectedStationId,
              hint: Text('Sélectionner une station'),
              onChanged: (int? newValue) {
                setState(() {
                  selectedStationId = newValue;
                });
              },
              items: stations.map((station) {
                return DropdownMenuItem<int>(
                  value: station['Id'],
                  child: Text(station['Name']),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text("Sélectionnez une borne :"),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: bornes.map((borne) {
                bool isSelected = selectedBorneId == borne["Id"];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBorneId = borne["Id"];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 50), // Placeholder icon for borne
                        SizedBox(height: 8),
                        Text(borne["ModelName"], textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Text("Sélectionnez un véhicule :"),
            DropdownButton<int>(
              value: selectedVehicleId,
              hint: Text('Sélectionner un véhicule'),
              onChanged: (int? newValue) {
                setState(() {
                  selectedVehicleId = newValue;
                });
              },
              items: vehicles.map((vehicle) {
                return DropdownMenuItem<int>(
                  value: vehicle['Id'],
                  child: Text(vehicle['ModelName']),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createReservation,
              child: Text("Réserver"),
            ),
          ],
        ),
      ),
    );
  }
}

