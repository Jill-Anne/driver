import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/global/global_var.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:driver/models/trip_details.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String lastName = '';
  String name = '';
  String bodynumber = '';
  String id = '';
    String phoneNumber = '';

  void _getUserData() async {
    final userData = await retrieveUserData();
    if (userData.isNotEmpty) {
      setState(() {
        name = userData['firstName'] ?? '';
        lastName = userData['lastName'] ?? '';

        id = userData['idNumber'] ?? '';
        bodynumber = userData['bodyNumber'] ?? '';
        phoneNumber = userData['phoneNumber'] ?? '';

      });
    }
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
  appBar: AppBar(
    title: const Align(
      alignment: Alignment.center, // Center the title within the AppBar
      child: Padding(
        padding: EdgeInsets.only(top: 16.0), // Add margin above the title
        child: Text(
          'Service Requests',
          style: TextStyle(
            color: Color.fromARGB(255, 1, 42, 123),
            fontWeight: FontWeight.bold,
            fontSize: 20, // You can adjust the font size as needed
          ),
        ),
      ),
    ),
    backgroundColor: Colors.white, // You can set the AppBar background color if needed
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

              // Check if there are no pending requests
    if (data.docs.isEmpty) {
      return Center(
        child: Image.asset(
          'assets/images/noPending.png', // Path to your image
          height: 300, // Set the desired height
          width: 300,  // Set the desired width
          fit: BoxFit.contain, // Adjust the fit of the image
        ),
      );
    }


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

 Widget _buildTripCard(DocumentSnapshot trip) {
  // Calculate the duration in days
  DateTime startDate = trip['date'].toDate();
  DateTime endDate = trip['dateto'].toDate();
  int daysDifference = endDate.difference(startDate).inDays + 1;

  // Format the service duration
  String serviceDuration = "$daysDifference Day Service";

  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF2E3192),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // Center content
                children: [
                  const Text(
                    'Would you accept this Service?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center, // Center text
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'After accepting, you will see full passenger details',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center, // Center text
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center buttons
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Rounded borders
      ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Space between buttons
                      Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Advance Bookings')
                                .doc(trip.id)
                                .update({
                              'status': 'Accepted',
                              'drivername': name, 
                              'driverlastName': lastName,
                              'driverid': id,
                              'driverbodynumber': bodynumber,
                              'phoneNumber' : phoneNumber,
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Rounded borders
      ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
    child: Card(
      color: Colors.grey[200],
      elevation: 10,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 35,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip['name'],
                        style: const TextStyle(
                            color: Colors.black, fontSize: 16)),
                    Text(trip['mynum'],
                        style: const TextStyle(
                            color: Colors.black, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Text(serviceDuration,
                style: const TextStyle(color: Colors.black, fontSize: 14)),
            const SizedBox(
              height: 10,
            ),
            Text(
              '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}\n${trip['time']}',
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            const Divider(),
            Text(trip['to'],
                style: const TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
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
