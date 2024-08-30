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
      body: Stack(
        children: [
          // Background image to fill the entire screen
          Positioned.fill(
            child: Image.asset(
              "assets/images/Background.png",
              fit: BoxFit.cover, // Ensure the image covers the full screen
            ),
          ),

          // Main content with scrollable feature
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Total Trips
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 180.0),
                          child: Container(
                            width: 300,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Color(
                                  0x662E3192), // Box background color with opacity
                              borderRadius:
                                  BorderRadius.circular(15), // Rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                  const SizedBox(width: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Text(
                                      currentDriverTotalTripsCompleted,
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
                      const SizedBox(height: 20),

                      // Check Trip History
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const TripsHistoryPage()),
                          );
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Container(
                              width: 300,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Color(0x662E3192),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 20.0),
                                      child: Text(
                                        "Check Trip History",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pending Advance Booking
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const NewAdvanceBooking()),
                          );
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Container(
                              width: 300,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Color(0x662E3192),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 20.0),
                                      child: Text(
                                        "Pending Advance Booking",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
