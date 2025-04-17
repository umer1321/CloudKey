
import 'package:flutter/material.dart';

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    String poiName = args?['poiName'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: Text('Reserve - $poiName')),
      body: const Center(child: Text('Reservation Booking Placeholder')),
    );
  }
}