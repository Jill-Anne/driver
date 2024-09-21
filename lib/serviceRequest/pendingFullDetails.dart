import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FullDetails extends StatelessWidget {
  final DocumentSnapshot trip; // Pass the selected trip data

  const FullDetails({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));

    DateTime startDate = trip['date'].toDate();
    DateTime endDate = trip['dateto'].toDate();

    // Generate list of dates
    List<DateTime> dateList = [];
    for (var d = startDate; d.isBefore(endDate.add(Duration(days: 1))); d = d.add(Duration(days: 1))) {
      dateList.add(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trip Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 1, 42, 123),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // Add vertical padding
        child: ListView.builder(
          itemCount: dateList.length,
          itemBuilder: (context, index) {
            DateTime currentDate = dateList[index];
            return Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${DateFormat.yMMMd().format(currentDate)} at ${trip['time']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            var phoneUrl = 'tel:${trip["mynum"]}';
                            if (await canLaunch(phoneUrl)) {
                              await launch(phoneUrl);
                            }
                          },
                          icon: Image.asset(
                            'assets/images/Call.png',
                            height: 45,
                            width: 45,
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1, color: Colors.black),
                    _buildDetailRow('Passenger Name:', trip['name']),
                    const SizedBox(height: 8),
                    _buildDetailRow('Start Date:', '${DateFormat.yMMMd().format(startDate)} at ${trip['time']}'),
                    const SizedBox(height: 8),
                    _buildDetailRow('End Date:', DateFormat.yMMMd().format(endDate)),
                    const SizedBox(height: 10),
                    _buildLocationRow('PICK-UP:', trip['from'], 'assets/images/initial.png', Colors.red),
                    const SizedBox(height: 8),
                    _buildLocationRow('DROP-OFF:', trip['to'], 'assets/images/final.png', Colors.green),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          ),
                          onPressed: () {
                            _showRejectDialog(context);
                          },
                          child: const Text('Reject Service'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String title, String location, String iconPath, Color titleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(iconPath, height: 20, width: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
                TextSpan(text: location),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject this service?'),
          content: const Text('Are you sure you want to reject this service request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle service rejection logic here
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
