import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:driver/models/trip_details.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NewAdvanceBooking extends StatefulWidget {
  const NewAdvanceBooking({super.key});

  @override
  _NewAdvanceBookingState createState() => _NewAdvanceBookingState();
}

class _NewAdvanceBookingState extends State<NewAdvanceBooking> {
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
        title: Padding(
          padding: const EdgeInsets.only(
              left: 0), // Add padding to the left of the title
          child: const Text(
            'Pending Service Request',
            style: TextStyle(color: Color.fromARGB(255, 1, 42, 123)),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 1, 42, 123)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Advance Bookings')
            .where('status', isEqualTo: 'Accepted')
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
          if (data.docs.isEmpty) {
            return const Center(
              child: Text(
                'No Pending Service Request',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
  DateTime startDate = trip['date'].toDate();
  DateTime endDate = trip['dateto'].toDate();

  return Card(
    color: Colors.white, // Card background color
    elevation: 1, // Reduced elevation for a flat look
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Colors.black, width: 1), // Black border
      borderRadius: BorderRadius.circular(10),
    ),
    margin: const EdgeInsets.all(10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Start Date Section with Call Icon on the Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Start Date Text
              Text(
                '${DateFormat.yMMMd().format(startDate)}, ${trip['time']}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              // Call Icon Button
              IconButton(
                onPressed: () async {
                  var text = 'tel:${trip["mynum"]}';
                  if (await canLaunch(text)) {
                    await launch(text);
                  }
                },
                icon: Image.asset(
                  'assets/images/Call.png',
                  height: 45, // Smaller icon height
                  width: 45, // Smaller icon width
                ),
                iconSize: 20, // Smaller icon size
                padding: EdgeInsets.only(
                    bottom: 0), // Adjust the padding to lower the icon
                constraints: BoxConstraints(), // Use default constraints
                splashRadius: 70, // Optional: adjust the splash radius
              ),
            ],
          ),

          Text(
            "Advance Booking",
            style: const TextStyle(color: Colors.black),
          ),
          // Straight Line Divider
          Divider(
            color: Colors.black,
            thickness: 1,
          ),
          const SizedBox(height: 10),

          // Passenger Name
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Passenger Name: ",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold, // Bold style for the label
                  ),
                ),
                TextSpan(
                  text: "${trip["name"]}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight:
                        FontWeight.normal, // Regular style for the date value
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Start Date
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Start Date: ",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold, // Bold style for the label
                  ),
                ),
                TextSpan(
                  text:
                      "${DateFormat.yMMMd().format(startDate)} ${trip['time']}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight:
                        FontWeight.normal, // Regular style for the date value
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "End Date: ",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold, // Bold style for the label
                  ),
                ),
                TextSpan(
                  text: DateFormat.yMMMd().format(endDate),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight:
                        FontWeight.normal, // Regular style for the date value
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Pick Up Location with Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/initial.png',
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8), // Space between icon and text
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "PICK-UP ",
                        style: const TextStyle(
                          color: Colors.red, // Red color for Pick Up
                          fontWeight:
                              FontWeight.bold, // Bold style for the label
                        ),
                      ),
                      TextSpan(
                        text: trip["from"],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight
                              .normal, // Regular style for the location value
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Drop Off Location with Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/final.png',
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8), // Space between icon and text
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "DROP-OFF ",
                        style: const TextStyle(
                          color: Colors.green, // Green color for Drop Off
                          fontWeight:
                              FontWeight.bold, // Bold style for the label
                        ),
                      ),
                      TextSpan(
                        text: trip["to"],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight
                              .normal, // Regular style for the location value
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        backgroundColor: Colors.red,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Reject this service?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, bottom: 10),
                                child: Text(
                                  'Before canceling the ride you should call the passenger to he/she cancel the ride',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20, bottom: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white30,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.account_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            trip['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            trip['mynum'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red,       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Rounded borders
      ),),
                child: const Text('Cancel Request'),
                
              ),
              const SizedBox(width: 16), // Space between buttons
              // ElevatedButton(
              //   onPressed: () async {
              //     await FirebaseFirestore.instance
              //         .collection('Advance Bookings')
              //         .doc(trip.id)
              //         .update({
              //       'status': 'Completed',
              //       'drivername': name,
              //       'driverid': id,
              //       'driverbodynumber': bodynumber,
              //     });

              //     Navigator.pop(context);
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.white,
              //   ),
              //   child: const Text(
              //     'Complete Ride',
              //     textAlign: TextAlign.center,
              //     style: TextStyle(
              //       color: Colors.black,
              //       fontSize: 15,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
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
