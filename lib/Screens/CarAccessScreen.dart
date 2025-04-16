import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CarAccessScreen extends StatefulWidget {
  final String reservationId;

  const CarAccessScreen({Key? key, required this.reservationId}) : super(key: key);

  @override
  _CarAccessScreenState createState() => _CarAccessScreenState();
}

class _CarAccessScreenState extends State<CarAccessScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _reservationData;

  @override
  void initState() {
    super.initState();
    _fetchReservationData();
  }

  Future<void> _fetchReservationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('car_reservations')
          .doc(widget.reservationId)
          .get();

      if (doc.exists) {
        setState(() {
          _reservationData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation not found!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reservation: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _reservationData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    DateTime startDate = (_reservationData!['startDate'] as Timestamp).toDate();
    DateTime endDate = (_reservationData!['endDate'] as Timestamp).toDate();
    bool isAccessed = _reservationData!['accessed'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Access'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'The car is on the ${_reservationData!['parkingSpot']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Serial Number ${_reservationData!['serialNumber']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Delivery Date ${DateFormat('ddMMM').format(startDate)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              '${_reservationData!['carName']}, ${_reservationData!['carColor']} color',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please use the barcode to open the car for you!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data: jsonEncode({
                  'reservationId': widget.reservationId,
                  'carId': _reservationData!['carId'],
                  'parkingSpot': _reservationData!['parkingSpot'],
                  'endDate': endDate.toIso8601String(),
                }),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This barcode will stop working on ${DateFormat('ddMMM').format(endDate)}.',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}