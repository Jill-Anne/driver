import 'dart:async';

import 'package:driver/global/global_var.dart';
import 'package:driver/methods/common_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/pages/new_trip_page.dart';
import 'package:driver/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';


class NotificationDialog extends StatefulWidget
{
  TripDetails? tripDetailsInfo;

  NotificationDialog({super.key, this.tripDetailsInfo,});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog>
{
  String tripRequestStatus = "";
  CommonMethods cMethods = CommonMethods();

  cancelNotificationDialogAfter20Sec()
  {
    const oneTickPerSecond = Duration(seconds: 1);

    var timerCountDown = Timer.periodic(oneTickPerSecond, (timer)
    {
      driverTripRequestTimeout = driverTripRequestTimeout - 1;

      if(tripRequestStatus == "accepted")
      {
        timer.cancel();
        driverTripRequestTimeout = 20;
      }

      if(driverTripRequestTimeout == 0)
      {
        Navigator.pop(context);
        timer.cancel();
        driverTripRequestTimeout = 20;
        audioPlayer.stop();
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    cancelNotificationDialogAfter20Sec();
  }


checkAvailabilityOfTripRequest(BuildContext context) async {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) => LoadingDialog(messageText: 'please wait...'),
  );

  DatabaseReference driverTripStatusRef = FirebaseDatabase.instance.ref()
      .child("driversAccount")
      .child(FirebaseAuth.instance.currentUser!.uid)
      .child("newTripStatus");

  // Listen for real-time updates
  driverTripStatusRef.onValue.listen((event) async {
    final snap = event.snapshot;

    // Debug: Log the current value of newTripStatus
    debugPrint("Current newTripStatus: ${snap.value}");

    // Only proceed if snapshot is not null
    if (snap.value != null) {
      String newTripStatusValue = snap.value.toString();

      // Debug: Log the newTripStatusValue
      debugPrint("newTripStatusValue: $newTripStatusValue");

      if (newTripStatusValue == widget.tripDetailsInfo!.tripID) {
        await driverTripStatusRef.set("accepted").catchError((error) {
          // Debug: Log error if setting "accepted" fails
          debugPrint("Error setting trip status to accepted: $error");
        });

        // Disable homepage location updates
        cMethods.turnOffLocationUpdatesForHomePage();

        // Close dialogs
        Navigator.pop(context);
        Navigator.pop(context);

        Navigator.push(context, MaterialPageRoute(builder: (c) => NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo)));
      } else if (newTripStatusValue == "cancelled" || newTripStatusValue == "timeout") {
        // Close dialogs
        Navigator.pop(context);
        Navigator.pop(context);

        // Display relevant message based on the trip status
        cMethods.displaySnackBar("Trip Request has been $newTripStatusValue.", context);
      }
    } else {
      // Close dialogs
      Navigator.pop(context);
      Navigator.pop(context);

      cMethods.displaySnackBar("Trip Request Not Found.", context);
    }
  }).onError((error) {
    // Debug: Log error if listening for updates fails
    debugPrint("Error listening to newTripStatus updates: $error");
  });
}



  @override
  Widget build(BuildContext context)
  {
    return Dialog(
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

            const SizedBox(height: 30.0,),

            Image.asset(
              "assets/images/LOGO.png",
              width: 140,
            ),

            const SizedBox(height: 16.0,),

            //title
            const Text(
              "NEW TRIP REQUEST",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const  SizedBox(height: 20.0,),

            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),

            const SizedBox(height: 10.0,),

            //pick - dropoff
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [

                  //pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Image.asset(
                        "assets/images/initial.png",
                        height: 16,
                        width: 16,
                      ),

                      const SizedBox(width: 18,),

                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.pickupAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 15,),

                  //dropoff
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Image.asset(
                        "assets/images/final.png",
                        height: 16,
                        width: 16,
                      ),

                      const SizedBox(width: 18,),

                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.dropOffAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),

                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20,),

            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),

            const SizedBox(height: 8,),

            //decline btn - accept btn
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed: ()
                      {
                        Navigator.pop(context);
                        audioPlayer.stop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      child: const Text(
                        "DECLINE",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10,),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: ()
                      {
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
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 10.0,),

          ],
        ),
      ),
    );
  }
}
