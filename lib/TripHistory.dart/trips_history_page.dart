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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content with ListView
          StreamBuilder(
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
              print("Data received from Firebase: $dataTrips");

              List<Map> tripsList = [];
              dataTrips.forEach((key, value) {
                print("Processing trip with key: $key and value: $value");
                tripsList.add({"key": key, ...value});
              });

              // Check if no trips are found
              if (tripsList.isEmpty) {
                print("No trips found for the current driver.");
                return const Center(
                  child: Text(
                    "No completed trips found.",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // Check if there are pending trips (status not 'ended')
              List<Map> pendingTrips = tripsList
                  .where((trip) =>
                      trip["status"] != "ended" &&
                      trip["driverID"] ==
                          FirebaseAuth.instance.currentUser!.uid)
                  .toList();

              if (pendingTrips.isEmpty) {
                print("No pending trips found for the current driver.");
                return const Center(
                  child: Text(
                    "No Trip Records Available",
                    style: TextStyle(color: Colors.black87, fontSize: 18),
                  ),
                );
              }

              // Group trips by date
              Map<String, List<Map>> groupedTrips = {};
              for (var trip in tripsList) {
                if (trip["status"] == "ended" &&
                    trip["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                  // Parse and format the trip ended time
                  if (trip["tripEndedTime"] != null) {
                    try {
                      DateFormat dateFormat = DateFormat("MMMM d, yyyy h:mm a");
                      DateTime tripEndedDateTime =
                          dateFormat.parse(trip["tripEndedTime"]);
                      String formattedDate =
                          DateFormat('MM/dd/yyyy').format(tripEndedDateTime);

                      // Initialize the list if not already present
                      if (!groupedTrips.containsKey(formattedDate)) {
                        groupedTrips[formattedDate] = [];
                      }

                      // Add trip to the corresponding date list
                      groupedTrips[formattedDate]!.add(trip);
                    } catch (e) {
                      print("Date parsing error: $e");
                    }
                  }
                }
              }

              // Sort the dates in descending order
              List<String> sortedDates = groupedTrips.keys.toList()
                ..sort((a, b) => DateFormat('MM/dd/yyyy')
                    .parse(b)
                    .compareTo(DateFormat('MM/dd/yyyy').parse(a)));

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
                        child: Text(
                          //'On $date (${tripsForDate.length} trips)',
                          '$date ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...tripsForDate.map((trip) {
                        String tripEndedTimeFormatted = "N/A";

                        if (trip["tripEndedTime"] != null) {
                          try {
                            DateFormat dateFormat =
                                DateFormat("MMMM d, yyyy h:mm a");
                            DateTime tripEndedDateTime =
                                dateFormat.parse(trip["tripEndedTime"]);
                            tripEndedTimeFormatted = DateFormat(
                                    'MMMM d, yyyy h:mm a')
                                .format(tripEndedDateTime);
                          } catch (e) {
                            tripEndedTimeFormatted = "Invalid date format";
                            print("Date parsing error: $e");
                          }
                        }

                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: Colors.grey[800]!, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            title: Text(
                              'Trip on $tripEndedTimeFormatted\nFare: PHP ${trip["fareAmount"]}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              'From ${trip["pickUpAddress"]} to ${trip["dropOffAddress"]}',
                              style: const TextStyle(
                                fontSize: 14,
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
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
