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
  final tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Booking'),
      ),
      body: StreamBuilder(
        stream: tripRequestsRef.onValue,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error Occurred.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text(
                "No record found.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          Map dataTrips = snapshot.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips.forEach((key, value) {
            if (value.containsKey("tripStartDate") &&
                value.containsKey("tripEndDate") &&
                value["tripStartDate"] != null &&
                value["tripEndDate"] != null &&
                value["tripStartDate"] != "Not set" &&
                value["tripEndDate"] != "Not set") {
              tripsList.add({"key": key, ...value});
            }
          });

          if (tripsList.isEmpty) {
            return const Center(child: Text("No trips found with valid dates."));
          }

          return ListView.builder(
            itemCount: tripsList.length,
            itemBuilder: (context, index) {
              return _buildTripCard(tripsList[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map trip) {
    return Card(
      color: Colors.grey[900],
      elevation: 10,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Start Date: ${trip["tripStartDate"]}",
                style: const TextStyle(color: Colors.white)),
            Text("End Date: ${trip["tripEndDate"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Pick Up Location: ${trip["pickUpAddress"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Drop Off Location: ${trip["dropOffAddress"]}",
                style: const TextStyle(color: Colors.white)),
            SizedBox(height: 10),
            Text("Passenger Name: ${trip["userName"]}",
                style: const TextStyle(color: Colors.white)),
           

            // Additional details as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _deleteTrip(trip["key"]),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTrip(String key) {
    // Delete the trip entry from Firebase
    tripRequestsRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip deleted successfully')),
      );
      setState(() {}); // Refresh the list after deletion
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting trip: $error')),
      );
    });
  }
}
