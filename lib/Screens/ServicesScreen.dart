import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> userBookings = [];
  bool isLoading = false;
  String? errorMessage;

  // Predefined list of services with standardized icons
  final List<Map<String, dynamic>> standardServices = [
    {
      'name': 'Room Cleaning',
      'icon': Icons.bed,
      'description': 'Full room cleaning service',
      'price': 15.0,
    },
    {
      'name': 'Breakfast',
      'icon': Icons.restaurant,
      'description': 'In-room breakfast service',
      'price': 20.0,
    },
    {
      'name': 'Laundry',
      'icon': Icons.local_laundry_service,
      'description': 'Laundry and ironing service',
      'price': 25.0,
    },
    {
      'name': 'Valet',
      'icon': Icons.directions_car,
      'description': 'Valet parking service',
      'price': 10.0,
    },
    {
      'name': 'Luggage',
      'icon': Icons.luggage,
      'description': 'Luggage handling and storage',
      'price': 5.0,
    },
    {
      'name': 'Concierge',
      'icon': Icons.person,
      'description': 'Personal concierge service',
      'price': 30.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    // For demo purposes, we can either use predefined services or fetch from Firestore
    _loadStandardServices();
    // _fetchServices(); // Comment this if using standardized services
    _fetchUserBookings();
  }

  // Load predefined standard services
  void _loadStandardServices() {
    setState(() {
      services = standardServices.map((service) {
        return {
          'id': service['name'].toString().toLowerCase().replaceAll(' ', '_'),
          'name': service['name'],
          'icon': service['icon'],
          'description': service['description'],
          'price': service['price'],
        };
      }).toList();
    });
  }

  Future<void> _fetchServices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      QuerySnapshot snapshot = await _firestore.collection('services').get();
      setState(() {
        services = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'],
            'icon': data['icon'],
            'description': data['description'],
            'price': data['price'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load services: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: $e')),
      );
    }
  }

  Future<void> _fetchUserBookings() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('service_bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        userBookings = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'serviceId': data['serviceId'],
            'serviceName': data['serviceName'],
            'bookingDate': (data['bookingDate'] as Timestamp).toDate(),
            'status': data['status'],
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  Future<void> _bookService(String serviceId, String serviceName, double price) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a service')),
      );
      return;
    }

    try {
      // Simulate haptic feedback for better UX
      HapticFeedback.mediumImpact();

      await _firestore.collection('service_bookings').add({
        'userId': user.uid,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'bookingDate': Timestamp.now(),
        'status': 'pending',
        'price': price,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$serviceName booked successfully!')),
      );

      // Refresh user bookings
      await _fetchUserBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking service: $e')),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      // Simulate haptic feedback for better UX
      HapticFeedback.mediumImpact();

      await _firestore.collection('service_bookings').doc(bookingId).update({
        'status': 'cancelled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully!')),
      );

      // Refresh user bookings
      await _fetchUserBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: $e')),
      );
    }
  }

  // Show booking dialog when service is tapped
  void _showBookingDialog(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${service['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(service['icon'] as IconData, color: Colors.black87, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              '${service['description']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Price: \$${service['price'].toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          ElevatedButton(
            onPressed: () {
              _bookService(
                service['id'],
                service['name'],
                service['price'],
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[100],
              foregroundColor: Colors.black87,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  // Show user bookings
  void _showUserBookings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Your Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: userBookings.isEmpty
                      ? const Center(child: Text('No active bookings'))
                      : ListView.separated(
                    controller: scrollController,
                    itemCount: userBookings.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final booking = userBookings[index];
                      IconData serviceIcon = Icons.room_service;

                      // Find matching icon for the service
                      for (var service in services) {
                        if (service['id'] == booking['serviceId']) {
                          serviceIcon = service['icon'] as IconData;
                          break;
                        }
                      }

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(serviceIcon, color: Colors.black87),
                        ),
                        title: Text(booking['serviceName']),
                        subtitle: Text(
                          'Booked: ${booking['bookingDate'].toString().split(' ')[0]}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          onPressed: () {
                            _cancelBooking(booking['id']);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with profile and notification icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.brown[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.black87),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.brown[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Top rating icon with stars
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.thumb_up,
                  color: Colors.black87,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Room Services Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  'Room Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Services Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                    : services.isEmpty
                    ? const Center(child: Text('No services available'))
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return GestureDetector(
                      onTap: () => _showBookingDialog(service),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  service['icon'] as IconData,
                                  color: Colors.black87,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            service['name'],
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: userBookings.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showUserBookings,
        backgroundColor: Colors.purple[100],
        child: const Icon(Icons.list, color: Colors.black87),
      )
          : null,
    );
  }
}