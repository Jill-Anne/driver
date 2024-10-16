import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:driver/serviceRequest/serviceHistoryCompleted.dart';
import 'package:driver/serviceRequest/serviceHistoryFullCancelled.dart';
import 'package:driver/serviceRequest/serviceHistoryfullAll.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ServiceHistory extends StatefulWidget {
  @override
  _ServiceHistoryState createState() => _ServiceHistoryState();
}

class _ServiceHistoryState extends State<ServiceHistory> {
  int selectedIndex = 0; // Default tab index for ALL

  // Function to change the tab
  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Service Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 1, 42, 123),
      ),
      body: Column(
        children: [
          // Tab bar with background color
          Container(
            height: 50,
            color: Color.fromARGB(255, 1, 42, 123),
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ALL Tab
                GestureDetector(
                  onTap: () => onTabSelected(0),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'ALL',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 0 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // COMPLETED Tab
                GestureDetector(
                  onTap: () => onTabSelected(1),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 1 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // CANCELLED Tab
                GestureDetector(
                  onTap: () => onTabSelected(2),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 2
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 2
                              ? Colors.white
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 2 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content changes based on selected tab
          Expanded(
            child: selectedIndex == 0
                ? AllServicesPage()
                : selectedIndex == 1
                    ? CompletedServicesPage()
                    : CancelledServicesPage(),
          ),
        ],
      ),
    );
  }
}

class AllServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error occurred: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(child: Text('No services found.'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              String status = service['status'] ?? 'Unknown';

              return _buildServiceTile(context, service, status);
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchServices() async {
    // Get current driver's data
    Map<String, dynamic> userData = await retrieveUserData();
    String currentDriverName =
        '${userData['firstName']} ${userData['lastName']}';
    String currentDriverPhone = userData['phoneNumber'];

    // Fetch completed services and filter them
    final completedServices = await FirebaseFirestore.instance
        .collection('Advance Booking History')
        .where('status', whereIn: [
      'Completed',
      'No Appearance',
      'Rejected and Cancelled'
    ]).get();

    List<DocumentSnapshot> filteredCompletedServices =
        completedServices.docs.where((service) {
      if (service.data().containsKey("drivername") &&
          service.data().containsKey("phoneNumber")) {
        String driverName = service["drivername"];
        String driverPhone = service["phoneNumber"];
        return driverName == currentDriverName ||
            driverPhone == currentDriverPhone;
      }
      return false; // Exclude services without driver details
    }).toList();

/*
    // Fetch and filter cancelled services
    final cancelledServices = await FirebaseFirestore.instance
        .collection('Cancelled Service')
        .where('status', isEqualTo: 'Rejected and Cancelled')
        .get();

    List<DocumentSnapshot> filteredCancelledServices =
        cancelledServices.docs.where((service) {
      if (service.data().containsKey("drivername") &&
          service.data().containsKey("phoneNumber")) {
        String driverName = service["drivername"];
        String driverPhone = service["phoneNumber"];
        return driverName == currentDriverName ||
            driverPhone == currentDriverPhone;
      }
      return false; // Exclude services without driver details
    }).toList();
*/
    // Combine filtered completed and cancelled services
    return [...filteredCompletedServices, ];
  }

  Widget _buildServiceTile(
      BuildContext context, DocumentSnapshot service, String status) {
    // Ensure 'postedAt' is a Timestamp
    Timestamp? timestamp = service['postedAt'] as Timestamp?;
    DateTime dateTime =
        timestamp?.toDate() ?? DateTime.now(); // Fallback to now if null
    String formattedDate = DateFormat('MMMM d, y  h:mm: a').format(dateTime);

    // Safely retrieve other fields
    String from = service['from'] ?? 'Unknown';
    String to = service['to'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Color.fromARGB(21, 245, 245, 245), // Light background color
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: Text(
              'Trip on $formattedDate',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From $from to $to',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: status == 'Completed' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            leading: Icon(Icons.event),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailsPage(service: service),
                ),
              );
            },
          ),
        ),
        Divider(
          thickness: 2,
          color: Colors.grey[400],
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }
}

class CompletedServicesPage extends StatefulWidget {
  @override
  _CompletedServicesPageState createState() => _CompletedServicesPageState();
}

