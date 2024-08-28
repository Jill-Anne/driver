import 'package:driver/pages/advance_booking_pending.dart';
import 'package:driver/pages/new_advance_booking_pending.dart';
import 'package:driver/pages/trips_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  String currentDriverTotalTripsCompleted = "";

  getCurrentDriverTotalNumberOfTripsCompleted() async {
    DatabaseReference tripRequestsRef =
        FirebaseDatabase.instance.ref().child("tripRequests");

    await tripRequestsRef.once().then((snap) async {
      if (snap.snapshot.value != null) {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
        int allTripsLength = allTripsMap.length;

        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value) {
          if (value["status"] != null) {
            if (value["status"] == "ended") {
              if (value["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                tripsCompletedByCurrentDriver.add(key);
              }
            }
          }
        });

        setState(() {
          currentDriverTotalTripsCompleted =
              tripsCompletedByCurrentDriver.length.toString();
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCurrentDriverTotalNumberOfTripsCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(
      mainAxisAlignment:
          MainAxisAlignment.center, // Centers vertically within the Column
      children: [
        // Total Trips
        Center(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 180.0), // Adds space above the entire content
            child: Container(
              width: 300, // Set your desired width here
              height: 100, // Set your desired height here
              decoration: BoxDecoration(
                color: Color(0x662E3192), // Box background color
                borderRadius: BorderRadius.circular(15), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: Offset(2, 2), // Shadow position
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0), // Adds horizontal padding for the text
                child: Row(
                  // Changed to Row to arrange texts horizontally

                  mainAxisAlignment: MainAxisAlignment
                      .start, // Centers content horizontally in the box
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Aligns text vertically centered
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        "Total Trips:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Spacing between the two texts
                    Padding(
                      padding: const EdgeInsets.only(
                          left:
                              10.0), // Padding to the left of the dynamic text
                      child: Text(
                        currentDriverTotalTripsCompleted, // Dynamic content
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 20, // Adds space below the entire container
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const TripsHistoryPage()),
            );
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10.0), // Adds space above the entire content
              child: Container(
                width: 300, // Set your desired width here
                height: 100, // Set your desired height here
                decoration: BoxDecoration(
                  color: Color(0x662E3192), // Box background color
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(2, 2), // Shadow position
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.0), // Adds horizontal padding for the text
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .start, // Aligns the texts to the start (left) of the row
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Aligns text vertically centered
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left:
                                20.0), // Padding to the left of the "Total Trips:" text
                        child: Text(
                          "Check Trip History",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(
                          width: 10), // Spacing between the two texts
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        //check trip history
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (c) => const NewAdvanceBooking()));
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10.0), // Adds space above the entire content
              child: Container(
                width: 300, // Set your desired width here
                height: 100, // Set your desired height here
                decoration: BoxDecoration(
                  color: Color(0x662E3192), // Box background color
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(2, 2), // Shadow position
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.0), // Adds horizontal padding for the text
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .start, // Aligns the texts to the start (left) of the row
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Aligns text vertically centered
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left:
                                20.0), // Padding to the left of the "Total Trips:" text
                        child: Text(
                          "Pending Advance Booking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(
                          width: 10), // Spacing between the two texts
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    )));
  }
}
