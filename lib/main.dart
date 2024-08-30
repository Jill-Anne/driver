import 'dart:developer';

import 'package:driver/env/env.dart';
import 'package:driver/pages/dashboard.dart';
import 'package:driver/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:driver/authentication/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  log('Initializing Firebase...');
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: Env.apiKey,
      authDomain: Env.authDomain,
      databaseURL: Env.databaseURL,
      projectId: Env.projectId,
      storageBucket: Env.storageBucket,
      messagingSenderId: Env.messagingSenderId,
      appId: Env.appId,
      measurementId: Env.measurementId,
    ),
  );
  log('Firebase initialized.');

  log('Checking notification permission...');
  await Permission.notification.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      log('Notification permission is denied, requesting...');
      Permission.notification.request();
    } else {
      log('Notification permission is already granted.');
    }
  });

  log('Checking location permission...');
  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      log('Location permission is denied, requesting...');
      Permission.locationWhenInUse.request();
    } else {
      log('Location permission is already granted.');
    }
  });

  // Fetch and log Firebase token
  Future<void> _fetchAndLogFirebaseToken() async {
    log('Fetching Firebase token...');
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('Firebase token: $token');
        log('Firebase token: $token');
      } else {
        debugPrint('Failed to retrieve Firebase token');
        log('Failed to retrieve Firebase token');
      }
    } catch (e) {
      debugPrint('Error fetching Firebase token: $e');
      log('Error fetching Firebase token: $e');
    }
  }

  await _fetchAndLogFirebaseToken(); // Ensure this runs before the app starts

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriversApp',
      theme: ThemeData(
        // Ensure all elements are using the correct colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white, // Set seed color to white
          primary: Colors.white,
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white, // Set background color for Scaffold
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // Set AppBar background color
          foregroundColor: Colors.black, // Set AppBar text color
        ),
        backgroundColor: Colors.white, // Set default background color
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.black), // Default text color
          bodyText2: TextStyle(color: Colors.black54),
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        // Check if the user is authenticated
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking authentication state
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasData && snapshot.data != null) {
              // If user is authenticated, show the Dashboard
              return Dashboard();
            } else {
              // If user is not authenticated, show the LoginScreen
              return LoginScreen();
            }
          }
        },
      ),
    );
  }
}
