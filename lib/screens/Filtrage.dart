import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vehicul_charging_station/screens/Models/Filtrage.models.dart';
import 'package:vehicul_charging_station/screens/Models/charging_station.dart';
class BorneService {
  static const String apiUrl = "https://localhost:7221/api/Borne"; // Remplace si tu utilises un appareil physique

  Future<List<Borne>> getBornes() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Borne.fromJson(item)).toList();
    } else {
      throw Exception('Échec de chargement des bornes');
    }
  }

  Future<void> reserveBorne(int id) async {
    final response = await http.post(Uri.parse("$apiUrl/reserve/$id"));
    if (response.statusCode != 200) {
      throw Exception('Échec de la réservation de la borne');
    }
  }

  Future<void> releaseBorne(int id) async {
    final response = await http.post(Uri.parse("$apiUrl/release/$id"));
    if (response.statusCode != 200) {
      throw Exception('Échec de la libération de la borne');
    }
  }

  Future<List<Borne>> fetchAvailableBornes(int stationId) async {
    final response = await http.get(Uri.parse('$apiUrl/station/$stationId/available'));
    if (response.statusCode == 200) {
      List<Borne> bornes = parseBornes(response.body);
      return bornes;
    } else {
      throw Exception('Failed to load available bornes');
    }
  }

  List<Borne> parseBornes(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Borne>((json) => Borne.fromJson(json)).toList();
  }
}

class BorneReservationPage extends StatefulWidget {
  final ChargingStation station;

    const BorneReservationPage({Key? key, required this.station}) : super(key: key);

  @override
  State<BorneReservationPage> createState() => _BorneReservationPageState();
}

class _BorneReservationPageState extends State<BorneReservationPage> {
  late Future<List<Borne>> bornes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    bornes = BorneService().fetchAvailableBornes(widget.station.id);
  }

  void _refreshBornes() {
    setState(() {
      bornes = BorneService().fetchAvailableBornes(widget.station.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bornes de ${widget.station.name}'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Borne>>(
        future: bornes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
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
              return ListTile(
                leading: Icon(Icons.bolt, color: Colors.orange),
                title: Text(borne.nom),
                subtitle: Text('Station: ${borne.chargingStationName ?? 'Inconnue'}'),
                trailing: Text(borne.etat),
                onTap: () => _showReservationDialog(borne),
              );
            },
          );
        },
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
                if (borne.etat == "Disponible") {
                  setState(() => isLoading = true);
                  try {
                    await BorneService().reserveBorne(borne.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Réservation réussie.")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la réservation.")));
                  }
                  _refreshBornes();
                  setState(() => isLoading = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("La borne est déjà occupée.")));
                }
              },
              child: Text('Réserver'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (borne.etat == "Occupée") {
                  setState(() => isLoading = true);
                  try {
                    await BorneService().releaseBorne(borne.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Borne libérée.")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la libération.")));
                  }
                  _refreshBornes();
                  setState(() => isLoading = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("La borne est déjà disponible.")));
                }
              },
              child: Text('Libérer'),
            ),
          ],
        );
      },
    );
  }
}

