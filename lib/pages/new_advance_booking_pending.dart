import 'package:driver/pages/profile_page.dart';
import 'package:driver/serviceRequest/pendingFullDetails.dart';
import 'package:driver/serviceRequest/serviceHistory.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _getUserData();
  //  _checkExpiredBookings(); // Check for expired bookings on init
   // Set the System UI overlay style when this tab is created
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    // Optionally reset the overlay style to default when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }
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

/*
void _checkExpiredBookings() async {
  final now = DateTime.now();
  final snapshot = await FirebaseFirestore.instance
      .collection('Advance Bookings')
      .where('status', isEqualTo: 'Accepted')
      .get();

  for (var trip in snapshot.docs) {
    // For testing, you can replace this line with a fixed date
    DateTime endDate = trip['dateto'].toDate(); // Ensure dateto is a Timestamp

    // Temporary testing date for dateto
    // Uncomment the next line for testing purposes
    // endDate = DateTime(2024, 9, 21); 

    print('Checking trip: ${trip.id}, endDate: $endDate, now: $now');

    if (now.isAfter(endDate)) {
      print('Trip ${trip.id} is expired, moving to Advance Booking History.');

      // Update status to "No Appearance"
      await FirebaseFirestore.instance
          .collection('Advance Booking History')
          .doc(trip.id)
          .set({
            ...trip.data(),
            'status': 'No Appearance', // Update status
          });

      // Optionally, delete from the original collection if needed
      // await FirebaseFirestore.instance
      //     .collection('Advance Bookings')
      //     .doc(trip.id)
      //     .delete();
    }
  }
}
*/

@override
Widget build(BuildContext context) {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 1, 42, 123),
    statusBarIconBrightness: Brightness.light,
  ));

  return Scaffold(
    backgroundColor: Color.fromARGB(247, 245, 245, 245), // Set your preferred background color
    body: Stack(
      children: [
// StreamBuilder for Pending Service
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('Advance Bookings')
      .where('status', whereIn: ['Completed', 'Accepted', 'Active'])
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

    // Group trips by start date for Pending Service
    Map<String, List<DocumentSnapshot>> groupedTrips = {};

    for (var trip in data.docs) {
      DateTime startDate = trip['date'].toDate();
      DateTime endDate = trip['dateto'].toDate();
      String formattedDate = DateFormat('MMM d, yyyy').format(startDate);

      // Check if the end date is before the current date
      DateTime currentDate = DateTime.now();
      if (endDate.isBefore(currentDate)) {
        continue; // Skip trips that have ended
      }

      // Check the 'dates' array for active status
      List<dynamic> datesArray = trip['dates'];
      bool hasActiveDates = datesArray.any((dateItem) => dateItem['status'] == 'active');

      // Include trips with 'Completed' status or those with active dates
      if (trip['status'] == 'Completed' || hasActiveDates) {
        // Create the entry in the groupedTrips map
        if (!groupedTrips.containsKey(formattedDate)) {
          groupedTrips[formattedDate] = [];
        }
        groupedTrips[formattedDate]!.add(trip);
      }
    }

    // Combine dates and trips into a single list for Pending Service
    List<dynamic> combinedList = [];
    for (var dateKey in groupedTrips.keys) {
      combinedList.add(dateKey); // Add the date header
      combinedList.addAll(groupedTrips[dateKey]!); // Add trips for this date
    }

    // Use ListView.builder for Pending Service
    return ListView.builder(
      itemCount: combinedList.length,
      itemBuilder: (context, index) {
        final item = combinedList[index];

        if (item is String) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 1, 42, 123),
              ),
            ),
          );
        } else {
          // Render the list tile and divider only if the trip is active
          if (item['dateto'].toDate().isAfter(DateTime.now())) {
            return Column(
              children: [
                _buildListTile(item, context), // Build the list tile for active trips
                Center(
                  child: Container(
                    width: 310,
                    child: Divider(height: 1, thickness: 2, color: Colors.grey[400]),
                  ),
                ),
              ],
            );
          } else {
            return const SizedBox.shrink(); // Return nothing if the trip has ended
          }
        }
      },
    );
  },
),

        /* StreamBuilder for Completed Service
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Advance Bookings')
              .where('status', isEqualTo: 'Completed')
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
              return const Center(child: Text('No Completed Service Request'));
            }

            // Group trips by start date for Completed Service
            Map<String, List<DocumentSnapshot>> completedGroupedTrips = {};
            for (var trip in data.docs) {
              DateTime startDate = trip['date'].toDate();
              String formattedDate = DateFormat('MMM d, yyyy').format(startDate);
              if (!completedGroupedTrips.containsKey(formattedDate)) {
                completedGroupedTrips[formattedDate] = [];
              }
              completedGroupedTrips[formattedDate]!.add(trip);
            }

            // Combine dates and trips into a single list for Completed Service
            List<dynamic> completedCombinedList = [];
            for (var dateKey in completedGroupedTrips.keys) {
              completedCombinedList.add(dateKey); // Add the date header
              completedCombinedList.addAll(completedGroupedTrips[dateKey]!); // Add trips for this date
            }

            // Use ListView.builder for Completed Service
            return ListView.builder(
              itemCount: completedCombinedList.length,
              itemBuilder: (context, index) {
                final item = completedCombinedList[index];

                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 1, 42, 123),
                      ),
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      _buildListTile(item, context),
                      Center(
                        child: Container(
                          width: 310,
                          child: Divider(height: 1, thickness: 2, color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          },
        ),
        */

        // Positioned text for the current date
        Positioned(
          top: 10,
          left: 15,
          bottom: 40,
          child: Text(
            'As of ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
            style: TextStyle(
              color: Color.fromARGB(255, 1, 42, 123),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),

        // Positioned text for "Service History"
        Positioned(
          top: 10,
          right: 15,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServiceHistory()),
              );
            },
            child: const Row(
              children: [
                Text(
                  'Service History',
                  style: TextStyle(
                    color: Color.fromARGB(255, 1, 42, 123),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                SizedBox(width: 10),
                Icon(Icons.history, color: Color.fromARGB(255, 1, 42, 123)),
              ],
            ),
          ),
        ),
      ],
    )
  );
  }


