import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> cars = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasFetchedCars = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> placeholderImages = [
    'assets/images/car1.jpg',
    'assets/images/car2.jpg',
  ];

  // Mock data with real car rental details for Riyadh
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
      // Simulate fetching cars with mock data
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      setState(() {
        cars = mockCars;
        isLoading = false;
        if (cars.isNotEmpty) {
          print('First Car Data: ${cars[0]}');
        }
      });
    } catch (e) {
      print('Error fetching cars: $e');
      setState(() {
        isLoading = false;
        cars = mockCars;
        errorMessage = 'Failed to fetch cars for $city: $e. Using mock data.';
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
        cars = [];
        hasFetchedCars = false;
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
        'paymentId': '', // Add paymentId field for later update
      });

      String reservationId = reservationRef.id;
      print('Car reservation created with reservationId: $reservationId, totalPrice: $totalPrice');

      // Navigate to PaymentScreen instead of CarReservationConfirmationScreen
      Navigator.pushNamed(
        context,
        Routes.payment,
        arguments: {
          'reservationId': reservationId, // Pass reservationId instead of bookingId
          'totalPrice': totalPrice,
          'isCarReservation': true, // Add a flag to indicate this is a car reservation
        },
      );
    } catch (e) {
      print('Error creating car reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating car reservation: $e')),
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

  @override
  Widget build(BuildContext context) {
    if (!hasFetchedCars && cars.isEmpty && errorMessage == null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          hasFetchedCars = true;
        });
        _fetchCars();
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
                          : cars.isEmpty && errorMessage == null
                          ? const Text('No cars found', style: TextStyle(fontSize: 16))
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
                                    price > 0 ? '\$${price.toStringAsFixed(2)} per day' : 'Price unavailable',
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
  }

  String _getMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}






//////////////

/*
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String apiHost = 'booking-com15.p.rapidapi.com';

  final List<dynamic> mockCars = [
    {
      'id': 'car1',
      'name': 'Nissan',
      'color': 'Black',
      'serialNumber': 'G 30',
      'pricePerDay': 50.0,
      'imageUrl': 'https://example.com/nissan.jpg',
    },
    {
      'id': 'car2',
      'name': 'Toyota',
      'color': 'White',
      'serialNumber': 'H 45',
      'pricePerDay': 60.0,
      'imageUrl': 'https://example.com/toyota.jpg',
    },
  ];

  final List<String> placeholderImages = [
    'assets/images/car1.jpg',
    'assets/images/car2.jpg',
  ];

  Future<String> _loadApiKey() async {
    try {
      final apiKey = dotenv.env['RAPIDAPI_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('RAPIDAPI_KEY not found in .env file.');
      }
      return apiKey;
    } catch (e) {
      print('Error loading API key: $e');
      throw Exception('Failed to load API key: $e');
    }
  }

  Future<void> _fetchCars(String apiKey) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pickUpDate = selectedDateRange?.start ?? DateTime.now();
      final dropOffDate = selectedDateRange?.end ?? DateTime.now().add(const Duration(days: 1));

      final carUri = Uri.https(
        'booking-com15.p.rapidapi.com',
        '/cars/search',
        {
          'city': city,
          'pickup_date': _formatDate(pickUpDate),
          'dropoff_date': _formatDate(dropOffDate),
          'currency': 'USD',
        },
      );

      final carResponse = await http.get(
        carUri,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      print('Car API Response (status=${carResponse.statusCode}):');
      print(carResponse.body);

      if (carResponse.statusCode == 200) {
        final carData = jsonDecode(carResponse.body);
        List<dynamic>? results = carData['cars'] ?? carData['results'];

        if (results == null || results.isEmpty) {
          throw Exception('No cars found in the response');
        }

        List<Map<String, dynamic>> mappedCars = results.map((car) {
          return {
            'id': car['id']?.toString() ?? 'car_${Random().nextInt(1000)}',
            'name': car['vehicle_name'] ?? car['vehicleType'] ?? 'Unknown Car',
            'color': car['color'] ?? 'Unknown Color',
            'serialNumber': car['license_plate'] ?? 'G ${Random().nextInt(50) + 1}',
            'pricePerDay': double.tryParse(car['price']?['per_day']?.toString() ?? '0') ?? 50.0,
            'imageUrl': car['images']?[0]['url'] ?? placeholderImages[Random().nextInt(placeholderImages.length)],
          };
        }).toList();

        setState(() {
          cars = mappedCars;
          isLoading = false;
          if (cars.isNotEmpty) {
            print('First Car Data: ${cars[0]}');
          }
        });
      } else {
        throw Exception('Failed to load cars: ${carResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching cars: $e');
      setState(() {
        isLoading = false;
        cars = mockCars;
        errorMessage = 'Failed to fetch cars for $city: $e. Using mock data for now.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cars: $e. Using mock data.')),
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
        cars = [];
        hasFetchedCars = false;
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
      final carColor = selectedCar['color'];
      final serialNumber = selectedCar['serialNumber'];
      double pricePerDay = selectedCar['pricePerDay'] ?? 0.0;
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
                'API key not found. Please add RAPIDAPI_KEY to the .env file.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!hasFetchedCars && cars.isEmpty && errorMessage == null && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              hasFetchedCars = true;
            });
            _fetchCars(snapshot.data!);
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
                              : cars.isEmpty && errorMessage == null
                              ? const Text('No cars found', style: TextStyle(fontSize: 16))
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
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator());
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
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                              double price = car['pricePerDay'] ?? 0.0;
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
                                        price > 0 ? '\$${price.toStringAsFixed(2)} per day' : 'Price unavailable',
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
}*/
