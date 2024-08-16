import 'package:driver/env/env.dart';
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
    
  await Permission.notification.isDenied.then((valueOfPermission)
  {
    if(valueOfPermission)
    {
      Permission.notification.request();
    }
  });


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
      title: 'DriversApp',
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
