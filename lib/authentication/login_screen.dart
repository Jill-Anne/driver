import 'package:driver/pages/dashboard.dart';
import 'package:driver/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController bodyNumberController = TextEditingController();
  TextEditingController birthdayController = TextEditingController();

  // Reference to Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _login(BuildContext context) async {
    try {
      String bodyNumber = bodyNumberController.text;

      // Print the query parameters for debugging
      print('Query: $bodyNumber - ${birthdayController.text}');

      // Query Firestore to check if the combination of body number and birthday exists
      QuerySnapshot querySnapshot = await _firestore
          .collection('driverUsers') // Replace with your Firestore collection name
          .where('bodyNumber', isEqualTo: bodyNumber)
          .where('birthdate', isEqualTo: birthdayController.text)
          .get();

      // Print the raw query result for debugging
      print('Query result: $querySnapshot');

      // Print matched documents for debugging
      print('Matched documents: ${querySnapshot.docs.map((doc) => doc.data())}');

      // Print the number of documents returned by the query
      print('Number of documents: ${querySnapshot.size}');

      // Check if any document matches the query
      bool isMatch = querySnapshot.docs.any((doc) =>
          doc['bodyNumber'].toString().toLowerCase() == bodyNumber.toLowerCase());

      if (isMatch) {
        // If the combination exists, navigate to another page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        // If the combination doesn't exist, show an alert or handle accordingly
        print('Invalid combination of body number and birthday');
        // TODO: Add error handling (show alert or snackbar)
      }
    } catch (e) {
      // Handle any errors
      print('Error: $e');
      // TODO: Add error handling (show alert or snackbar)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your existing UI code
          CustomColumnWithLogo(),
          Positioned(
            top: 100,
            left: 30,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sign in with body number and birthday.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                // Your existing text field code
                TextField(
                  controller: bodyNumberController,
                  obscureText: false,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: const Color.fromARGB(255, 19, 19, 19),
                  style: const TextStyle(color: Color.fromARGB(255, 14, 13, 13)),
                  decoration: InputDecoration(
                    labelText: "Body Number",
                    prefixIcon: Icon(Icons.directions_car, color: const Color.fromARGB(179, 40, 39, 39)),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                // Your existing text field code
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
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 30),
                signInSignUpButton(context, true, () {
                  _login(context);
                }),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: -10,
            child: logowidget("assets/images/LOGO.png"),
          ),
        ],
      ),
    );
  }
}



// class AnotherPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome'),
//       ),
//       body: Center(
//         child: Text('You have successfully logged in!'),
//       ),
//     );
//   }
// }
