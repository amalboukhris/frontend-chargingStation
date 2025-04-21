import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicul_charging_station/screens/Filtrage.dart';
import 'package:vehicul_charging_station/screens/Models/charging_station.dart';
import 'package:vehicul_charging_station/screens/Profile.dart';
import 'package:vehicul_charging_station/screens/Reservation.dart';
import 'package:vehicul_charging_station/screens/reservation_history_page.dart';

class MainMapScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String token;

  const MainMapScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.token,
  });

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  final Location _locationService = Location();
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  List<ChargePoint>_chargePoints  = [];
  LatLng? _currentLocation;
  bool _isLoading = false;
int _currentIndex = 0;
bool _isFetchingStations = false;
  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchChargePoints();
  }

  Future<void> _initializeLocation() async {
    if (!await _checkLocationPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission required')),
      );
      return;
    }
    
    _locationService.onLocationChanged.listen((locationData) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    });

    try {
      final locationData = await _locationService.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: ${e.toString()}')),
      );
    }
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      return (await Permission.location.request()).isGranted;
    }
    return status.isGranted;
  }

 Future<void> _fetchChargePoints() async {
  setState(() => _isLoading = true);
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7080/api/ChargePoints'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    
    print('API Response: ${response.body}'); // Add this debug line
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      setState(() {
        _chargePoints = data.map((e) => ChargePoint.fromJson(e)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error fetching charge points: $e'); // Add this debug line
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: ${e.toString()}')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<void> fetchDataSearch() async {
  String name = _nameController.text.trim();
  String baseUrl = "http://10.0.2.2:7080/api/ChargePoints/advanced-search";
  String apiUrl = name.isNotEmpty ? "$baseUrl?name=$name" : baseUrl;

  setState(() => _isFetchingStations = true);

  try {
    print("Fetching from: $apiUrl"); // Debug log
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    print("Response status: ${response.statusCode}"); // Debug log
    print("Response body: ${response.body}"); // Debug log

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print("Parsed data: $data"); // Debug log
      
      final fetchedStations = data.map((e) => ChargePoint.fromJson(e)).toList();
      // ... rest of your code
    } else {
      _showError("Server error: ${response.statusCode}");
    }
  } catch (e, stackTrace) {
    print("Error: $e"); // Debug log
    print("Stack trace: $stackTrace"); // Debug log
    _showError("Connection error: $e");
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
  stations: _chargePoints,
  currentLocation: _currentLocation,
  onSearch: fetchDataSearch,
  nameController: _nameController,
  isFetchingStations: _isFetchingStations,
  mapController: _mapController, token: widget.token,
 userId: widget.userId,
        userEmail: widget.userEmail,
),


    // For bottom nav, show empty state or first station
    _chargePoints.isNotEmpty 
      ? ChargePointReservationPage(  chargePoint: _chargePoints.first, token: widget.token, serverUrl: 'ws://10.0.2.2:7080',)
      : Center(child: Text("No stations available")),
       ReservationHistoryPage(token: widget.token),
    ProfilePage(
  userId: widget.userId, 
  userEmail: widget.userEmail,
)
  ];
  


 return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  BottomNavigationBar _buildModernNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: "Carte",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: "Réservations",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: "Historique",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: "Profil",
        ),
      ],
    );
  }
}



// -------------------------
// Widget Carte
// -------------------------
class MapContent extends StatelessWidget {
  final List<ChargePoint> stations;
  final LatLng? currentLocation;
  final VoidCallback onSearch;
  final TextEditingController nameController;
  final bool isFetchingStations;
final String token;

  final String userId;
  
  final String userEmail;
  const MapContent({
    super.key,
    required this.stations,
    required this.currentLocation,
    required this.onSearch,
    required this.nameController,
    required this.isFetchingStations,
     required MapController mapController,
     required this.token, required this.userId, required  this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchCard(context),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: currentLocation ?? const LatLng(35.821430, 10.634422),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.vehicul_charging_station',
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(context),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: Colors.green[700]),
                  onPressed: () {
                    // Recentrer la carte sur la position actuelle
                  },
                ),
              ),
            ],
          ),
        ),
        _buildStationsList(context),
      ],
    );
  }

  Card _buildSearchCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Rechercher une station...",
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.tune, color: Colors.green[700]),
                  onPressed: () {
                    // Ouvrir les filtres avancés
                  },
                ),
              ),
            ),
            if (isFetchingStations)
              LinearProgressIndicator(
                minHeight: 2,
                color: Colors.green[700],
              ),
          ],
        ),
      ),
    );
  }


List<Marker> _buildMarkers(BuildContext context) {
  return [
    if (currentLocation != null)
      Marker(
        point: currentLocation!,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
      ),
    ...stations.map((station) {
      final isAvailable = station.isAvailable;
      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 50,
        height: 50,
        child: Tooltip(
          message: station.isAvailable 
              ? '${station.name} - Disponible'
              : '${station.name} - Occupé jusqu\'à ${DateFormat('HH:mm').format(station.nextAvailableTime ?? DateTime.now())}',
          child: GestureDetector(
            onTap: () => _showStationDetails(context, station),
            child: Container(
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green[100] : Colors.red[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAvailable ? Colors.green : Colors.red,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),)
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.ev_station,
                    color: isAvailable ? Colors.green[700] : Colors.red[700],
                    size: 24,
                  ),
                  if (!isAvailable)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${station.availableConnectors}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }),
  ];
}
  Widget _buildStationsList(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Stations à proximité",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${stations.length} résultats",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return SizedBox(
                width: 160, // Largeur fixe
                child: _buildStationCard(context, station),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildStationCard(BuildContext context, ChargePoint station) {
  return Container(
    width: 160,
    margin: EdgeInsets.only(right: 12, bottom: 12),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important pour éviter les débordements
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image de la carte
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 80,
              color: Colors.grey[200], // Couleur de fond si l'image ne charge pas
              child: Image.network(
                "https://maps.googleapis.com/maps/api/staticmap?center=${station.latitude},${station.longitude}&zoom=15&size=320x120&maptype=roadmap&markers=color:green%7C${station.latitude},${station.longitude}&key=YOUR_API_KEY",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
          // Contenu texte
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name ?? "Station",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}",
                        style: TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 30, // Hauteur fixe pour le bouton
                  child: ElevatedButton(
                    onPressed: () => _showReservationDialog(context, station),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Réserver",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  void _showStationDetails(BuildContext context, ChargePoint station) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              station.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: station.isAvailable ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: station.isAvailable ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    station.isAvailable ? 'DISPONIBLE' : 'OCCUPÉ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: station.isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  if (!station.isAvailable && station.nextAvailableTime != null)
                    Text(
                      'Prochaine disponibilité: ${DateFormat('HH:mm').format(station.nextAvailableTime!)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  Text(
                    'Connecteurs disponibles: ${station.availableConnectors}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: station.isAvailable
                  ? () => _showReservationDialog(context, station)
                  : null,
              child: Text('Réserver'),
            ),
          ],
        ),
      );
    },
  );
}

  void _showReservationDialog(BuildContext context, ChargePoint station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationPage(
          chargePointId: station.id,
          chargePointName: station.name ?? "Station",
          token: token,
        ),
      ),
    );
  }
}