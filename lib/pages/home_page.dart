import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:driver/authentication/login_screen.dart';
import 'package:driver/pages/dashboard.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:driver/pushNotification/push_notification_system.dart';
import 'package:driver/widgets/presence_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../global/global_var.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfDriver;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;
  DatabaseReference? newTripRequestReference;

  StreamSubscription<Position>? positionStreamHomePage;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> userData = {};
  void initState() {
    super.initState();
 listenToTripStatus();
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('User is authenticated: ${user.uid}');
        
      } else {
        print('User is not authenticated.');
      }
    });

    

    // Initialize Geofire
    Geofire.initialize('driversLocation');

    // Initialize push notification system
    initializePushNotificationSystem();

    // Call retrieveUserData and print the retrieved data
    retrieveUserData().then((userData) {
      print('Retrieved user data: $userData');
    });

    
        setOnlineStatus(false);
    getOnlineStatus();

  }

  @override
  void dispose() {
    positionStreamHomePage?.cancel();
   //  presenceManager.dispose(); // Stop the PresenceManager timer
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: const EdgeInsets.only(top: 136),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              googleMapCompleterController.complete(controllerGoogleMap);

              getCurrentLiveLocationOfDriver();
            },
          ),
          Container(
            height: 136,
            width: double.infinity,
            color: Colors.black54,
          ),
          Positioned(
            top: 61,
            left: 0,
            right: 0,
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  builder: (BuildContext context) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 5.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7),
                          ),
                        ],
                      ),
                      height: 221,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 11),
                            Text(
                              (!isDriverAvailable)
                                  ? "GO ONLINE NOW"
                                  : "GO OFFLINE NOW",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 21),
                            Text(
                              (!isDriverAvailable)
                                  ? "You are about to go online, you will become available to receive trip requests from users."
                                  : "You are about to go offline, you will stop receiving new trip requests from users.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white30,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Row(
children: [
  Expanded(
    child: ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: const Color.fromARGB(255, 186, 196, 204), // Text color
      ),
      child: const Text("BACK"),
    ),
  ),
                                const SizedBox(width: 16),
                                Expanded(
    child: ElevatedButton(
  onPressed: () {
    if (!isDriverAvailable) {
      goOnlineNow();
      setAndGetLocationUpdates();
      Navigator.pop(context);
      setState(() {
        colorToShow = Colors.red;
        titleToShow = "GO OFFLINE NOW";
        isDriverAvailable = true;
      });
    } else {
      goOfflineNow();
      Navigator.pop(context);
      setState(() {
        colorToShow = Colors.green;
        titleToShow = "GO ONLINE NOW";
        isDriverAvailable = false;
      });
    }
  },
  
  style: ElevatedButton.styleFrom(
    backgroundColor: (titleToShow == "GO ONLINE NOW") 
        ? Colors.green 
        : Colors.pink,
        
  ),
  child: Text(
    "CONFIRM",
    style: TextStyle(
      color: (titleToShow == "GO ONLINE NOW") 
          ? Colors.black // Black text for green background
          : Colors.white, // White text for pink background
      fontWeight: FontWeight.bold, // Bold text
    ),
  ),
  
),

                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorToShow,
              ),
              child: Text(titleToShow,
              style: TextStyle(
      color: Colors.white,  // Force the title text color to white
      fontWeight: FontWeight.bold,  // Bold text
    ),),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: Dashboard(),
          // ),
        ],
      ),
    );
  }

  void getCurrentLiveLocationOfDriver() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfDriver = positionOfUser;
    driverCurrentPosition = currentPositionOfDriver;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

// Add these variables to your class
DateTime? lastUpdateTime;
Position? lastKnownPosition;

void setAndGetLocationUpdates() {
  positionStreamHomePage = Geolocator.getPositionStream().listen((Position position) async {
    currentPositionOfDriver = position;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && isDriverAvailable) {
      try {
        final DateTime now = DateTime.now();
        
        // Debounce logic
        if (lastUpdateTime == null || now.difference(lastUpdateTime!).inSeconds >= 5) {
          // Check for significant movement
          if (lastKnownPosition == null || _hasSignificantMovement(lastKnownPosition!, position)) {
            lastUpdateTime = now; // Update last write time
            lastKnownPosition = position; // Update last known position
            await Geofire.setLocation(user.uid, currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);
          }
        }
      } catch (e) {
        print("Error updating location: $e");
      }
    }

    // Update Google Map camera
    LatLng positionLatLng = LatLng(position.latitude, position.longitude);
    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLng(positionLatLng));
  }, onError: (e) {
    print("Error getting location: $e");
  });
}

// Method to determine if the movement is significant
bool _hasSignificantMovement(Position lastPosition, Position newPosition) {
  const double threshold = 10.0; // meters
  final double distanceInMeters = Geolocator.distanceBetween(
    lastPosition.latitude, lastPosition.longitude,
    newPosition.latitude, newPosition.longitude,
  );
  return distanceInMeters >= threshold;
}


void listenToTripStatus() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DatabaseReference newTripRequestReference = FirebaseDatabase.instance
        .reference()
        .child("driversAccount")
        .child(user.uid)
        .child("newTripStatus");

    newTripRequestReference.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        String newStatus = snapshot.value.toString();
        if (newStatus == "ended") {
          goOnlineNow(); // Make the driver online
        } else if (newStatus == "accepted") {
          goOfflineNow(); // Make the driver offline
        }
      }
    });
  }
}

void goOnlineNow() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Retrieve the current position of the user
      Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      // Initialize Geofire and set the driver's location
      Geofire.initialize("onlineDrivers");
      Geofire.setLocation(
        user.uid,
        positionOfUser.latitude,
        positionOfUser.longitude,
      );

      // Update driver's new trip status to "waiting"
      DatabaseReference userRef = FirebaseDatabase.instance
          .reference()
          .child("driversAccount")
          .child(user.uid);
      await userRef.child("newTripStatus").set("waiting");

      setState(() {
        colorToShow = Colors.pink;
        titleToShow = "GO OFFLINE NOW";
        isDriverAvailable = true;
      });

      print("User is now online.");
    } else {
      print('User is not authenticated.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  } catch (e) {
    print("Error going online: $e");
  }
}


void goOfflineNow() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Stop sharing driver live location updates
      Geofire.removeLocation(user.uid);

      // Stop listening to newTripStatus
      DatabaseReference newTripRequestReference = FirebaseDatabase.instance
          .reference()
          .child("driversAccount")
          .child(user.uid)
          .child("newTripStatus");
      newTripRequestReference.onDisconnect().remove();

      // Update online status
      await setOnlineStatus(false);

      setState(() {
        colorToShow = Colors.green;
        titleToShow = "GO ONLINE NOW";
        isDriverAvailable = false;
      });

      print("User is now offline.");
    }
  } catch (e) {
    print("Error going offline: $e");
  }
}


Future<void> getOnlineStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool previouslyOnline = prefs.getBool('isDriverAvailable') ?? false; // Default to false if not set
  setState(() {
    isDriverAvailable = previouslyOnline;
    colorToShow = isDriverAvailable ? Colors.pink : Colors.green;
    titleToShow = isDriverAvailable ? "GO OFFLINE NOW" : "GO ONLINE NOW";
  });
}


  Future<void> setOnlineStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDriverAvailable', status);
  }


 
  initializePushNotificationSystem() {
    PushNotificationSystem notificationSystem = PushNotificationSystem();
    notificationSystem.generateDeviceRegistrationToken();
    notificationSystem.startListeningForNewNotification(context);
  }
}
