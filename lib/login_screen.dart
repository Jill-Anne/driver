import 'package:flutter/material.dart';
import 'package:driver/reusable_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController plateNumberController = TextEditingController();
  TextEditingController birthdayController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomColumnWithLogo(), // Using the custom column with logo from reusable_widgets.dart
          Positioned(
            top: 100,
            left: 30,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sign in with email or phone number.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                customTextField(
                  "Body Number",
                  Icons.directions_car,
                  false,
                  plateNumberController,
                  inputType: TextInputType.text, // Allowing letters and numbers
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: birthdayController,
                  obscureText: false,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: const Color.fromARGB(255, 19, 19, 19),
                  style: const TextStyle(color: Color.fromARGB(255, 14, 13, 13)),
                  decoration: InputDecoration(
                    labelText: "Birthdate (MMDDYYYY)",
                    prefixIcon: Icon(Icons.calendar_today, color: const Color.fromARGB(179, 40, 39, 39)),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number, // Only allowing numbers
                ),
                const SizedBox(height: 30),
                signInSignUpButton(context, true, () {
                  // Implement your login logic here
                }),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: -10,
            child: logowidget("assets/images/LOGO.png"), // Inserting the logo
          ),
        ],
      ),
    );
  }
}
