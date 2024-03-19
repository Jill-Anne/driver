import 'package:driver/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/reusable_widgets.dart';

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
    UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: birthdate,
    );

    if (userCredential.user != null) {
      print('Login successful.');
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
