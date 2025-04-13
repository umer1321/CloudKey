import 'package:flutter/material.dart';
import '../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE6E1F5)], // Light purple gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Cloud elements
            Positioned(
              top: 100,
              left: 30,
              child: Image.asset(
                'assets/images/cloud.png', // Add cloud image
                height: 80,
              ),
            ),
            Positioned(
              top: 150,
              right: 30,
              child: Image.asset(
                'assets/images/cloud.png', // Add cloud image
                height: 60,
              ),
            ),
            Positioned(
              bottom: 100,
              left: 50,
              child: Image.asset(
                'assets/images/cloud.png', // Add cloud image
                height: 70,
              ),
            ),
            // Main content
            Column(
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
                // Hotel icon in circular gradient
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD3CCE3), Color(0xFFE9E4F0)], // Light purple gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/city.png',
                      height: 120,
                    ),
                  ),
                ),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildButton(
                        context: context,
                        text: 'Bookings',
                        color: const Color(0xFFD3CCE3), // Light purple shade
                        route: Routes.bookings,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: 'Digital Key',
                        color: const Color(0xFFD3CCE3).withOpacity(0.9),
                        route: Routes.digitalKey,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: 'Car Rental',
                        color: const Color(0xFFD3CCE3).withOpacity(0.8),
                        route: Routes.carRental,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        context: context,
                        text: 'Hotel Services',
                        color: const Color(0xFFD3CCE3).withOpacity(0.7),
                        route: Routes.hotelServices,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required Color color,
    required String route,
  }) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}