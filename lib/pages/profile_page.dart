import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/authentication/login_screen.dart';
import 'package:driver/widgets/rating_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      //final averageRating = userData['totalRatings']['averageRating'] ?? 0.0;
      userData['driverPhoto'] = driverPhoto;
      //userData['averageRating'] = averageRating;
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
  TextEditingController _passwordController = TextEditingController();

bool _isPasswordSet = false; // Ensure this is defined
  String userKey = '';
  File? _imageFile;
  String? _driverPhotoUrl;
  bool _loadingImage = false;
  double _averageRating = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    Map<String, dynamic> userData = await retrieveUserData();
    setState(() {
      _averageRating = userData['totalRatings']['averageRating'] ??
          0.0; // Ensure you access the correct field
      _isLoading = false; // Set loading to false once data is fetched
    });
  }

  

Future<void> _updatePassword(String newPassword) async {
  final user = _auth.currentUser;
  if (user != null && newPassword.isNotEmpty) {
    try {
      String currentPassword = await _showCurrentPasswordDialog();
      if (currentPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current password is required for password update.')),
        );
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPasswordSet', true);

      setState(() {
        _isPasswordSet = true;
      });

      print('Password updated successfully. Password set flag updated.');
    } catch (e) {
      print('Error updating password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }
  } else {
    print('User not authenticated or password is empty.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User not authenticated or password is empty.')),
    );
  }
}


Future<void> _updateUserData() async {
  print('Starting user data update...');
  
  if (userKey.isEmpty) {
    print('User key is empty, aborting update.');
    return; // Ensure that userKey is available
  }

  final names = _fullNameController.text.split(' ');
  final firstName = names.length > 1 ? names[0] : '';
  final lastName = names.length > 1 ? names.sublist(1).join(' ') : names.first;

  Map<String, dynamic> updatedData = {};

  // Add fields to be updated
  if (_fullNameController.text.isNotEmpty) {
    updatedData['firstName'] = firstName;
    updatedData['lastName'] = lastName;
    print('Updating full name to: $firstName $lastName');
  }
  if (_birthdateController.text.isNotEmpty) {
    updatedData['birthdate'] = _birthdateController.text;
    print('Updating birthdate to: ${_birthdateController.text}');
  }
  if (_idNumberController.text.isNotEmpty) {
    updatedData['idNumber'] = _idNumberController.text;
    print('Updating ID number to: ${_idNumberController.text}');
  }
  if (_bodyNumberController.text.isNotEmpty) {
    updatedData['bodyNumber'] = _bodyNumberController.text;
    print('Updating body number to: ${_bodyNumberController.text}');
  }
  if (_emailController.text.isNotEmpty) {
    updatedData['email'] = _emailController.text;
    print('Updating email to: ${_emailController.text}');
  }
  if (_phoneNumberController.text.isNotEmpty) {
    updatedData['phoneNumber'] = _phoneNumberController.text;
    print('Updating phone number to: ${_phoneNumberController.text}');
  }

  try {
    if (updatedData.isNotEmpty) {
      await _database.child('driversAccount').child(userKey).update(updatedData);
      print('User data updated in Firebase.');
    }

    // Optionally handle password update if still applicable
    if (_passwordController.text.isNotEmpty) {
      print('Updating password as part of user data update.');
      await _updatePassword(_passwordController.text);
    }

    // Provide success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User data updated successfully')),
    );
  } catch (e) {
    // Provide error feedback
    print('Error updating user data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating user data: $e')),
    );
  }
}

Future<String> _showCurrentPasswordDialog() async {
  String currentPassword = '';

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController _currentPasswordController = TextEditingController();

      return AlertDialog(
        title: Text(
          'Re-enter Current Password',
          style: TextStyle(color: Colors.black),
        ),
        content: TextField(
          controller: _currentPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Current Password',
            labelStyle: TextStyle(color: Colors.black),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              currentPassword = _currentPasswordController.text;
              print('Current password entered in dialog: $currentPassword');
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      );
    },
  );

  return currentPassword;
}

