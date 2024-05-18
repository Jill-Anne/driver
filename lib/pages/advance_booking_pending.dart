import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:driver/models/trip_details.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class AdvanceBooking extends StatefulWidget {
  const AdvanceBooking({super.key});

  @override
  _AdvanceBookingState createState() => _AdvanceBookingState();
}

class _AdvanceBookingState extends State<AdvanceBooking> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUserData();
  }

  final tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

  String name = '';
  String bodynumber = '';
  String id = '';

  void _getUserData() async {
    final userData = await retrieveUserData();
    if (userData.isNotEmpty) {
      setState(() {
        name = userData['firstName'] ?? '';

        id = userData['idNumber'] ?? '';
        bodynumber = userData['bodyNumber'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Booking'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Advance Bookings')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            return const Center(child: Text('Error'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                  child: CircularProgressIndicator(
                color: Colors.black,
              )),
            );
          }

          final data = snapshot.requireData;

          return ListView.builder(
            itemCount: data.docs.length,
            itemBuilder: (context, index) {
              return _buildTripCard(data.docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(trip) {
    return Card(
      color: Colors.grey[900],
      elevation: 10,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Start Date: ${DateFormat.yMMMd().add_jm().format(trip['date'].toDate())}",
                style: const TextStyle(color: Colors.white)),
            Text(
                "End Date: ${DateFormat.yMMMd().add_jm().format(trip['date'].toDate())}",
                style: const TextStyle(color: Colors.white)),
            Text("Pick Up Location: ${trip["from"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Drop Off Location: ${trip["to"]}",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text("Passenger Name: ${trip["name"]}",
                style: const TextStyle(color: Colors.white)),

            // Additional details as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('Advance Bookings')
                        .doc(trip.id)
                        .update({
                      'status': 'Accepted',
                      'drivername': name,
                      'driverid': id,
                      'driverbodynumber': bodynumber,
                    });
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text('Accept'),
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
