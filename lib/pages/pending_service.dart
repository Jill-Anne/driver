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
    _checkExpiredBookings(); // Check for expired bookings on init
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

  // Retrieve current user data (name, body number, etc.)
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

  // Check for expired bookings and move them to history if needed
  void _checkExpiredBookings() async {
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('Advance Bookings')
        .where('status', isEqualTo: 'Accepted')
        .get();

    for (var trip in snapshot.docs) {
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

  @override
  Widget build(BuildContext context) {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 1, 42, 123),
    statusBarIconBrightness: Brightness.light,
  ));

    return Scaffold(
      backgroundColor: const Color.fromARGB(247, 245, 245, 245),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Advance Bookings')
                .where('status', whereIn: ['Completed', 'Accepted', 'Active'])
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            // Existing error and loading checks...

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading data'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.requireData;
              if (data.docs.isEmpty) {
                return const Center(child: Text('No Pending Service Request'));
              }

              // Create a list to hold the filtered services
              List<DocumentSnapshot> filteredPendingServices = [];

              // Compare with current driver's data (name and phone number)
              for (var trip in data.docs) {
                String driverName = trip['drivername'] ?? '';
                String driverPhone = trip['phoneNumber'] ?? '';

                // Only add trips that match the current driver's name or phone
                if (driverName == name || driverPhone == bodynumber) {
                  filteredPendingServices.add(trip);
                }
              }

              // Group trips by start date for Pending Service
              Map<String, List<DocumentSnapshot>> groupedTrips = {};

              for (var trip in filteredPendingServices) {
                DateTime startDate = trip['date'].toDate();
                DateTime endDate = trip['dateto'].toDate();
                String formattedDate = DateFormat('MMM d, yyyy').format(startDate);
                DateTime currentDate = DateTime.now();

                // Skip trips that have ended
                if (endDate.isBefore(currentDate)) {
                  continue;
                }

                // Check the 'dates' array for active status
                List<dynamic> datesArray = trip['dates'];
                bool hasActiveDates = datesArray.any((dateItem) => dateItem['status'] == 'active');

                // Include trips with 'Completed' status or those with active dates
                if (trip['status'] == 'Completed' || hasActiveDates) {
                  if (!groupedTrips.containsKey(formattedDate)) {
                    groupedTrips[formattedDate] = [];
                  }
                  groupedTrips[formattedDate]!.add(trip);
                }
              }

              // Sort the dates in descending order
              List<String> sortedDates = groupedTrips.keys.toList()
                ..sort((a, b) => DateFormat('MMM d, yyyy').parse(b).compareTo(DateFormat('MMM d, yyyy').parse(a)));

              // Use ListView.builder for Pending Service
              return ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedDates[index];
                  final tripsForDate = groupedTrips[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          dateKey, // Display the date as a header
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color.fromARGB(255, 1, 42, 123), // Updated color
                          ),
                        ),
                      ),

                      ...tripsForDate.map((trip) {
                        return _buildListTile(trip, context, dateKey); // Pass dateKey to ListTile
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),

        // Positioned text for the current date
          Positioned(
            top: 10,
            left: 15,
            bottom: 40,
            child: Text(
              'As of ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: const TextStyle(
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
      ),
    );
  }

  Widget _buildListTile(DocumentSnapshot trip, BuildContext context, String dateKey) {
    DateTime endDate = trip['dateto'].toDate();

    // Check if any of the in-between dates have an "active" status
    List<dynamic> dates = trip['dates'];
    bool hasActiveDates = dates.any((dateEntry) => dateEntry['status'] == 'active');

    // Only show the ListTile if there are active dates and the end date has not passed
    if (!hasActiveDates || endDate.isBefore(DateTime.now())) {
      return const SizedBox.shrink(); // Return nothing if there are no active dates or if the trip has ended
    }

    // Build and return the ListTile with the date included
    return Column(
      children: [
        Container(
          color: const Color.fromARGB(21, 245, 245, 245),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            title: Text(
              'Scheduled on ${dateKey}, ${trip['time']}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'From ${trip["from"]} to ${trip["to"]}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            leading: const Icon(Icons.event),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // Navigate to the full details screen when clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullDetails(trip: trip),
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
