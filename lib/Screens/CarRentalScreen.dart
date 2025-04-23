/*
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../routes.dart';
import '../utils/translations.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  DateTimeRange? selectedDateRange;
  String? selectedCarId;
  String city = 'Riyadh';
  List<Map<String, dynamic>> cars = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasFetchedCars = false;
  String _locale = 'en-gb'; // Default locale
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> placeholderImages = [
    'assets/images/car1.jpg',
    'assets/images/car2.jpg',
  ];

  final List<Map<String, dynamic>> mockCars = [
    {
      'id': 'car1',
      'name': 'Nissan Sunny',
      'color': 'Black',
      'serialNumber': 'G 30',
      'pricePerDay': 50.0,
      'imageUrl': 'https://example.com/nissan-sunny.jpg',
    },
    {
      'id': 'car2',
      'name': 'Toyota Corolla',
      'color': 'White',
      'serialNumber': 'H 45',
      'pricePerDay': 60.0,
      'imageUrl': 'https://example.com/toyota-corolla.jpg',
    },
    {
      'id': 'car3',
      'name': 'Hyundai Accent',
      'color': 'Silver',
      'serialNumber': 'J 12',
      'pricePerDay': 45.0,
      'imageUrl': 'https://example.com/hyundai-accent.jpg',
    },
    {
      'id': 'car4',
      'name': 'Ford Escape',
      'color': 'Blue',
      'serialNumber': 'K 78',
      'pricePerDay': 70.0,
      'imageUrl': 'https://example.com/ford-escape.jpg',
    },
  ];



  Future<void> _fetchCars() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String apiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';
      final String apiHost = dotenv.env['CAR_RENTAL_RAPIDAPI_HOST'] ?? '';

      if (apiKey.isEmpty || apiHost.isEmpty) {
        throw Exception('API key or car rental host not found in .env file');
      }

      final Uri url = Uri.parse('https://$apiHost/search-car-rentals').replace(queryParameters: {
        'city': city,
        'pickup_date': _formatDate(selectedDateRange?.start ?? DateTime.now()),
        'dropoff_date': _formatDate(selectedDateRange?.end ?? DateTime.now().add(Duration(days: 1))),
        'currency': 'USD',
      });

      print('Fetching cars from URL: $url');

      final response = await http.get(url, headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': apiHost,
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['results'] ?? [];
        setState(() {
          cars = data.map((car) => {
            'id': car['id'].toString(),
            'name': car['vehicle_name'] ?? 'Unknown Car',
            'color': car['color'] ?? 'Unknown',
            'serialNumber': car['serial_number'] ?? 'N/A',
            'pricePerDay': car['price_per_day']?.toDouble() ?? 0.0,
            'imageUrl': car['image_url'] ?? placeholderImages[Random().nextInt(placeholderImages.length)],
          }).toList();
          isLoading = false;
          if (cars.isNotEmpty) {
            print('First Car Data: ${cars[0]}');
          }
        });
      } else {
        throw Exception('Failed to fetch cars: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching cars: $e');
      setState(() {
        isLoading = false;
        cars = mockCars;
        errorMessage = Translations.translate('failed_to_fetch_cars', _locale) + ' $city: $e. ' + Translations.translate('using_mock_data', _locale);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }
*/
/*  Future<void> _fetchCars() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String apiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';
      final String apiHost = dotenv.env['CAR_RENTAL_RAPIDAPI_HOST'] ?? '';

      // Ensure API key and host are loaded
      if (apiKey.isEmpty || apiHost.isEmpty) {
        throw Exception('API key or car rental host not found in .env file');
      }

      // Car rental API endpoint (adjust based on actual API)
      final Uri url = Uri.parse('https://$apiHost/v1/cars').replace(queryParameters: {
        'city': city,
        'start_date': _formatDate(selectedDateRange?.start ?? DateTime.now()),
        'end_date': _formatDate(selectedDateRange?.end ?? DateTime.now().add(Duration(days: 1))),
      });

      print('Fetching cars from URL: $url'); // Debug URL

      final response = await http.get(url, headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': apiHost,
      });

      print('Response status: ${response.statusCode}'); // Debug status
      print('Response body: ${response.body}'); // Debug response

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          cars = data.map((car) => {
            'id': car['id'].toString(),
            'name': car['name'] ?? 'Unknown Car',
            'color': car['color'] ?? 'Unknown',
            'serialNumber': car['serial_number'] ?? 'N/A',
            'pricePerDay': car['price_per_day']?.toDouble() ?? 0.0,
            'imageUrl': car['image_url'] ?? placeholderImages[Random().nextInt(placeholderImages.length)],
          }).toList();
          isLoading = false;
          if (cars.isNotEmpty) {
            print('First Car Data: ${cars[0]}');
          }
        });
      } else {
        throw Exception('Failed to fetch cars: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching cars: $e');
      setState(() {
        isLoading = false;
        cars = mockCars; // Fallback to mock data
        errorMessage = Translations.translate('failed_to_fetch_cars', _locale) + ' $city: $e. ' + Translations.translate('using_mock_data', _locale);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }*//*


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
        cars = [];
        hasFetchedCars = false;
      });
    }
  }

  Future<void> _createCarReservation() async {
    if (selectedDateRange == null || selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.translate('select_dates_and_car', _locale))),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.translate('please_log_in', _locale))),
      );
      return;
    }

    try {
      final selectedCar = cars.firstWhere((car) => car['id'].toString() == selectedCarId);
      final carName = selectedCar['name'];
      final carColor = selectedCar['color'];
      final serialNumber = selectedCar['serialNumber'];
      double pricePerDay = selectedCar['pricePerDay']?.toDouble() ?? 0.0;
      int days = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      double totalPrice = pricePerDay * days;

      String parkingSpot = _generateRandomParkingSpot();

      DocumentReference reservationRef = await _firestore.collection('car_reservations').add({
        'userId': user.uid,
        'carId': selectedCarId,
        'carName': carName,
        'carColor': carColor,
        'serialNumber': serialNumber,
        'pricePerDay': pricePerDay,
        'startDate': Timestamp.fromDate(selectedDateRange!.start),
        'endDate': Timestamp.fromDate(selectedDateRange!.end),
        'totalPrice': totalPrice,
        'status': 'pending',
        'parkingSpot': parkingSpot,
        'accessed': false,
        'paymentId': '',
      });

      String reservationId = reservationRef.id;
      print('Car reservation created with reservationId: $reservationId, totalPrice: $totalPrice');

      Navigator.pushNamed(
        context,
        Routes.payment,
        arguments: {
          'reservationId': reservationId,
          'totalPrice': totalPrice,
          'isCarReservation': true,
        },
      );
    } catch (e) {
      print('Error creating car reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.translate('error_creating_reservation', _locale) + ': $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _generateRandomParkingSpot() {
    final random = Random();
    final spotNumber = random.nextInt(50) + 1;
    return 'G $spotNumber';
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb';
    });
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
    if (!hasFetchedCars && cars.isEmpty && errorMessage == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          hasFetchedCars = true;
        });
        _fetchCars();
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
                          Translations.translate('available_cars_in', _locale) + ' $city',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(
                            5,
                                (index) => const Icon(Icons.star, color: Colors.yellow, size: 20),
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
                                const Icon(Icons.calendar_today, color: Colors.black87, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  selectedDateRange == null
                                      ? Translations.translate('select_dates', _locale)
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
                            : cars.isEmpty && errorMessage == null
                            ? Text(Translations.translate('no_cars_found', _locale), style: const TextStyle(fontSize: 16))
                            : cars.isEmpty
                            ? const SizedBox()
                            : SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: cars.length,
                            itemBuilder: (context, index) {
                              final car = cars[index];
                              final carId = car['id'].toString();
                              final carName = car['name'];
                              final imageUrl = car['imageUrl'] ??
                                  placeholderImages[index % placeholderImages.length];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCarId = carId;
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
                                            color: selectedCarId == carId
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
                                            loadingBuilder:
                                                (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(
                                                  child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey,
                                                child: const Center(
                                                  child: Icon(Icons.error, color: Colors.white),
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
                                                  child: Icon(Icons.error, color: Colors.white),
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
                                          carName,
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w500),
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
                        if (!isLoading && cars.isNotEmpty)
                          ...cars.map((car) {
                            final carId = car['id'].toString();
                            double price = car['pricePerDay']?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      car['name'],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      price > 0 ? '\$${price.toStringAsFixed(2)} ' + Translations.translate('per_day', _locale) : Translations.translate('price_unavailable', _locale),
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
                          onPressed: _createCarReservation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            Translations.translate('reserve_now', _locale),
                            style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
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
      ),
    );
  }
}
*/





