import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/global/global_var.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AdvanceBooking extends StatefulWidget {
  const AdvanceBooking({super.key});

  @override
  _AdvanceBookingState createState() => _AdvanceBookingState();
}

class _AdvanceBookingState extends State<AdvanceBooking> {
  final tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");
  
  String lastName = '';
  String name = '';
  String bodynumber = '';
  String id = '';
  String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Service Requests',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 1, 42, 123),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Advance Bookings')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
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

          final data = snapshot.data;

          if (data?.docs.isEmpty ?? true) {
            return Center(
              child: Image.asset(
                'assets/images/noPending.png',
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),
            );
          }

          return ListView.builder(
            itemCount: data!.docs.length,
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
    int daysDifference = endDate.difference(startDate).inDays + 1;
    String serviceDuration = "$daysDifference Day Service";

    return GestureDetector(
      onTap: () async {
        final overlappingTrips = await _checkForOverlappingTrips(startDate, endDate, trip['time']);
        if (overlappingTrips.isNotEmpty) {
          print('Overlapping trips found: ${overlappingTrips.length}');
          _showOverlappingDialog(context, overlappingTrips);
        } else {
          print('No overlapping trips, showing acceptance dialog.');
          _showAcceptanceDialog(context, trip);
        }
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
                  const Icon(Icons.account_circle, size: 35),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip['name'], style: const TextStyle(color: Colors.black, fontSize: 16)),
                      Text(trip['mynum'], style: const TextStyle(color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(serviceDuration, style: const TextStyle(color: Colors.black, fontSize: 14)),
              const SizedBox(height: 10),
              Text(
                '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}\n${trip['time']}',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              const Divider(),
              Text(trip['to'], style: const TextStyle(color: Colors.black, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

Future<List<DocumentSnapshot>> _checkForOverlappingTrips(DateTime startDate, DateTime endDate, String tripTime) async {
  // Get current driver's data
  Map<String, dynamic> userData = await retrieveUserData();
  String firstName = userData['firstName'];
  String lastName = userData['lastName'];

  print("Current Driver: $firstName $lastName");
  print("Querying with First Name: $firstName, Last Name: $lastName");

  // Query for advance bookings for the current driver
final snapshot = await FirebaseFirestore.instance
    .collection('Advance Bookings')
    .where('drivername', isEqualTo: firstName)
    .where('driverlastName', isEqualTo: lastName)
    .get(const GetOptions(source: Source.serverAndCache)); // Optionally use caching


  print("User's Advance Bookings: ${snapshot.docs.length} found");

  // Check if any bookings are found
  if (snapshot.docs.isEmpty) {
    print("No advance bookings found for this driver.");
    return []; // Return an empty list
  }

  // Print retrieved bookings for debugging
  for (var doc in snapshot.docs) {
    print("Booking ID: ${doc.id}, Date: ${doc['date']}, To: ${doc['to']}, Time: ${doc['time']}");
  }

  tripTime = cleanTripTime(tripTime);
  DateTime chosenTime = parseTime(tripTime);

  DateTime bufferStart = chosenTime.subtract(const Duration(hours: 1));
  DateTime bufferEnd = chosenTime.add(const Duration(hours: 1));

  // Filter for overlapping trips
  return snapshot.docs.where((doc) {
    DateTime tripStartDate = doc['date'].toDate();
    DateTime tripEndDate = doc['dateto'].toDate();
    String existingTripTime = cleanTripTime(doc['time']);
    DateTime existingTime = parseTime(existingTripTime);

    bool sameDay = tripStartDate.isAtSameMomentAs(tripEndDate) ||
                   (tripStartDate.isBefore(tripEndDate) && tripEndDate.isAfter(tripStartDate));

    print("Checking booking ID: ${doc.id}, Existing Time: $existingTime, Buffer Start: $bufferStart, Buffer End: $bufferEnd");

    return sameDay && (existingTime.isAfter(bufferStart) && existingTime.isBefore(bufferEnd) ||
                        existingTime.isAtSameMomentAs(chosenTime));
  }).toList();
}


  String cleanTripTime(String tripTime) {
    return tripTime
        .replaceAll(RegExp(r'[\u00A0]'), '')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime parseTime(String time) {
    try {
      return DateFormat.jm().parse(time);
    } catch (e) {
      final parts = time.split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        final hour = int.parse(timeParts[0]) % 12 + (parts[1] == 'PM' ? 12 : 0);
        final minute = int.parse(timeParts[1]);
        return DateTime(0, 1, 1, hour, minute);
      }
      throw FormatException("Invalid time format: '$time'");
    }
  }

  void _showOverlappingDialog(BuildContext context, List<DocumentSnapshot> overlappingTrips) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF2E3192),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Warning: There are overlapping trips!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'The following trips overlap:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                ...overlappingTrips.map((doc) => Text(
                  'Trip to ${doc['to']} on ${DateFormat.yMMMd().format(doc['date'].toDate())} at ${doc['time']}',
                  style: const TextStyle(color: Colors.white),
                )),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Rounded borders
      ),
                  ),
                  child: const Text(
                          'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAcceptanceDialog(BuildContext context, DocumentSnapshot trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF2E3192),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Would you accept this Service?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'After accepting, you will see full passenger details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(width: 16),
                    Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('Advance Bookings').doc(trip.id).update({
                            'status': 'Accepted',
                            'drivername': name,
                            'driverlastName': lastName,
                            'driverid': id,
                            'driverbodynumber': bodynumber,
                            'phoneNumber': phoneNumber,
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
  }

  void _deleteTrip(String key) {
    tripRequestsRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip deleted successfully')));
      setState(() {});
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting trip: $error')));
    });
  }
}