class _CompletedServicesPageState extends State<CompletedServicesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchCompletedServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error occurred: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(child: Text('No completed services found.'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              String status = service['status'] ?? 'Unknown';
              List<dynamic> datesArray = service['dates'] ?? [];

              List<Widget> completedTiles = [];

              // Loop through the 'dates' array and find completed entries
              for (var dateEntry in datesArray) {
                if (dateEntry is Map<String, dynamic> &&
                    dateEntry['status'] == 'Completed') {
                  String completedTime = dateEntry['completed time'] ??
                      'No completed time available';
                  completedTiles
                      .add(_buildServiceTile(service, status, completedTime));
                }
              }

              // If no completed services found, show a message
              if (completedTiles.isEmpty) {
                return Center(child: Text('No completed services found.'));
              }

              // Return the list of completed service tiles
              return Column(
                children: completedTiles,
              );
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchCompletedServices() async {
    // Fetch all completed services
    final completedServices = await FirebaseFirestore.instance
        .collection('Advance Booking History')
        .where('status', isEqualTo: 'Completed')
        .get();

    // Create a list to hold the filtered services
    List<DocumentSnapshot> filteredCompletedServices = [];

    // Get current driver's data
    Map<String, dynamic> userData = await retrieveUserData();
    String currentDriverName =
        '${userData['firstName']} ${userData['lastName']}';
    String currentDriverPhone = userData['phoneNumber'];

    print('Current Driver Name: $currentDriverName');
    print('Current Driver Phone: $currentDriverPhone');

    // Filter completed services
    for (var service in completedServices.docs) {
      print('Checking completed service: ${service.id}');

      // Check if the service has driver details
      if (service.data().containsKey("drivername") &&
          service.data().containsKey("phoneNumber")) {
        String driverName = service["drivername"];
        String driverPhone = service["phoneNumber"];

        print('Driver Name in Service: $driverName');
        print('Driver Phone in Service: $driverPhone');

        // Compare with current driver's details
        if (driverName == currentDriverName ||
            driverPhone == currentDriverPhone) {
          filteredCompletedServices.add(service);
          print('Added completed service: ${service.id}');
        } else {
          print('Driver details do not match.');
        }
      } else {
        print('No driver details in completed service: ${service.id}');
      }
    }

    // Combine the filtered lists and return
    return [
      ...filteredCompletedServices,
    ];
  }

  String _extractCompletedTime(DocumentSnapshot serviceData) {
    String completedTime = '';

    // Check if 'dates' exists and is a List
    if (serviceData['dates'] is List) {
      List<dynamic> datesArray = serviceData['dates'];

      print('Dates array: $datesArray'); // Debug print

      for (var dateEntry in datesArray) {
        // Ensure dateEntry is a Map
        if (dateEntry is Map<String, dynamic>) {
          print('Checking date entry: $dateEntry'); // Debug print

          // Check the status and completed time
          if (dateEntry['status'] == 'Completed') {
            completedTime =
                dateEntry['completed time'] ?? 'No completed time available';
            print('Found completed time: $completedTime'); // Debug print
            break; // Exit the loop after finding the completed time
          } else {
            print(
                'Status is not Completed: ${dateEntry['status']}'); // Debug print
          }
        } else {
          print('Date entry is not a Map: $dateEntry'); // Debug print
        }
      }
    } else {
      print('No dates found or not a list.'); // Debug print
    }

    return completedTime;
  }

  Widget _buildServiceTile(
      DocumentSnapshot service, String status, String completedTime) {
    Timestamp? timestamp = service['postedAt'] as Timestamp?;
    DateTime dateTime = timestamp?.toDate() ?? DateTime.now();
    String formattedDate = DateFormat('MMMM d, y  h:mm: a').format(dateTime);

    String from = service['from'] ?? 'Unknown';
    String to = service['to'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Color.fromARGB(21, 245, 245, 245),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: Text(
              'Trip on $formattedDate',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From $from to $to',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: status == 'Completed' ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Completed Time: $completedTime',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            leading: Icon(Icons.event),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {
              // Add navigation or other actions here if needed
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ServiceCompleteDetailPage(service: service),
                ),
              );
            },
          ),
        ),
        Divider(
          thickness: 2,
          color: Colors.grey[400],
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }
}

