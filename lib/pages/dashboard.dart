import 'package:driver/pages/advance_booking_pending.dart';
import 'package:flutter/material.dart';
import 'package:driver/pages/home_page.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:driver/pages/trips_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Set Dashboard as the initial route
      initialRoute: '/',
      routes: {
        // Define the routes
        '/': (context) => const Dashboard(),
        '/home': (context) => const HomePage(),
        '/advance': (context) => const AdvanceBooking(),
        '/trips': (context) => const TripsPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  int indexSelected = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onBarItemClicked(int i) {
    setState(() {
      indexSelected = i;
      controller.index = indexSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: const [
          HomePage(),
          AdvanceBooking(),
          TripsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              indexSelected == 0
                  ? "assets/images/Home_selected.png" // Grey image for selected
                  : "assets/images/Home.png", // Color image for unselected
              height: 24,
              width: 24,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              indexSelected == 1
                  ? "assets/images/AdvanceBooking_selected.png" // Grey image for selected
                  : "assets/images/AdvanceBooking.png", // Color image for unselected
              height: 24,
              width: 24,
            ),
            label: "Service Request",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              indexSelected == 2
                  ? "assets/images/TripHistory_selected.png" // Grey image for selected
                  : "assets/images/TripHistory.png", // Color image for unselected
              height: 24,
              width: 24,
            ),
            label: "Trips",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              indexSelected == 3
                  ? "assets/images/Profile_selected.png" // Grey image for selected
                  : "assets/images/Profile.png", // Color image for unselected
              height: 24,
              width: 24,
            ),
            label: "Profile",
          ),
        ],
        currentIndex: indexSelected,
        unselectedItemColor: Colors.grey,
        selectedItemColor:Color(0x662E3192),
         backgroundColor: Color(0xFFF2F8FC),
        showSelectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        onTap: onBarItemClicked,
      ),
    );
  }
}
