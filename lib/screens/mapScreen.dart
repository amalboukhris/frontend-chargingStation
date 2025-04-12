// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:vehicul_charging_station/screens/Models/charging_station.dart';
// import 'package:vehicul_charging_station/screens/Profile.dart';
// import 'package:vehicul_charging_station/screens/Filtrage.dart';
// import 'package:location/location.dart' hide PermissionStatus;
// import 'package:permission_handler/permission_handler.dart';

// class Mapscreen extends StatefulWidget {
//   const Mapscreen({super.key, required String userId, required String userEmail, required String token});

//   @override
//   // ignore: library_private_types_in_public_api
//   _MapscreenState createState() => _MapscreenState();
// }

// class _MapscreenState extends State<Mapscreen> {
//   final Location _locationService = Location();
//   final TextEditingController _nameController = TextEditingController();
//   bool _isFetchingStations = false;
//   LatLng? _currentLocation;
//   List<LatLng> _chargingStations = [];

//   int _currentIndex = 0; // Index pour la navbar

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocation();
//     fetchData(); // Chargement des stations au démarrage
//   }

//   Future<void> _initializeLocation() async {
//     if (!await _checkAndRequestPermission()) {
//       _showError("Permission de localisation refusée.");
//       return;
//     }

//     // Commencez à écouter la localisation
//     _locationService.onLocationChanged.listen((LocationData locationData) {
//       if (locationData.latitude != null && locationData.longitude != null) {
//         setState(() {
//           _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
//         });
//       }
//     });

//     // Essayez de récupérer la localisation actuelle dès le démarrage
//     final LocationData? locationData = await _locationService.getLocation();
//     if (locationData != null && locationData.latitude != null && locationData.longitude != null) {
//       setState(() {
//         _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
//       });
//     } else {
//       _showError("Impossible de récupérer la position actuelle.");
//     }
//   }

//   Future<bool> _checkAndRequestPermission() async {
//     bool serviceEnabled = await _locationService.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _locationService.requestService();
//       if (!serviceEnabled) return false;
//     }
//     PermissionStatus permissionGranted =
//         (await _locationService.hasPermission()) as PermissionStatus;
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted =
//           (await _locationService.requestPermission()) as PermissionStatus;
//       if (permissionGranted != PermissionStatus.granted) return false;
//     }
//     return true;
//   }

//   Future<void> fetchData() async {
//     final String apiUrl = "https://localhost:7221/api/ChargingStation";

//     setState(() {
//       _isFetchingStations = true;
//     });

//     try {
//       final response = await http.get(Uri.parse(apiUrl));

//       if (response.statusCode == 200) {
//         List<dynamic> data = json.decode(response.body);

//         setState(() {
//           _chargingStations = data.map((stationJson) {
//             ChargingStation station = ChargingStation.fromJson(stationJson);
//             return LatLng(station.latitude, station.longitude);
//           }).toList();
//         });

//         print("Stations de recharge reçues: $_chargingStations");
//       } else {
//         _showError("Erreur serveur: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Erreur de connexion: Vérifiez l'API et votre connexion.");
//     } finally {
//       setState(() {
//         _isFetchingStations = false;
//       });
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> _pages = [
//       MapContent(
//         chargingStations: _chargingStations,
//         currentLocation: _currentLocation,
//         onSearch: fetchData,
//         nameController: _nameController,
//         isFetchingStations: _isFetchingStations,
//       ),
//       ReservationFilterPage(),
//       ProfilePage(),
//       // Page des réservations
//       // Page du profil
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Carte avec Stations",
//             style: TextStyle(fontSize: 20, color: Colors.white)),
//         backgroundColor: Colors.green,
//       ),
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _pages,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         selectedItemColor: Colors.green,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.map), label: "Carte"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.list), label: "Réservations"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
//         ],
//       ),
//     );
//   }
// }

// // Page de la carte
// class MapContent extends StatelessWidget {
//   final List<LatLng> chargingStations;
//   final LatLng? currentLocation;
//   final VoidCallback onSearch;
//   final TextEditingController nameController;
//   final bool isFetchingStations;

//   const MapContent({
//     Key? key,
//     required this.chargingStations,
//     required this.currentLocation,
//     required this.onSearch,
//     required this.nameController,
//     required this.isFetchingStations,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Barre de recherche
//         Card(
//           margin: const EdgeInsets.all(8.0),
//           elevation: 4.0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(
//                     labelText: "Nom de la station",
//                     border: InputBorder.none,
//                     prefixIcon: Icon(Icons.search, color: Colors.green),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: onSearch,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 10),
//                   ),
//                   child: isFetchingStations
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Rechercher",
//                           style: TextStyle(color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Expanded(
//           child: Column(
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: FlutterMap(
//                   options: MapOptions(
//                     initialCenter: currentLocation ?? const LatLng(35.821430, 10.634422), // Si la localisation est disponible, utilisez-la, sinon utilisez la position par défaut.
//                     initialZoom: 14,
//                   ),
//                   children: [
//                     TileLayer(
//                       urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                     ),
//                     MarkerLayer(
//                       markers: [
//                         if (currentLocation != null) ...[
//                           Marker(
//                             point: currentLocation!,
//                             width: 40,
//                             height: 40,
//                             child: Icon(
//                               Icons.location_on,
//                               color: Colors.blue,
//                               size: 40,
//                             ),
//                           ),
//                         ],
//                         ...chargingStations.map((station) {
//                           return Marker(
//                             point: station,
//                             width: 40,
//                             height: 40,
//                             child: Icon(
//                               Icons.location_on,
//                               color: Colors.blue,
//                               size: 40,
//                             ), // Assurez-vous que l'image est présente dans assets
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 flex: 1,
//                 child: ListView.builder(
//                   itemCount: chargingStations.length,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       leading: Icon(Icons.ev_station, color: Colors.green),
//                       title: Text("Station ${index + 1}"),
//                       subtitle: Text(
//                           "Lat: ${chargingStations[index].latitude}, Lng: ${chargingStations[index].longitude}"),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:vehicul_charging_station/screens/Models/charging_station.dart';
import 'package:vehicul_charging_station/screens/Profile.dart';
import 'package:vehicul_charging_station/screens/Filtrage.dart';
import 'package:location/location.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';
import 'package:vehicul_charging_station/screens/reservation_history_page.dart';

class Mapscreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String token;

  const Mapscreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.token,
  });

  @override
  _MapscreenState createState() => _MapscreenState();
}