//////////////

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../routes.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  DateTimeRange? selectedDateRange;
  String? selectedCarId;
  String city = 'Riyadh';
  List<dynamic> cars = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasFetchedCars = false;
  int currentPage = 1;
  bool hasMoreData = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String carRentalApiHost;
  ScrollController _scrollController = ScrollController();

  final Map<String, Map<String, double>> cityCoordinates = {
    'Riyadh': {
      'latitude': 24.7136,
      'longitude': 46.6753,
    },
  };

  final List<dynamic> mockCars = [
    {
      'id': 'car1',
      'name': 'Nissan',
      'serialNumber': 'G 30',
      'pricePerDay': 50.0,
      'imageUrl': 'assets/images/car1.jpg',
    },
    {
      'id': 'car2',
      'name': 'Toyota',
      'serialNumber': 'H 45',
      'pricePerDay': 60.0,
      'imageUrl': 'assets/images/car2.jpg',
    },
  ];

  final List<String> placeholderImages = [
    'assets/images/car1.jpg',
    'assets/images/car2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    carRentalApiHost = dotenv.env['CAR_RENTAL_API_HOST'] ?? 'booking-com.p.rapidapi.com';
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: now.add(Duration(days: 1)),
      end: now.add(Duration(days: 2)),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
        _fetchCars(dotenv.env['CAR_RENTAL_API_KEY']!, loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _loadApiKey() async {
    try {
      final apiKey = dotenv.env['CAR_RENTAL_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('CAR_RENTAL_API_KEY not found in .env file.');
      }
      return apiKey;
    } catch (e) {
      print('Error loading API key: $e');
      throw Exception('Failed to load API key: $e');
    }
  }

  Future<void> _fetchCars(String apiKey, {bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        cars = [];
        currentPage = 1;
        hasMoreData = true;
      });
    } else if (!hasMoreData) {
      return;
    }

    try {
      final pickUpDate = selectedDateRange?.start ?? DateTime.now().add(Duration(days: 1));
      final dropOffDate = selectedDateRange?.end ?? DateTime.now().add(Duration(days: 2));

      final coordinates = cityCoordinates[city] ?? {
        'latitude': 24.7136,
        'longitude': 46.6753,
      };

      final carUri = Uri.parse('https://$carRentalApiHost/v1/car-rental/search').replace(
        queryParameters: {
          'pick_up_datetime': _formatDateTime(pickUpDate),
          'drop_off_datetime': _formatDateTime(dropOffDate),
          'loc_id_from': '1042171',
          'loc_id_to': '1042171',
          'pick_up_latitude': coordinates['latitude'].toString(),
          'pick_up_longitude': coordinates['longitude'].toString(),
          'drop_off_latitude': coordinates['latitude'].toString(),
          'drop_off_longitude': coordinates['longitude'].toString(),
          'currency': 'SAR',
          'locale': 'ar',
          'sort_by': 'price_low_to_high',
          'from_country': 'ar',
          'client_country': 'sa',
          'page': currentPage.toString(),
        },
      );

      print('Fetching cars from URL: $carUri');

      final carResponse = await http.get(
        carUri,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': carRentalApiHost,
        },
      );

      print('Car API Response (status=${carResponse.statusCode}):');
      print('Response Body: ${carResponse.body}');
      final carData = jsonDecode(carResponse.body);
      print('Response Keys: ${carData.keys}');

      if (carResponse.statusCode == 200) {
        List<dynamic>? results = carData['search_results'];
        int totalCount = carData['count'] ?? 0;

        if (results == null || results.isEmpty) {
          print('No car data found in search_results. Response count: ${carData['count']}');
          setState(() {
            isLoading = false;
            errorMessage = 'No cars available for $city on the selected dates.';
            hasMoreData = false;
          });
          return;
        }

        print('First car in search_results: ${results[0]}');

        List<Map<String, dynamic>> mappedCars = results.map((car) {
          print('vehicle_info: ${car['vehicle_info']}');
          print('price_info: ${car['price_info']}');

          return {
            'id': car['vehicle_info']?['v_id']?.toString() ?? 'car_${Random().nextInt(1000)}',
            'name': car['vehicle_info']?['v_name'] ?? 'Unknown Car',
            'serialNumber': car['vehicle_info']?['license_plate'] ?? 'G ${Random().nextInt(50) + 1}',
            'pricePerDay': _calculatePricePerDay(
              car['price_info']?['total_price'] ?? car['price_info']?['price'] ?? car['price'],
              pickUpDate,
              dropOffDate,
              car,
            ),
            'imageUrl': car['vehicle_info']?['image']?['url'] ??
                car['vehicle_info']?['images']?.first?['url'] ??
                car['vehicle_info']?['image_url'] ??
                car['supplier_info']?['logo_url'] ??
                placeholderImages[Random().nextInt(placeholderImages.length)],
          };
        }).toList();

        setState(() {
          cars.addAll(mappedCars);
          isLoading = false;
          currentPage++;
          hasMoreData = cars.length < totalCount;
          if (cars.isNotEmpty) {
            print('First Car Data: ${cars[0]}');
          }
        });
      } else {
        final errorBody = jsonDecode(carResponse.body);
        final errorDetails = errorBody['detail']?.map((e) => e['msg']).join(', ') ?? 'Unknown error';
        throw Exception('Failed to load cars: ${carResponse.statusCode} - $errorDetails');
      }
    } catch (e) {
      print('Error fetching cars: $e');
      setState(() {
        isLoading = false;
        cars = mockCars;
        errorMessage = 'Failed to fetch cars for $city: $e. Using mock data for now.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  double _calculatePricePerDay(dynamic priceData, DateTime start, DateTime end, Map<String, dynamic> car) {
    try {
      if (priceData != null) {
        double totalPrice = double.tryParse(priceData.toString()) ?? 50.0;
        int days = end.difference(start).inDays;
        if (days <= 0) days = 1;
        return totalPrice / days;
      }

      // Fallback pricing based on car category
      String? category = car['vehicle_info']?['group']?.toString().toLowerCase();
      if (category == null) return 50.0;

      switch (category) {
        case 'mini':
          return 40.0;
        case 'economy':
          return 50.0;
        case 'compact':
          return 60.0;
        case 'standard':
          return 70.0;
        case 'luxury':
          return 100.0;
        default:
          return 50.0;
      }
    } catch (e) {
      return 50.0;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00';
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
      final adjustedStart = picked.start.isBefore(now)
          ? now.add(Duration(minutes: 1))
          : picked.start;
      final adjustedEnd = picked.end.isBefore(adjustedStart)
          ? adjustedStart.add(Duration(days: 1))
          : picked.end;

      setState(() {
        selectedDateRange = DateTimeRange(start: adjustedStart, end: adjustedEnd);
        cars = [];
        hasFetchedCars = false;
        currentPage = 1;
        hasMoreData = true;
      });
    }
  }

  Future<void> _createCarReservation() async {
    if (selectedDateRange == null || selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates and a car')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a reservation')),
      );
      return;
    }

    try {
      final selectedCar = cars.firstWhere((car) => car['id'].toString() == selectedCarId);
      final carName = selectedCar['name'];
      final serialNumber = selectedCar['serialNumber'];
      double pricePerDay = selectedCar['pricePerDay'] ?? 0.0;
      int days = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;
      double totalPrice = pricePerDay * days;

      String parkingSpot = _generateRandomParkingSpot();

      DocumentReference reservationRef = await _firestore.collection('car_reservations').add({
        'userId': user.uid,
        'carId': selectedCarId,
        'carName': carName,
        'serialNumber': serialNumber,
        'pricePerDay': pricePerDay,
        'startDate': Timestamp.fromDate(selectedDateRange!.start),
        'endDate': Timestamp.fromDate(selectedDateRange!.end),
        'totalPrice': totalPrice,
        'status': 'pending',
        'parkingSpot': parkingSpot,
        'accessed': false,
      });

      String reservationId = reservationRef.id;
      Navigator.pushNamed(
        context,
        Routes.carReservationConfirmation,
        arguments: {'reservationId': reservationId},
      );
    } catch (e) {
      print('Error creating car reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating car reservation: $e')),
      );
    }
  }

  String _generateRandomParkingSpot() {
    final random = Random();
    final spotNumber = random.nextInt(50) + 1;
    return 'G $spotNumber';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadApiKey(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading API key: ${snapshot.error}\nPlease ensure the .env file exists.',
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
                'API key not found. Please add CAR_RENTAL_API_KEY to the .env file.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!hasFetchedCars && cars.isEmpty && errorMessage == null && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                hasFetchedCars = true;
              });
              _fetchCars(snapshot.data!);
            }
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
                            'Available Cars in $city',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(
                              5,
                                  (index) => Icon(Icons.star, color: Colors.yellow, size: 20),
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
                                  const Icon(Icons.calendar_today, color: Colors.black87, size: 20),
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
                          isLoading && cars.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : cars.isEmpty && errorMessage == null
                              ? const Text('No cars found', style: TextStyle(fontSize: 16))
                              : cars.isEmpty
                              ? const SizedBox()
                              : SizedBox(
                            height: 180,
                            child: ListView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: cars.length + (hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == cars.length && hasMoreData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final car = cars[index];
                                final carId = car['id'].toString();
                                final carName = car['name'];
                                final imageUrl = car['imageUrl'] ??
                                    placeholderImages[index % placeholderImages.length];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCarId = carId;
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
                                              color: selectedCarId == carId
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
                                              placeholder: (context, url) => const Center(
                                                  child: CircularProgressIndicator()),
                                              errorWidget: (context, url, error) => Image.asset(
                                                placeholderImages[
                                                index % placeholderImages.length],
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                                : Image.asset(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
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
                                            carName,
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
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
                          if (!isLoading && cars.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Note: Prices are estimated and may vary.',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (!isLoading && cars.isNotEmpty)
                            ...cars.map((car) {
                              final carId = car['id'].toString();
                              double price = car['pricePerDay'] ?? 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        car['name'],
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '\$${price.toStringAsFixed(2)}/day',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _createCarReservation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Reserve Now',
                              style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
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
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}