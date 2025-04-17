import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';
import '../utils/translations.dart';

class CarReservationConfirmationScreen extends StatefulWidget {
  const CarReservationConfirmationScreen({super.key});

  @override
  State<CarReservationConfirmationScreen> createState() => _CarReservationConfirmationScreenState();
}

class _CarReservationConfirmationScreenState extends State<CarReservationConfirmationScreen> {
  String _locale = 'en-gb'; // Default locale

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String reservationId = args['reservationId'];

    TextDirection textDirection = _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Translations.translate('reservation_confirmation', _locale),
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.translate('reservation_confirmed', _locale),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                Translations.translate('reservation_id', _locale) + ': $reservationId',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                Translations.translate('access_car_message', _locale),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.carAccess,
                    arguments: {'reservationId': reservationId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  Translations.translate('access_car', _locale),
                  style: const TextStyle(
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
    );
  }
}