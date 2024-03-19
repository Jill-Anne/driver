import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationSystem {
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async {
    try {
      String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();
      
      // Print the retrieved device recognition token
      print('Device Registration Token: $deviceRecognitionToken');

      if (deviceRecognitionToken != null) {
        DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance
            .reference()
            .child("driversAccount")
            .child(FirebaseAuth.instance.currentUser!.uid)
            .child("deviceToken");

        referenceOnlineDriver.set(deviceRecognitionToken);
        
        // Print success message after setting the device token
        print('Device token set successfully for user: ${FirebaseAuth.instance.currentUser!.uid}');

        // Subscribe to topics
        firebaseCloudMessaging.subscribeToTopic("drivers");
        firebaseCloudMessaging.subscribeToTopic("users");
        
        // Print success message after subscribing to topics
        print('Subscribed to topics: drivers, users');
      } else {
        // Handle case where deviceRecognitionToken is null
        print('Failed to retrieve device recognition token.');
      }
      
      return deviceRecognitionToken;
    } catch (e) {
      // Handle any exceptions that occur during the token retrieval process
      print('Error generating device registration token: $e');
      return null;
    }
  }
}