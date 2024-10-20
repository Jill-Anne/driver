import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/methods/common_methods.dart';

class ForgotPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final CommonMethods cMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Text(
              "Forgot Password",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Enter your email to receive a password reset link",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 35),
            Container(
              width: 300,
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 120),
            Container(
              width: 300,
              height: 60,
              child: TextButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  if (email.isNotEmpty) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      cMethods.displaySnackBar("Password reset email sent!", context);
                      Navigator.pop(context);
                    } catch (e) {
                      cMethods.displaySnackBar("Error: ${e.toString()}", context);
                    }
                  } else {
                    cMethods.displaySnackBar("Please enter your email.", context);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 1, 42, 123),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  "Send Code",
                  style: TextStyle(fontSize: 21),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void navigateToForgotPassword(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
  );
}

Widget forgotPasswordText(BuildContext context) {
  return Center(
    child: GestureDetector(
      onTap: () {
        navigateToForgotPassword(context);
      },
      child: const Text(
        "Forgot Password?",
        style: TextStyle(
          color: Color.fromARGB(255, 1, 42, 123),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
