import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/auth_service.dart';
import '../routes.dart';
import '../Screens/signup.dart';
import '../Screens/login.dart';
import '../utils/translations.dart'; // Import the Translations class

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String _locale = 'en-gb'; // Default locale

  @override
  void initState() {
    super.initState();
    _loadLocale(); // Load the saved locale when the screen initializes
  }

  // Load the saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb'; // Default to English if no locale is saved
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set text direction based on locale (RTL for Arabic, LTR for English)
    TextDirection textDirection = _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Column(
          children: [
            // Top section with logo and hotel background image
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  // Hotel background image
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/hotel_room.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Logo overlay
                  Positioned(
                    top: 35,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/cloudkey.png',
                        height: 60,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section with search bar, hotel options, and auth buttons
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: Translations.translate('choose_the_hotel', _locale),
                          hintStyle: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        textDirection: textDirection,
                      ),
                    ),

                    // Hotel options
                    SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          HotelCircleOption(
                            name: Translations.translate('intercontinental_riyadh', _locale),
                            color: Colors.amber,
                            letter: _locale == 'ar' ? 'إ' : 'I', // Adjust letter for Arabic
                          ),
                          HotelCircleOption(
                            name: Translations.translate('rosh_rayhaan_by_rotana', _locale),
                            color: Colors.purple,
                            letter: _locale == 'ar' ? 'ر' : 'R', // Adjust letter for Arabic
                          ),
                          HotelCircleOption(
                            name: Translations.translate('novotel_riyadh_al_anoud', _locale),
                            color: Colors.grey,
                            label: 'NOVOTEL', // Label can remain the same as it's a brand name
                          ),
                          Icon(
                            _locale == 'ar'
                                ? Icons.chevron_left // Reverse chevron for RTL
                                : Icons.chevron_right,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // User icon
                    CircleAvatar(
                      backgroundColor: Colors.black87,
                      radius: 20,
                      child: const Icon(Icons.person, color: Colors.white, size: 25),
                    ),
                    const SizedBox(height: 15),

                    // Sign Up button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Text(
                        Translations.translate('sign_up', _locale),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Log In button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Text(
                        Translations.translate('log_in', _locale),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Continue with Google button
                    ElevatedButton(
                      onPressed: () async {
                        AuthService authService = AuthService();
                        User? user = (await authService.signInWithGoogle()) as User?;
                        if (user != null) {
                          Navigator.pushReplacementNamed(context, Routes.home);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                Translations.translate('google_signin_failed', _locale),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/Google.jpg',
                            height: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Translations.translate('continue_with_google', _locale),
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for hotel circle option
class HotelCircleOption extends StatelessWidget {
  final String name;
  final Color color;
  final String? letter;
  final String? label;

  const HotelCircleOption({
    super.key,
    required this.name,
    required this.color,
    this.letter,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.2),
          child: letter != null
              ? Text(
            letter!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )
              : Text(
            label ?? '',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: const TextStyle(color: Colors.black87, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}