class _MapscreenState extends State<Mapscreen> {
  final Location _locationService = Location();
  final TextEditingController _nameController = TextEditingController();
  final MapController _mapController = MapController();

  bool _isFetchingStations = false;
  LatLng? _currentLocation;
  List<ChargingStation> _stations = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    fetchData();
  }

  Future<void> _initializeLocation() async {
    if (!await _checkAndRequestPermission()) {
      _showError("Permission de localisation refusée.");
      return;
    }

    _locationService.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    });

    final locationData = await _locationService.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
      });
    } else {
      _showError("Impossible de récupérer la position actuelle.");
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    if (await Permission.location.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    return true;
  }

  Future<void> fetchData() async {
  final String apiUrl = "https://localhost:7081/api/ChargingStation";
  setState(() => _isFetchingStations = true);

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        // Vérification si les données sont valides avant de les convertir
        _stations = data
            .map((e) => ChargingStation.fromJson(e)) // Assurez-vous que le modèle prend en compte les valeurs nulles
            .toList();
      });
    } else {
      _showError("Erreur serveur: ${response.statusCode}");
    }
  } catch (e) {
    _showError("Erreur de connexion: $e");
  } finally {
    setState(() => _isFetchingStations = false);
  }
}
Future<void> fetchDataSarsh() async {
  String name = _nameController.text.trim();
  String baseUrl = "https://localhost:7081/api/ChargingStation/search";
  String apiUrl = name.isNotEmpty ? "$baseUrl?name=$name" : baseUrl;

  setState(() => _isFetchingStations = true);

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      final fetchedStations = data.map((e) => ChargingStation.fromJson(e)).toList();

      setState(() {
        _stations = fetchedStations;
      });

      // ✅ Recentre la carte après avoir mis à jour _stations
      if (_stations.isNotEmpty) {
        final firstStation = _stations.first;
        _mapController.move(
          LatLng(firstStation.latitude, firstStation.longitude),
          15.0, // niveau de zoom
        );
      }
    } else {
      _showError("Erreur serveur: ${response.statusCode}");
    }
  } catch (e) {
    _showError("Erreur de connexion: $e");
  } finally {
    setState(() => _isFetchingStations = false);
  }
}




  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
Widget build(BuildContext context) {
  final List<Widget> _pages = [
   MapContent(
  stations: _stations,
  currentLocation: _currentLocation,
  onSearch: fetchDataSarsh, // <-- ici
  nameController: _nameController,
  isFetchingStations: _isFetchingStations,
   mapController: _mapController,
),

    // For bottom nav, show empty state or first station
    _stations.isNotEmpty 
      ? BorneReservationPage(station: _stations.first)
      : Center(child: Text("No stations available")),
       ReservationHistoryPage(token: widget.token),
    ProfilePage(),
  ];
  


    return Scaffold(
     
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Carte"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: "Réservations"),
             BottomNavigationBarItem(
      icon: Icon(Icons.history), 
      label: "Historique", // Changé de "Réservations" à "Historique"
    ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

// -------------------------
// Widget Carte
// -------------------------
class MapContent extends StatelessWidget {
  final List<ChargingStation> stations;
  final LatLng? currentLocation;
  final VoidCallback onSearch;
  final TextEditingController nameController;
  final bool isFetchingStations;

  const MapContent({
    super.key,
    required this.stations,
    required this.currentLocation,
    required this.onSearch,
    required this.nameController,
    required this.isFetchingStations,
     required MapController mapController,
  });

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = [
      if (currentLocation != null)
        Marker(
          point: currentLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
        ),
      ...stations.asMap().entries.map((entry) {
        int index = entry.key;
        ChargingStation station = entry.value;
        LatLng location = LatLng(station.latitude, station.longitude);

        return Marker(
          point: location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => BorneReservationPage(station: station),

                ),
              );
            },
            child: Icon(
              Icons.ev_station,
              color: Colors.green,
              size: 20,
            ),
          ),
        );
      }).toList(),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nom de la station",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isFetchingStations
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Rechercher",
                            style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter:
                  currentLocation ?? const LatLng(35.821430, 10.634422),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
        ),
      Expanded(
  flex: 1,
  child: ListView.builder(
    itemCount: stations.length,
    itemBuilder: (context, index) {
      final s = stations[index];
      return ListTile(
        leading: const Icon(Icons.ev_station, color: Colors.green),
        title: Text(s.name ?? "Station ${index + 1}"),
        subtitle: Text("Lat: ${s.latitude}, Lng: ${s.longitude}"),
        onTap: () {
          // Navigation vers la page de réservation avec la station
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BorneReservationPage(station: s),
            ),
          );
        },
      );
    },
  ),
),

      ],
    );
  }
}
