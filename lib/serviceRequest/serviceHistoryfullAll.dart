import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceDetailsPage extends StatelessWidget {
  final DocumentSnapshot service;

  const ServiceDetailsPage({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> serviceData = service.data() as Map<String, dynamic>;
    DateTime postedDate = (serviceData['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedDate = DateFormat('MMMM d, y  h:mm: a').format(postedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text("Service Details"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ListView.builder(
              itemCount: _getDatesArray(serviceData).length,
              itemBuilder: (context, index) {
                var dateEntry = _getDatesArray(serviceData)[index];
                return _buildTripCard(dateEntry, serviceData, context);
              },
            ),
          ),
          Positioned(
            bottom: -80,
            left: -10,
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Image.asset(
                'assets/images/LOGO.png',
                width: 300,
                height: 400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getDatesArray(Map<String, dynamic> serviceData) {
    return serviceData['dates'] ?? [];
  }

  Widget _buildTripCard(Map<String, dynamic> dateEntry, Map<String, dynamic> serviceDetails, BuildContext context) {
    DateTime date = (dateEntry['date'] as Timestamp).toDate();
    String status = dateEntry['status'] ?? 'Unknown';
    String completedTime = dateEntry['completed time'] ?? 'N/A';

    final startDate = (serviceDetails['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final endDate = (serviceDetails['dateto'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Container(
margin: const EdgeInsets.all(10),
        child: Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${DateFormat.yMMMd().format(date)}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (serviceDetails["phoneNumber"] != null)
                    IconButton(
                      icon: Image.asset(
                        'assets/images/Call.png',
                        width: 30,
                        height: 30,
                      ),
                      onPressed: () async {
                        var url = 'tel:${serviceDetails["phoneNumber"]}';
                        if (await canLaunch(url)) {
                          await launch(url);
                        }
                      },
                    ),
                ],
              ),
              _buildStatusText('Completed Time: ', completedTime, status),
              _buildStatusText('Status: ', status, status),
              const Divider(color: Colors.grey, thickness: 1),
              _buildTripDetails(serviceDetails),
               

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRow('Start Date: ', DateFormat.yMMMd().format(startDate)),
                  const SizedBox(height: 5),
                  _buildDateRow('End Date: ', DateFormat.yMMMd().format(endDate)),
                ],
              ),
              Transform.translate(
                offset: Offset(0, -40),
                child: _buildDriverDetails(serviceDetails),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(String label, String value, String status) {
    return Text.rich(
      TextSpan(
        text: '$label',
        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: '$value',
            style: TextStyle(
              color: status == 'Cancelled' ? Colors.red : Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }


Widget _buildDateRow(String label, String date) { 
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: date,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverDetails(Map<String, dynamic> serviceDetails) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.translate(
              offset: Offset(10, 5),
              child: Container(
                width: 120,
                height: 100,
                child: Image.asset(
                  'assets/images/splash.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(
              '${serviceDetails["drivername"] ?? 'N/A'} ${serviceDetails["driverlastName"] ?? 'N/A'}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text('Phone: ${serviceDetails["phoneNumber"] ?? 'N/A'}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 14)),
            const SizedBox(height: 5),
            Text('Body Number: ${serviceDetails["driverbodynumber"] ?? 'N/A'}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 14)),
            const SizedBox(height: 5),
            Text('ID Number: ${serviceDetails["driverid"] ?? 'N/A'}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 14)),
          ],
        ),
      ],
    );
  }
  Widget _buildTripDetails(Map<String, dynamic> serviceDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/initial.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'PICK-UP: ',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: serviceDetails["from"] ?? 'N/A',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Image.asset(
              'assets/images/final.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'DROP-OFF: ',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: serviceDetails["to"] ?? 'N/A',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
