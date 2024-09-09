import 'package:driver/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/reusable_widgets.dart';
import 'package:lottie/lottie.dart';
import '../pages/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String birthdate = _birthdateController.text.trim();

    // Validate email and birthdate
    if (email.isEmpty || birthdate.isEmpty) {
      _showErrorDialog(
        context,
        "Please enter both email and birthdate.",
      );
      return;
    }

    try {
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

      // Simulate login process (replace with actual login code)
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: birthdate,
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
      } else {
        print('Login failed: User is null.');
        _showErrorDialog(
          context,
          "User authentication failed. Please check your credentials.",
        );
      }
    } catch (error) {
      // Close the animation dialog before showing error
      Navigator.pop(context);

      print('Login failed: $error');
      _showErrorDialog(context, "An error occurred: $error");
    }
  }

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
      resizeToAvoidBottomInset: false, // Prevents resizing when keyboard is shown
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
                  "Sign in with email and birthday.",
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
                    decoration: TextDecoration.none, // No underline
                    color: Colors.black,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
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
                    decoration: TextDecoration.none, // No underline
                    color: Colors.black,
                  ),
                  keyboardType: TextInputType.number,
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
