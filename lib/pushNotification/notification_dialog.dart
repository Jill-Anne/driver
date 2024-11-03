import 'dart:async';
import 'package:driver/global/global_var.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/pages/dashboard.dart';
import 'package:driver/pages/new_trip_page.dart';
import 'package:driver/pushNotification/cancel_passenfer.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotificationDialog extends StatefulWidget {
  final TripDetails? tripDetailsInfo;

  NotificationDialog({
    Key? key,
    this.tripDetailsInfo,
  }) : super(key: key);

  static bool isDialogOpen = false; // Static variable to track dialog state

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();

  // Static method to show the dialog
  static Future<void> show(BuildContext context, TripDetails tripDetailsInfo) async {
    if (!isDialogOpen) {
      isDialogOpen = true;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo),
      ).then((_) {
        isDialogOpen = false; // Reset dialog state when closed
      });
    }
  }
}

class _NotificationDialogState extends State<NotificationDialog> {
  String tripRequestStatus = "";
  CommonMethods cMethods = CommonMethods();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // We don't need to set isDialogOpen here again as it is already handled in the show method.
    cancelNotificationDialogAfter20Sec();
  }




bool isDialogOpen = false; // Track if the dialog is already shown
  void cancelNotificationDialogAfter20Sec() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (tripRequestStatus == "accepted") {
        timer.cancel();
        driverTripRequestTimeout = 20; // Reset the timeout
      }

      if (driverTripRequestTimeout <= 0) {
        Navigator.of(context).pop(); // Ensure dialog is dismissed
        _timer?.cancel();
        driverTripRequestTimeout = 20; // Reset the timeout
        audioPlayer.stop();
      }
      driverTripRequestTimeout--;
    });
  }



bool isTripAccepted = false; // Track if the trip has been accepted


Future<void> checkAvailabilityOfTripRequest(BuildContext context) async {
  DatabaseReference driverTripStatusRef = FirebaseDatabase.instance
      .ref()
      .child("driversAccount")
      .child(FirebaseAuth.instance.currentUser!.uid)
      .child("newTripStatus");

  // Check the current status before showing the dialog
  try {
    final snap = await driverTripStatusRef.once();
    
    if (snap.snapshot.exists && snap.snapshot.value != null) {
      String newTripStatusValue = snap.snapshot.value.toString();
      print("Current New Trip Status Value: $newTripStatusValue"); // Debugging log
      
      // If the status is "timeout", do not show the dialog
      if (newTripStatusValue == "timeout") {
        print("Status is timeout. Not showing dialog."); // Debugging log
        return; // Exit the method
      }

      // Show the loading dialog since the status is not timeout
      if (!NotificationDialog.isDialogOpen) {
        NotificationDialog.isDialogOpen = true;
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...'),
        );
      }

      // Store the trip ID here
      setTripID(newTripStatusValue);

      // Continue processing based on the new trip status
      if (newTripStatusValue == widget.tripDetailsInfo!.tripID) {
        // Trip accepted
        isTripAccepted = true; // Mark the trip as accepted
        print("Trip accepted: ${widget.tripDetailsInfo!.tripID}"); // Debugging log
        driverTripStatusRef.set("accepted");
        cMethods.turnOffLocationUpdatesForHomePage();
        //Navigator.of(context).pop(); // Close the loading dialog
       // NotificationDialog.isDialogOpen = false; // Mark dialog as closed
        navigateToNewTripPage(context);
      } else {
        handleTripCancellationOrTimeout(newTripStatusValue, context);
      }
    } else {
      print("Trip Request Not Found."); // Debugging log
      cMethods.displaySnackBar("Trip Request Not Found.", context);
    }
  } catch (e) {
    Navigator.pop(context); // Close loading dialog
    print("Error fetching trip status: ${e.toString()}"); // Debugging log
    cMethods.displaySnackBar("Error fetching trip status: ${e.toString()}", context);
  }
}

