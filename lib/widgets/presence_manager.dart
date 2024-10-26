import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';

class PresenceManager {
  final String userId;
  final DatabaseReference _onlineDriversRef = FirebaseDatabase.instance.ref('onlineDrivers');
  Timer? _pingTimer;

  PresenceManager(this.userId) {
    _checkInitialConnection();

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _checkPingAndSetOnline();
      } else {
        _setDriverOffline();
      }
    });
  }

  void _checkInitialConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      _checkPingAndSetOnline();
    } else {
      _setDriverOffline();
    }
  }

  Future<void> _checkPingAndSetOnline() async {
    if (await _pingServer('8.8.8.8')) {
      _setDriverOnline();
    } else {
      _setDriverOffline();
    }

    // Start a periodic ping to check connectivity
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (await _pingServer('8.8.8.8')) {
        _setDriverOnline();
      } else {
        _setDriverOffline();
      }
    });
  }

  Future<bool> _pingServer(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _setDriverOnline() {
    _onlineDriversRef.child(userId).set(true).then((_) {
      _onlineDriversRef.child(userId).onDisconnect().remove();
    });
  }

  void _setDriverOffline() {
    // Handle the offline logic here if needed
  }

  void dispose() {
    _pingTimer?.cancel();
  }
}
