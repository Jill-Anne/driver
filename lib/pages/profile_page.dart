import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<Map<String, dynamic>> retrieveUserData() async {
  final DatabaseReference database = FirebaseDatabase.instance.reference();
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  if (user != null) {
    final DatabaseEvent event = await database
        .child('driversAccount')
        .orderByChild('uid')
        .equalTo(user.uid)
        .once();
    final Map<dynamic, dynamic> data =
        event.snapshot.value as Map<dynamic, dynamic>;
    final String userKey = data.keys
        .firstWhere((k) => data[k]['uid'] == user.uid, orElse: () => '');
    if (userKey.isNotEmpty) {
      final userData = Map<String, dynamic>.from(data[userKey]);
      userData['key'] = userKey;
      print('Retrieved user data: $userData');
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
  final ImagePicker _picker = ImagePicker();

  Map<String, TextEditingController> controllers = {};
  String userKey = '';
  File? _imageFile;
  String? _driverPhotoUrl;
  bool _loadingImage = false;

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
      'phoneNumber': TextEditingController(),
    };
    _getUserData();
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
        userKey = userData['key'] ?? '';
        controllers['firstName']?.text = userData['firstName'] ?? '';
        controllers['lastName']?.text = userData['lastName'] ?? '';
        controllers['birthdate']?.text = userData['birthdate'] ?? '';
        controllers['idNumber']?.text = userData['idNumber'] ?? '';
        controllers['bodyNumber']?.text = userData['bodyNumber'] ?? '';
        controllers['email']?.text = userData['email'] ?? '';
        controllers['phoneNumber']?.text = userData['phoneNumber'] ?? '';
        _driverPhotoUrl = userData['driverPhoto'];
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
      'phoneNumber': controllers['phoneNumber']?.text ?? '',
    };

    await _database.child('driversAccount').child(userKey).update(newData);
  }

  Future<void> _pickImage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    if (await Permission.storage.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadDriverPhoto(_imageFile!);
      }
    } else {
      print('Storage permission not granted');
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _uploadDriverPhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('User is not authenticated.');
      return;
    }

    try {
      setState(() {
        _loadingImage = true; // Set loading state while uploading
      });

      final storageReference =
          FirebaseStorage.instance.ref().child('driver_photos/${user.uid}.jpg');
      final uploadTask = storageReference.putFile(imageFile);

      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      final photoUrl = await taskSnapshot.ref.getDownloadURL();

      await _database
          .child('driversAccount')
          .child(userKey)
          .update({'driverPhoto': photoUrl});

      setState(() {
        _driverPhotoUrl = photoUrl;
        _loadingImage = false; // Reset loading state after uploading
      });
    } catch (e) {
      print('Error uploading driver photo: $e');
      setState(() {
        _loadingImage = false; // Reset loading state on error
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text('This app needs photo access to upload profile pictures.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateUserData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
           CachedNetworkImage(
              imageUrl: _driverPhotoUrl ?? '',
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 50,
                backgroundImage: imageProvider,
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: Text('Upload Profile Picture'),
            ),
            TextFormField(
              controller: controllers['firstName'],
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextFormField(
              controller: controllers['lastName'],
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextFormField(
              controller: controllers['birthdate'],
              decoration: InputDecoration(labelText: 'Birthdate'),
            ),
            TextFormField(
              controller: controllers['idNumber'],
              decoration: InputDecoration(labelText: 'ID Number'),
            ),
            TextFormField(
              controller: controllers['bodyNumber'],
              decoration: InputDecoration(labelText: 'Body Number'),
            ),
            TextFormField(
              controller: controllers['email'],
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: controllers['phoneNumber'],
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
      ),
    );
  }
}
