import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userProfile = {};

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

Future<void> fetchUserProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getString('userId');
  final token = prefs.getString('authToken'); // Assumes you're saving an auth token

  if (id == null || token == null) {
    print("User ID or Token not found in SharedPreferences");
    return;
  }

  final url = Uri.parse('https://localhost:7221/api/User/$id');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() {
      userProfile = data;
    });
  } else {
    print("Failed to load user profile: ${response.statusCode}");
    // You can also show a message in the UI instead of just printing the error
    setState(() {
      userProfile = {'error': 'Failed to load profile'};
    });
  }
}


  @override
  Widget build(BuildContext context) {
    if (userProfile.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Profile")),
        body: Center(
            child:
                CircularProgressIndicator()), // Loading indicator while fetching data
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Name: ${userProfile['firstName'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Last Name: ${userProfile['lastName'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${userProfile['email'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phone Number: ${userProfile['phoneNumber'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Date of Birth: ${userProfile['dateOfBirth'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Role: ${userProfile['role'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
