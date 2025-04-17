import 'package:flutter/material.dart';
import 'Screens/payment_screen.dart';
import 'Screens/splash_screen.dart';
import 'Screens/start_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/booking_screen.dart';
import 'Screens/CheckInOutScreen.dart'; // For hotel check-in/check-out
import 'Screens/BookingConfirmationScreen.dart'; // For hotel booking confirmation
import 'Screens/CarRentalScreen.dart'; // For car rental browsing
import 'Screens/CarReservationConfirmationScreen.dart'; // For car reservation confirmation
import 'Screens/CarAccessScreen.dart'; // For car access with barcode
import 'Screens/signup.dart'; // Added import for signup screen
import 'Screens/GuestProfileScreen.dart';
import 'Screens/LanguageSelectionScreen.dart';
import 'Screens/NotificationsScreen.dart';
import 'screens/ServicesScreen.dart';
import 'screens/AccountManagementScreen.dart';
import 'Screens/ReservationScreen.dart';
import 'Screens/HotelMapScreen.dart';
import 'Screens/EmergencySupportScreen.dart';
import 'Screens/RatingAndReviewScreen.dart';

class Routes {
  static const String splash = '/splash';
  static const String languageSelection = '/language_selection';
  static const String auth = '/auth';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String booking = '/booking';
  static const String digitalKey = '/digital_key'; // Keep the route name for consistency
  static const String carRental = '/car_rental';
  static const String carReservationConfirmation = '/car_reservation_confirmation';
  static const String carAccess = '/car_access';
  static const String hotelServices = '/hotel_services';
  static const String payment = '/payment';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String checkInOut = '/check_in_out';
  static const String guestProfile = '/guest_profile';
  static const String notifications = '/notifications';
  static const String accountManagement = '/account_management';
  static const String reservation = '/reservation';
  static const String hotelMap = '/hotel_map';
  static const String emergencySupport = '/emergency_support';
  static const String ratingAndReview = '/rating_and_review';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      languageSelection: (context) => const LanguageSelectionScreen(),
      auth: (context) => const StartScreen(),
      signup: (context) => const SignUpScreen(),
      home: (context) => const HomeScreen(),
      booking: (context) => const BookingScreen(),
      digitalKey: (context) {
        return const Scaffold(
          body: Center(
            child: Text(
              'Please use the Digital Key button on the Home Screen.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      carRental: (context) => const CarRentalScreen(),
      carReservationConfirmation: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('reservationId')) {
          return const CarReservationConfirmationScreen();
        }
        return const Scaffold(
          body: Center(
            child: Text(
              'Car Reservation Confirmation Screen requires a reservationId.',
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      carAccess: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('reservationId')) {
          return CarAccessScreen(reservationId: args['reservationId'] as String);
        }
        return const Scaffold(
          body: Center(
            child: Text(
              'Car Access Screen requires a reservationId.',
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      hotelServices: (context) => const ServicesScreen(), // Updated to point to ServicesScreen
      payment: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        return PaymentScreen(
          transactionId: args?['transactionId'] ?? args?['reservationId'] ?? args?['bookingId'],
          totalPrice: args?['totalPrice'],
          isCarReservation: args?['isCarReservation'] ?? false,
        );
      },
      bookingConfirmation: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('bookingId')) {
          return BookingConfirmationScreen(bookingId: args['bookingId'] as String);
        }
        return const Scaffold(
          body: Center(
            child: Text(
              'Booking Confirmation Screen requires a bookingId.',
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      checkInOut: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('bookingId')) {
          return CheckInOutScreen(bookingId: args['bookingId'] as String, locale: '');
        }
        return const Scaffold(
          body: Center(
            child: Text(
              'Check-In/Out Screen requires a bookingId.',
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      guestProfile: (context) => const GuestProfileScreen(),
      notifications: (context) => const NotificationsScreen(),
      accountManagement: (context) => const AccountManagementScreen(),
      reservation: (context) => const ReservationScreen(),
      hotelMap: (context) => const HotelMapScreen(),
      emergencySupport: (context) => const EmergencySupportScreen(),
      ratingAndReview: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('bookingId')) {
          return RatingAndReviewScreen(bookingId: args['bookingId'] as String);
        }
        return const Scaffold(
          body: Center(
            child: Text(
              'Rating and Review Screen requires a bookingId.',
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    };
  }
}

















///////////////
/*
import 'package:flutter/material.dart';
import 'Screens/splash_screen.dart';
import 'Screens/start_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/booking_screen.dart';
import 'Screens/CheckInOutScreen.dart'; // For hotel check-in/check-out
import 'Screens/BookingConfirmationScreen.dart'; // For hotel booking confirmation
import 'Screens/CarRentalScreen.dart'; // For car rental browsing
import 'Screens/CarReservationConfirmationScreen.dart'; // For car reservation confirmation
import 'Screens/CarAccessScreen.dart'; // For car access with barcode
import 'Screens/signup.dart'; // Added import for signup screen

class Routes {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String signup = '/signup'; // Added signup route
  static const String home = '/home';
  static const String bookings = '/bookings';
  static const String digitalKey = '/digital_key';
  static const String carRental = '/car_rental';
  static const String carReservationConfirmation = '/car_reservation_confirmation';
  static const String carAccess = '/car_access';
  static const String hotelServices = '/hotel_services';
  static const String payment = '/payment';
  static const String bookingConfirmation = '/booking_confirmation';
  static const String checkInOut = '/check_in_out';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const StartScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen()); // Added case for signup
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case bookings:
        return MaterialPageRoute(builder: (_) => const BookingScreen());
      case digitalKey:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Digital Key Screen')),
          ),
        );
      case carRental:
        return MaterialPageRoute(
          builder: (_) => const CarRentalScreen(),
        );
      case carReservationConfirmation:
      // Extract reservationId from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('reservationId')) {
          return MaterialPageRoute(
            builder: (_) => CarReservationConfirmationScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Car Reservation Confirmation Screen requires a reservationId.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case carAccess:
      // Extract reservationId from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('reservationId')) {
          return MaterialPageRoute(
            builder: (_) => CarAccessScreen(
              reservationId: args['reservationId'] as String,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Car Access Screen requires a reservationId.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case hotelServices:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Hotel Services Screen')),
          ),
        );
      case payment:
      // Since PaymentScreen requires constructor arguments (bookingId and totalPrice),
      // it cannot be instantiated directly here. Navigation to PaymentScreen
      // should be handled via Navigator.push with the required arguments.
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Payment Screen cannot be accessed directly. Please book a hotel or car first.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case bookingConfirmation:
      // Extract bookingId from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('bookingId')) {
          return MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              bookingId: args['bookingId'] as String,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Booking Confirmation Screen requires a bookingId.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case checkInOut:
      // Extract bookingId from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('bookingId')) {
          return MaterialPageRoute(
            builder: (_) => CheckInOutScreen(
              bookingId: args['bookingId'] as String,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Check-In/Out Screen requires a bookingId.',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}*/
