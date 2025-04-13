import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../routes.dart';
import '../Screens/signup.dart';
import '../Screens/login.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        hintText: 'Choose The Hotel',
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
                    ),
                  ),

                  // Hotel options
                  SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        HotelCircleOption(
                          name: 'InterContinental Riyadh',
                          color: Colors.amber,
                          letter: 'I',
                        ),
                        HotelCircleOption(
                          name: 'Rosh Rayhaan by Rotana',
                          color: Colors.purple,
                          letter: 'R',
                        ),
                        HotelCircleOption(
                          name: 'Novotel Riyadh Al Anoud',
                          color: Colors.grey,
                          label: 'NOVOTEL',
                        ),
                        Icon(Icons.chevron_right, size: 30, color: Colors.grey),
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
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
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
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
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
                          const SnackBar(content: Text('Google Sign-In failed')),
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
                        const Text(
                          'continue with google',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
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