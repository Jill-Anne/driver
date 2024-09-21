import 'package:driver/pages/profile_page.dart';
import 'package:driver/serviceRequest/pendingFullDetails.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewAdvanceBooking extends StatefulWidget {
  const NewAdvanceBooking({super.key});

  @override
  _NewAdvanceBookingState createState() => _NewAdvanceBookingState();
}

class _NewAdvanceBookingState extends State<NewAdvanceBooking> {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Advance Bookings')
            .where('status', isEqualTo: 'Accepted')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error occurred'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.requireData;
          if (data.docs.isEmpty) {
            return const Center(child: Text('No Pending Service Request'));
          }

          // Group trips by start date
          Map<String, List<DocumentSnapshot>> groupedTrips = {};
          for (var trip in data.docs) {
            DateTime startDate = trip['date'].toDate();
            String formattedDate = DateFormat('MMM d, yyyy').format(startDate);
            if (!groupedTrips.containsKey(formattedDate)) {
              groupedTrips[formattedDate] = [];
            }
            groupedTrips[formattedDate]!.add(trip);
          }

          // Combine dates and trips into a single list
List<dynamic> combinedList = [];

for (var dateKey in groupedTrips.keys) {
  combinedList.add(dateKey); // Add the date header
  combinedList.addAll(groupedTrips[dateKey]!); // Add trips for this date
}

// Use ListView.builder
return ListView.builder(
  itemCount: combinedList.length,
  itemBuilder: (context, index) {
    final item = combinedList[index];

    if (item is String) {
      // If it's a date header, display it without a divider
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          item, // Displaying the grouped date
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 42, 123),
          ),
        ),
      );
    } else {
      // Otherwise, it's a trip document, display it with a divider
      return Column(
        children: [
          _buildListTile(item, context), // Display the trip ListTile
          Center( // Divider after each ListTile
            child: Container(
              width: 310, // Shorter width
              child: Divider(
                height: 1, // Less space around the divider
                thickness: 2, // Thinner divider
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      );
    }
  },
);

        },
      ),
    );
  }

  Widget _buildListTile(DocumentSnapshot trip, BuildContext context) {
    DateTime startDate = trip['date'].toDate();
    DateTime endDate = trip['dateto'].toDate();

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      title: Text(
        'Scheduled on ${DateFormat.yMMMd().format(startDate)} to ${DateFormat.yMMMd().format(endDate)}, ${trip['time']}',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      subtitle: Text(
        'From ${trip["from"]} to ${trip["to"]}',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
      leading: Icon(Icons.event),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullDetails(trip: trip),
          ),
        );
      },
    );
  }

  void _deleteTrip(String key) {
    tripRequestsRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip deleted successfully')));
      setState(() {}); // Refresh the list after deletion
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting trip: $error')));
    });
  }
}
