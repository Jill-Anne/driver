import 'package:driver/pages/advance_booking_pending.dart';
import 'package:driver/pages/new_advance_booking_pending.dart';
import 'package:driver/TripHistory.dart/trips_history_page.dart';
import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  // Variable to track which tab is currently selected
  int selectedIndex = 1; // Set default tab index to 1 (Pending Service)

  // Function to change the tab
  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Add space at the top
          SizedBox(height: 30),

          // Tab bar with background color
          Container(
            height: 50,
            color: Color.fromARGB(255, 1, 42,
                123), // Color(0xFFF2F8FC), // Set the background color of the tab bar
            padding: const EdgeInsets.symmetric(
                vertical: 0), // Adjust padding as needed
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pending Booking Tab
                GestureDetector(
                  onTap: () => onTabSelected(1),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Color.fromARGB(255, 1, 42, 123), // Background color
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 1
                              ? Color.fromARGB(255, 1, 42, 123)
                              : Color.fromARGB(255, 1, 42, 123),
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'Pending Service',
                      style: TextStyle(
                        fontSize: 17,
                        color: selectedIndex == 1 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                // Trip History Tab
                GestureDetector(
                  onTap: () => onTabSelected(0),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Color.fromARGB(255, 1, 42, 123), // Background color
                      border: Border(
                        bottom: BorderSide(
                          color:
                              selectedIndex == 0 ? Color.fromARGB(255, 1, 42, 123): Color.fromARGB(255, 1, 42, 123),
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'Trip History',
                      style: TextStyle(
                        fontSize: 17,
                        color: selectedIndex == 0 ?Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 20), // Space between the two tabs
              ],
            ),
          ),

          // Content changes based on selected tab
          Expanded(
            child: selectedIndex == 0
                ? TripsHistoryPage() // Show Trip History content
                : NewAdvanceBooking(), // Show Pending Booking content
          ),
        ],
      ),
    );
  }
}
