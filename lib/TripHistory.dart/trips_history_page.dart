import 'package:driver/TripHistory.dart/FullTripHistoryInfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});
  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}
class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentDriver =
      FirebaseDatabase.instance.ref().child("tripRequests");

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
    body: Column(
      children: [
        // Row for Recent Rides on the left and Total Trips on the right (fixed header)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                width: 140, // Specify width for the rectangle
                height: 40, // Specify height for the rectangle
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                  borderRadius: BorderRadius.circular(3),
                  color: Color.fromARGB(255, 1, 42, 123),
                ),
                alignment: Alignment.center, // Center the text inside the container
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

        // Scrollable content
        Expanded(
          child: StreamBuilder(
            stream: completedTripRequestsOfCurrentDriver.onValue,
            builder: (BuildContext context, snapshotData) {
              if (snapshotData.hasError) {
                print("Error occurred: ${snapshotData.error}");
                return const Center(
                  child: Text(
                    "Error Occurred.",
                    style: TextStyle(color: Color(0x662E3192)),
                  ),
                );
              }
              if (!(snapshotData.hasData) ||
                  snapshotData.data?.snapshot.value == null) {
                print("No data available or snapshot is null.");
                return const Center(
                  child: Text(
                    "No record found.",
                    style: TextStyle(color: Color(0x662E3192)),
                  ),
                );
              }

              Map dataTrips = snapshotData.data!.snapshot.value as Map;
              List<Map> tripsList = [];
              dataTrips.forEach((key, value) {
                tripsList.add({"key": key, ...value});
              });
              if (tripsList.isEmpty) {
                return const Center(
                  child: Text(
                    "No completed trips found.",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // Group trips by date
              Map<String, List<Map>> groupedTrips = {};
              for (var trip in tripsList) {
                if (trip["status"] == "ended" &&
                    trip["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                  if (trip["tripEndedTime"] != null) {
                    try {
                      DateFormat dateFormat = DateFormat("MMMM d, yyyy h:mm a");
                      DateTime tripEndedDateTime = dateFormat.parse(trip["tripEndedTime"]);
                      String formattedDate = DateFormat('MM/dd/yyyy').format(tripEndedDateTime);
                      if (!groupedTrips.containsKey(formattedDate)) {
                        groupedTrips[formattedDate] = [];
                      }
                      groupedTrips[formattedDate]!.add(trip);
                    } catch (e) {
                      print("Date parsing error: $e");
                    }
                  }
                }
              }

              // Sort the dates in descending order
              List<String> sortedDates = groupedTrips.keys.toList()
                ..sort((a, b) => DateFormat('MM/dd/yyyy').parse(b).compareTo(DateFormat('MM/dd/yyyy').parse(a)));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: sortedDates.length,
                itemBuilder: (context, dateIndex) {
                  String date = sortedDates[dateIndex];
                  List<Map> tripsForDate = groupedTrips[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 4),
                        ///DISPLAY OF DATE 
                        child: Text(
                          '$date ',
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
                            tripEndedTimeFormatted = DateFormat('MMMM d, yyyy h:mm a').format(tripEndedDateTime);
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
                                  width: 50, // Set width of the image
                                  height: 50, // Set height of the image
                                  fit: BoxFit.contain, // Fit the image
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
                              thickness: 2, // Adjust thickness
                              color: Colors.grey[400], // Adjust color
                              indent: 20, // Adjust the left padding of the divider
                              endIndent: 20, // Adjust the right padding of the divider
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