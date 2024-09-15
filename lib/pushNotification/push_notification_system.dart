import 'dart:convert';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:driver/global/global_var.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/pushNotification/notification_dialog.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class PushNotificationSystem {
  final FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;
  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

Future<void> generateDeviceRegistrationToken() async {
  try {
    // Get the current user ID
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Generate a new device token
    String? deviceToken = await firebaseCloudMessaging.getToken();
    print('Generated new device token for user $userId: $deviceToken');

    if (deviceToken != null) {
      // Save the new token to Firebase for the current user
      DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance
          .ref()
          .child("driversAccount")
          .child(userId)
          .child("deviceToken");
      
      await referenceOnlineDriver.set(deviceToken);
      print('New device token saved to database for user $userId');

      // Unsubscribe from previous topics
      await firebaseCloudMessaging.unsubscribeFromTopic("drivers");
      await firebaseCloudMessaging.unsubscribeFromTopic("users");
      print('Unsubscribed from previous topics.');

      // Subscribe to topics for the current user
      await firebaseCloudMessaging.subscribeToTopic("drivers");
      await firebaseCloudMessaging.subscribeToTopic("users");
      print('Subscribed to topics: drivers, users for user $userId');
    } else {
      print('Failed to generate device token for user $userId');
    }
  } catch (e) {
    print('Error generating device token: $e');
  }
}

  void startListeningForNewNotification(BuildContext context) async {
    // Terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        print('Terminated state notification received: ${messageRemote.data}');
        String tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      } else {
        print('No initial message received');
      }
    });

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage messageRemote) {
      print('Foreground state notification received: ${messageRemote.data}');
      String tripID = messageRemote.data["tripID"];
      retrieveTripRequestInfo(tripID, context);
    });

    // Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage messageRemote) {
      print('Background state notification received: ${messageRemote.data}');
      String tripID = messageRemote.data["tripID"];
      retrieveTripRequestInfo(tripID, context);
    });
  }

  Future<void> retrieveTripRequestInfo(String tripID, BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );

    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);

    try {
      DataSnapshot dataSnapshot = await tripRequestsRef.get();
      print('Trip request data retrieved: ${dataSnapshot.value}');
      
      Navigator.pop(context);
      
      audioPlayer.open(Audio("assets/audio/alert_sound.mp3"));
      audioPlayer.play();

      if (dataSnapshot.exists) {
        final tripMap = Map<String, dynamic>.from(dataSnapshot.value as Map);

        TripDetails tripDetailsInfo = TripDetails(
          tripID: tripID,
          pickUpLatLng: LatLng(
            double.parse(tripMap["pickUpLatLng"]["latitude"]),
            double.parse(tripMap["pickUpLatLng"]["longitude"])
          ),
          dropOffLatLng: LatLng(
            double.parse(tripMap["dropOffLatLng"]["latitude"]),
            double.parse(tripMap["dropOffLatLng"]["longitude"])
          ),
          pickupAddress: tripMap["pickUpAddress"],
          dropOffAddress: tripMap["dropOffAddress"],
          userName: tripMap["userName"],
          userPhone: tripMap["userPhone"],
          tripStartDate: tripMap["tripStartDate"] ?? "Not set",
          tripEndDate: tripMap["tripEndDate"] ?? "Not set",
          tripTime: tripMap["tripTime"] ?? "Not set"
        );

        showDialog(
          context: context,
          builder: (BuildContext context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo),
        );
      } else {
        print("No data available for tripID $tripID");
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error retrieving trip request info: $e');
    }
  }
}
