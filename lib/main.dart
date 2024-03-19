import 'package:driver/pages/dashboard.dart';
import 'package:driver/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:driver/authentication/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDtvRVetb6lZzxpIQQ8gqIGK1J2WOlBnok",
        authDomain: "passenger-signuplogin.firebaseapp.com",
        databaseURL:
            "https://passenger-signuplogin-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "passenger-signuplogin",
        storageBucket: "passenger-signuplogin.appspot.com",
        messagingSenderId: "755339267599",
        appId: "1:755339267599:web:b6fae1da7711fc97e01d7a",
        measurementId: "G-4H2JKHJB7F"),
  );

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
