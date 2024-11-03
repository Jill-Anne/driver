/*
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceManager {
  final String userId;
  final DatabaseReference _onlineDriversRef = FirebaseDatabase.instance.ref('onlineDrivers');

  PresenceManager(this.userId) {
    _checkInitialConnection();

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setDriverOffline();
      }
      // No action needed for ConnectivityResult.mobile or ConnectivityResult.wifi
    });
  }

  void _checkInitialConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setDriverOffline();
    }
    // Do nothing if there's a connection
  }

  void setDriverOnline() {
    // Set the driver online only when explicitly called
    _onlineDriversRef.child(userId).set(true).then((_) {
      _onlineDriversRef.child(userId).onDisconnect().remove();
      print("Driver is set online.");
    }).catchError((e) {
      print("Error setting driver online: $e");
    });
  }

  void setDriverOffline() {
    _onlineDriversRef.child(userId).remove().then((_) {
      print("Driver is set offline.");
    }).catchError((e) {
      print("Error setting driver offline: $e");
    });
  }

  void dispose() {
    // No timers to cancel anymore
  }
}

*/