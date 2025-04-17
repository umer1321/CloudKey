import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart'; // Assuming this file contains the Translations class

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
  final Map<String, bool> _services = {
    'Spa': false,
    'Restaurant': false,
    'Room Service': false,
    'Concierge': false,
  };

  // Personalized recommendations
  String? _recommendedRoomType;
  List<String> _recommendedServices = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userAvatar;
  String _userName = '';
  int _totalBookings = 0;
  int _loyaltyPoints = 0;

  final _formKey = GlobalKey<FormState>();
  String _locale = 'en-gb'; // Default locale

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _loadUserProfile();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb';
    });
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

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _emailController.text = data['email'] ?? user.email ?? '';
        _roomTypePreference = data['roomTypePreference'] ?? 'Single';
        _userName = data['name'] ?? user.displayName ?? 'Guest';
        _userAvatar = data['avatar'];
        _loyaltyPoints = data['loyaltyPoints'] ?? 0;

        Map<String, dynamic> specialRequests = data['specialRequests'] ?? {'accessibility': false, 'bedConfiguration': 'Single'};
        _accessibility = specialRequests['accessibility'] ?? false;
        _bedConfiguration = specialRequests['bedConfiguration'] ?? 'Single';

        List<dynamic> repeatServices = data['repeatServices'] ?? [];
        for (String service in _services.keys) {
          _services[service] = repeatServices.contains(service);
        }
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? 'Guest',
          'roomTypePreference': 'Single',
          'specialRequests': {'accessibility': false, 'bedConfiguration': 'Single'},
          'repeatServices': [],
          'loyaltyPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _emailController.text = user.email ?? '';
        _roomTypePreference = 'Single';
        _accessibility = false;
        _bedConfiguration = 'Single';
        _userName = user.displayName ?? 'Guest';
      }

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
        SnackBar(
          content: Text(Translations.translate('error_loading_profile', _locale) + ': $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPersonalizedRecommendations(String userId) async {
    try {
      QuerySnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('checkInDate', descending: true)
          .get();

      _totalBookings = bookingSnapshot.docs.length;

      if (bookingSnapshot.docs.isNotEmpty) {
        Map<String, int> roomTypeCounts = {};
        Map<String, int> serviceCounts = {};
        for (var service in _services.keys) {
          serviceCounts[service] = 0;
        }

        for (var doc in bookingSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String roomType = data['roomType'] ?? 'Single';
          roomTypeCounts[roomType] = (roomTypeCounts[roomType] ?? 0) + 1;

          List<dynamic> bookedServices = data['hotelServices'] ?? [];
          for (var service in bookedServices) {
            if (serviceCounts.containsKey(service)) {
              serviceCounts[service] = serviceCounts[service]! + 1;
            }
          }
        }

        if (roomTypeCounts.isNotEmpty) {
          _recommendedRoomType = roomTypeCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

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
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      List<String> repeatServices = _services.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await _firestore.collection('users').doc(user.uid).update({
        'email': _emailController.text,
        'roomTypePreference': _roomTypePreference,
        'specialRequests': {
          'accessibility': _accessibility,
          'bedConfiguration': _bedConfiguration,
        },
        'repeatServices': repeatServices,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.translate('profile_updated', _locale)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.translate('error_saving_profile', _locale) + ': $e'),
          backgroundColor: Colors.red,
        ),
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

  Widget _buildSectionHeader(String title, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
          ],
          Text(
            Translations.translate(title, _locale),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: _userAvatar != null ? NetworkImage(_userAvatar!) : null,
                  child: _userAvatar == null
                      ? Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatsItem(Translations.translate('total_bookings', _locale), _totalBookings.toString()),
                _buildStatsItem(Translations.translate('loyalty_points', _locale), _loyaltyPoints.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomPreference() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.translate('room_type_preference', _locale),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _roomTypePreference,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: ['Single', 'Double', 'Twin', 'Deluxe', 'Suite', 'Presidential Suite']
                  .map((String value) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialRequests() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(Translations.translate('accessibility_features', _locale)),
              subtitle: Text(Translations.translate('wheelchair_access', _locale)),
              value: _accessibility,
              activeColor: Theme.of(context).primaryColor,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _accessibility = value;
                });
              },
            ),
            const Divider(),
            Text(
              Translations.translate('bed_configuration', _locale),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _bedConfiguration,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: ['Single', 'Twin', 'Queen', 'King', 'California King']
                  .map((String value) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.translate('preferred_services', _locale),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _services.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _services[entry.key] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_recommendedRoomType == null && _recommendedServices.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.translate('no_recommendations', _locale),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                Translations.translate('make_booking_for_suggestions', _locale),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recommendedRoomType != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.hotel,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Translations.translate('recommended_room', _locale) + ': $_recommendedRoomType',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_recommendedServices.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.star,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.translate('recommended_services', _locale),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _recommendedServices.map((service) {
                            return Chip(
                              label: Text(service),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(Translations.translate('loading_profile', _locale)),
            ],
          ),
        ),
      );
    }

    final TextDirection textDirection = _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Translations.translate('guest_profile', _locale)),
          elevation: 0,
          actions: [
            _isSaving
                ? Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            )
                : TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(Translations.translate('save', _locale)),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _saveProfile,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(),
              _buildSectionHeader('Preferences', Icons.settings),
              _buildRoomPreference(),
              _buildSectionHeader('Special Requests', Icons.request_page),
              _buildSpecialRequests(),
              _buildSectionHeader('Services', Icons.room_service),
              _buildServicesGrid(),
              _buildSectionHeader('Personalized For You', Icons.thumb_up),
              _buildRecommendations(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}