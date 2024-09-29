import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceCompleteDetailPage extends StatelessWidget {
  final DocumentSnapshot service;

  const ServiceCompleteDetailPage({Key? key, required this.service}) : super(key: key);
 @override
  Widget build(BuildContext context) {
    // Extracting service data from the passed DocumentSnapshot
    Map<String, dynamic> serviceData = service.data() as Map<String, dynamic>;

    // Extract the completed time from the dates array
    String completedTime = '';
    if (serviceData.containsKey('dates') && serviceData['dates'] is List) {
      List<dynamic> datesArray = serviceData['dates'];

      for (var dateEntry in datesArray) {
        if (dateEntry is Map<String, dynamic> &&
            dateEntry['status'] == 'Completed') {
          completedTime =
              dateEntry['completed time'] ?? 'No completed time available';
          break; // Exit the loop after finding the completed time
        }
      }
    }

    // Creating a map with the service details
    Map<String, dynamic> serviceDetails = {
      'serviceId': serviceData['id'] ?? 'Unknown ID',
      'name': serviceData['name'] ?? 'Unknown',
      'from': serviceData['from'] ?? 'Unknown',
      'to': serviceData['to'] ?? 'Unknown',
      'completedTime': completedTime,
      'status': serviceData['status'] ?? 'Unknown',
      'postedAt': serviceData['postedAt'], // Assuming 'postedAt' is a Timestamp
      'phoneNumber':
          serviceData['phoneNumber'] ?? 'No phone number', // Default value
      'driverName': serviceData['drivername'] ?? 'Unknown Driver',
      'driverLastName': serviceData['driverlastName'] ?? '',
      'driverId': serviceData['driverid'] ?? 'No ID',
      'driverBodyNumber': serviceData['driverbodynumber'] ?? 'No Body #',
      'date': serviceData['postedAt'], // Assuming this is the posted date
      'dateto': serviceData['dateto'], // Added to ensure it is available
      'time': serviceData['time'] ??
          'Unknown time', // Ensure the time field is available
    };

    DateTime postedDate = (serviceDetails['postedAt'] as Timestamp).toDate();
    String formattedTime = DateFormat('h:mm a').format(postedDate);

return Scaffold(
  appBar: AppBar(
    title: Text("Service Details"),
  ),
  body: Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 10.0), // Adjust the value as needed
        child: Column(
          children: [
            _buildTripCard(serviceDetails, formattedTime, context),
            Spacer(), // This allows the card to grow
          ],
        ),
      ),
      Positioned(
        bottom: -80, // Move the image outside the card's bounds
        left: -10, // Align it to the left
        child: Padding(
          padding: const EdgeInsets.all(0), // Optional padding for spacing
          child: Image.asset(
            'assets/images/LOGO.png',
            width: 300, // Adjust size as needed
            height: 400, // Adjust size as needed
          ),
        ),
      ),
    ],
  ),
);

  }

Widget _buildTripCard(Map<String, dynamic> serviceDetails, String formattedTime, BuildContext context) {
  final startDate = (serviceDetails['date'] as Timestamp).toDate();
  final endDate = (serviceDetails['dateto'] as Timestamp).toDate();
  final startTime = serviceDetails['time'];
  String status = serviceDetails['status'];

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
                    "${DateFormat.yMMMd().format(startDate)} $startTime",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (status != 'Pending')
                  IconButton(
                    icon: Image.asset(
                      'assets/images/Call.png',
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () async {
                      var text = 'tel:${serviceDetails["phoneNumber"]}';
                      if (await canLaunch(text)) {
                        await launch(text);
                      }
                    },
                  ),
              ],
            ),
            _buildStatusText('Completed Time: ', serviceDetails['completedTime'], status),
            _buildStatusText('Status: ', status, status),
            const Divider(color: Colors.grey, thickness: 1),
            
            // Combine Date Rows and Trip Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRow('Start Date: ', DateFormat.yMMMd().format(startDate)),
                const SizedBox(height: 5), // Minimal space between Start and End date
                _buildDateRow('End Date: ', DateFormat.yMMMd().format(endDate)),
                const SizedBox(height: 20), // Minimal space before trip details
                _buildTripDetails(context, serviceDetails), // Call the trip details here
                
              ],
            ),

Transform.translate(
  offset: Offset(0, -90), // Adjust this to move the driver details
  child: _buildDriverDetails(serviceDetails),
),

            // Driver info to the right side
            
          ],
        ),
      ),
    ),
  );
}

Widget _buildTripDetails(BuildContext context, Map<String, dynamic> serviceDetails) {
  return Column(
    children: [
      Row(
        children: [
   Transform.translate(
  offset: Offset(0, -20), // Adjust the offset as needed
  child: Image.asset(
    'assets/images/initial.png',
    width: 20,
    height: 20,
    fit: BoxFit.contain,
  ),
),

          const SizedBox(width: 8),
          SizedBox(
            width: 180,
            child: Text.rich(
              TextSpan(
                text: 'PICK-UP: ', // Static text
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${serviceDetails["from"]}', // Dynamic "from" field
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              maxLines: 6, // Limits to one line
              overflow: TextOverflow.ellipsis, // Adds "..." if text overflows
            ),
          ),
        ],
      ),
      const SizedBox(height: 10), // Minimal space between PICK-UP and DROP-OFF
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
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '${serviceDetails["to"]}',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.normal),
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
    mainAxisAlignment: MainAxisAlignment.end, // Align the row items to the end
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
 Transform.translate(
  offset: Offset(10, 5), 
  child: Container(
    width: 120, // Adjusted width for the image
    height: 100, // Adjusted height for the image
    child: Image.asset(
      'assets/images/splash.png',
      fit: BoxFit.cover, // Use BoxFit.cover or BoxFit.contain as needed
    ),
  ),
)
,
          Text(
            '${serviceDetails["driverName"]} ${serviceDetails["driverLastName"]}',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5), 
          Text('Phone: ${serviceDetails["phoneNumber"]}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 14)),
          const SizedBox(height: 5), 
          Text('Body Number: ${serviceDetails["driverBodyNumber"]}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 14)),
          const SizedBox(height: 5), 
          Text('ID Number: ${serviceDetails["driverId"]}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 14)),
        ],
      ),
    ],
  );
}



  



  String _extractCompletedTime(DocumentSnapshot serviceData) {
    // Your existing implementation for extracting completed time
    String completedTime = '';
    if (serviceData['dates'] is List) {
      List<dynamic> datesArray = serviceData['dates'];
      for (var dateEntry in datesArray) {
        if (dateEntry is Map<String, dynamic> &&
            dateEntry['status'] == 'Completed') {
          completedTime = dateEntry['completed time'] ?? 'No completed time available';
          break;
        }
      }
    }
    return completedTime;
  }
}
