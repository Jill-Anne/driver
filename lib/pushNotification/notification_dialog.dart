import 'dart:async';
import 'package:driver/global/global_var.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/pages/new_trip_page.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class NotificationDialog extends StatefulWidget {
  final TripDetails? tripDetailsInfo;

  NotificationDialog({
    Key? key,
    this.tripDetailsInfo,
  }) : super(key: key);

  @override
  _NotificationDialogState createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  String tripRequestStatus = "";
  CommonMethods cMethods = CommonMethods();

  @override
  void initState() {
    super.initState();
    cancelNotificationDialogAfter20Sec();
    print('Notification Dialog Initialized');
  }

  cancelNotificationDialogAfter20Sec() {
    const oneTickPerSecond = Duration(seconds: 1);
    var timerCountDown = Timer.periodic(oneTickPerSecond, (timer) {
      driverTripRequestTimeout = driverTripRequestTimeout - 1;
      print('Timer countdown: $driverTripRequestTimeout');

      if (tripRequestStatus == "accepted" || driverTripRequestTimeout == 0) {
        timer.cancel();
        driverTripRequestTimeout = 20;
        Navigator.pop(context);
        audioPlayer.stop();
      }
    });
  }

void checkAvailabilityOfTripRequest(BuildContext context) async {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...'),
  );

  DatabaseReference driverTripStatusRef = FirebaseDatabase.instance
      .ref()
      .child("driversAccount")
      .child(FirebaseAuth.instance.currentUser!.uid)
      .child("newTripStatus");

  try {
    await driverTripStatusRef.once().then((snap) async {
      Navigator.pop(context); // Dismiss the loading dialog

      if (snap.snapshot.value != null &&
          snap.snapshot.value.toString() == widget.tripDetailsInfo!.tripID) {
        // Retrieve and save driver data to trip info
        await saveDriverDataToTripInfo();
        await driverTripStatusRef.set("accepted").then((_) {
          // Show the "Accepted" dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => AlertDialog(
              title: Text("Accepted"),
              content: Text("Advance booking request accepted."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        });
      } else {
        cMethods.displaySnackBar("Trip request status: ${snap.snapshot.value}", context);
      }
    });
  } catch (e) {
    Navigator.pop(context); // Ensure the loading dialog is dismissed in case of an error
    cMethods.displaySnackBar("Failed to update status: $e", context);
  }

  if (widget.tripDetailsInfo?.tripStartDate == "Not set" ||
      widget.tripDetailsInfo?.tripEndDate == "Not set") {
    // Either tripStartDate or tripEndDate is "Not set"
    cMethods.turnOffLocationUpdatesForHomePage();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => NewTripPage(
          newTripDetailsInfo: widget.tripDetailsInfo,
        ),
      ),
    );
  }
}

Future<void> saveDriverDataToTripInfo() async {
  // Retrieve user data
  Map<String, dynamic> userData = await retrieveUserData();

  if (userData.isNotEmpty) {
    // Extract necessary data from user data
    String firstName = userData['firstName'];
    String lastName = userData['lastName'];
    String idNumber = userData['idNumber'];
    String bodyNumber = userData['bodyNumber'];

    // Create a map containing driver data
    Map<String, dynamic> driverDataMap = {
      "status": "accepted",
      "driverID": FirebaseAuth.instance.currentUser!.uid,
      "firstName": firstName,
      "lastName": lastName,
      "idNumber": idNumber,
      "bodyNumber": bodyNumber,
    };

    // Update trip request with driver data
    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.tripDetailsInfo!.tripID!)
        .update(driverDataMap);

    // Get current driver location
    Map<String, dynamic> driverCurrentLocation = {
      'latitude': driverCurrentPosition!.latitude.toString(),
      'longitude': driverCurrentPosition!.longitude.toString(),
    };

    // Update trip request with driver's current location
    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.tripDetailsInfo!.tripID!)
        .child("driverLocation").update(driverCurrentLocation);

    print('Driver data and location saved successfully.');
  } else {
    print("Error: No user data found.");
  }
}



  @override
  Widget build(BuildContext context) {
    bool hasDateTime = widget.tripDetailsInfo?.tripStartDate != null &&
        widget.tripDetailsInfo?.tripEndDate != null;

    if (!hasDateTime) {
      return SizedBox
          .shrink(); // Return an empty SizedBox if there are no trip dates
    }

    String titleText =
        hasDateTime ? 'NEW TRIP REQUESTS' : 'ADVANCE TRIP REQUEST';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(titleText,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey)),
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
                      Image.asset("assets/images/initial.png",
                          height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.pickupAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset("assets/images/final.png",
                          height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.dropOffAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'Trip starts: ${widget.tripDetailsInfo?.tripStartDate ?? "N/A"}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.grey, fontSize: 18)),
                  Text(
                      'Trip ends: ${widget.tripDetailsInfo?.tripEndDate ?? "N/A"}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.grey, fontSize: 18)),
                  Text(
                      'Trip time: ${widget.tripDetailsInfo?.tripTime ?? "N/A"}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        audioPlayer.stop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink),
                      child: const Text("DECLINE",
                          style: TextStyle(color: Colors.white)),
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
                          backgroundColor: Colors.green),
                      child: const Text("ACCEPT",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  
}