void handleTripCancellationOrTimeout(String status, BuildContext context) {
  if (isTripAccepted) {
    // If the trip has been accepted, ignore any cancellation or timeout
    print("Trip has already been accepted. Ignoring cancellation or timeout.");
    return;
  }

  print("Handling trip cancellation or timeout. Status: $status"); // Debugging log

  switch (status) {
    case "cancelled":
      print("Trip Request has been Cancelled by user."); // Debugging log
      cMethods.displaySnackBar("Trip Request has been Cancelled by user.", context);
      break;
    case "timeout":
      print("Trip Request timed out."); // Debugging log
      cMethods.displaySnackBar("Trip Request timed out.", context);
      break;
    default:
      print("Trip Request removed. Not Found."); // Debugging log
      cMethods.displaySnackBar("Trip Request removed. Not Found.", context);
      break;
  }

  // Close the dialog after handling the cancellation or timeout
  if (isDialogOpen) {
    Navigator.of(context).pop(); // Dismiss the dialog
    isDialogOpen = false; // Mark dialog as closed
  }
}



  void navigateToNewTripPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo),
      ),
    ).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    });
  }

  @override
  void dispose() {
    NotificationDialog.isDialogOpen = false; // Mark dialog as closed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent the dialog from being dismissed
        return false;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.black54,
        child: Container(
          margin: const EdgeInsets.all(5),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30.0),
              Image.asset("assets/images/LOGO.png", width: 140),
              const SizedBox(height: 16.0),
              const Text(
                "NEW TRIP REQUEST",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20.0),
              const Divider(height: 1, color: Colors.white, thickness: 1),
              const SizedBox(height: 10.0),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset("assets/images/initial.png", height: 16, width: 16),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            widget.tripDetailsInfo!.pickupAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset("assets/images/final.png", height: 16, width: 16),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            widget.tripDetailsInfo!.dropOffAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Colors.white, thickness: 1),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await handleDecline(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        child: const Text(
                          "DECLINE",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          audioPlayer.stop();
                          setState(() {
                            tripRequestStatus = "accepted";
                          });
                          checkAvailabilityOfTripRequest(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          "ACCEPT",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleDecline(BuildContext context) async {
    try {
      String driverUID = FirebaseAuth.instance.currentUser!.uid;
      DatabaseReference driverRef = FirebaseDatabase.instance.ref().child("driversAccount").child(driverUID);

      // Retrieve the trip ID
      DataSnapshot snapshot = await driverRef.child("newTripStatus").get();
      if (snapshot.exists) {
        String tripID = snapshot.value.toString();
        print("Trip ID retrieved: $tripID");

        // Update the driver trip status
        await driverRef.child("driverTripStatusFromDRIVER").set("cancelled");
        print("Driver trip status updated to 'cancelled'");

        // Update the trip request status
        DatabaseReference tripRequestUpdateRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID).child("status");
        await tripRequestUpdateRef.set("cancelled");
        print("Trip request status updated to 'cancelled'");

        // Fetch the passenger's device token and send a notification
        DatabaseReference passengerRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID).child("deviceToken");
        DataSnapshot tokenSnapshot = await passengerRef.get();
        if (tokenSnapshot.exists) {
          String passengerDeviceToken = tokenSnapshot.value.toString();
          print("Passenger device token retrieved: $passengerDeviceToken");

          // Send notification to passenger
          PushNotificationService.sendNotificationToPassenger(
            passengerDeviceToken, tripID, "cancelled", "Trip Cancelled");
        } else {
          print("No device token found for tripID: $tripID");
        }
      } else {
        print("No newTripStatus found for driver UID: $driverUID");
      }
    } catch (e) {
      print("Failed to handle decline action: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline trip: $e')),
      );
    } finally {
      Navigator.of(context).pop(); // Ensure dialog is dismissed
    }
  }
}
