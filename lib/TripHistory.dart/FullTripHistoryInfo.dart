import 'package:driver/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class TripDetailsPage extends StatelessWidget {
  final Map tripDetails;

  const TripDetailsPage({super.key, required this.tripDetails});
  

  @override
  Widget build(BuildContext context) {
    // Initialize formatted date and time
    String tripEndedTimeFormatted = "N/A";
    String timeOnly = "N/A";

    // Try parsing the trip ended time
    if (tripDetails["tripEndedTime"] != null) {
      try {
        DateFormat dateFormat = DateFormat("MMMM d, yyyy h:mm a");
        DateTime tripEndedDateTime = dateFormat.parse(tripDetails["tripEndedTime"]);
        tripEndedTimeFormatted = DateFormat('MMMM d, yyyy h:mm a').format(tripEndedDateTime);
      } catch (e) {
        tripEndedTimeFormatted = "Invalid date format";
        print("Date parsing error: $e");
      }
    }

    // Try parsing the publish date and time
    if (tripDetails["publishDateTime"] != null) {
      try {
        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
        DateTime publishDateTime = dateFormat.parse(tripDetails["publishDateTime"]);
        timeOnly = DateFormat('h:mm a').format(publishDateTime);
      } catch (e) {
        timeOnly = "Invalid time format";
        print("Time parsing error: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
    
body: Stack(
  children: [
    CustomColumnWithLogo(),
    Positioned(
      top: 60, // Adjust this value to move the card upwards or downwards
      left: 10,
      right:10,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 340, // Adjust this value to set the desired maximum height
        ),
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[800]!, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Ended Time
                Text(
                  '$tripEndedTimeFormatted - $timeOnly',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Grey Line Divider
                Divider(
                  color: Colors.grey[800],
                  thickness: 1,
                ),
                const SizedBox(height: 16),

                // Content Row with Two Columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side (Pick Up, Drop Off, and Fare Information Sections)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pick Up Section
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset('assets/images/initial.png', height: 20, width: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pick Up',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Wrap(
                                        children: [
                                          Text(
                                            tripDetails["pickUpAddress"].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Drop Off Section
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset('assets/images/final.png', height: 20, width: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Drop Off',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Wrap(
                                        children: [
                                          Text(
                                            tripDetails["dropOffAddress"].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Fare Amount Section
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₱ ${tripDetails["fareAmount"] ?? "0.00"}",
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Total Fare',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // Right side (Driver Information)
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 40),

                          // Driver Photo
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/toda.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Driver Name
                          Text(
                            '${tripDetails["userName"] ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Phone Number
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Phone Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Wrap(
                                        children: [
                                          Text(
                                            tripDetails["userPhone"].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),

    Positioned(
          left: 0,
          bottom: 0,
          child: logowidget("assets/images/LOGO.png"),
        ),
  ],
),

    );

  }
}
