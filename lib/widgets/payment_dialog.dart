import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:restart_app/restart_app.dart';

class PaymentDialog extends StatefulWidget {
  final String fareAmount;
  final String tripID;
  final String amount;

  PaymentDialog({
    Key? key,
    required this.fareAmount,
    required this.tripID,
    required this.amount,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  Future<double>? _fareAmountFuture;

  @override
  void initState() {
    super.initState();
    _fareAmountFuture = _getFareAmount();
  }

  Future<double> _getFareAmount() async {
    try {
      return await FirebaseFirestore.instance.runTransaction<double>((transaction) async {
        DocumentReference fareRef = FirebaseFirestore.instance
            .collection('currentFare')
            .doc('latestFare');
        
        DocumentSnapshot fareDoc = await transaction.get(fareRef);

        if (fareDoc.exists) {
          double fareAmount = (fareDoc['amount'] as num).toDouble();
          return fareAmount;
        } else {
          print("No data found at 'currentFare/latestFare'");
          return 0.0;
        }
      });
    } catch (e) {
      print("Error fetching fare amount: $e");
      return 0.0;
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
     backgroundColor: Colors.transparent, // Changed to transparent to avoid extra space
      child: Container(
        width: 100, // Ensure the dialog is the same width
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<double>(
              future: _fareAmountFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Loading state
                  return Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: Colors.white,
                      size: 50, // Adjusted size to fit within the dialog
                      secondRingColor: Colors.black,
                      thirdRingColor: Colors.purple,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                  );
                } else {
                  double fare = snapshot.data ?? 0.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "COLLECT CASH",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(
                        height: 20,
                        color: Colors.white70,
                        thickness: 1.0,
                      ),
                      Text(
                        "₱" + fare.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "This is fare amount ₱ ${fare.toStringAsFixed(2)} to be charged from the passenger.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
  width: 180,  // Set button width
  height: 50, 
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          Navigator.pop(context);

                        //  Restart.restartApp();

                              // After payment, clear the latest fare amount from Firestore
      await FirebaseFirestore.instance
          .collection('currentFare')
          .doc('latestFare')
          .set({'amount': ''}); // Set the amount to 0 or empty
      print('Latest fare has been cleared.');
                        },
                         style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E3192),//Colors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5), // Border radius here
      ),
    ),
    child: const Text(
      "COLLECT CASH",
      style: TextStyle(
        color: Colors.white,  // Set text color to white
        fontWeight: FontWeight.bold,  // Bold text
        fontSize: 18,  // Set font size
      ),
    ),
                      ),
                      )
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
