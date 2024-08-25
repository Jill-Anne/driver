import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentDriver = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Completed Trips',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: StreamBuilder(
        stream: completedTripRequestsOfCurrentDriver.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            print("Error occurred: ${snapshotData.error}");
            return const Center(
              child: Text(
                "Error Occurred.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!(snapshotData.hasData) || snapshotData.data?.snapshot.value == null) {
            print("No data available or snapshot is null.");
            return const Center(
              child: Text(
                "No record found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          print("Data received from Firebase: $dataTrips");

          List tripsList = [];
          dataTrips.forEach((key, value) {
            print("Processing trip with key: $key and value: $value");
            tripsList.add({"key": key, ...value});
          });

          if (tripsList.isEmpty) {
            print("No trips found for the current driver.");
            return const Center(
              child: Text(
                "No completed trips found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length,
            itemBuilder: ((context, index) {
              print("Rendering trip at index $index: ${tripsList[index]}");

              if (tripsList[index]["status"] != null &&
                  tripsList[index]["status"] == "ended" &&
                  tripsList[index]["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                return Card(
                  color: Colors.white12,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Name
                        Text(
                          'Driver Name: ${tripsList[index]["firstName"] ?? "N/A"} ${tripsList[index]["lastName"] ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ID Number
                        Text(
                          'ID Number: ${tripsList[index]["idNumber"] ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Pickup - fare amount
                        Row(
                          children: [
                            Image.asset('assets/images/initial.png', height: 16, width: 16),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                tripsList[index]["pickUpAddress"].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "₱ ${tripsList[index]["fareAmount"] ?? "0.00"}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Dropoff
                        Row(
                          children: [
                            Image.asset('assets/images/final.png', height: 16, width: 16),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                tripsList[index]["dropOffAddress"].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Delete Button
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            String tripKey = tripsList[index]["key"];
                            try {
                              await completedTripRequestsOfCurrentDriver
                                  .child(tripKey)
                                  .remove();
                              print("Trip with key $tripKey deleted successfully.");
                            } catch (e) {
                              print("Error deleting trip with key $tripKey: $e");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                print("Trip does not match criteria, skipping.");
                return Container();
              }
            }),
          );
        },
      ),
    );
  }
}
