import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FullDetails extends StatefulWidget {
  final DocumentSnapshot trip; // Pass the selected trip data

  const FullDetails({Key? key, required this.trip}) : super(key: key);

  @override
  State<FullDetails> createState() => _FullDetailsState();
}

class _FullDetailsState extends State<FullDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));

    _tabController = TabController(length: 2, vsync: this); // 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime startDate = widget.trip['date'].toDate();
    DateTime endDate = widget.trip['dateto'].toDate();

    // Generate list of dates
    List<DateTime> dateList = [];
    for (var d = startDate;
        d.isBefore(endDate.add(Duration(days: 1)));
        d = d.add(Duration(days: 1))) {
      dateList.add(d);
    }

    // Filter completed dates
    List<Map<String, dynamic>> completedDates = [];
    if (widget.trip['dates'] != null) {
      for (var dateEntry in widget.trip['dates']) {
        if (dateEntry['status'] == 'Completed') {
          completedDates.add(dateEntry);
        }
      }
    }

    // Filter active dates for Pending Service
    List<Map<String, dynamic>> pendingDates = [];
    if (widget.trip['dates'] != null) {
      for (var dateEntry in widget.trip['dates']) {
        if (dateEntry['status'] == 'active') {
          pendingDates.add(dateEntry);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trip Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 42, 123),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
         onPressed: () {
  Navigator.pop(context);

  // Use `addPostFrameCallback` to set the status bar color after the UI frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));
  });
},

        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Service'),
            Tab(text: 'Completed Service'),
          ],
          indicatorColor: Colors.white, // Indicator color (underline)
  labelColor: Colors.white, // Text color when selected
  unselectedLabelColor: Colors.grey[400], // Text color when not selected
  labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Style for selected text
  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal), // Style for unselected text
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Service Tab
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: pendingDates.isEmpty
                ? const Center(child: Text('No Pending Service Request'))
                : ListView.builder(
                    itemCount: pendingDates.length,
                    itemBuilder: (context, index) {
                      var dateEntry = pendingDates[index];
                      DateTime currentDate =
                          (dateEntry['date'] as Timestamp).toDate();
                      return _buildTripCard(
                          currentDate); // Pass current date for card rendering
                    },
                  ),
          ),
          // Completed Service Tab
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ListView.builder(
              itemCount: completedDates.length,
              itemBuilder: (context, index) {
                var dateEntry = completedDates[index];
                DateTime currentDate =
                    (dateEntry['date'] as Timestamp).toDate();
                return _buildTripCard(
                    currentDate); // Pass current date for card rendering
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(DateTime currentDate) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 1),
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
                    '${DateFormat.yMMMd().format(currentDate)} at ${widget.trip['time']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var phoneUrl = 'tel:${widget.trip["mynum"]}';
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
            // Text(
            //   'Status: ${widget.trip['status']}',
            //   style: TextStyle(
            //     fontWeight: FontWeight.bold,
            //     color: widget.trip['status'] == 'Accepted'
            //         ? const Color.fromARGB(255, 27, 28, 27)
            //         : Colors.red,
            //   ),
            // ),
            const Divider(thickness: 1, color: Colors.black),
            _buildDetailRow('Passenger Name:', widget.trip['name']),
            const SizedBox(height: 8),
            _buildDetailRow('Start Date:',
                '${DateFormat.yMMMd().format(widget.trip['date'].toDate())} at ${widget.trip['time']}'),
            const SizedBox(height: 8),
            _buildDetailRow('End Date:',
                DateFormat.yMMMd().format(widget.trip['dateto'].toDate())),
            const SizedBox(height: 10),
            _buildLocationRow('PICK-UP:', widget.trip['from'],
                'assets/images/initial.png', Colors.red),
            const SizedBox(height: 8),
            _buildLocationRow('DROP-OFF:', widget.trip['to'],
                'assets/images/final.png', Colors.green),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3)),
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
  }

  Widget _buildDetailRow(String title, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      String title, String location, String iconPath, Color titleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(iconPath, height: 20, width: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: titleColor)),
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
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFF2E3192), // Dark blue background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            child: Padding(
              padding: const EdgeInsets.all(20), // Uniform padding
              child: SizedBox(
                width: 300,
                height: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Reject this Service?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white, // White text
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please contact the driver to discuss any concerns before rejecting the service request.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white70, // Slightly lighter white text
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Reset logic and close dialog
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // White button background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            minimumSize: const Size(100, 40),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.black87, // Dark text
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                            // Handle service rejection
                                                var phoneUrl = 'tel:${widget.trip["mynum"]}';
                    if (await canLaunch(phoneUrl)) {
                      await launch(phoneUrl);
                    }
                            Navigator.pop(context);
                            
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF922E2E), // Red background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            minimumSize: const Size(100, 43),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              color: Colors.white, // White text
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

}
