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












  void startListeningForNewNotification() async {
  // 1. Terminated
  // When the app is completely closed and it receives a push notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote) {
    if (messageRemote != null) {
      String? tripID = messageRemote.data["tripID"];
      print("Terminated: Received initial message with tripID: ${tripID ?? 'N/A'}");
    } else {
      print("Terminated: No initial message received.");
    }
  });

  // 2. Foreground
  // When the app is open and it receives a push notification
  FirebaseMessaging.onMessage.listen((RemoteMessage messageRemote) {
    String? tripID = messageRemote.data["tripID"];
    print("Foreground: Received message with tripID: ${tripID ?? 'N/A'}");
    // Display the notification as an overlay or in the UI if required.
  }, onError: (error) {
    print("Foreground: Error receiving message: $error");
  });

  // 3. Background
  // When the app is in the background and it receives a push notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage messageRemote) {
    String? tripID = messageRemote.data["tripID"];
    print("Background: Received message with tripID: ${tripID ?? 'N/A'}");
    // You can navigate to a different screen with the tripID here.
  }, onError: (error) {
    print("Background: Error receiving message: $error");
  });
}

}