import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
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
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
bool _isEditing = false;
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
  if (userKey.isEmpty) return; // Ensure that userKey is available

  final names = _fullNameController.text.split(' ');
  final firstName = names.length > 1 ? names[0] : '';
  final lastName =
      names.length > 1 ? names.sublist(1).join(' ') : names.first;

  Map<String, dynamic> updatedData = {};

  // Add fields to be updated
  if (_fullNameController.text.isNotEmpty) {
    updatedData['firstName'] = firstName;
    updatedData['lastName'] = lastName;
  }
  if (_birthdateController.text.isNotEmpty) {
    updatedData['birthdate'] = _birthdateController.text;
  }
  if (_idNumberController.text.isNotEmpty) {
    updatedData['idNumber'] = _idNumberController.text;
  }
  if (_bodyNumberController.text.isNotEmpty) {
    updatedData['bodyNumber'] = _bodyNumberController.text;
  }
  if (_emailController.text.isNotEmpty) {
    updatedData['email'] = _emailController.text;
  }
  if (_phoneNumberController.text.isNotEmpty) {
    updatedData['phoneNumber'] = _phoneNumberController.text;
  }

  if (updatedData.isNotEmpty) {
    await _database.child('driversAccount').child(userKey).update(updatedData);
  }
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
          content: const Text(
              'This app needs photo access to upload profile pictures.'),
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
    // Set the status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 60,
            padding: const EdgeInsets.only(
              left: 13.0,
              right: 0,
              top: 20.0,
              bottom: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isEditing) // Show the X icon when editing
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      setState(() {
                        _isEditing = false; // Exit edit mode without saving
                      });
                    },
                  ),
                if (_isEditing) // Show the save button when editing
                  TextButton(
                    onPressed: () {
                      _updateUserData();
                      setState(() {
                        _isEditing = false; // Exit edit mode after saving
                      });
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Color.fromARGB(255, 1, 42, 123), 
                  height: 120,// Blue background
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 35), // Space to position image
                      Center(
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 32, 2, 87),
            width: 4,
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
                      "https://firebasestorage.googleapis.com/v0/b/driver-test-ef6fc.appspot.com/o/driver_photos%2Fdefault.jpg?alt=media",
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Image.asset(
                    'assets/images/avatarman.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/avatarman.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
      Positioned(
        bottom: -10, // Adjust to move the icon up slightly
        right: -9,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (_isEditing) {
                _pickImage();
              }
              _isEditing = !_isEditing; // Toggle edit mode
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 1, 42, 123),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isEditing ? Icons.camera_alt : Icons.edit, // Change icon based on state
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  ),
),

                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _birthdateController,
                        label: 'Birthdate',
                        hint: 'Enter your birthdate',
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _idNumberController,
                        label: 'ID Number',
                        hint: 'Enter your ID number',
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _bodyNumberController,
                        label: 'Body Number',
                        hint: 'Enter your body number',
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _phoneNumberController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: _logout,
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      width: double
          .infinity, // Set width of the TextField container (adjust as needed)
      height: 40, // Set height of the TextField container (adjust as needed)
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Color.fromARGB(255, 32, 2, 87), // Label color
          ),
          hintStyle: TextStyle(
            color: Colors.grey, // Hint text color
          ),
          contentPadding: EdgeInsets.only(
            top: 5.0, // Adjust this value for top padding inside the TextField
            left:
                10.0, // Adjust this value for left padding inside the TextField
            right:
                10.0, // Adjust this value for right padding inside the TextField
            bottom:
                0.0, // Adjust this value for bottom padding inside the TextField
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                3.0), // Rounded corners (adjust as needed)
            borderSide: BorderSide(color: Color.fromARGB(255, 32, 2, 87)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                3.0), // Rounded corners (adjust as needed)
            borderSide: BorderSide(color: Color.fromARGB(255, 32, 2, 87)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                3.0), // Rounded corners (adjust as needed)
            borderSide: BorderSide(color: Color.fromARGB(255, 32, 2, 87)),
          ),
        ),
      ),
    );
  }
}
