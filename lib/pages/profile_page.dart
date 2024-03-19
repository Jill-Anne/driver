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

  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _database.child('driversAccount').orderByChild('uid').equalTo(user.uid).once().then((DatabaseEvent event) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        final key = data.keys.firstWhere((k) => data[k]['uid'] == user.uid, orElse: () => null);
        if (key != null) {
          setState(() {
            userData = Map<String, dynamic>.from(data[key]);
          });
        }
      }).catchError((error) {
        print('Error fetching user data: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: userData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: <Widget>[
                ListTile(
                  title: Text('First Name'),
                  subtitle: Text(userData['firstName'] ?? 'N/A'),
                ),
                ListTile(
                  title: Text('Last Name'),
                  subtitle: Text(userData['lastName'] ?? 'N/A'),
                ),
                ListTile(
                  title: Text('Birthdate'),
                  subtitle: Text(userData['birthdate'] ?? 'N/A'),
                ),
                ListTile(
                  title: Text('ID Number'),
                  subtitle: Text(userData['idNumber'] ?? 'N/A'),
                ),
                ListTile(
                  title: Text('Body Number'),
                  subtitle: Text(userData['bodyNumber'] ?? 'N/A'),
                ),
                ListTile(
                  title: Text('Email'),
                  subtitle: Text(userData['email'] ?? 'N/A'),
                ),
                // Add more ListTiles for additional data fields if necessary
              ],
            ),
    );
  }
}
