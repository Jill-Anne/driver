import 'package:cloud_firestore/cloud_firestore.dart';
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
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0 ? Color.fromARGB(255, 1, 42, 123) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 0 ? Colors.white : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'ALL',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 0 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // COMPLETED Tab
                GestureDetector(
                  onTap: () => onTabSelected(1),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1 ? Color.fromARGB(255, 1, 42, 123) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 1 ? Colors.white : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 1 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // CANCELLED Tab
                GestureDetector(
                  onTap: () => onTabSelected(2),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 2 ? Color.fromARGB(255, 1, 42, 123) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 2 ? Colors.white : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 2 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 2 ? FontWeight.bold : FontWeight.normal,
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

// Placeholder widgets for the content of each tab
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

              return _buildServiceTile(service, status);
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchServices() async {
    // Fetch completed services
    final completedServices = await FirebaseFirestore.instance
    .collection('Advance Booking History')
    .where('status', whereIn: ['Completed', 'No Appearance'])
    .get();

    // Fetch cancelled services
    final cancelledServices = await FirebaseFirestore.instance
        .collection('Cancelled Service')
        .where('status', isEqualTo: 'Rejected and Cancelled')
        .get();

    // Combine both lists
    return [...completedServices.docs, ...cancelledServices.docs];
  }

  Widget _buildServiceTile(DocumentSnapshot service, String status) {
    // Ensure 'postedAt' is a Timestamp
    Timestamp? timestamp = service['postedAt'] as Timestamp?;
    DateTime dateTime = timestamp?.toDate() ?? DateTime.now(); // Fallback to now if null
    String formattedDate = DateFormat('MMMM d, y at h:mm:ss a').format(dateTime);

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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From $from to $to',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4), // Small space between lines
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
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // Add navigation or other actions here if needed
            },
          ),
        ),
        Divider(
          thickness: 2, // Adjust thickness
          color: Colors.grey[400], // Adjust color
          indent: 20, // Adjust the left padding of the divider
          endIndent: 20, // Adjust the right padding of the divider
        ),
      ],
    );
  }
}

class CompletedServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 245, 245, 245), // Light background color
      body: Stack(
        children: [
          // Add padding to create space above the ListView
          Padding(
            padding: const EdgeInsets.only(top: 60.0), // Adjust the top padding as needed
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Advance Booking History')
                  .where('status', isEqualTo: 'Completed')
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error occurred'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;
                if (data.docs.isEmpty) {
                  return const Center(child: Text('No Completed Services'));
                }

                // Group completed services by completed time
                Map<String, List<DocumentSnapshot>> groupedServices = {};
                for (var service in data.docs) {
                  String completedTime = service['completed time']; // Directly retrieve as string
                  String formattedDate = completedTime.split(' at ')[0]; // Get the date part
                  if (!groupedServices.containsKey(formattedDate)) {
                    groupedServices[formattedDate] = [];
                  }
                  groupedServices[formattedDate]!.add(service);
                }

                // Combine dates and services into a single list
                List<dynamic> combinedList = [];
                for (var dateKey in groupedServices.keys) {
                  combinedList.add(dateKey); // Add the date header
                  combinedList.addAll(groupedServices[dateKey]!); // Add services for this date
                }

                // Use ListView.builder
                return ListView.builder(
                  itemCount: combinedList.length,
                  itemBuilder: (context, index) {
                    final item = combinedList[index];

                    if (item is String) {
                      // If it's a date header, display it without a divider
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          item, // Displaying the grouped date
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 42, 123),
                          ),
                        ),
                      );
                    } else {
                      // Otherwise, it's a service document, display it with a divider
                      return Column(
                        children: [
                          _buildListTile(item, context), // Display the service ListTile
                          Center(
                            // Divider after each ListTile
                            child: Container(
                              width: 310, // Shorter width
                              child: Divider(
                                height: 1, // Less space around the divider
                                thickness: 2, // Thinner divider
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Positioned text for the current date
          Positioned(
            top: 10,
            left: 15,
            bottom: 40,
            child: Text(
              'As of ${DateFormat('MMM d, yyyy').format(DateTime.now())}', // Current date
              style: TextStyle(
                color: Color.fromARGB(255, 1, 42, 123),
                fontWeight: FontWeight.w500,
                fontSize: 14, // Adjust font size as needed
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(DocumentSnapshot service, BuildContext context) {
    // Extract the completed time as a string
    String completedTime = service['completed time']; // Assuming this field is a string

    return Container(
      color: Color.fromARGB(21, 245, 245, 245), // Light background color
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          'Completed on $completedTime', // Displaying the completed time
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        subtitle: Text(
          'From ${service["from"]} to ${service["to"]}',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        leading: Icon(Icons.event),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Add navigation or other actions here if needed
        },
      ),
    );
  }
}


class CancelledServicesPage extends StatefulWidget {
  const CancelledServicesPage({super.key});

  @override
  _CancelledServicesPageState createState() => _CancelledServicesPageState();
}

class _CancelledServicesPageState extends State<CancelledServicesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 245, 245, 245),
      body: Stack(
        children: [
          // Add padding to create space above the StreamBuilder
          Padding(
            padding: const EdgeInsets.only(top: 60.0), // Adjust the top padding as needed
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Cancelled Service')
                  .where('status', isEqualTo: 'Rejected and Cancelled')
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error occurred'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;
                if (data.docs.isEmpty) {
                  return const Center(child: Text('No Cancelled Services'));
                }

                // Group cancelled services by date
                Map<String, List<DocumentSnapshot>> groupedServices = {};
                for (var service in data.docs) {
                  DateTime serviceDate = service['date'].toDate();
                  String formattedDate = DateFormat('MMM d, yyyy').format(serviceDate);
                  if (!groupedServices.containsKey(formattedDate)) {
                    groupedServices[formattedDate] = [];
                  }
                  groupedServices[formattedDate]!.add(service);
                }

                // Combine dates and services into a single list
                List<dynamic> combinedList = [];
                for (var dateKey in groupedServices.keys) {
                  combinedList.add(dateKey); // Add the date header
                  combinedList.addAll(groupedServices[dateKey]!); // Add services for this date
                }

                // Use ListView.builder
                return ListView.builder(
                  itemCount: combinedList.length,
                  itemBuilder: (context, index) {
                    final item = combinedList[index];

                    if (item is String) {
                      // If it's a date header, display it without a divider
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          item, // Displaying the grouped date
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 42, 123),
                          ),
                        ),
                      );
                    } else {
                      // Otherwise, it's a service document, display it with a divider
                      return Column(
                        children: [
                          _buildListTile(item, context), // Display the service ListTile
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
                        ],
                      );
                    }
                  },
                );
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

  Widget _buildListTile(DocumentSnapshot service, BuildContext context) {
    DateTime serviceDate = service['date'].toDate();

    return Container(
      color: Color.fromARGB(21, 245, 245, 245),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          'Cancelled on ${DateFormat.yMMMd().format(serviceDate)}',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        subtitle: Text(
          'From ${service["from"]} to ${service["to"]}',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        leading: Icon(Icons.cancel),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Implement navigation if needed
        },
      ),
    );
  }
}
