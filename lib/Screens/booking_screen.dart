import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        hotels = mockHotels;
        isLoading = false;
        if (hotels.isNotEmpty) print('First Hotel Data: ${hotels[0]}');
      });
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
}


/*
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
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
  List<Map<String, dynamic>> hotels = []; // To store hotel names, images, and rates
  bool isLoading = false;
  String? errorMessage;
  bool hasFetchedHotels = false;
  String selectedLocale = 'en-gb'; // Default to English (supports multi-language)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> placeholderImages = [
    'assets/images/hotel1.jpg',
    'assets/images/hotel2.jpg',
    'assets/images/hotel3.jpg',
  ];

  // Mock data for hotels (since /hotels/search-by-location is not accessible)
  final List<Map<String, dynamic>> mockHotels = [
    {
      'id': '1377073',
      'name': 'Sample Hotel Riyadh 1',
      'price': 120.50,
      'image': 'https://example.com/hotel-image1.jpg',
    },
    {
      'id': '1377074',
      'name': 'Sample Hotel Riyadh 2',
      'price': 150.75,
      'image': 'https://example.com/hotel-image2.jpg',
    },
    {
      'id': '1377075',
      'name': 'Sample Hotel Riyadh 3',
      'price': 200.00,
      'image': 'https://example.com/hotel-image3.jpg',
    },
  ];

  // Function to generate a random room number
  String _generateRandomRoomNumber() {
    final random = Random();
    final roomNumber = random.nextInt(900) + 100; // Generates a number between 100 and 999
    return 'R.N $roomNumber';
  }

  Future<void> _fetchHotels() async {
    // Load API key from .env
    final rapidApiKey = dotenv.env['RAPIDAPI_KEY'];
    if (rapidApiKey == null || rapidApiKey.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage =
        'RapidAPI key not found. Please add RAPIDAPI_KEY to the .env file.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Test the /hotels/description endpoint with a sample hotel ID
      final hotelUri = Uri.https(
        'booking-com.p.rapidapi.com',
        '/v2/hotels/description',
        {
          'locale': selectedLocale,
          'hotel_id': '1377073', // Sample hotel ID
        },
      );

      final hotelResponse = await http.get(
        hotelUri,
        headers: {
          'X-RapidAPI-Key': rapidApiKey,
          'X-RapidAPI-Host': 'booking-com.p.rapidapi.com',
        },
      );

      print('Hotel API Response (status=${hotelResponse.statusCode}):');
      print(hotelResponse.body);

      if (hotelResponse.statusCode == 200) {
        // Since /hotels/description only gives description and not name, image, or price,
        // we'll use mock data for now
        setState(() {
          hotels = mockHotels;
          isLoading = false;
          if (hotels.isNotEmpty) {
            print('First Hotel Data: ${hotels[0]}');
          }
        });
      } else {
        throw Exception('Failed to load hotel description: ${hotelResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      setState(() {
        isLoading = false;
        hotels = mockHotels;
        errorMessage =
        'Failed to fetch hotels for $city: $e. Using mock data for now.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
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
      final selectedHotel =
      hotels.firstWhere((hotel) => hotel['id'].toString() == selectedHotelId);
      final hotelName = selectedHotel['name'];
      double pricePerNight = selectedHotel['price']?.toDouble() ?? 0.0;
      int nights = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      double totalPrice = pricePerNight * nights;

      // Generate a random room number
      String roomNumber = _generateRandomRoomNumber();
      print('Assigned room number: $roomNumber');

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
      print(
          'Booking created with bookingId: $bookingId, totalPrice: $totalPrice, roomNumber: $roomNumber');

      Navigator.pushNamed(
        context,
        Routes.bookingConfirmation,
        arguments: {'bookingId': bookingId},
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
                    icon: const Icon(
                      Icons.account_circle,
                      color: Colors.brown,
                      size: 30,
                    ),
                    onPressed: () {
                      // Navigate to profile screen (placeholder)
                    },
                  ),
                  DropdownButton<String>(
                    value: selectedLocale,
                    items: const [
                      DropdownMenuItem(
                        value: 'en-gb',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text('Arabic'),
                      ),
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
                        selectedLocale == 'en-gb'
                            ? 'Available Hotels in $city'
                            : 'الفنادق المتوفرة في $city',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                                    ? (selectedLocale == 'en-gb'
                                    ? 'Select Dates'
                                    : 'اختر التواريخ')
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
                          ? Text(
                        selectedLocale == 'en-gb'
                            ? 'No hotels found'
                            : 'لم يتم العثور على فنادق',
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
                                placeholderImages[
                                index % placeholderImages.length];
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
                                        borderRadius:
                                        BorderRadius.circular(15),
                                        border: Border.all(
                                          color: selectedHotelId == hotelId
                                              ? Colors.yellow
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(15),
                                        child: imageUrl.startsWith('http')
                                            ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return const Center(
                                              child: CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                          double price = hotel['price']?.toDouble() ?? 0.0;
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
                                    price > 0
                                        ? '\$${price.toStringAsFixed(2)} per night'
                                        : (selectedLocale == 'en-gb'
                                        ? 'Price unavailable'
                                        : 'السعر غير متوفر'),
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
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      return months[month - 1];
    } else {
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC'
      ];
      return months[month - 1];
    }
  }
}*/
