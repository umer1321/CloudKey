import 'package:flutter/material.dart';
import 'Screens/splash_screen.dart';
import 'Screens/start_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/booking_screen.dart';
import 'Screens/payment_screen.dart'; // Import the PaymentScreen

class Routes {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String bookings = '/bookings';
  static const String digitalKey = '/digital_key';
  static const String carRental = '/car_rental';
  static const String hotelServices = '/hotel_services';
  static const String payment = '/payment'; // New route for PaymentScreen

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const StartScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case bookings:
        return MaterialPageRoute(builder: (_) => const BookingScreen());
      case digitalKey:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Digital Key Screen'))));
      case carRental:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Car Rental Screen'))));
      case hotelServices:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Hotel Services Screen'))));
      case payment:
        return MaterialPageRoute(builder: (_) => const PaymentScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}