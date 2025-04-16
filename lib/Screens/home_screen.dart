

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes.dart';
import '../utils/Translations.dart';

class HomeScreen extends StatefulWidget {
  final String locale;

  const HomeScreen({super.key, required this.locale});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? mostRecentBookingId;
  bool isLoading = true;
  bool hasActiveDigitalKey = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndFetchBooking();
  }

  Future<void> _checkAuthenticationAndFetchBooking() async {
    User? user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, Routes.auth);
      });
      return;
    }

    await _fetchMostRecentBooking();
  }

  Future<void> _fetchMostRecentBooking() async {
    setState(() {
      isLoading = true;
      hasActiveDigitalKey = false;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('Current user UID: ${user.uid}');

      QuerySnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('checkedIn', isEqualTo: true)
          .where('checkedOut', isEqualTo: false)
          .orderBy('checkInDate', descending: true)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isEmpty) {
        bookingSnapshot = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('checkInDate', descending: true)
            .limit(1)
            .get();
      }

      if (bookingSnapshot.docs.isEmpty) {
        print('No bookings found for user: ${user.uid}');
        setState(() {
          isLoading = false;
        });
      } else {
        var bookingData = bookingSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          mostRecentBookingId = bookingSnapshot.docs.first.id;
          hasActiveDigitalKey = bookingData['checkedIn'] == true &&
              bookingData['checkedOut'] == false &&
              (bookingData['digitalKey']?.isNotEmpty ?? false);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching recent booking: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('error_fetching_booking', widget.locale) + ': $e',
          ),
        ),
      );
    }
  }

  void _navigateToDigitalKey(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, Routes.auth);
      return;
    }

    if (mostRecentBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('no_bookings', widget.locale),
          ),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.checkInOut,
      arguments: {'bookingId': mostRecentBookingId},
    );
  }

  void _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, Routes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE6E1F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: 30,
              child: Image.asset(
                'assets/images/cloud.png',
                height: 80,
              ),
            ),
            Positioned(
              top: 150,
              right: 30,
              child: Image.asset(
                'assets/images/cloud.png',
                height: 60,
              ),
            ),
            Positioned(
              bottom: 100,
              left: 50,
              child: Image.asset(
                'assets/images/cloud.png',
                height: 70,
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle,
                          color: Colors.brown,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.guestProfile);
                        },
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          return IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.brown,
                              size: 30,
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD3CCE3), Color(0xFFE9E4F0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/city.png',
                      height: 120,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    children: [
                      _buildButton(
                        context: context,
                        text: Translations.translate('bookings', widget.locale),
                        icon: Icons.hotel,
                        color: const Color(0xFFD3CCE3),
                        onPressed: () {
                          if (_auth.currentUser == null) {
                            Navigator.pushNamed(context, Routes.auth);
                          } else {
                            Navigator.pushNamed(context, Routes.booking);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: Translations.translate('digital_key', widget.locale),
                        icon: Icons.vpn_key,
                        color: const Color(0xFFD3CCE3).withOpacity(0.9),
                        onPressed: () => _navigateToDigitalKey(context),
                        subText: hasActiveDigitalKey
                            ? Translations.translate('digital_key_active', widget.locale)
                            : Translations.translate('digital_key_inactive', widget.locale),
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: Translations.translate('car_rental', widget.locale),
                        icon: Icons.directions_car,
                        color: const Color(0xFFD3CCE3).withOpacity(0.8),
                        onPressed: () {
                          if (_auth.currentUser == null) {
                            Navigator.pushNamed(context, Routes.auth);
                          } else {
                            Navigator.pushNamed(context, Routes.carRental);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: Translations.translate('hotel_services', widget.locale),
                        icon: Icons.room_service,
                        color: const Color(0xFFD3CCE3).withOpacity(0.7),
                        onPressed: () {
                          if (_auth.currentUser == null) {
                            Navigator.pushNamed(context, Routes.auth);
                          } else {
                            Navigator.pushNamed(context, Routes.hotelServices);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD3CCE3), Color(0xFFE9E4F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _auth.currentUser?.email ?? Translations.translate('guest', widget.locale),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(Translations.translate('profile', widget.locale)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.guestProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(Translations.translate('notifications', widget.locale)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.notifications);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(Translations.translate('sign_out', widget.locale)),
              onTap: () {
                Navigator.pop(context);
                _signOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? subText,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subText != null)
                Text(
                  subText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}



/*
import 'package:flutter/material.dart';
import '../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE6E1F5)], // Light purple gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Cloud elements
            Positioned(
              top: 100,
              left: 30,
              child: Image.asset(
                'assets/images/cloud.png', // Add cloud image
                height: 80,
              ),
            ),
            Positioned(
              top: 150,
              right: 30,
              child: Image.asset(
                'assets/images/cloud.png', // Add cloud image
                height: 60,
              ),
            ),
            Positioned(
              bottom: 100,
              left: 50,
              child: Image.asset(
                'assets/images/cloud.png', // Add cloud image
                height: 70,
              ),
            ),
            // Main content
            Column(
              children: [
                // Top bar with icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle,
                          color: Colors.brown,
                          size: 30,
                        ),
                        onPressed: () {
                          // Navigate to profile screen (placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile screen not implemented yet.')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.brown,
                          size: 30,
                        ),
                        onPressed: () {
                          // Open drawer or menu (placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Menu not implemented yet.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Hotel icon in circular gradient
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD3CCE3), Color(0xFFE9E4F0)], // Light purple gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/city.png',
                      height: 120,
                    ),
                  ),
                ),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildButton(
                        context: context,
                        text: 'Bookings',
                        icon: Icons.hotel,
                        color: const Color(0xFFD3CCE3), // Light purple shade
                        route: Routes.booking,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: 'Digital Key',
                        icon: Icons.vpn_key,
                        color: const Color(0xFFD3CCE3).withOpacity(0.9),
                        route: Routes.digitalKey,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: 'Car Rental',
                        icon: Icons.directions_car,
                        color: const Color(0xFFD3CCE3).withOpacity(0.8),
                        route: Routes.carRental,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: 'Hotel Services',
                        icon: Icons.room_service,
                        color: const Color(0xFFD3CCE3).withOpacity(0.7),
                        route: Routes.hotelServices,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}*/
