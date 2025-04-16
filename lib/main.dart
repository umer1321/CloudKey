







import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel & Car Booking App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      initialRoute: Routes.splash,
      routes: Routes.getRoutes(), // Use the getRoutes method
    );
  }
}
/*
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'firebase_options.dart';
import 'routes.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize Firebase
      print('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully.');

      // Load the .env file as an asset
      print('Loading .env file...');
      final envString = await rootBundle.loadString('.env');
      await dotenv.load(mergeWith: _parseEnvString(envString));
      print('.env file loaded successfully.');

      // Run the app
      runApp(const MyApp());
    } catch (e, stackTrace) {
      print('Error during app initialization: $e');
      print('Stack trace: $stackTrace');
      runApp(ErrorApp(errorMessage: e.toString()));
    }
  }, (error, stackTrace) {
    print('Unhandled error: $error');
    print('Stack trace: $stackTrace');
  });
}

// Helper function to parse the .env string into a Map
Map<String, String> _parseEnvString(String envString) {
  final envMap = <String, String>{};
  final lines = envString.split('\n');
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue; // Skip empty lines and comments
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      envMap[key] = value;
    }
  }
  return envMap;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    return MaterialApp(
      title: 'CloudKey',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to initialize app.\nError: $errorMessage\nPlease ensure the .env file exists in the project root with a valid RAPIDAPI_KEY.',
              style: const TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}*/
