import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../routes.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTimeRange? selectedDateRange;
  String? selectedHotelId;
  String city = 'Riyadh';
  String? regionId;
  List<dynamic> hotels = [];
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Replace with your new API key (stored securely)
  final String apiKey = 'ce933af03amshabbc6a35511223dp1a748djsn095433b0ec40';
  final String apiHost = 'hotels-com-provider.p.rapidapi.com';

  @override
  void initState() {
    super.initState();
    _fetchRegionIdAndHotels();
  }

  Future<void> _fetchRegionIdAndHotels() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Step 1: Fetch the region ID for Riyadh
      final regionResponse = await http.get(
        Uri.parse('https://hotels-com-provider.p.rapidapi.com/v2/regions?query=$city&domain=US&locale=en_US'),
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      if (regionResponse.statusCode == 200) {
        final regionData = jsonDecode(regionResponse.body);
        final regionList = regionData['data'] as List;
        if (regionList.isNotEmpty) {
          setState(() {
            regionId = regionList[0]['regionId'].toString();
          });
        } else {
          throw Exception('No region found for $city');
        }
      } else {
        print('Region API Response: ${regionResponse.body}');
        throw Exception('Failed to load region ID: ${regionResponse.statusCode}');
      }

      // Step 2: Fetch hotels using the region ID
      if (regionId != null) {
        // Use selected dates if available, otherwise use default dates
        final checkInDate = selectedDateRange?.start ?? DateTime.now();
        final checkOutDate = selectedDateRange?.end ?? DateTime.now().add(const Duration(days: 1));

        final hotelResponse = await http.get(
          Uri.parse(
              'https://hotels-com-provider.p.rapidapi.com/v2/hotels/search'
                  '?domain=US'
                  '&sort_order=RECOMMENDED'
                  '&locale=en_US'
                  '&currency=USD'
                  '&checkin_date=${_formatDate(checkInDate)}'
                  '&checkout_date=${_formatDate(checkOutDate)}'
                  '&region_id=$regionId'
                  '&adults_number=1' // Added required parameter
                  '&guest_rating_min=7' // Optional: Filter for better-rated hotels
          ),
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': apiHost,
          },
        );

        if (hotelResponse.statusCode == 200) {
          final hotelData = jsonDecode(hotelResponse.body);
          setState(() {
            hotels = hotelData['data']['body']['searchResults']['results'];
            isLoading = false;
          });
        } else {
          print('Hotel API Response: ${hotelResponse.body}');
          throw Exception('Failed to load hotels: ${hotelResponse.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hotels: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedDateRange,
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
      // Refresh hotels with the new dates
      _fetchRegionIdAndHotels();
    }
  }

  Future<void> _createBooking() async {
    if (selectedDateRange == null || selectedHotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates and a hotel')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a booking')),
      );
      return;
    }

    try {
      // Find the selected hotel
      final selectedHotel = hotels.firstWhere((hotel) => hotel['id'].toString() == selectedHotelId);
      final hotelName = selectedHotel['name'];
      final ratePlan = selectedHotel['ratePlan'];
      double pricePerNight = ratePlan != null && ratePlan['price'] != null
          ? ratePlan['price']['exactCurrent'].toDouble()
          : 0.0;
      int nights = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      double totalPrice = pricePerNight * nights;

      // Create or update room in Firestore
      DocumentReference roomRef = await _firestore.collection('rooms').add({
        'roomNumber': selectedHotelId,
        'type': hotelName,
        'price': pricePerNight,
        'amenities': selectedHotel['amenities']?.map((a) => a['description']).toList() ?? ['WiFi', 'TV'],
        'availability': {
          selectedDateRange!.start.toIso8601String().split('T')[0]: false,
          selectedDateRange!.end.toIso8601String().split('T')[0]: false,
        },
      });

      // Create a booking
      DocumentReference bookingRef = await _firestore.collection('bookings').add({
        'userId': user.uid,
        'roomId': roomRef.id,
        'checkInDate': Timestamp.fromDate(selectedDateRange!.start),
        'checkOutDate': Timestamp.fromDate(selectedDateRange!.end),
        'totalPrice': totalPrice,
        'status': 'pending',
        'digitalKey': '',
        'paymentId': '',
      });

      // Navigate to PaymentScreen with booking details
      Navigator.pushNamed(
        context,
        Routes.payment,
        arguments: {
          'bookingId': bookingRef.id,
          'totalPrice': totalPrice,
        },
      );
    } catch (e) {
      print('Error creating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating booking: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image (with error handling)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Fallback to a network image if asset fails
                  const NetworkImage('https://via.placeholder.com/150');
                },
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.3),
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
                      },
                    ),
                  ],
                ),
              ),
              // Main content centered
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            'Available Hotels in $city',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Date range selector
                          GestureDetector(
                            onTap: () => _selectDateRange(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD3CCE3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedDateRange == null
                                        ? 'Select Dates'
                                        : '${selectedDateRange!.start.day} ${_getMonth(selectedDateRange!.start.month)} - ${selectedDateRange!.end.day} ${_getMonth(selectedDateRange!.end.month)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Hotel list
                          isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : hotels.isEmpty
                              ? const Text(
                            'No hotels found',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          )
                              : Column(
                            children: hotels.map((hotel) {
                              final hotelId = hotel['id'].toString();
                              final price = hotel['ratePlan']?['price']?['exactCurrent']?.toDouble() ?? 0.0;
                              final starRating = hotel['starRating']?.toDouble() ?? 0.0;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedHotelId = hotelId;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: selectedHotelId == hotelId
                                        ? Colors.yellow.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hotel['name'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            price > 0 ? 'Price: \$${price.toStringAsFixed(2)}/night' : 'Price unavailable',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(
                                          starRating.round(),
                                              (index) => const Icon(
                                            Icons.star,
                                            color: Colors.yellow,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 30),
                          // Book Now button
                          ElevatedButton(
                            onPressed: _createBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD3CCE3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}