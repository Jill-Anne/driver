import 'package:driver/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
    };
    _getUserData();
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is removed from the widget tree
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _database.child('driversAccount').orderByChild('uid').equalTo(user.uid).once().then((DatabaseEvent event) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        userKey = data.keys.firstWhere((k) => data[k]['uid'] == user.uid, orElse: () => null);
        if (userKey != null) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(data[userKey]);
          setState(() {
            controllers['firstName']?.text = userData['firstName'] ?? '';
            controllers['lastName']?.text = userData['lastName'] ?? '';
            controllers['birthdate']?.text = userData['birthdate'] ?? '';
            controllers['idNumber']?.text = userData['idNumber'] ?? '';
            controllers['bodyNumber']?.text = userData['bodyNumber'] ?? '';
            controllers['email']?.text = userData['email'] ?? '';
          });
        }
      }).catchError((error) {
        print('Error fetching user data: $error');
      });
    }
  }

  Future<void> _updateUserData() async {
    Map<String, dynamic> newData = {
      'firstName': controllers['firstName']?.text ?? '',
      'lastName': controllers['lastName']?.text ?? '',
      'birthdate': controllers['birthdate']?.text ?? '',
      'idNumber': controllers['idNumber']?.text ?? '',
      'bodyNumber': controllers['bodyNumber']?.text ?? '',
      'email': controllers['email']?.text ?? '',
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
