import 'package:driver/pages/advance_booking_pending.dart';
import 'package:driver/pages/new_advance_booking_pending.dart';
import 'package:driver/TripHistory.dart/trips_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  // Variable to track which tab is currently selected
  int selectedIndex = 1; // Default tab index (1 = Pending Service)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the System UI overlay style whenever dependencies change
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void initState() {
    super.initState();
    // Set the System UI overlay style when this page is created
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
          const SizedBox(height: 30),

          // Tab bar with background color
          Container(
            height: 50,
            color: const Color.fromARGB(255, 1, 42, 123), // Background color
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pending Booking Tab
                GestureDetector(
                  onTap: () => onTabSelected(1),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 1, 42, 123), // Background color
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 1 ? Colors.white : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'Pending Service',
                      style: TextStyle(
                        fontSize: 17,
                        color: selectedIndex == 1 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                // Trip History Tab
                GestureDetector(
                  onTap: () => onTabSelected(0),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 1, 42, 123), // Background color
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 0 ? Colors.white : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'Trip History',
                      style: TextStyle(
                        fontSize: 17,
                        color: selectedIndex == 0 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20), // Space between the two tabs
              ],
            ),
          ),

          // Content changes based on selected tab
          Expanded(
            child: selectedIndex == 0
                ? const TripsHistoryPage() // Show Trip History content
                : const NewAdvanceBooking(), // Show Pending Booking content
          ),
        ],
      ),
    );
  }
}
