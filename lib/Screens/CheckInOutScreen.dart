import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import '../utils/Translations.dart';

class CheckInOutScreen extends StatefulWidget {
  final String bookingId;
  final String locale;

  const CheckInOutScreen({Key? key, required this.bookingId, required this.locale}) : super(key: key);

  @override
  _CheckInOutScreenState createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _bookingData;
  bool _isNfcAvailable = false;
  String? _digitalKey;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _showKeyAnimation = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingData();
    _checkNfcAvailability();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  Future<void> _checkNfcAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
  }

  Future<void> _fetchBookingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (doc.exists) {
        setState(() {
          _bookingData = doc.data() as Map<String, dynamic>;
          _digitalKey = _bookingData!['digitalKey'] ?? '';
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar(Translations.translate('error_fetching_booking', widget.locale));
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('${Translations.translate('error_fetching_booking', widget.locale)}: $e');
      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _checkIn() async {
    if (_bookingData == null) return;

    DateTime checkInDate = (_bookingData!['checkInDate'] as Timestamp).toDate();
    DateTime now = DateTime.now();

    if (now.year == checkInDate.year &&
        now.month == checkInDate.month &&
        now.day == checkInDate.day) {
      setState(() {
        _isLoading = true;
      });

      try {
        const uuid = Uuid();
        String newDigitalKey = uuid.v4();

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'checkedIn': true,
          'digitalKey': newDigitalKey,
        });

        setState(() {
          _bookingData!['checkedIn'] = true;
          _bookingData!['digitalKey'] = newDigitalKey;
          _digitalKey = newDigitalKey;
          _isLoading = false;
          _showKeyAnimation = true;
        });

        _animationController.repeat(reverse: true);
        _showSuccessSnackBar(Translations.translate('check_in_success', widget.locale));
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('${Translations.translate('error_fetching_booking', widget.locale)}: $e');
      }
    } else {
      _showErrorSnackBar(Translations.translate('no_bookings', widget.locale));
    }
  }

  Future<void> _checkOut() async {
    if (_bookingData == null || !_bookingData!['checkedIn']) return;

    DateTime checkOutDate = (_bookingData!['checkOutDate'] as Timestamp).toDate();
    DateTime now = DateTime.now();

    if (now.year == checkOutDate.year &&
        now.month == checkOutDate.month &&
        now.day == checkOutDate.day) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'checkedOut': true,
          'digitalKey': '',
        });

        setState(() {
          _bookingData!['checkedOut'] = true;
          _bookingData!['digitalKey'] = '';
          _digitalKey = '';
          _isLoading = false;
          _showKeyAnimation = false;
        });

        _showSuccessSnackBar(Translations.translate('check_out_success', widget.locale));

        // Delay before popping to show success message
        Future.delayed(Duration(seconds: 2), () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('${Translations.translate('error_fetching_booking', widget.locale)}: $e');
      }
    } else {
      _showErrorSnackBar(Translations.translate('no_bookings', widget.locale));
    }
  }

  Future<void> _activateDigitalKey() async {
    if (_digitalKey == null || _digitalKey!.isEmpty) {
      _showErrorSnackBar(Translations.translate('no_digital_key', widget.locale));
      return;
    }

    if (!_isNfcAvailable) {
      _showErrorSnackBar(Translations.translate('nfc_not_available', widget.locale));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            Translations.translate('scan_nfc', widget.locale),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 100 * _pulseAnimation.value,
                        height: 100 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.3),
                        ),
                        child: Icon(
                          Icons.nfc,
                          size: 50 * _pulseAnimation.value,
                          color: Colors.blue,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                Translations.translate('hold_phone_to_door', widget.locale),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    try {
      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef != null && ndef.isWritable) {
            final message = NdefMessage([
              NdefRecord.createText(_digitalKey!),
            ]);
            await ndef.write(message);
            Navigator.pop(context); // Close dialog
            _showSuccessSnackBar(Translations.translate('key_activated', widget.locale));
          } else {
            Navigator.pop(context); // Close dialog
            _showErrorSnackBar(Translations.translate('incompatible_nfc', widget.locale));
          }
        } catch (e) {
          Navigator.pop(context); // Close dialog
          _showErrorSnackBar('${Translations.translate('error_nfc', widget.locale)}: $e');
        } finally {
          await NfcManager.instance.stopSession();
        }
      });
    } catch (e) {
      Navigator.pop(context); // Close dialog if open
      _showErrorSnackBar('${Translations.translate('error_nfc', widget.locale)}: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Widget _buildLoadingAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            Translations.translate('loading', widget.locale),
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10 * _pulseAnimation.value,
                  spreadRadius: 5 * _pulseAnimation.value,
                ),
              ],
            ),
            child: Icon(
              Icons.key,
              size: 50,
              color: Colors.blue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_outline,
        size: 80,
        color: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _bookingData == null) {
      return Scaffold(
        body: _buildLoadingAnimation(),
      );
    }

    DateTime checkInDate = (_bookingData!['checkInDate'] as Timestamp).toDate();
    DateTime checkOutDate = (_bookingData!['checkOutDate'] as Timestamp).toDate();
    bool isCheckedIn = _bookingData!['checkedIn'] ?? false;
    bool isCheckedOut = _bookingData!['checkedOut'] ?? false;
    String roomNumber = _bookingData!['roomNumber'] ?? 'R.N 100';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          Translations.translate('digital_key', widget.locale),
          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.blueAccent),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.blue[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Room $roomNumber',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              isCheckedOut
                                  ? Translations.translate('checked_out', widget.locale)
                                  : isCheckedIn
                                  ? Translations.translate('checked_in', widget.locale)
                                  : Translations.translate('pending', widget.locale),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                          SizedBox(width: 5),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(checkInDate)} - ${DateFormat('MMM dd, yyyy').format(checkOutDate)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.confirmation_number_outlined, color: Colors.white70, size: 16),
                          SizedBox(width: 5),
                          Text(
                            '${widget.bookingId.substring(0, 8)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Digital Key Section
                if (isCheckedIn && !isCheckedOut) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          Translations.translate('your_digital_key', widget.locale),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 20),
                        _showKeyAnimation
                            ? _buildKeyAnimation()
                            : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.key_off,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _digitalKey!.isEmpty
                              ? Translations.translate('no_digital_key', widget.locale)
                              : Translations.translate('key_ready', widget.locale),
                          style: TextStyle(
                            color: _digitalKey!.isEmpty ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _activateDigitalKey,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.nfc),
                              SizedBox(width: 10),
                              Text(
                                Translations.translate('unlock_door', widget.locale),
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 30),

                // Action Button Section
                if (!isCheckedIn) ...[
                  ElevatedButton(
                    onPressed: _checkIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      minimumSize: Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login),
                        SizedBox(width: 10),
                        Text(
                          Translations.translate('check_in', widget.locale),
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isCheckedIn && !isCheckedOut) ...[
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _checkOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      minimumSize: Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 10),
                        Text(
                          Translations.translate('check_out', widget.locale),
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isCheckedOut) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildSuccessAnimation(),
                        SizedBox(height: 10),
                        Text(
                          Translations.translate('check_out_success', widget.locale),
                          style: TextStyle(fontSize: 16, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Text(
                          Translations.translate('thank_you_message', widget.locale),
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}






/*
import 'dart:convert'; // For JSON encoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CheckInOutScreen extends StatefulWidget {
  final String bookingId;

  const CheckInOutScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  _CheckInOutScreenState createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _bookingData;

  @override
  void initState() {
    super.initState();
    _fetchBookingData();
  }

  Future<void> _fetchBookingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (doc.exists) {
        setState(() {
          _bookingData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching booking: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _checkIn() async {
    if (_bookingData == null) return;

    DateTime checkInDate = (_bookingData!['checkInDate'] as Timestamp).toDate();
    DateTime now = DateTime.now();

    // Check if today is the check-in date
    if (now.year == checkInDate.year &&
        now.month == checkInDate.month &&
        now.day == checkInDate.day) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'checkedIn': true,
        });

        setState(() {
          _bookingData!['checkedIn'] = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-In Successful!')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking in: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-In is only allowed on the check-in date!')),
      );
    }
  }

  Future<void> _checkOut() async {
    if (_bookingData == null || !_bookingData!['checkedIn']) return;

    DateTime checkOutDate = (_bookingData!['checkOutDate'] as Timestamp).toDate();
    DateTime now = DateTime.now();

    // Check if today is the check-out date
    if (now.year == checkOutDate.year &&
        now.month == checkOutDate.month &&
        now.day == checkOutDate.day) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'checkedOut': true,
        });

        setState(() {
          _bookingData!['checkedOut'] = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-Out Successful!')),
        );

        // Navigate back to HomeScreen after successful check-out
        Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking out: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-Out is only allowed on the check-out date!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _bookingData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    DateTime checkInDate = (_bookingData!['checkInDate'] as Timestamp).toDate();
    DateTime checkOutDate = (_bookingData!['checkOutDate'] as Timestamp).toDate();
    bool isCheckedIn = _bookingData!['checkedIn'] ?? false;
    bool isCheckedOut = _bookingData!['checkedOut'] ?? false;
    // Use a placeholder room number if not available in Firestore
    String roomNumber = _bookingData!['roomNumber'] ?? 'R.N 100'; // Update this based on your data

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Key'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking ID: ${widget.bookingId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Check-In Date: ${DateFormat('yyyy-MM-dd').format(checkInDate)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Check-Out Date: ${DateFormat('ddMMM').format(checkOutDate)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (isCheckedIn && !isCheckedOut) ...[
              Text(
                'Room Barcode $roomNumber',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Center(
                child: QrImageView(
                  data: jsonEncode({
                    'bookingId': widget.bookingId,
                    'roomNumber': roomNumber,
                    'checkOutDate': checkOutDate.toIso8601String(),
                  }),
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'This barcode will stop working on ${DateFormat('ddMMM').format(checkOutDate)}.',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
            if (!isCheckedIn) ...[
              ElevatedButton(
                onPressed: _checkIn,
                child: const Text('Check In'),
              ),
            ],
            if (isCheckedIn && !isCheckedOut) ...[
              ElevatedButton(
                onPressed: _checkOut,
                child: const Text('Check Out'),
              ),
            ],
            if (isCheckedOut) ...[
              const Text(
                'You have checked out!',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/