Future<void> _updatePasswordAndSetFlag(String newPassword) async {
  try {
    final user = _auth.currentUser;

    if (user != null) {
      await user.updatePassword(newPassword);
      print('Password updated successfully.');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? currentFlag = prefs.getBool('isPasswordSet');
      print('Current isPasswordSet before updating: $currentFlag');
      
      await prefs.setBool('isPasswordSet', true);
      setState(() {
        _isPasswordSet = true;
      });
      print("Password set flag (_isPasswordSet) updated to: $_isPasswordSet");

 await FirebaseDatabase.instance
        .reference()
        .child('users')
        .child(user.uid)
        .child('passwordSet')
        .set(true)
        .catchError((error) {
          print('Failed to set password flag: $error');
        });

      
    }
  } catch (error) {
    print('Failed to update password: $error');
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

void goOfflineNow() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Stop sharing driver live location updates
      Geofire.removeLocation(user.uid);

      // Remove the user from "onlineDrivers"
      Geofire.removeLocation(user.uid);

      // Remove the deviceToken from the database for the current user
      DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance
          .ref()
          .child("driversAccount")
          .child(user.uid)
          .child("deviceToken");
          
      await referenceOnlineDriver.remove();  // Remove device token from current user
      print("Removed device token for user: ${user.uid}");

     
    }
  } catch (e) {
    print("Error going offline: $e");
  }
}


Future<void> _logout() async {
  try {
    goOfflineNow();  // Go offline and remove the device token

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');  // Remove auth token
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    
    print("User logged out and token removed.");
  } catch (e) {
    print("Error during logout: $e");
  }
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
                  height: 70, // Blue background
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 0), // Space to position image
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
                                        placeholder: (context, url) =>
                                            Image.asset(
                                          'assets/images/avatarman.png',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                          'assets/images/avatarman.png',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom:
                                  -10, // Adjust to move the icon up slightly
                              right: -9,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_isEditing) {
                                      _pickImage();
                                    }
                                    _isEditing =
                                        !_isEditing; // Toggle edit mode
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 1, 42, 123),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isEditing
                                        ? Icons.camera_alt
                                        : Icons
                                            .edit, // Change icon based on state
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),

                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: '${_fullNameController.text}\n',
                                style: const TextStyle(
                                  fontSize:
                                      20, // Different font size for the name
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              WidgetSpan(
                                child: SizedBox(
                                    height: 20), // Add spacing between lines
                              ),
                              TextSpan(
                                text: 'ID #: ${_idNumberController.text} ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              WidgetSpan(
                                child: SizedBox(
                                    width:
                                        2), // Adjust the width to your preference for spacing
                              ),
                              TextSpan(
                                text: 'BODY #: ${_bodyNumberController.text}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Star rating widgets
                            ...getStarRating(_averageRating),
                            const SizedBox(
                                width:
                                    6), // Add space between stars and rating text
                            // Rating text
                            Text(
                              _averageRating.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                    
SizedBox(height: 40),
Container(
  //width: 700.0,
  padding: EdgeInsets.symmetric(horizontal: 0), // Add padding to match the text field's appearance
  child: TextField(
    controller: _birthdateController,
    enabled: false, // Disable editing
    decoration: InputDecoration(
      prefixIcon: Icon(Icons.cake, color: Colors.black), // Birthday icon with black color
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Black border for enabled field
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2.0), // Black border when focused
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Black border when disabled
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Default black border
      ),
    ),
    style: TextStyle(color: Colors.black), // Ensure the text remains black
  ),
),

SizedBox(height: 20),
_buildTextField(
  controller: _emailController,
  icon: Icon(Icons.email), // Email icon
  enabled: _isEditing, // Enable editing only if _isEditing is true
),

SizedBox(height: 20),
_buildTextField(
  controller: _phoneNumberController,
  icon: Icon(Icons.phone), // Phone number icon
  enabled: _isEditing, // Enable editing only if _isEditing is true
),

                  SizedBox(height: 20),
                  _buildPasswordField(), // Add password field


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

Widget _buildPasswordField() {
  return TextField(
    controller: _passwordController,
    enabled: _isEditing, // Only editable if _isEditing is true
    obscureText: true, // To hide password input
    style: TextStyle(color: Colors.black), // Ensure text stays black
    decoration: InputDecoration(
      prefixIcon: Icon(Icons.lock, color: Colors.black), // Black icon
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Black border when enabled
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2.0), // Black border when focused
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Black border when disabled
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Default black border
      ),
    ),
  );
}


// Reusable text field builder
Widget _buildTextField({
  required TextEditingController controller,
  required Icon icon,
  bool enabled = true, // By default, fields are editable unless specified
}) {
  return TextField(
    controller: controller,
    enabled: enabled, // Enable or disable based on _isEditing state
    decoration: InputDecoration(
      prefixIcon: IconTheme(
        data: IconThemeData(color: Colors.black), // Set icon color to black
        child: icon,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Black border for enabled field
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2.0), // Black border when focused
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Black border when disabled
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Default black border
      ),
    ),
    style: TextStyle(color: Colors.black), // Ensure the text remains black
  );
}


}
