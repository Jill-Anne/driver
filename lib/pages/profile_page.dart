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

  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _birthdateController = TextEditingController();
  TextEditingController _idNumberController = TextEditingController();
  TextEditingController _bodyNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
bool _isPasswordVisible = false;
bool _isPasswordSet = false; // Ensure this is defined
  String userKey = '';
  File? _imageFile;
  String? _driverPhotoUrl;
  bool _loadingImage = false;
  double _averageRating = 0.0;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _obscureText = true; // Track whether the text is obscured
  
 // Whether to obscure the password or not

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadUserData();
        _passwordController.addListener(() {
      setState(() {});
    });
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
    _averageRating = userData['totalRatings']?['averageRating']?.toDouble() ?? 0.0;
    _isLoading = false;
  });
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

  String? currentPassword;

  if (_emailController.text.isNotEmpty || _passwordController.text.isNotEmpty) {
    // Prompt for password to re-authenticate only if updating email or password
    currentPassword = await _showCurrentPasswordDialog();
    if (currentPassword == null || currentPassword.isEmpty) {
      print('Current password is required for updates.');
      return; // User canceled the prompt or didn't enter a password
    }
  }

  if (_emailController.text.isNotEmpty) {
    String newEmail = _emailController.text;
    print('Attempting to update email to: $newEmail');

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user is currently signed in.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    try {
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword!,
      );
      await user.reauthenticateWithCredential(credential);
      print('Re-authentication successful.');

      // Update the email in Firebase Auth
      await user.updateEmail(newEmail);
      print('Email updated to: $newEmail');

      // Update the email in Realtime Database
      updatedData['email'] = newEmail;

      // Send a verification email to the new address
      await user.sendEmailVerification();
      print('Verification email sent to $newEmail');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A verification email has been sent to $newEmail. Please verify it.')),
      );

    } catch (e) {
      // Handle errors related to email update
      print('Error updating email: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating email: ${e.toString()}')),
      );
      return; // Abort the update if email update fails
    }
  }

  if (_passwordController.text.isNotEmpty) {
    print('Updating password as part of user data update.');
    await _updatePassword(_passwordController.text, currentPassword!);
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User data updated successfully')),
    );
  } catch (e) {
    print('Error updating user data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating user data: $e')),
    );
  }
}

Future<String?> _showCurrentPasswordDialog() async {
  String currentPassword = '';
  bool _isPasswordVisible = false; // Visibility state

  await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController _currentPasswordController = TextEditingController();

      return AlertDialog(
        title: const Center(
          child: Text(
            'Re-enter Current Password',
            style: TextStyle(color: Color.fromARGB(255, 1, 42, 123), fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: !_isPasswordVisible, // Toggle visibility
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 1, 42, 123)),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Color.fromARGB(255, 1, 42, 123)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Color.fromARGB(255, 1, 42, 123),
                      ),
                      onPressed: () {
                        // Toggle the visibility state
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: <Widget>[
          Center(
            child: Container(
              height: 50,
              width: 150,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 1, 42, 123),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  currentPassword = _currentPasswordController.text;
                  print('Current password entered in dialog: $currentPassword');
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  return currentPassword;
}



Future<void> _updatePassword(String newPassword, String currentPassword) async {
  final user = _auth.currentUser;
  if (user != null && newPassword.isNotEmpty) {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      print('Password updated successfully.');
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPasswordSet', true);
      setState(() {
        _isPasswordSet = true;
      });

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

    // Upload the image to Firebase Storage
    final storageReference = FirebaseStorage.instance.ref().child('driver_photos/${user.uid}.jpg');
    final uploadTask = storageReference.putFile(imageFile);

    final TaskSnapshot taskSnapshot = await uploadTask;
    final photoUrl = await taskSnapshot.ref.getDownloadURL();

    // Get a reference to the driversAccount node
    final driversRef = FirebaseDatabase.instance.ref().child('driversAccount');

    // Query to find the node with matching uid
    final driverSnapshot = await driversRef.orderByChild('uid').equalTo(user.uid).once();

    if (driverSnapshot.snapshot.exists) {
      // Since `equalTo` may return multiple results, ensure you get the correct path
      final Map<dynamic, dynamic> driverData = driverSnapshot.snapshot.value as Map<dynamic, dynamic>;

      driverData.forEach((key, value) async {
        // Update the driverPhoto URL in the located node
        await driversRef.child(key).update({'driverPhoto': photoUrl});
        print('Updated driverPhoto in node: $key');
      });
    } else {
      print('No matching driver found with UID: ${user.uid}');
    }

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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 1, 42, 123),//Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  return Scaffold(
    resizeToAvoidBottomInset: true, // Allow resizing to accommodate the keyboard
    body: Column(
      children: [
        Container(
           color: _isEditing ? Colors.white : Color.fromARGB(255, 1, 42, 123),
          height: 60,
          padding: const EdgeInsets.only(
            left: 13.0,
            right: 0,
            top: 25.0,
            bottom: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _isEditing = false; // Exit edit mode without saving
                    });
                  },
                ),
              if (_isEditing)
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
  child: SingleChildScrollView(
    child: Column(
      children: [
        // Blue background with border radius
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 1, 42, 123),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30), // Adjust the radius as needed
            ),
          ),
          height: 110, // Blue background height
        ),
                // Content with upward transformation
                Transform.translate(
                  offset: Offset(0, -80), // Adjust the Y value to move it upward
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                bottom: 0,
                                right: -5,
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
                                      color: const Color.fromARGB(255, 27, 70, 154),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isEditing ? Icons.camera_alt : Icons.edit,
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                WidgetSpan(
                                  child: SizedBox(height: 20),
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
                                  child: SizedBox(width: 2),
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
                              ...getStarRating(_averageRating),
                              const SizedBox(width: 6),
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
                        _buildInputField(), // Input fields
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
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


Widget _buildInputField() {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: TextField(
          controller: _birthdateController,
          enabled: false,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.cake, color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
      ),
      SizedBox(height: 20),
      _buildTextField(
        controller: _phoneNumberController,
        icon: Icon(Icons.phone),
        enabled: _isEditing,
      ),
      SizedBox(height: 20),
      _buildTextField(
        controller: _emailController,
        icon: Icon(Icons.email),
        enabled: _isEditing,
      ),
      SizedBox(height: 20),
      _buildPasswordField(),
    ],
  );
}


    void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      enabled: _isEditing, // Only editable if _isEditing is true
      obscureText: _obscureText, // Toggle between obscure and visible text
      style: const TextStyle(color: Colors.black), // Ensure text stays black
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.black), // Black icon
        hintText: _isEditing || _passwordController.text.isNotEmpty ? null : '••••••••', // Remove hint when editing or text is present
        hintStyle: const TextStyle(
          color: Colors.black, // Dots will be black
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black), // Black border when enabled
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2.0), // Black border when focused
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black), // Black border when disabled
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black), // Default black border
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.black, // Black icon color
          ),
          onPressed: _toggleObscureText, // Toggle visibility
        ),
      ),
      onTap: () {
        setState(() {
          _isEditing = true; // Set editing state when user taps on the field
        });
      },
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
