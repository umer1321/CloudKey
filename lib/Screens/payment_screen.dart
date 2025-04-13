import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve booking details from arguments
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String bookingId = args['bookingId'];
    final double totalPrice = args['totalPrice'];

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    Future<void> _processPayment(String method) async {
      try {
        // Simulate payment processing (replace with actual payment gateway integration)
        DocumentReference paymentRef = await _firestore.collection('payments').add({
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'amount': totalPrice,
          'method': method,
          'status': 'completed',
          'timestamp': Timestamp.now(),
        });

        // Update the booking with the payment ID
        await _firestore.collection('bookings').doc(bookingId).update({
          'paymentId': paymentRef.id,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!')),
        );

        // Navigate back to HomeScreen
        Navigator.popUntil(context, (route) => route.settings.name == '/home');
      } catch (e) {
        print('Error processing payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Payment icon
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
                    // Payment options
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.credit_card,
                      text: 'Credit/Debit Card',
                      onTap: () => _processPayment('Credit/Debit Card'),
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.apple,
                      text: 'Apple Pay',
                      onTap: () => _processPayment('Apple Pay'),
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentOption(
                      context: context,
                      icon: Icons.payment,
                      text: 'Pay Pal',
                      onTap: () => _processPayment('PayPal'),
                    ),
                    const SizedBox(height: 30),
                    // Secure Payment button
                    ElevatedButton(
                      onPressed: () => _processPayment('Default'),
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