import 'package:flutter/material.dart';
import 'package:driver/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';


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
      home: LoginScreen(),
    );
  }
}