class CancelledServicesPage extends StatefulWidget {
  const CancelledServicesPage({super.key});

  @override
  _CancelledServicesPageState createState() => _CancelledServicesPageState();
}

class _CancelledServicesPageState extends State<CancelledServicesPage> {
  Future<List<DocumentSnapshot>> _fetchFilteredCancelledServices() async {
    // Fetch all cancelled services
    final cancelledServices = await FirebaseFirestore.instance
        .collection('Cancelled Service')
        .where('status',
            whereIn: ['Cancelled', 'Rejected and Cancelled']).get();

    print('Fetched ${cancelledServices.docs.length} cancelled services');

    // Create a list to hold the filtered services
    List<DocumentSnapshot> filteredCancelledServices = [];

    // Get current driver's data
    Map<String, dynamic> userData = await retrieveUserData();
// Get current driver's full name
    String currentDriverFullName =
        '${userData['firstName']} ${userData['lastName']}';

// Filter cancelled services based on driver name
    for (var service in cancelledServices.docs) {
      print('Checking cancelled service: ${service.id}');

      // Get both driver names
      String driverName = service["drivername"];
      String driverLastName = service["driverlastName"];
      String fullDriverNameFromService =
          '$driverName $driverLastName'; // Concatenate

      // Print both names for comparison
      print('Current Driver Full Name: $currentDriverFullName');
      print('Driver Full Name from Service: $fullDriverNameFromService');

      // Compare with current driver's full name
      if (fullDriverNameFromService.trim() == currentDriverFullName.trim()) {
        // Check the 'dates' array for cancelled statuses
        var dates = service['dates'] as List;

        for (var date in dates) {
          if (date['status'] == 'Cancelled' ||
              date['status'] == 'Rejected and Cancelled') {
            filteredCancelledServices.add(service);
            print('Added cancelled service: ${service.id}');
            break; // Stop checking other dates if we found a cancelled status
          }
        }
      } else {
        print('Driver details do not match.');
      }
    }

    print(
        'Total filtered cancelled services: ${filteredCancelledServices.length}');
    return filteredCancelledServices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 245, 245, 245),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60.0),
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchFilteredCancelledServices(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error occurred'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;
                if (data == null || data.isEmpty) {
                  return const Center(child: Text('No Cancelled Services'));
                }

                // Process cancelled services without grouping by date
                List<Widget> serviceWidgets = [];
                for (var service in data) {
                  // Check the 'dates' array for cancelled statuses
                  var dates = service['dates'] as List;
                  for (var date in dates) {
                    if (date['status'] == 'Cancelled' ||
                        date['status'] == 'Rejected and Cancelled') {
                      serviceWidgets.add(_buildListTile(
                          service, date['date'].toDate(), context));
                      serviceWidgets.add(
                        Center(
                          // Divider after each ListTile
                          child: Container(
                            width: 310, // Shorter width
                            child: Divider(
                              height: 1,
                              thickness: 2,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }

                return ListView(children: serviceWidgets);
              },
            ),
          ),

          // Positioned text for the current date
          Positioned(
            top: 10,
            left: 15,
            child: Text(
              'As of ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: TextStyle(
                color: Color.fromARGB(255, 1, 42, 123),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildListTile(
    DocumentSnapshot service, DateTime serviceDate, BuildContext context) {
  String cancelledTime = '';
  List<dynamic> datesArray = service['dates'];

  // Loop through the dates array to find the cancelled entry
  for (var dateEntry in datesArray) {
    if (dateEntry['status'] == 'Cancelled') {
      cancelledTime = dateEntry['cancelled time'] ?? ''; // Get the cancelled time
      break; // Exit after finding the first cancelled entry
    }
  }

  return Container(
    color: Color.fromARGB(21, 245, 245, 245),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      title: Text(
        'Cancelled at $cancelledTime for Scheduled Service Request on ${DateFormat.yMMMd().format(serviceDate)}',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      subtitle: Text(
        'From ${service["from"]} to ${service["to"]}',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
      leading: Icon(Icons.cancel),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceHistoryFullCancelledPage(service: service),
          ),
        );
      },
    ),
  );
}

}
