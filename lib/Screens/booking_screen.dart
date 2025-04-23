/*import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../routes.dart';
import '../utils/translations.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTimeRange? selectedDateRange;
  String? selectedHotelId;
  String city = 'Riyadh';
  List<Map<String, dynamic>> hotels = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasFetchedHotels = false;
  String _locale = 'en-gb'; // Default locale
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> placeholderImages = [
    'assets/images/hotel1.jpg',
    'assets/images/hotel2.jpg',
    'assets/images/hotel3.jpg',
  ];

  final List<Map<String, dynamic>> mockHotels = [
    {'id': '1', 'name': 'Ritz-Carlton Riyadh', 'price': 350.00, 'image': 'https://example.com/ritz-carlton-riyadh.jpg'},
    {'id': '2', 'name': 'Four Seasons Hotel Riyadh', 'price': 400.00, 'image': 'https://example.com/four-seasons-riyadh.jpg'},
    {'id': '3', 'name': 'Burj Al Rajhi Hotel', 'price': 250.00, 'image': 'https://example.com/burj-al-rajhi.jpg'},
    {'id': '4', 'name': 'Kingdom Centre Tower Hotel', 'price': 300.00, 'image': 'https://example.com/kingdom-centre-tower.jpg'},
    {'id': '5', 'name': 'Al Rajhi Grand Hotel', 'price': 280.00, 'image': 'https://example.com/al-rajhi-grand.jpg'},
  ];

  String _generateRandomRoomNumber() {
    final random = Random();
    final roomNumber = random.nextInt(900) + 100;
    return 'R.N $roomNumber';
  }


  Future<void> _fetchHotels() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String apiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';
      final String apiHost = dotenv.env['RAPIDAPI_HOST'] ?? '';

      if (apiKey.isEmpty || apiHost.isEmpty) {
        throw Exception('API key or host not found in .env file');
      }

      // Step 1: Fetch the destination ID for the city (Riyadh)
      String destId;
      try {
        destId = await _fetchDestinationId(apiHost, apiKey);
      } catch (e) {
        print('Failed to fetch destination ID: $e');
        // Fallback to a hardcoded dest_id for Riyadh
        destId = '-553173'; // Replace with the correct dest_id if known
        print('Using fallback destination ID: $destId');
      }

      // Step 2: Fetch hotels using the destination ID
      final Uri url = Uri.parse('https://$apiHost/hotels/search').replace(queryParameters: {
        'checkin_date': _formatDate(selectedDateRange?.start ?? DateTime.now()),
        'checkout_date': _formatDate(selectedDateRange?.end ?? DateTime.now().add(Duration(days: 1))),
        'dest_type': 'city',
        'dest_id': destId,
        'locale': _locale,
        'currency': 'USD',
        'adults_number': '1',
        'order_by': 'popularity',
        'units': 'metric',
      });

      print('Fetching hotels from URL: $url');

      final response = await http.get(url, headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': apiHost,
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['result'] ?? [];
        if (data.isEmpty) {
          throw Exception('No hotels found in the response');
        }
        setState(() {
          hotels = data.map((hotel) => {
            'id': hotel['hotel_id'].toString(),
            'name': hotel['hotel_name'] ?? 'Unknown Hotel',
            'price': hotel['price_breakdown']?['all_inclusive_price']?.toDouble() ??
                hotel['min_total_price']?.toDouble() ?? 0.0,
            'image': hotel['main_photo_url'] ?? placeholderImages[Random().nextInt(placeholderImages.length)],
          }).toList();
          isLoading = false;
          if (hotels.isNotEmpty) {
            print('First Hotel Data: ${hotels[0]}');
          }
        });
      } else {
        throw Exception('Failed to fetch hotels: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      setState(() {
        isLoading = false;
        hotels = mockHotels;
        errorMessage = Translations.translate('failed_to_fetch_hotels', _locale) + ': $e. ' + Translations.translate('using_mock_data', _locale);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
    }
  }

  Future<String> _fetchDestinationId(String apiHost, String apiKey) async {
    final Uri locationUrl = Uri.parse('https://$apiHost/v1/locations').replace(queryParameters: {
      'name': city,
      'locale': _locale,
    });

    print('Fetching destination ID from URL: $locationUrl');

    final response = await http.get(locationUrl, headers: {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': apiHost,
    });

    print('Destination ID response status: ${response.statusCode}');
    print('Destination ID response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final destId = data.firstWhere(
              (location) => location['dest_type'] == 'city',
          orElse: () => null,
        )?['dest_id']?.toString();
        if (destId != null) {
          return destId;
        }
        throw Exception('No city destination ID found for $city');
      } else {
        throw Exception('No destination ID found for $city');
      }
    } else {
      throw Exception('Failed to fetch destination ID: ${response.statusCode} - ${response.body}');
    }
  }




 *//* Future<void> _fetchHotels() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String apiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';
      final String apiHost = dotenv.env['RAPIDAPI_HOST'] ?? '';

      // Booking.com RapidAPI endpoint for hotels (adjust based on actual API)
      final Uri url = Uri.parse('https://$apiHost/v1/hotels/search?city=$city&checkin_date=${_formatDate(selectedDateRange?.start ?? DateTime.now())}&checkout_date=${_formatDate(selectedDateRange?.end ?? DateTime.now().add(Duration(days: 1)))}');
      final response = await http.get(url, headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': apiHost,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          hotels = data.map((hotel) => {
            'id': hotel['id'].toString(),
            'name': hotel['name'] ?? 'Unknown Hotel',
            'price': hotel['price_per_night']?.toDouble() ?? 0.0,
            'image': hotel['image_url'] ?? placeholderImages[Random().nextInt(placeholderImages.length)],
          }).toList();
          isLoading = false;
          if (hotels.isNotEmpty) {
            print('First Hotel Data: ${hotels[0]}');
          }
        });
      } else {
        throw Exception('Failed to fetch hotels: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      setState(() {
        isLoading = false;
        hotels = mockHotels; // Fallback to mock data
        errorMessage = Translations.translate('failed_to_fetch_hotels', _locale) + ': $e. ' + Translations.translate('using_mock_data', _locale);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
    }
  }*//*

  Future<void> _createBooking() async {
    if (selectedDateRange == null || selectedHotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.translate('select_dates_and_hotel', _locale))));
      return;
    }
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.translate('please_log_in', _locale))));
      return;
    }
    try {
      final selectedHotel = hotels.firstWhere((hotel) => hotel['id'].toString() == selectedHotelId);
      final hotelName = selectedHotel['name'];
      double pricePerNight = selectedHotel['price']?.toDouble() ?? 0.0;
      int nights = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      double totalPrice = pricePerNight * nights;
      String roomNumber = _generateRandomRoomNumber();
      DocumentReference bookingRef = await _firestore.collection('bookings').add({
        'userId': user.uid,
        'hotelId': selectedHotelId,
        'hotelName': hotelName,
        'pricePerNight': pricePerNight,
        'checkInDate': Timestamp.fromDate(selectedDateRange!.start),
        'checkOutDate': Timestamp.fromDate(selectedDateRange!.end),
        'totalPrice': totalPrice,
        'status': 'pending',
        'digitalKey': '',
        'paymentId': '',
        'checkedIn': false,
        'checkedOut': false,
        'roomNumber': roomNumber,
      });
      String bookingId = bookingRef.id;
      Navigator.pushNamed(context, Routes.payment, arguments: {'bookingId': bookingId, 'totalPrice': totalPrice});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.translate('error_creating_booking', _locale) + ': $e')));
    }
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb';
    });
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

  String _getMonth(int month) {
    if (_locale == 'ar') {
      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return months[month - 1];
    } else {
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return months[month - 1];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLocale();
    if (!hasFetchedHotels && hotels.isEmpty && errorMessage == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          hasFetchedHotels = true;
        });
        _fetchHotels();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TextDirection textDirection = _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
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
                      icon: const Icon(Icons.account_circle, color: Colors.brown, size: 30),
                      onPressed: () {},
                    ),
                    DropdownButton<String>(
                      value: _locale,
                      items: const [
                        DropdownMenuItem(value: 'en-gb', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('locale', value);
                          setState(() {
                            _locale = value;
                            hotels = [];
                            hasFetchedHotels = false;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.brown, size: 30),
                      onPressed: () {},
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
                          Translations.translate('available_hotels_in', _locale) + ' $city',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                const Icon(Icons.calendar_today, color: Colors.black87, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  selectedDateRange == null
                                      ? Translations.translate('select_dates', _locale)
                                      : '${selectedDateRange!.start.day} ${_getMonth(selectedDateRange!.start.month)} - ${selectedDateRange!.end.day} ${_getMonth(selectedDateRange!.end.month)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                          ),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : hotels.isEmpty && errorMessage == null
                            ? Text(Translations.translate('no_hotels_found', _locale), style: const TextStyle(fontSize: 16))
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
                              final imageUrl = hotel['image']?.toString() ?? placeholderImages[index % placeholderImages.length];
                              return GestureDetector(
                                onTap: () => setState(() => selectedHotelId = hotelId),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 200,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: selectedHotelId == hotelId ? Colors.yellow : Colors.transparent, width: 2),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: imageUrl.startsWith('http')
                                              ? Image.network(imageUrl, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey, child: const Center(child: Icon(Icons.error, color: Colors.white))))
                                              : Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey, child: const Center(child: Icon(Icons.error, color: Colors.white)))),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        width: 200,
                                        child: Text(hotelName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                            double price = hotel['price']?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(hotel['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                  Expanded(
                                    child: Text(
                                      price > 0 ? '\$${price.toStringAsFixed(2)} ' + Translations.translate('per_night', _locale) : Translations.translate('price_unavailable', _locale),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 15), minimumSize: const Size(double.infinity, 50)),
                          child: Text(Translations.translate('book_now', _locale), style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/

///////////////////

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
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
  List<Map<String, dynamic>> hotels = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasFetchedHotels = false;
  String selectedLocale = 'ar'; // Default to Arabic for Saudi Arabia
  int numberOfAdults = 1;
  String selectedRoomType = 'Standard';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> placeholderImages = [
    'assets/images/hotel1.jpg',
    'assets/images/hotel2.jpg',
    'assets/images/hotel3.jpg',
  ];

  final List<Map<String, dynamic>> mockHotels = [
    {
      'id': '1377073',
      'name': 'Sample Hotel Riyadh 1',
      'price': 120.50,
      'image': 'assets/images/hotel1.jpg',
      'room_type': 'Standard',
      'available': true,
    },
    {
      'id': '1377074',
      'name': 'Sample Hotel Riyadh 2',
      'price': 150.75,
      'image': 'assets/images/hotel2.jpg',
      'room_type': 'Deluxe',
      'available': true,
    },
    {
      'id': '1377075',
      'name': 'Sample Hotel Riyadh 3',
      'price': 200.00,
      'image': 'assets/images/hotel3.jpg',
      'room_type': 'Suite',
      'available': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: now.add(Duration(days: 1)),
      end: now.add(Duration(days: 2)),
    );
  }

  Future<void> _fetchHotels() async {
    final rapidApiKey = dotenv.env['RAPIDAPI_KEY'];
    if (rapidApiKey == null || rapidApiKey.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = selectedLocale == 'en-gb'
            ? 'RapidAPI key not found. Please add RAPIDAPI_KEY to the .env file.'
            : 'مفتاح RapidAPI غير موجود. يرجى إضافة RAPIDAPI_KEY إلى ملف .env.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      hotels = [];
      hasFetchedHotels = true;
    });

    try {
      const String destId = '-553173'; // dest_id for Riyadh

      final Uri url = Uri.parse('https://booking-com.p.rapidapi.com/v1/hotels/search').replace(queryParameters: {
        'checkin_date': _formatDate(selectedDateRange?.start ?? DateTime.now()),
        'checkout_date': _formatDate(selectedDateRange?.end ?? DateTime.now().add(Duration(days: 1))),
        'dest_type': 'city',
        'dest_id': destId,
        'locale': selectedLocale,
        'currency': 'SAR', // Use Saudi Riyal
        'filter_by_currency': 'SAR',
        'adults_number': numberOfAdults.toString(),
        'order_by': 'popularity',
        'units': 'metric',
        'room_number': '1',
      });

      print('Fetching hotels from URL: $url');

      final response = await http.get(url, headers: {
        'X-RapidAPI-Key': rapidApiKey,
        'X-RapidAPI-Host': 'booking-com.p.rapidapi.com',
      });

      print('Hotel API Response (status=${response.statusCode}):');
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['result'] ?? [];
        if (data.isEmpty) {
          throw Exception('No hotels found in the response');
        }
        setState(() {
          hotels = data.map((hotel) {
            double price = hotel['price_breakdown']?['all_inclusive_price']?.toDouble() ??
                hotel['min_total_price']?.toDouble() ??
                0.0;
            if (price == 0.0) {
              // Fallback pricing based on room type
              switch (selectedRoomType.toLowerCase()) {
                case 'standard':
                  price = 100.0;
                  break;
                case 'deluxe':
                  price = 150.0;
                  break;
                case 'suite':
                  price = 200.0;
                  break;
                default:
                  price = 100.0;
              }
            }
            return {
              'id': hotel['hotel_id']?.toString() ?? 'unknown_${Random().nextInt(1000)}',
              'name': hotel['hotel_name'] ?? 'Unknown Hotel',
              'price': price,
              'image': hotel['main_photo_url'] ?? placeholderImages[Random().nextInt(placeholderImages.length)],
              'room_type': selectedRoomType,
              'available': true,
            };
          }).toList();
          isLoading = false;
          if (hotels.isNotEmpty) {
            print('First Hotel Data: ${hotels[0]}');
          }
        });
      } else {
        throw Exception('Failed to fetch hotels: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      setState(() {
        isLoading = false;
        hotels = mockHotels;
        errorMessage = selectedLocale == 'en-gb'
            ? 'Failed to fetch hotels for $city: $e. Using mock data for now.'
            : 'فشل في جلب الفنادق لـ $city: $e. يتم استخدام بيانات وهمية الآن.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: now.add(Duration(days: 1)),
            end: now.add(Duration(days: 2)),
          ),
    );
    if (picked != null && picked != selectedDateRange) {
      final adjustedStart = picked.start.isBefore(now) ? now.add(Duration(minutes: 1)) : picked.start;
      final adjustedEnd = picked.end.isBefore(adjustedStart) ? adjustedStart.add(Duration(days: 1)) : picked.end;

      setState(() {
        selectedDateRange = DateTimeRange(start: adjustedStart, end: adjustedEnd);
        hotels = [];
        hasFetchedHotels = false;
      });
    }
  }

  Future<void> _createBooking() async {
    if (selectedDateRange == null || selectedHotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedLocale == 'en-gb' ? 'Please select dates and a hotel' : 'يرجى اختيار التواريخ والفندق'),
        ),
      );
      return;
    }

    User? user = _auth.currentUser;
    print('Current user: ${user?.uid}');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedLocale == 'en-gb' ? 'Please log in to make a booking' : 'يرجى تسجيل الدخول لإجراء الحجز'),
        ),
      );
      return;
    }

    try {
      final selectedHotel = hotels.firstWhere((hotel) => hotel['id'].toString() == selectedHotelId);
      final hotelName = selectedHotel['name'];
      final roomType = selectedHotel['room_type'] ?? 'Standard';
      double pricePerNight = selectedHotel['price']?.toDouble() ?? 0.0;
      int nights = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      if (nights <= 0) nights = 1;
      double totalPrice = pricePerNight * nights;

      String roomNumber = _generateRandomRoomNumber();
      print('Assigned room number: $roomNumber');

      DocumentReference bookingRef = await _firestore.collection('bookings').add({
        'userId': user.uid,
        'hotelId': selectedHotelId,
        'hotelName': hotelName,
        'roomType': roomType,
        'numberOfAdults': numberOfAdults,
        'pricePerNight': pricePerNight,
        'checkInDate': Timestamp.fromDate(selectedDateRange!.start),
        'checkOutDate': Timestamp.fromDate(selectedDateRange!.end),
        'totalPrice': totalPrice,
        'status': 'pending',
        'digitalKey': '',
        'paymentId': '',
        'checkedIn': false,
        'checkedOut': false,
        'roomNumber': roomNumber,
      });

      String bookingId = bookingRef.id;
      print('Booking created with bookingId: $bookingId, totalPrice: $totalPrice, roomNumber: $roomNumber');

      // Navigate to PaymentScreen
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'bookingId': bookingId,
          'totalPrice': totalPrice,
        },
      );
    } catch (e) {
      print('Error creating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedLocale == 'en-gb' ? 'Error creating booking: $e' : 'خطأ أثناء إنشاء الحجز: $e'),
        ),
      );
    }
  }

  String _generateRandomRoomNumber() {
    final random = Random();
    final roomNumber = random.nextInt(900) + 100;
    return 'R.N $roomNumber';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasFetchedHotels && hotels.isEmpty && errorMessage == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          hasFetchedHotels = true;
        });
        _fetchHotels();
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
                    icon: const Icon(Icons.account_circle, color: Colors.brown, size: 30),
                    onPressed: () {},
                  ),
                  DropdownButton<String>(
                    value: selectedLocale,
                    items: const [
                      DropdownMenuItem(value: 'en-gb', child: Text('English')),
                      DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLocale = value;
                          hotels = [];
                          hasFetchedHotels = false;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.brown, size: 30),
                    onPressed: () {},
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
                        selectedLocale == 'en-gb'
                            ? 'Available Hotels in $city'
                            : 'الفنادق المتوفرة في $city',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
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
                                    const Icon(Icons.calendar_today, color: Colors.black87, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedDateRange == null
                                          ? (selectedLocale == 'en-gb' ? 'Select Dates' : 'اختر التواريخ')
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<int>(
                              value: numberOfAdults,
                              items: List.generate(4, (index) => index + 1)
                                  .map((count) => DropdownMenuItem(
                                value: count,
                                child: Text(selectedLocale == 'en-gb'
                                    ? '$count Adult${count > 1 ? 's' : ''}'
                                    : '$count بالغ${count > 1 ? 'ون' : ''}'),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    numberOfAdults = value;
                                    hotels = [];
                                    hasFetchedHotels = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: selectedRoomType,
                              items: const [
                                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
                                DropdownMenuItem(value: 'Suite', child: Text('Suite')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedRoomType = value;
                                    hotels = [];
                                    hasFetchedHotels = false;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  hotels = [];
                                  hasFetchedHotels = false;
                                });
                                _fetchHotels();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text(
                                selectedLocale == 'en-gb' ? 'Search' : 'بحث',
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
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
                          ? Text(
                        selectedLocale == 'en-gb' ? 'No hotels found' : 'لم يتم العثور على فنادق',
                        style: const TextStyle(fontSize: 16),
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
                            final imageUrl = hotel['image']?.toString() ??
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
                                            ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                          const Center(child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) => Image.asset(
                                            placeholderImages[index % placeholderImages.length],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                            : Image.asset(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey,
                                            child: const Center(
                                              child: Icon(Icons.error, color: Colors.white),
                                            ),
                                          ),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            selectedLocale == 'en-gb'
                                ? 'Note: Prices are estimated and may vary.'
                                : 'ملاحظة: الأسعار تقديرية وقد تختلف.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (!isLoading && hotels.isNotEmpty)
                        ...hotels.map((hotel) {
                          final hotelId = hotel['id'].toString();
                          double price = hotel['price']?.toDouble() ?? 0.0;
                          final roomType = hotel['room_type'] ?? 'Standard';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${hotel['name']} ($roomType)',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    price > 0
                                        ? 'SAR ${price.toStringAsFixed(2)} ${selectedLocale == 'en-gb' ? 'per night' : 'لكل ليلة'}'
                                        : (selectedLocale == 'en-gb' ? 'Price unavailable' : 'السعر غير متوفر'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                        child: Text(
                          selectedLocale == 'en-gb' ? 'Book Now' : 'احجز الآن',
                          style: const TextStyle(
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
  }

  String _getMonth(int month) {
    if (selectedLocale == 'ar') {
      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return months[month - 1];
    } else {
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return months[month - 1];
    }
  }
}