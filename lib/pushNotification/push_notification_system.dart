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
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async {
    String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();

    DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance
        .ref()
        .child("driversAccount")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("deviceToken");

    referenceOnlineDriver.set(deviceRecognitionToken);

    firebaseCloudMessaging.subscribeToTopic("drivers");
    firebaseCloudMessaging.subscribeToTopic("users");
  }

  startListeningForNewNotification(BuildContext context) async {
    ///1. Terminated
    //When the app is completely closed and it receives a push notification
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        String tripID = messageRemote.data["tripID"];

        retrieveTripRequestInfo(tripID, context);
      }
    });

    ///2. Foreground
    //When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        String tripID = messageRemote.data["tripID"];

        retrieveTripRequestInfo(tripID, context);
      }
    });

    ///3. Background
    //When the app is in the background and it receives a push notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        String tripID = messageRemote.data["tripID"];

        retrieveTripRequestInfo(tripID, context);
      }
    });
  }

  retrieveTripRequestInfo(String tripID, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );

    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);

    tripRequestsRef.once().then((dataSnapshot) {
      Navigator.pop(context);

      audioPlayer.open(Audio("assets/audio/alert_sound.mp3"));
      audioPlayer.play();

      if (dataSnapshot.snapshot.value != null) {
        final tripMap = Map<String, dynamic>.from(dataSnapshot.snapshot.value as Map);

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
    });
  }
}
