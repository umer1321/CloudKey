
import 'dart:ui'; // Explicitly import for TextDirection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed 'package:intl/intl.dart' temporarily to avoid conflict
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // For local notifications
import '../utils/translations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String _locale = 'en-gb'; // Default locale
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _initializeNotifications();
    _checkCheckoutNotifications(); // Check for checkout notifications when screen opens
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb';
    });
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Check for bookings where today is the checkout day and send notification
  Future<void> _checkCheckoutNotifications() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day); // Strip time for comparison

      // Query bookings where checkOutDate matches today
      QuerySnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('checkedOut', isEqualTo: false) // Only active bookings
          .get();

      for (var doc in bookingSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['checkOutDate'] != null) {
          DateTime checkOutDate = (data['checkOutDate'] as Timestamp).toDate();
          DateTime checkOutDay = DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);

          if (checkOutDay == today) {
            // Send notification for checkout
            await _sendCheckoutNotification(doc.id, data['roomType'], data['hotelName']);
          }
        }
      }
    } catch (e) {
      print('Error checking checkout notifications: $e');
    }
  }

  // Send a local notification for checkout
  Future<void> _sendCheckoutNotification(String bookingId, String? roomType, String? hotelName) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'checkout_channel',
      'Checkout Reminders',
      importance: Importance.max,
      priority: Priority.high,
      channelDescription: 'Notifications for checkout reminders',
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(); // For iOS
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final String title = Translations.translate('checkout_reminder', _locale);
    final String body = Translations.translate('checkout_today', _locale)
        .replaceAll('{roomType}', roomType ?? 'your room')
        .replaceAll('{hotelName}', hotelName ?? 'your hotel');

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformDetails,
      payload: '{"type": "checkout", "bookingId": "$bookingId"}',
    );

    print('Checkout notification sent for booking $bookingId');
  }

  Stream<QuerySnapshot> getNotificationsStream() {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr, // Inline conditional
      child: Scaffold(
        appBar: AppBar(
          title: Text(Translations.translate('notifications_screen', _locale)),
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  Translations.translate('no_notifications', _locale),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.notification_important, color: Theme.of(context).primaryColor),
                    title: Text(
                      data['title'] ?? Translations.translate('unknown_notification', _locale),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(data['body'] ?? ''),
                    trailing: Text(
                      data['timestamp'] != null
                          ? (data['timestamp'] as Timestamp).toDate().toString()
                          : '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}