Widget _buildListTile(DocumentSnapshot trip, BuildContext context) {
  DateTime startDate = trip['date'].toDate();
  DateTime endDate = trip['dateto'].toDate();
  DateTime currentDate = DateTime.now();

  /* Check if the end date is before the current date
  if (endDate.isBefore(currentDate)) {
    return const SizedBox.shrink(); // Return nothing if the trip has ended
  }
  */

  // Check if any of the in-between dates have an "active" status
  List<dynamic> dates = trip['dates'];
  bool hasActiveDates = dates.any((dateEntry) => dateEntry['status'] == 'active');

  // Only show the ListTile if there are active dates
  if (!hasActiveDates) {
    return const SizedBox.shrink(); // Return nothing if there are no active dates
  }

  // Build and return the ListTile if there are active dates and the end date has not passed
  return Container(
    color: Color.fromARGB(21, 245, 245, 245),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      title: Text(
        'Scheduled on ${DateFormat.yMMMd().format(startDate)} to ${DateFormat.yMMMd().format(endDate)}, ${trip['time']}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        'From ${trip["from"]} to ${trip["to"]}',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
      leading: Icon(Icons.event),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        // Navigate to the full details screen when clicked
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FullDetails(trip: trip),
  ),
).then((_) {
  // Reset system UI style when returning to TripsPage
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 1, 42, 123),
    statusBarIconBrightness: Brightness.light,
  ));
});
      },
    ),
  );
}




  void _deleteTrip(String key) {
    tripRequestsRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip deleted successfully')));
      setState(() {}); // Refresh the list after deletion
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting trip: $error')));
    });
  }
}
