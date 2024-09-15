import 'package:driver/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/reusable_widgets.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isPasswordSet = false; // Flag to check if password is set.

  @override
  void initState() {
    super.initState();
    _checkIfPasswordSet(); // Check if password is set when screen loads.
  }


Future<void> _checkIfPasswordSet() async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? isPasswordSet = prefs.getBool('isPasswordSet');
  
  setState(() {
    _isPasswordSet = isPasswordSet ?? false;
  });

   
  print('Retrieved isPasswordSet: $isPasswordSet');
  print('Flag _isPasswordSet after setState: $_isPasswordSet');
}


Future<void> _login(BuildContext context) async {
  final String email = _emailController.text.trim();
  final String passwordOrBirthdate = _isPasswordSet
      ? _passwordController.text.trim()
      : _birthdateController.text.trim();

  if (email.isEmpty || passwordOrBirthdate.isEmpty) {
    _showErrorDialog(context, "Please enter both email and password or birthdate.");
    return;
  }

  try {
    // Authentication logic
          // Show full-screen "Logging in..." animation while processing the login
      showDialog(
        context: context,
        barrierDismissible: false, // Prevents dismissing
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.white,// Colors.white.withOpacity(0.5),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fullscreen Lottie animation for "Loading" or "Logging in"
                  Lottie.asset(
                    'assets/images/loading.json', // Path to your Lottie animation
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.width * 0.9,
                    fit: BoxFit.cover,
                    repeat: true,
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    "Authenticating",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 1, 42, 123),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: passwordOrBirthdate,
    );

    if (userCredential.user != null) {
      print('Login successful.');
              // Delay closing the dialog to let the animation finish
        await Future.delayed(const Duration(seconds: 2));

        // Close the "Logging in..." animation dialog after success
        Navigator.pop(context);

        // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    }
  } catch (error) {
    print('Login failed: $error');
    _showErrorDialog(context, "An error occurred: $error");
  }
}

  // Method to show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false,
    body: Stack(
      children: [
        CustomColumnWithLogo(),
        Positioned(
          top: 100,
          left: 30,
          right: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sign in with email and password.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: Colors.black,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              if (_isPasswordSet)
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.black,
                  ),
                  obscureText: true,
                )
              else
                TextField(
  controller: _birthdateController,
  decoration: InputDecoration(
    labelText: "Birthdate (MMDDYYYY)",
    prefixIcon: Icon(Icons.calendar_today),
    border: OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 2.0),
    ),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: TextStyle(color: Colors.black),
  ),
  style: TextStyle(
    decoration: TextDecoration.none,
    color: Colors.black,
  ),
  keyboardType: TextInputType.text, // Allows both letters and numbers
  inputFormatters: [
    FilteringTextInputFormatter.deny(RegExp(r'[^\dA-Za-z]')), // Allow only letters and numbers
    LengthLimitingTextInputFormatter(16), // Limits the length to 8 characters if necessary
  ],
),

              SizedBox(height: 30),
              signInSignUpButton(context, true, () {
                _login(context);
              }),
            ],
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: logowidget("assets/images/LOGO.png"),
        ),
      ],
    ),
  );
}

}
