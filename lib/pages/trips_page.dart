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
  int selectedIndex = 0;

  // Function to change the tab
  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Trips'),
      //   backgroundColor: Colors.deepPurple,
      // ),
 
      body: Column(
        
        children: [
          // Tab bar at the top that shows both tabs and highlights the selected one
           SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [


// Pending Booking Tab
              GestureDetector(
                onTap: () => onTabSelected(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedIndex == 1 ? Colors.deepPurple : Colors.white,
                        width: 2.0,
                      ),
                    ),
                  ),
                  child: Text(
                    'Pending Service',
                    style: TextStyle(
                      fontSize: 17,
                      color: selectedIndex == 1 ? Colors.deepPurple : Colors.grey,
                      fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),

              // Trip History Tab
               
              GestureDetector(
                onTap: () => onTabSelected(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedIndex == 0 ? Colors.deepPurple : Colors.white,
                        width: 2.0,
                      ),
                    ),
                  ),
                  child: Text(
                    'Trip History',
                    style: TextStyle(
                      fontSize: 17,
                      color: selectedIndex == 0 ? Colors.deepPurple : Colors.black54,
                      fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 20), // Space between the two tabs

              
            ],
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
