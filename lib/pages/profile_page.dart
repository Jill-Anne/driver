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
  final DatabaseReference database = FirebaseDatabase.instance.ref();
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
      // Fetch currentTripID, deviceToken, and driverPhoto
      final currentTripID = userData['currentTripID'];
      final driverPhoto = userData['driverPhoto'] ?? '';
      userData['driverPhoto'] = driverPhoto;
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

  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _birthdateController = TextEditingController();
  TextEditingController _idNumberController = TextEditingController();
  TextEditingController _bodyNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  String userKey = '';
  File? _imageFile;
  String? _driverPhotoUrl;
  bool _loadingImage = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthdateController.dispose();
    _idNumberController.dispose();
    _bodyNumberController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _getUserData() async {
    final userData = await retrieveUserData();
    if (userData.isNotEmpty) {
      setState(() {
        userKey = userData['key'] ?? '';
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        _fullNameController.text = '$firstName $lastName';
        _birthdateController.text = userData['birthdate'] ?? '';
        _idNumberController.text = userData['idNumber'] ?? '';
        _bodyNumberController.text = userData['bodyNumber'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneNumberController.text = userData['phoneNumber'] ?? '';
        _driverPhotoUrl = userData['driverPhoto'];
      });
    }
  }

  Future<void> _updateUserData() async {
    final names = _fullNameController.text.split(' ');
    final firstName = names.length > 1 ? names[0] : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : names.first;

    Map<String, dynamic> newData = {
      'firstName': firstName,
      'lastName': lastName,
      'birthdate': _birthdateController.text,
      'idNumber': _idNumberController.text,
      'bodyNumber': _bodyNumberController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneNumberController.text,
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
          .child(user.uid)
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
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color.fromARGB(255, 15, 27, 90),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 15, 27, 90),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Color.fromARGB(255, 15, 27, 90),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 105, // Slightly larger to accommodate the border
                      height: 105, // Slightly larger to accommodate the border
                      decoration: BoxDecoration(
                        color: Colors.white, // Background color for the container
                        shape: BoxShape.circle, // Ensures the border is circular
                        border: Border.all(
                          color: Color.fromARGB(255, 32, 2, 87), // Border color
                          width: 4, // Border width
                        ),
                      ),
                      child: ClipOval(
                        child: _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: _driverPhotoUrl ?? 
                                    "https://firebasestorage.googleapis.com/v0/b/passenger-signuplogin.appspot.com/o/avatarman.png?alt=media&token=11c39289-3c10-4355-9537-9003913dbeef",
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),
              _buildTextField('Full Name', _fullNameController),
              _buildTextField('Birthdate', _birthdateController),
              _buildTextField('ID Number', _idNumberController),
              _buildTextField('Body Number', _bodyNumberController),
              _buildTextField('Email', _emailController),
              _buildTextField('Phone Number', _phoneNumberController),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _updateUserData();
                    // Optionally show a confirmation message
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 15, 27, 90),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), // Adjusted padding
        ),
      ),
    );
  }
}
