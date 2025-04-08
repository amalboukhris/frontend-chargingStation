import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('https://localhost:7221/api/User/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateFullProfile(Map<String, dynamic> updatedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('https://localhost:7221/api/User/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedData),
      );
print('Response status: ${response.statusCode}');
print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        _fetchUserProfile(); // Rafraîchir les données après mise à jour
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final Map<String, TextEditingController> controllers = {
      'firstName': TextEditingController(text: userData['firstName'] ?? ''),
      'lastName': TextEditingController(text: userData['lastName'] ?? ''),
      'email': TextEditingController(text: userData['email'] ?? ''),
      'phoneNumber': TextEditingController(text: userData['phoneNumber'] ?? ''),
      'dateOfBirth': TextEditingController(text: userData['dateOfBirth'] ?? ''),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controllers['firstName'],
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: controllers['lastName'],
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: controllers['email'],
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: controllers['phoneNumber'],
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: controllers['dateOfBirth'],
                  decoration: const InputDecoration(labelText: 'Birth Date'),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      controllers['dateOfBirth']!.text = 
                          pickedDate.toLocal().toString().split(' ')[0];
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'firstName': controllers['firstName']!.text,
                  'lastName': controllers['lastName']!.text,
                  'email': controllers['email']!.text,
                  'phoneNumber': controllers['phoneNumber']!.text,
                  'dateOfBirth': controllers['dateOfBirth']!.text,
                };
                await _updateFullProfile(updatedData);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget itemProfile(String title, String subtitle, IconData iconData) {
    return GestureDetector(
      onTap: () => _showEditFieldDialog(
        title.toLowerCase().replaceAll(' ', ''),
        subtitle,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 5),
              color: Colors.deepOrange.withOpacity(.2),
              spreadRadius: 2,
              blurRadius: 10,
            )
          ],
        ),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          leading: Icon(iconData),
          trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
          tileColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _showEditFieldDialog(String field, String currentValue) async {
    final TextEditingController _editController = 
        TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${field.replaceAll(RegExp(r'(?<=[a-z])[A-Z]'), r' $0')}'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              hintText: 'Enter new ${field.replaceAll(RegExp(r'(?<=[a-z])[A-Z]'), r' $0')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_editController.text.isNotEmpty) {
                  await _updateFullProfile({field: _editController.text});
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  itemProfile('First Name', userData['firstName'] ?? 'N/A', Icons.person),
                  const SizedBox(height: 10),
                  itemProfile('Last Name', userData['lastName'] ?? 'N/A', Icons.person_outline),
                  const SizedBox(height: 10),
                  itemProfile('Email', userData['email'] ?? 'N/A', Icons.email),
                  const SizedBox(height: 10),
                  itemProfile('Phone', userData['phoneNumber'] ?? 'N/A', Icons.phone),
                  const SizedBox(height: 10),
                  itemProfile('Birth Date', userData['dateOfBirth'] ?? 'N/A', Icons.cake),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showEditProfileDialog,
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}