import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuestProfileScreen extends StatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  State<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends State<GuestProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final _emailController = TextEditingController();
  String? _roomTypePreference;
  bool _accessibility = false;
  String? _bedConfiguration;
  bool _spaService = false;
  bool _restaurantService = false;

  // Personalized recommendations
  String? _recommendedRoomType;
  List<String> _recommendedServices = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      // Load user profile from Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _emailController.text = data['email'] ?? user.email ?? '';
        _roomTypePreference = data['roomTypePreference'] ?? 'Single';
        Map<String, dynamic> specialRequests =
            data['specialRequests'] ?? {'accessibility': false, 'bedConfiguration': 'Single'};
        _accessibility = specialRequests['accessibility'] ?? false;
        _bedConfiguration = specialRequests['bedConfiguration'] ?? 'Single';
        List<dynamic> repeatServices = data['repeatServices'] ?? [];
        _spaService = repeatServices.contains('Spa');
        _restaurantService = repeatServices.contains('Restaurant');
      } else {
        // If user document doesn't exist, create one with default values
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'roomTypePreference': 'Single',
          'specialRequests': {'accessibility': false, 'bedConfiguration': 'Single'},
          'repeatServices': [],
        });
        _emailController.text = user.email ?? '';
        _roomTypePreference = 'Single';
        _accessibility = false;
        _bedConfiguration = 'Single';
        _spaService = false;
        _restaurantService = false;
      }

      // Load personalized recommendations based on booking history
      await _loadPersonalizedRecommendations(user.uid);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _loadPersonalizedRecommendations(String userId) async {
    try {
      // Fetch the user's booking history
      QuerySnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('checkInDate', descending: true)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        // Analyze booking history for recommendations
        Map<String, int> roomTypeCounts = {};
        Map<String, int> serviceCounts = {'Spa': 0, 'Restaurant': 0};

        for (var doc in bookingSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String roomType = data['roomType'] ?? 'Single'; // Adjust based on your booking data
          roomTypeCounts[roomType] = (roomTypeCounts[roomType] ?? 0) + 1;

          // Check for services in booking history (e.g., from hotelServices field if available)
          List<dynamic> bookedServices = data['hotelServices'] ?? [];
          if (bookedServices.contains('Spa')) serviceCounts['Spa'] = serviceCounts['Spa']! + 1;
          if (bookedServices.contains('Restaurant')) {
            serviceCounts['Restaurant'] = serviceCounts['Restaurant']! + 1;
          }
        }

        // Recommend the most frequently booked room type
        _recommendedRoomType = roomTypeCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        // Recommend services that have been booked at least once
        _recommendedServices = serviceCounts.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key)
            .toList();
      }
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      // Prepare the data to save
      List<String> repeatServices = [];
      if (_spaService) repeatServices.add('Spa');
      if (_restaurantService) repeatServices.add('Restaurant');

      await _firestore.collection('users').doc(user.uid).set({
        'email': _emailController.text,
        'roomTypePreference': _roomTypePreference,
        'specialRequests': {
          'accessibility': _accessibility,
          'bedConfiguration': _bedConfiguration,
        },
        'repeatServices': repeatServices,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email (read-only for now)
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),

            // Room Type Preference
            const Text(
              'Room Type Preference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _roomTypePreference,
              isExpanded: true,
              items: ['Single', 'Double', 'Suite'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _roomTypePreference = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            // Special Requests
            const Text(
              'Special Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Accessibility Features'),
              value: _accessibility,
              onChanged: (value) {
                setState(() {
                  _accessibility = value ?? false;
                });
              },
            ),
            const Text('Bed Configuration'),
            DropdownButton<String>(
              value: _bedConfiguration,
              isExpanded: true,
              items: ['Single', 'Queen', 'King'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _bedConfiguration = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            // Repeat Services
            const Text(
              'Repeat Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Spa'),
              value: _spaService,
              onChanged: (value) {
                setState(() {
                  _spaService = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Restaurant'),
              value: _restaurantService,
              onChanged: (value) {
                setState(() {
                  _restaurantService = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),

            // Personalized Recommendations
            const Text(
              'Personalized Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_recommendedRoomType != null) ...[
              Text('Recommended Room Type: $_recommendedRoomType'),
              const SizedBox(height: 10),
            ],
            if (_recommendedServices.isNotEmpty) ...[
              Text('Recommended Services: ${_recommendedServices.join(', ')}'),
            ],
            if (_recommendedRoomType == null && _recommendedServices.isEmpty) ...[
              const Text('No recommendations available. Make a booking to get personalized suggestions.'),
            ],
          ],
        ),
      ),
    );
  }
}