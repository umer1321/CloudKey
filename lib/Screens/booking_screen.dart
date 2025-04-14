import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudkey/Screens/payment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  String? errorMessage;
  bool hasFetchedHotels = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String apiHost = 'hotels-com-provider.p.rapidapi.com';

  final List<String> placeholderImages = [
    'assets/images/hotel1.jpg',
    'assets/images/hotel2.jpg',
    'assets/images/hotel3.jpg',
  ];

  // Mock data for hotels (temporary fallback)
  final List<dynamic> mockHotels = [
    {
      'id': 'mock1',
      'name': 'Mock Hotel 1',
      'ratePlan': {
        'price': {'exactCurrent': 100.0}
      },
      'optimizedThumbUrls': {
        'srpDesktop': 'https://example.com/mock-hotel1.jpg'
      }
    },
    {
      'id': 'mock2',
      'name': 'Mock Hotel 2',
      'ratePlan': {
        'price': {'exactCurrent': 150.0}
      },
      'optimizedThumbUrls': {
        'srpDesktop': 'https://example.com/mock-hotel2.jpg'
      }
    },
  ];

  Future<String> _loadApiKey() async {
    try {
      final apiKey = dotenv.env['RAPIDAPI_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('RAPIDAPI_KEY not found in .env file. Please add it to the .env file in the project root.');
      }
      return apiKey;
    } catch (e) {
      print('Error loading API key: $e');
      throw Exception('Failed to load API key: $e');
    }
  }

  Future<void> _fetchRegionIdAndHotels(String apiKey) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? successfulDomain;

    try {
      const domainsToTry = ['XE', 'US'];

      for (String domain in domainsToTry) {
        try {
          final regionUri = Uri.https(
            'hotels-com-provider.p.rapidapi.com',
            '/v2/regions',
            {
              'query': city,
              'domain': domain,
              'locale': domain == 'XE' ? 'en_IE' : 'en_US',
            },
          );

          final regionResponse = await http.get(
            regionUri,
            headers: {
              'X-RapidAPI-Key': apiKey,
              'X-RapidAPI-Host': apiHost,
            },
          );

          if (regionResponse.statusCode == 200) {
            final regionData = jsonDecode(regionResponse.body);
            print('Region API Full Response (domain=$domain): $regionData');
            final regionList = regionData['data'] as List?;
            if (regionList == null || regionList.isEmpty) {
              throw Exception('No regions found for $city with domain $domain');
            }

            final rawRegionId = regionList[0]['gaiaId'] ?? regionList[0]['regionId'];
            print('Raw regionId: $rawRegionId');
            if (rawRegionId == null) {
              throw Exception('Region ID is null for $city with domain $domain');
            }
            if (rawRegionId is int) {
              regionId = rawRegionId.toString();
            } else if (rawRegionId is String && int.tryParse(rawRegionId) != null) {
              regionId = rawRegionId;
            } else if (rawRegionId is double) {
              regionId = rawRegionId.toInt().toString();
            } else {
              throw Exception('Invalid regionId format: $rawRegionId');
            }
            print('Parsed regionId: $regionId');
            successfulDomain = domain;
            break;
          } else {
            print('Region API Response (domain=$domain): ${regionResponse.body}');
            throw Exception('Failed to load region ID for $city with domain $domain: ${regionResponse.statusCode}');
          }
        } catch (e) {
          if (domain == domainsToTry.last) {
            throw Exception('Failed to load region ID after trying all domains: $e');
          }
          print('Trying next domain due to error: $e');
          continue;
        }
      }

      if (regionId != null && successfulDomain != null) {
        final checkInDate = selectedDateRange?.start ?? DateTime.now();
        final checkOutDate = selectedDateRange?.end ?? DateTime.now().add(const Duration(days: 1));

        final hotelUri = Uri.https(
          'hotels-com-provider.p.rapidapi.com',
          '/v2/hotels/search',
          {
            'domain': successfulDomain,
            'sort_order': 'RECOMMENDED',
            'locale': successfulDomain == 'XE' ? 'en_IE' : 'en_US',
            'currency': 'USD',
            'checkin_date': _formatDate(checkInDate),
            'checkout_date': _formatDate(checkOutDate),
            'region_id': regionId!,
            'adults_number': '1',
            'guest_rating_min': '7',
          },
        );

        final hotelResponse = await http.get(
          hotelUri,
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': apiHost,
          },
        );

        print('Hotel API Response (status=${hotelResponse.statusCode}):');
        print(hotelResponse.body);

        if (hotelResponse.statusCode == 200) {
          final hotelData = jsonDecode(hotelResponse.body);
          List<dynamic>? results;
          if (hotelData['properties'] != null) {
            results = hotelData['properties'];
          } else if (hotelData['results'] != null) {
            results = hotelData['results'];
          } else {
            throw Exception('Hotel API response missing "properties" or "results" field');
          }

          if (results == null || results.isEmpty) {
            throw Exception('No hotels found in the response');
          }

          setState(() {
            hotels = results!;
            isLoading = false;
            if (hotels.isNotEmpty) {
              print('First Hotel Data: ${hotels[0]}');
            }
          });
        } else {
          throw Exception('Failed to load hotels: ${hotelResponse.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      setState(() {
        isLoading = false;
        hotels = mockHotels;
        errorMessage = 'Failed to fetch hotels for $city: $e. Using mock data for now.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hotels: $e. Using mock data.')),
      );
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
        hotels = [];
        hasFetchedHotels = false;
      });
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
    print('Current user: ${user?.uid}');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a booking')),
      );
      return;
    }

    try {
      final selectedHotel = hotels.firstWhere((hotel) => hotel['id'].toString() == selectedHotelId);
      final hotelName = selectedHotel['name'];
      double pricePerNight = 0.0;
      if (selectedHotel['mapMarker']?['label'] != null) {
        String priceLabel = selectedHotel['mapMarker']['label'];
        priceLabel = priceLabel.replaceAll(RegExp(r'[^0-9.]'), '');
        pricePerNight = double.tryParse(priceLabel) ?? 0.0;
      }
      int nights = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      double totalPrice = pricePerNight * nights;

      DocumentReference bookingRef = await _firestore.collection('bookings').add({
        'userId': user.uid,
        'hotelId': selectedHotelId,
        'hotelName': hotelName,
        'pricePerNight': pricePerNight,
        'amenities': selectedHotel['amenities']?.map((a) => a['description']).toList() ?? ['WiFi', 'TV'],
        'checkInDate': Timestamp.fromDate(selectedDateRange!.start),
        'checkOutDate': Timestamp.fromDate(selectedDateRange!.end),
        'totalPrice': totalPrice,
        'status': 'pending',
        'digitalKey': '',
        'paymentId': '',
      });

      // Log the arguments before navigation
      print('Navigating to PaymentScreen with bookingId: ${bookingRef.id}, totalPrice: $totalPrice');

      // Navigate using constructor parameters
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            bookingId: bookingRef.id,
            totalPrice: totalPrice,
          ),
        ),
      );
      print('Navigation to PaymentScreen completed');
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
    return FutureBuilder<String>(
      future: _loadApiKey(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading API key: ${snapshot.error}\nPlease ensure the .env file exists in the project root with a valid RAPIDAPI_KEY.',
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'API key not found. Please add RAPIDAPI_KEY to the .env file.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!hasFetchedHotels && hotels.isEmpty && errorMessage == null && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              hasFetchedHotels = true;
            });
            _fetchRegionIdAndHotels(snapshot.data!);
          });
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Hotels in $city',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(
                              5,
                                  (index) => const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => _selectDateRange(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
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
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : hotels.isEmpty && errorMessage == null
                              ? const Text(
                            'No hotels found',
                            style: TextStyle(fontSize: 16),
                          )
                              : hotels.isEmpty
                              ? const SizedBox()
                              : SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: hotels.length,
                              itemBuilder: (context, index) {
                                final hotel = hotels[index];
                                final hotelId = hotel['id'].toString();
                                final hotelName = hotel['name'];
                                final imageUrl = hotel['propertyImage']?['image']?['url']?.toString() ??
                                    placeholderImages[index % placeholderImages.length];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedHotelId = hotelId;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 15),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 200,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: selectedHotelId == hotelId
                                                  ? Colors.yellow
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: imageUrl.startsWith('http')
                                                ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: CircularProgressIndicator(),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                                : Image.asset(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        SizedBox(
                                          width: 200,
                                          child: Text(
                                            hotelName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!isLoading && hotels.isNotEmpty)
                            ...hotels.map((hotel) {
                              final hotelId = hotel['id'].toString();
                              double price = 0.0;
                              if (hotel['mapMarker']?['label'] != null) {
                                String priceLabel = hotel['mapMarker']['label'];
                                priceLabel = priceLabel.replaceAll(RegExp(r'[^0-9.]'), '');
                                price = double.tryParse(priceLabel) ?? 0.0;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hotel['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        price > 0 ? '\$${price.toStringAsFixed(2)} per night' : 'Price unavailable',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _createBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
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
              ],
            ),
          ),
        );
      },
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