import 'package:driver/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:driver/authentication/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      authDomain: "add-users-admin.firebaseapp.com",
      projectId: "add-users-admin",
      storageBucket: "add-users-admin.appspot.com",
      messagingSenderId: "660357140183",
      appId: "1:660357140183:web:940b0b0ff28e6fc0dbea92",
      measurementId: "G-NTJ6FKBQMM",
      apiKey: "AIzaSyC09UWjC-mDHPf7DOpLseRBdFA6qVhQML0",
    ),
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
        future: checkAuthenticationState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading indicator or splash screen while checking authentication status
            return CircularProgressIndicator();
          } else {
            bool isAuthenticated = snapshot.data as bool;
            return isAuthenticated ? const HomePage() : const LoginScreen();
          }
        },
      ),
    );
  }

  Future<bool> checkAuthenticationState() async {
    // Add your authentication check logic here
    // For example, you can use FirebaseAuth.instance.currentUser
    // to check if the user is authenticated or not
    // Replace this with your actual authentication logic
    await Future.delayed(const Duration(seconds: 2)); // Simulating a delay for demonstration
    bool isAuthenticated = FirebaseAuth.instance.currentUser != null;
    return isAuthenticated;
  }
}

