import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceManager {
  final String userId;
  final DatabaseReference _onlineDriversRef = FirebaseDatabase.instance.ref('onlineDrivers');
  final DatabaseReference _connectedRef = FirebaseDatabase.instance.ref('.info/connected');
  
  PresenceManager(this.userId) {
    _connectedRef.onValue.listen((event) {
      bool connected = event.snapshot.value as bool;
      if (connected) {
        _setDriverOnline();
      } else {
        _setDriverOffline();
      }
    });
  }

  void _setDriverOnline() {
    _onlineDriversRef.child(userId).set(true).then((_) {
      // Set an onDisconnect operation to remove the driver when they disconnect
      _onlineDriversRef.child(userId).onDisconnect().remove();
    });
  }

  void _setDriverOffline() {
    // Handle the offline logic here if needed
  }
}
