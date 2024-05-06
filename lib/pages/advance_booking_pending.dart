import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:driver/models/trip_details.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdvanceBooking extends StatefulWidget {
  const AdvanceBooking({Key? key}) : super(key: key);

  @override
  _AdvanceBookingState createState() => _AdvanceBookingState();
}

class _AdvanceBookingState extends State<AdvanceBooking> {
  final completedTripRequestsOfCurrentDriver =
      FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Booking'),
      ),
      body: StreamBuilder(
        stream: completedTripRequestsOfCurrentDriver.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            return const Center(
              child: Text(
                "Error Occurred.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          if (!(snapshotData.hasData)) {
            return const Center(
              child: Text(
                "No record found.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          Map dataTrips =
              snapshotData.data!.snapshot.value as Map; // Retrieve trip data
          List tripsList = [];
          dataTrips.forEach((key, value) =>
              tripsList.add({"key": key, ...value})); // Convert data to list

          return ListView.builder(
            itemCount: tripsList.length,
            itemBuilder: (context, index) {
              // Check if the trip is completed by the current driver
              if (tripsList[index]["status"] != null &&
                  tripsList[index]["status"] == "ended" &&
                  tripsList[index]["driverID"] ==
                      FirebaseAuth.instance.currentUser!.uid) {
                // Create a TripDetails object from the fetched data
                TripDetails tripDetails = TripDetails(
                  tripID: tripsList[index]["key"],
                  pickUpLatLng: LatLng(
                    double.parse(tripsList[index]["pickUpLatLng"]["latitude"]),
                    double.parse(tripsList[index]["pickUpLatLng"]["longitude"]),
                  ),
                  dropOffLatLng: LatLng(
                    double.parse(tripsList[index]["dropOffLatLng"]["latitude"]),
                    double.parse(
                        tripsList[index]["dropOffLatLng"]["longitude"]),
                  ),
                  pickupAddress: tripsList[index]["pickUpAddress"],
                  dropOffAddress: tripsList[index]["dropOffAddress"],
                  userName: tripsList[index]["userName"],
                  userPhone: tripsList[index]["userPhone"],
                  tripStartDate: tripsList[index]["tripStartDate"] ?? "Not set",
                  tripEndDate: tripsList[index]["tripEndDate"] ?? "Not set",
                  tripTime: tripsList[index]["tripTime"] ?? "Not set",
                );

                // Display trip details in UI
                return Card(
                  color: Colors.white,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "User: ${tripDetails.userName}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Pickup Address: ${tripDetails.pickupAddress}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Dropoff Address: ${tripDetails.dropOffAddress}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Trip Start Date: ${tripDetails.tripStartDate}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Trip End Date: ${tripDetails.tripEndDate}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Trip Time: ${tripDetails.tripTime}",
                          style: TextStyle(fontSize: 18),
                        ),
                        // Add more trip details as needed
                      ],
                    ),
                  ),
                );
              } else {
                return Container();
              }
            },
          );
        },
      ),
    );
  }
}
