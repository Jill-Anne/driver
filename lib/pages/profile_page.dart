import 'package:driver/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This function retrieves user data from Firebase without needing a controller.
// It can be reused in any part of your project where user data needs to be fetched.
Future<Map<String, dynamic>> retrieveUserData() async {
  final DatabaseReference database = FirebaseDatabase.instance.reference();
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  if (user != null) {
    final DatabaseEvent event = await database.child('driversAccount').orderByChild('uid').equalTo(user.uid).once();
    final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
    final String userKey = data.keys.firstWhere((k) => data[k]['uid'] == user.uid, orElse: () => '');
    if (userKey.isNotEmpty) {
      final userData = Map<String, dynamic>.from(data[userKey]);
      print('Retrieved user data: $userData'); // Print the retrieved data
      return userData;
    }
  }
  print('No user data found.');
  return {};
}


class ProfilePage extends StatefulWidget {
  static const String id = "profilePage";

  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, TextEditingController> controllers = {};
  String userKey = '';

  @override
  void initState() {
    super.initState();
    controllers = {
      'firstName': TextEditingController(),
      'lastName': TextEditingController(),
      'birthdate': TextEditingController(),
      'idNumber': TextEditingController(),
      'bodyNumber': TextEditingController(),
      'email': TextEditingController(),
      'phoneNumber': TextEditingController(), // Added phone number controller
    };
    _getUserData();
    _listenUserDataChanges(); // Listen to changes in user data
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _getUserData() async {
    final userData = await retrieveUserData();
    if (userData.isNotEmpty) {
      setState(() {
        userKey = userData['uid'] ?? '';
        controllers['firstName']?.text = userData['firstName'] ?? '';
        controllers['lastName']?.text = userData['lastName'] ?? '';
        controllers['birthdate']?.text = userData['birthdate'] ?? '';
        controllers['idNumber']?.text = userData['idNumber'] ?? '';
        controllers['bodyNumber']?.text = userData['bodyNumber'] ?? '';
        controllers['email']?.text = userData['email'] ?? '';
        controllers['phoneNumber']?.text = userData['phoneNumber'] ?? ''; // Set phone number text
      });
    }
  }
void _listenUserDataChanges() {
  _database.child('driversAccount').child(userKey).onValue.listen((event) {
    final Map<dynamic, dynamic>? userDataMap = event.snapshot.value as Map<dynamic, dynamic>?;

    if (userDataMap != null) {
      final userData = Map<String, dynamic>.from(userDataMap);
      setState(() {
        controllers['firstName']?.text = userData['firstName'] ?? '';
        controllers['lastName']?.text = userData['lastName'] ?? '';
        controllers['birthdate']?.text = userData['birthdate'] ?? '';
        controllers['idNumber']?.text = userData['idNumber'] ?? '';
        controllers['bodyNumber']?.text = userData['bodyNumber'] ?? '';
        controllers['email']?.text = userData['email'] ?? '';
        controllers['phoneNumber']?.text = userData['phoneNumber'] ?? ''; // Set phone number text
      });
    } else {
      // Handle null case or set default values if needed
    }
  });
}


  Future<void> _updateUserData() async {
    Map<String, dynamic> newData = {
      'firstName': controllers['firstName']?.text ?? '',
      'lastName': controllers['lastName']?.text ?? '',
      'birthdate': controllers['birthdate']?.text ?? '',
      'idNumber': controllers['idNumber']?.text ?? '',
      'bodyNumber': controllers['bodyNumber']?.text ?? '',
      'email': controllers['email']?.text ?? '',
      'phoneNumber': controllers['phoneNumber']?.text ?? '', // Include phone number in update
    };

    await _database.child('driversAccount').child(userKey).update(newData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully.')));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $error')));
    });
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ...controllers.keys.map((String field) {
            return TextField(
              controller: controllers[field],
              decoration: InputDecoration(
                labelText: field[0].toUpperCase() + field.substring(1), // Capitalize label
              ),
              keyboardType: field == 'email' ? TextInputType.emailAddress : TextInputType.text,
            );
          }),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateUserData,
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}