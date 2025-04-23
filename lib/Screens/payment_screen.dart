/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes.dart';

class PaymentScreen extends StatelessWidget {
  final String? transactionId; // Generic ID for either booking or reservation
  final double? totalPrice;
  final bool isCarReservation; // Flag to determine if this is a car reservation

  const PaymentScreen({
    super.key,
    this.transactionId,
    this.totalPrice,
    this.isCarReservation = false, // Default to false (hotel booking)
  });

  Future<void> _processPayment(String method, BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Simulate payment processing (mock)
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      // Use dummy transactionId if not provided
      String effectiveTransactionId = transactionId ?? 'dummy_transaction_${DateTime.now().millisecondsSinceEpoch}';

      // Mock payment success
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      DocumentReference paymentRef = await _firestore.collection('payments').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
        'amount': totalPrice ?? 500.00, // Default dummy amount if not provided
        'method': method,
        'status': 'completed', // Mock payment status
        'timestamp': Timestamp.now(),
        'stripePaymentIntentId': 'mock_payment_intent_${DateTime.now().millisecondsSinceEpoch}',
      });

      // If transactionId was not provided, create a dummy transaction
      if (transactionId == null) {
        DocumentReference transactionRef;
        if (isCarReservation) {
          transactionRef = await _firestore.collection('car_reservations').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
            'carId': 'dummy_car_1',
            'carName': 'Dummy Car Riyadh',
            'carColor': 'Black',
            'serialNumber': 'DUMMY123',
            'pricePerDay': 50.0,
            'startDate': Timestamp.fromDate(DateTime.now()),
            'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
            'totalPrice': totalPrice ?? 500.00,
            'status': 'pending',
            'parkingSpot': 'G 99',
            'accessed': false,
            'paymentId': paymentRef.id,
          });
        } else {
          transactionRef = await _firestore.collection('bookings').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
            'hotelId': 'dummy_hotel_1',
            'hotelName': 'Dummy Hotel Riyadh',
            'pricePerNight': 100.0,
            'checkInDate': Timestamp.fromDate(DateTime.now()),
            'checkOutDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
            'totalPrice': totalPrice ?? 500.00,
            'status': 'pending',
            'digitalKey': '',
            'paymentId': paymentRef.id,
            'checkedIn': false,
            'checkedOut': false,
            'roomNumber': 'R.N 999',
          });
        }
        effectiveTransactionId = transactionRef.id;
      } else {
        // Update the appropriate collection based on isCarReservation
        if (isCarReservation) {
          await _firestore.collection('car_reservations').doc(transactionId).update({
            'paymentId': paymentRef.id,
            'status': 'confirmed', // Update reservation status to confirmed
          });
        } else {
          await _firestore.collection('bookings').doc(transactionId).update({
            'paymentId': paymentRef.id,
            'status': 'confirmed', // Update booking status to confirmed
          });
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful (Mock)!')),
      );

      // Navigate to the appropriate confirmation screen
      Navigator.pushNamed(
        context,
        isCarReservation ? Routes.carReservationConfirmation : Routes.bookingConfirmation,
        arguments: {
          isCarReservation ? 'reservationId' : 'bookingId': effectiveTransactionId,
        },
      );
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
      }
      print('Error processing payment: $e');

      // Use dummy transactionId if not provided
      String effectiveTransactionId = transactionId ?? 'dummy_transaction_${DateTime.now().millisecondsSinceEpoch}';

      // Save payment as failed in Firestore
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      DocumentReference paymentRef = await _firestore.collection('payments').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
        'amount': totalPrice ?? 500.00,
        'method': method,
        'status': 'failed',
        'timestamp': Timestamp.now(),
        'stripePaymentIntentId': 'mock_payment_intent_failed',
      });

      // If transactionId was not provided, create a dummy transaction
      if (transactionId == null) {
        DocumentReference transactionRef;
        if (isCarReservation) {
          transactionRef = await _firestore.collection('car_reservations').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
            'carId': 'dummy_car_1',
            'carName': 'Dummy Car Riyadh',
            'carColor': 'Black',
            'serialNumber': 'DUMMY123',
            'pricePerDay': 50.0,
            'startDate': Timestamp.fromDate(DateTime.now()),
            'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
            'totalPrice': totalPrice ?? 500.00,
            'status': 'pending_payment',
            'parkingSpot': 'G 99',
            'accessed': false,
            'paymentId': paymentRef.id,
          });
        } else {
          transactionRef = await _firestore.collection('bookings').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
            'hotelId': 'dummy_hotel_1',
            'hotelName': 'Dummy Hotel Riyadh',
            'pricePerNight': 100.0,
            'checkInDate': Timestamp.fromDate(DateTime.now()),
            'checkOutDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
            'totalPrice': totalPrice ?? 500.00,
            'status': 'pending_payment',
            'digitalKey': '',
            'paymentId': paymentRef.id,
            'checkedIn': false,
            'checkedOut': false,
            'roomNumber': 'R.N 999',
          });
        }
        effectiveTransactionId = transactionRef.id;
      } else {
        // Update the appropriate collection based on isCarReservation
        if (isCarReservation) {
          await _firestore.collection('car_reservations').doc(transactionId).update({
            'paymentId': paymentRef.id,
            'status': 'pending_payment', // Update reservation status
          });
        } else {
          await _firestore.collection('bookings').doc(transactionId).update({
            'paymentId': paymentRef.id,
            'status': 'pending_payment', // Update booking status
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing payment: $e')),
      );

      // Navigate to the appropriate confirmation screen
      Navigator.pushNamed(
        context,
        isCarReservation ? Routes.carReservationConfirmation : Routes.bookingConfirmation,
        arguments: {
          isCarReservation ? 'reservationId' : 'bookingId': effectiveTransactionId,
        },
      );
    }
  }

  Future<void> _skipPayment(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Use dummy transactionId if not provided
      String effectiveTransactionId = transactionId ?? 'dummy_transaction_${DateTime.now().millisecondsSinceEpoch}';

      // Save payment as skipped in Firestore
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      DocumentReference paymentRef = await _firestore.collection('payments').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
        'amount': totalPrice ?? 500.00,
        'method': 'skipped',
        'status': 'skipped',
        'timestamp': Timestamp.now(),
        'stripePaymentIntentId': 'mock_payment_intent_skipped',
      });

      // If transactionId was not provided, create a dummy transaction
      if (transactionId == null) {
        DocumentReference transactionRef;
        if (isCarReservation) {
          transactionRef = await _firestore.collection('car_reservations').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
            'carId': 'dummy_car_1',
            'carName': 'Dummy Car Riyadh',
            'carColor': 'Black',
            'serialNumber': 'DUMMY123',
            'pricePerDay': 50.0,
            'startDate': Timestamp.fromDate(DateTime.now()),
            'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
            'totalPrice': totalPrice ?? 500.00,
            'status': 'pending_payment',
            'parkingSpot': 'G 99',
            'accessed': false,
            'paymentId': paymentRef.id,
          });
        } else {
          transactionRef = await _firestore.collection('bookings').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'dummy_user',
            'hotelId': 'dummy_hotel_1',
            'hotelName': 'Dummy Hotel Riyadh',
            'pricePerNight': 100.0,
            'checkInDate': Timestamp.fromDate(DateTime.now()),
            'checkOutDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
            'totalPrice': totalPrice ?? 500.00,
            'status': 'pending_payment',
            'digitalKey': '',
            'paymentId': paymentRef.id,
            'checkedIn': false,
            'checkedOut': false,
            'roomNumber': 'R.N 999',
          });
        }
        effectiveTransactionId = transactionRef.id;
      } else {
        // Update the appropriate collection based on isCarReservation
        if (isCarReservation) {
          await _firestore.collection('car_reservations').doc(transactionId).update({
            'paymentId': paymentRef.id,
            'status': 'pending_payment', // Update reservation status
          });
        } else {
          await _firestore.collection('bookings').doc(transactionId).update({
            'paymentId': paymentRef.id,
            'status': 'pending_payment', // Update booking status
          });
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Skipped')),
      );

      // Navigate to the appropriate confirmation screen
      Navigator.pushNamed(
        context,
        isCarReservation ? Routes.carReservationConfirmation : Routes.bookingConfirmation,
        arguments: {
          isCarReservation ? 'reservationId' : 'bookingId': effectiveTransactionId,
        },
      );
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
      }
      print('Error skipping payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error skipping payment: $e')),
      );

      // Use dummy transactionId if not provided
      String effectiveTransactionId = transactionId ?? 'dummy_transaction_${DateTime.now().millisecondsSinceEpoch}';

      // Navigate to the appropriate confirmation screen
      Navigator.pushNamed(
        context,
        isCarReservation ? Routes.carReservationConfirmation : Routes.bookingConfirmation,
        arguments: {
          isCarReservation ? 'reservationId' : 'bookingId': effectiveTransactionId,
        },
      );
    }
  }

  // Since PaymentScreen is stateless, we can't use setState directly.
  // We'll handle the effectiveTransactionId in the methods above.
  void setState(VoidCallback fn) {
    // This is a workaround to satisfy the setState calls in a StatelessWidget.
    // In a real app, you might want to convert this to a StatefulWidget if you need to update state.
    fn();
  }

  @override
  Widget build(BuildContext context) {
    // Use dummy values if arguments are missing
    final displayTotalPrice = totalPrice ?? 500.00; // Default dummy amount
    final displayTransactionId = transactionId ?? 'dummy_transaction_${DateTime.now().millisecondsSinceEpoch}';

    print('PaymentScreen accessed with transactionId: $displayTransactionId, totalPrice: $displayTotalPrice');
    return Scaffold(
      backgroundColor: Colors.grey[100], // Match BookingScreen background
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
                      Icons.arrow_back,
                      color: Colors.brown,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    isCarReservation ? 'Car Reservation Payment' : 'Hotel Booking Payment',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.brown,
                      size: 30,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Amount: \$${displayTotalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.payment,
                        size: 40,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.credit_card,
                      text: 'Credit/Debit Card',
                      onTap: () => _processPayment('Credit/Debit Card', context),
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.apple,
                      text: 'Apple Pay',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Apple Pay not supported yet.')),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.payment,
                      text: 'PayPal',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PayPal not supported yet.')),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => _processPayment('Default', context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Secure Payment',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => _skipPayment(context),
                      child: const Text(
                        'Skip Payment for Now',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
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
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Add this for Firebase Cloud Functions

class PaymentScreen extends StatelessWidget {
  final String bookingId;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalPrice,
  });

  Future<Map<String, dynamic>> _createPaymentIntent(double amount) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
      final response = await callable.call(<String, dynamic>{
        'amount': amount,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create Payment Intent: $e');
    }
  }

  Future<void> _processPayment(String method, BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Step 1: Create Payment Intent via Cloud Function
      final paymentIntentData = await _createPaymentIntent(totalPrice);
      final clientSecret = paymentIntentData['clientSecret'];

      // Step 2: Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CloudKey Hotel Booking',
          allowsDelayedPaymentMethods: false,
        ),
      );

      // Close loading dialog
      Navigator.pop(context);

      // Step 3: Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 4: If payment is successful, update Firestore
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      DocumentReference paymentRef = await _firestore.collection('payments').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'amount': totalPrice,
        'method': method,
        'status': 'completed',
        'timestamp': Timestamp.now(),
        'stripePaymentIntentId': clientSecret.split('_secret_')[0], // Store the Payment Intent ID
      });

      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentId': paymentRef.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );

      // Navigate back to HomeScreen
      Navigator.popUntil(context, (route) => route.settings.name == '/home');
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
      }
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PaymentScreen accessed with bookingId: $bookingId, totalPrice: $totalPrice');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.brown,
                    size: 30,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD3CCE3).withOpacity(0.5),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.credit_card,
                      text: 'Credit/Debit Card',
                      onTap: () => _processPayment('Credit/Debit Card', context),
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.apple,
                      text: 'Apple Pay',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Apple Pay not supported yet.')),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.payment,
                      text: 'Pay Pal',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PayPal not supported yet.')),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => _processPayment('Default', context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD3CCE3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Secure Payment',
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
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFD3CCE3).withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
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
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}