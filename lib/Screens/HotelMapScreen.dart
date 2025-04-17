import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';

class HotelMapScreen extends StatefulWidget {
  const HotelMapScreen({super.key});

  @override
  State<HotelMapScreen> createState() => _HotelMapScreenState();
}

class _HotelMapScreenState extends State<HotelMapScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> pointsOfInterest = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPointsOfInterest();
  }

  Future<void> _fetchPointsOfInterest() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Check if user is authenticated
      User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please log in to view the hotel map.';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, Routes.auth);
        });
        return;
      }

      QuerySnapshot snapshot = await _firestore.collection('points_of_interest').get();
      pointsOfInterest = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading map data: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading map data: $e')),
      );
    }
  }

  void _handlePoiTap(Map<String, dynamic> poi) {
    String action = poi['action'] ?? '';
    String poiName = poi['name'] ?? 'Unknown';

    if (action == 'order') {
      // Navigate to ServicesScreen for room service ordering
      Navigator.pushNamed(
        context,
        Routes.hotelServices,
        arguments: {'poiName': poiName},
      );
    } else if (action == 'reserve') {
      // Navigate to ReservationScreen for booking
      Navigator.pushNamed(
        context,
        Routes.reservation,
        arguments: {'poiName': poiName},
      );
    } else {
      // Show POI details in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(poiName),
          content: Text(poi['description'] ?? 'No description available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Map'),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(0.5, 0.5),
              initialZoom: 1.0,
              minZoom: 0.5,
              maxZoom: 3.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'assets/images/hotel_map/{z}/{x}/{y}.png',
                tileProvider: AssetTileProvider(),
                userAgentPackageName: 'com.example.hotel_booking_app',
                tileBounds: LatLngBounds(
                  const LatLng(0, 0),
                  const LatLng(1, 1),
                ),
              ),
              MarkerLayer(
                markers: pointsOfInterest.map((poi) {
                  return Marker(
                    point: LatLng(
                      poi['latitude'] ?? 0.5,
                      poi['longitude'] ?? 0.5,
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _handlePoiTap(poi),
                      child: Icon(
                        _getIconForPoiType(poi['type']),
                        color: Colors.brown,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (errorMessage != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                color: Colors.red.withOpacity(0.8),
                padding: const EdgeInsets.all(10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForPoiType(String? type) {
    switch (type) {
      case 'restaurant':
        return Icons.restaurant;
      case 'amenity':
        return Icons.fitness_center; // Use different icons for gym, pool, etc., in a real app
      default:
        return Icons.place;
    }
  }
}

class AssetTileProvider extends TileProvider {
  AssetTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    return const AssetImage('assets/images/hotel_map.png');
  }
}