import 'package:driver/TripHistory.dart/FullTripHistoryInfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentDriver =
      FirebaseDatabase.instance.ref().child("tripRequests");

  String currentDriverTotalTripsCompleted = "";

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));
    getCurrentDriverTotalNumberOfTripsCompleted();
  }

  Future<void> getCurrentDriverTotalNumberOfTripsCompleted() async {
    DatabaseReference tripRequestsRef =
        FirebaseDatabase.instance.ref().child("tripRequests");

    final snap = await tripRequestsRef.once();
    if (snap.snapshot.value != null) {
      Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
      int allTripsLength = allTripsMap.length;

      List<String> tripsCompletedByCurrentDriver = [];

      allTripsMap.forEach((key, value) {
        if (value["status"] == "ended" &&
            value["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
          tripsCompletedByCurrentDriver.add(key);
        }
      });

      setState(() {
        currentDriverTotalTripsCompleted =
            tripsCompletedByCurrentDriver.length.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchCompletedTrips() async {
    final snap = await completedTripRequestsOfCurrentDriver.once();
    if (snap.snapshot.value != null) {
      Map dataTrips = snap.snapshot.value as Map;
      List<Map<String, dynamic>> tripsList = [];
      dataTrips.forEach((key, value) {
        tripsList.add({"key": key, ...value});
      });
      return tripsList;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Rides',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 1, 42, 123),
                  ),
                ),
                Container(
                  width: 140,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                    borderRadius: BorderRadius.circular(3),
                    color: Color.fromARGB(255, 1, 42, 123),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Total Trips: $currentDriverTotalTripsCompleted',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchCompletedTrips(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error Occurred.",
                        style: TextStyle(color: Color(0x662E3192))),
                  );
                }

                List<Map<String, dynamic>> tripsList = snapshot.data ?? [];
                if (tripsList.isEmpty) {
                  return const Center(
                    child: Text("No completed trips found.",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                // Group trips by date
                Map<String, List<Map<String, dynamic>>> groupedTrips = {};
                for (var trip in tripsList) {
                  if (trip["status"] == "ended" &&
                      trip["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                    if (trip["tripEndedTime"] != null) {
                      try {
                        DateFormat dateFormat = DateFormat("MMMM d, yyyy h:mm a");
                        DateTime tripEndedDateTime = dateFormat.parse(trip["tripEndedTime"]);
                        String formattedDate = DateFormat('MMM d, yyyy').format(tripEndedDateTime);
                        groupedTrips.putIfAbsent(formattedDate, () => []).add(trip);
                      } catch (e) {
                        print("Date parsing error: $e");
                      }
                    }
                  }
                }

                // Sort the dates in descending order
                List<String> sortedDates = groupedTrips.keys.toList()
                  ..sort((a, b) => DateFormat('MMM d, yyyy').parse(b).compareTo(DateFormat('MMM d, yyyy').parse(a)));

                return ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, dateIndex) {
                    String date = sortedDates[dateIndex];
                    List<Map<String, dynamic>> tripsForDate = groupedTrips[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 18, bottom: 4),
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 42, 123),
                            ),
                          ),
                        ),
                        ...tripsForDate.map((trip) {
                          String tripEndedTimeFormatted = "N/A";
                          if (trip["tripEndedTime"] != null) {
                            try {
                              DateFormat dateFormat = DateFormat("MMMM d, yyyy h:mm a");
                              DateTime tripEndedDateTime = dateFormat.parse(trip["tripEndedTime"]);
                              tripEndedTimeFormatted = DateFormat('MMM d, yyyy h:mm a').format(tripEndedDateTime);
                            } catch (e) {
                              tripEndedTimeFormatted = "Invalid date format";
                              print("Date parsing error: $e");
                            }
                          }

                          return Column(
                            children: [
                              Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: Image.asset(
                                    'assets/images/trisikol.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                  title: Text(
                                    'Trip on $tripEndedTimeFormatted\nFare: ₱${trip["fareAmount"]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'From ${trip["pickUpAddress"]} to ${trip["dropOffAddress"]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TripDetailsPage(
                                          tripDetails: trip,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Divider(
                                thickness: 2,
                                color: Colors.grey[400],
                                indent: 20,
                                endIndent: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
