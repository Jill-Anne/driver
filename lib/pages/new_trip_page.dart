import 'dart:async';

import 'package:driver/methods/common_methods.dart';
import 'package:driver/methods/map_theme_methods.dart';
import 'package:driver/models/trip_details.dart';
import 'package:driver/pages/profile_page.dart';
import 'package:driver/widgets/payment_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/global_var.dart';
import '../widgets/loading_dialog.dart';


class NewTripPage extends StatefulWidget
{
  TripDetails? newTripDetailsInfo;

  NewTripPage({super.key, this.newTripDetailsInfo,});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage>
{
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  MapThemeMethods themeMethods = MapThemeMethods();
  double googleMapPaddingFromBottom = 0;
  List<LatLng> coordinatesPolylineLatLngList = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Marker> markersSet = Set<Marker>();
  Set<Circle> circlesSet = Set<Circle>();
  Set<Polyline> polyLinesSet = Set<Polyline>();
  BitmapDescriptor? carMarkerIcon;
  bool directionRequested = false;
  String statusOfTrip = "accepted";
  String durationText = "", distanceText = "";
  String buttonTitleText = "ARRIVED";
  Color buttonColor = Colors.indigoAccent;
  CommonMethods cMethods = CommonMethods();
   Future<double>? fareAmountFuture;




  makeMarker()
  {
    if(carMarkerIcon == null)
    {
      ImageConfiguration configuration = createLocalImageConfiguration(context, size: Size(2, 2));

      BitmapDescriptor.fromAssetImage(configuration, "assets/images/tracking.png")
          .then((valueIcon)
      {
        carMarkerIcon = valueIcon;
      });
    }
  }


  obtainDirectionAndDrawRoute(sourceLocationLatLng, destinationLocationLatLng) async
  {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...',)
    );

    var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
        sourceLocationLatLng,
        destinationLocationLatLng
    );

    Navigator.pop(context);

    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPoints = pointsPolyline.decodePolyline(tripDetailsInfo!.encodedPoints!);

    coordinatesPolylineLatLngList.clear();

    if(latLngPoints.isNotEmpty)
    {
      latLngPoints.forEach((PointLatLng pointLatLng)
      {
        coordinatesPolylineLatLngList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    //draw polyline
    polyLinesSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("routeID"),
        color: Colors.amber,
        points: coordinatesPolylineLatLngList,
        jointType: JointType.round,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true
      );

      polyLinesSet.add(polyline);
    });

    //fit the polyline on google map
    LatLngBounds boundsLatLng;

    if(sourceLocationLatLng.latitude > destinationLocationLatLng.latitude
        && sourceLocationLatLng.longitude > destinationLocationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
          southwest: destinationLocationLatLng,
          northeast: sourceLocationLatLng,
      );
    }
    else if(sourceLocationLatLng.longitude > destinationLocationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
          northeast: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
      );
    }
    else if(sourceLocationLatLng.latitude > destinationLocationLatLng.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
        northeast: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(
        southwest: sourceLocationLatLng,
        northeast: destinationLocationLatLng,
      );
    }

    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add marker
    Marker sourceMarker = Marker(
      markerId: const MarkerId('sourceID'),
      position: sourceLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId('destinationID'),
      position: destinationLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersSet.add(sourceMarker);
      markersSet.add(destinationMarker);
    });

    //add circle
    Circle sourceCircle = Circle(
      circleId: const CircleId('sourceCircleID'),
      strokeColor: Colors.orange,
      strokeWidth: 4,
      radius: 14,
      center: sourceLocationLatLng,
      fillColor: Colors.green,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId('destinationCircleID'),
      strokeColor: Colors.green,
      strokeWidth: 4,
      radius: 14,
      center: destinationLocationLatLng,
      fillColor: Colors.red,
    );

    setState(() {
      circlesSet.add(sourceCircle);
      circlesSet.add(destinationCircle);
    });
  }

  getLiveLocationUpdatesOfDriver()
  {
    LatLng lastPositionLatLng = LatLng(0, 0);

    positionStreamNewTripPage = Geolocator.getPositionStream().listen((Position positionDriver)
    {
      driverCurrentPosition = positionDriver;

      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      Marker carMarker = Marker(
        markerId: const MarkerId("carMarkerID"),
        position: driverCurrentPositionLatLng,
        icon: carMarkerIcon!,
        infoWindow: const InfoWindow(title: "My Location"),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: driverCurrentPositionLatLng, zoom: 16);
        controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet.removeWhere((element) => element.markerId.value == "carMarkerID");
        markersSet.add(carMarker);
      });

      lastPositionLatLng = driverCurrentPositionLatLng;

      //update Trip Details Information
      updateTripDetailsInformation();

      //update driver location to tripRequest
      Map updatedLocationOfDriver =
      {
        "latitude": driverCurrentPosition!.latitude,
        "longitude": driverCurrentPosition!.longitude,
      };
      FirebaseDatabase.instance.ref().child("tripRequests")
          .child(widget.newTripDetailsInfo!.tripID!)
          .child("driverLocation")
          .set(updatedLocationOfDriver);
    });
  }

  updateTripDetailsInformation() async
  {
    if(!directionRequested)
    {
      directionRequested = true;

      if(driverCurrentPosition == null)
      {
        return;
      }

      var driverLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      LatLng dropOffDestinationLocationLatLng;
      if(statusOfTrip == "accepted")
      {
        dropOffDestinationLocationLatLng = widget.newTripDetailsInfo!.pickUpLatLng!;
      }
      else
      {
        dropOffDestinationLocationLatLng = widget.newTripDetailsInfo!.dropOffLatLng!;
      }

      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(driverLocationLatLng, dropOffDestinationLocationLatLng);

      if(directionDetailsInfo != null)
      {
        directionRequested = false;

        setState(() {
          durationText = directionDetailsInfo.durationTextString!;
          distanceText = directionDetailsInfo.distanceTextString!;
        });
      }
    }
  }
endTripNow() async {
  // Create LatLng for driver's current location
  var driverCurrentLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
  print('Driver Current Location: ${driverCurrentLocationLatLng.latitude}, ${driverCurrentLocationLatLng.longitude}');

  // Show loading dialog (optional)
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...'),
  );

  // Get direction details from API
  var directionDetailsEndTripInfo = await CommonMethods.getDirectionDetailsFromAPI(
    widget.newTripDetailsInfo!.pickUpLatLng!, // pickup
    widget.newTripDetailsInfo!.dropOffLatLng! // drop-off
  );

  // Dismiss loading dialog early
  Navigator.pop(context); 

  // Check if direction details were retrieved
  if (directionDetailsEndTripInfo != null) {
    print('Direction Details:');
    print('Distance: ${directionDetailsEndTripInfo.distanceTextString}');
    print('Duration: ${directionDetailsEndTripInfo.durationTextString}');
    
    // Calculate fare amount
    String fareAmount = (await cMethods.calculateFareAmount(directionDetailsEndTripInfo)).toString();
    print('Calculated fareAmount: $fareAmount');

    // Display payment dialog immediately
    displayPaymentDialog(fareAmount);

    // Save fare amount in Firebase (run this in the background)
    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("fareAmount")
        .set(fareAmount);
    print('Fare amount saved in Firebase: $fareAmount');

    // Update trip status in Firebase
    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("status")
        .set("ended");

    // Update driver's newTripStatus to "ended"
    String driverUID = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance.ref()
        .child("driversAccount")
        .child(driverUID)
        .child("newTripStatus")
        .set("ended");
    print('Driver newTripStatus updated to "ended"');

    // Cancel any position streams if necessary
    positionStreamNewTripPage!.cancel();
  } else {
    print('Failed to retrieve direction details.');
  }
}


displayPaymentDialog(String fareAmount) {
  // Check if the current context is still valid
  if (context.mounted) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        fareAmount: fareAmount,
        tripID: widget.newTripDetailsInfo!.tripID!,
        amount: '', // Pass any relevant amount here
      ),
    );
  } else {
    print("Context is no longer valid, cannot show dialog.");
  }
}

  // saveFareAmountToDriverTotalEarnings(String fareAmount) async
  // {
  //   DatabaseReference driverEarningsRef = FirebaseDatabase.instance.ref()
  //       .child("driversAccount")
  //       .child(FirebaseAuth.instance.currentUser!.uid)
  //       .child("earnings");

  //   await driverEarningsRef.once().then((snap)
  //   {
  //     if(snap.snapshot.value != null)
  //     {
  //       double previousTotalEarnings = double.parse(snap.snapshot.value.toString());
  //       double fareAmountForTrip = double.parse(fareAmount);

  //       double newTotalEarnings = previousTotalEarnings + fareAmountForTrip;

  //       driverEarningsRef.set(newTotalEarnings);
  //     }
  //     else
  //     {
  //       driverEarningsRef.set(fareAmount);
  //     }
  //   });
  // }

Future<void> saveDriverDataToTripInfo() async {
  // Retrieve user data
  Map<String, dynamic> userData = await retrieveUserData();

  if (userData.isNotEmpty) {
    // Extract necessary data from user data
    String firstName = userData['firstName'];
    String lastName = userData['lastName'];
    String idNumber = userData['idNumber'];
    String bodyNumber = userData['bodyNumber'];

    // Create a map containing driver data
    Map<String, dynamic> driverDataMap = {
      "status": "accepted",
      "driverID": FirebaseAuth.instance.currentUser!.uid,
      "firstName": firstName,
      "lastName": lastName,
      "idNumber": idNumber,
      "bodyNumber": bodyNumber,
    };

    // Print driver data for debugging
    print('Driver Data:');
    print(driverDataMap);

    // Update trip request with driver data
    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .update(driverDataMap);

    // Get current driver location
    Map<String, dynamic> driverCurrentLocation = {
      'latitude': driverCurrentPosition!.latitude.toString(),
      'longitude': driverCurrentPosition!.longitude.toString(),
    };

    // Print current driver location for debugging
    print('Driver Current Location:');
    print(driverCurrentLocation);

    // Update trip request with driver's current location
    await FirebaseDatabase.instance.ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("driverLocation").update(driverCurrentLocation);

    // Print success message
    print('Driver data and location saved successfully.');
  } else {
    // Print error message if no user data found
    print("Error: No user data found.");
  }
}

void setupFirebaseListeners() {
  FirebaseDatabase.instance.ref()
    .child("tripRequests")
    .child(widget.newTripDetailsInfo!.tripID!)
    .onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        // Check for trip status updates
        final status = data['status'] as String?;
        if (status == 'cancelled') {
          showCancellationDialog();
        } else if (status == 'ended') {
          // Handle trip ended logic here
          // e.g., show final summary, navigate to another page, etc.
        }
      }
    });
}

void showCancellationDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: Text('Trip Cancelled'),
      content: Text('The trip has been cancelled by the driver.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    ),
  );
}



@override
void initState() {
  super.initState();
  saveDriverDataToTripInfo();
  setupFirebaseListeners(); // Add this line to set up Firebase listeners
}


  @override
  Widget build(BuildContext context)
  {
    makeMarker();

    return Scaffold(
      body: Stack(
        children: [

          ///google map
          GoogleMap(
            padding: EdgeInsets.only(bottom: googleMapPaddingFromBottom),
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: markersSet,
            circles: circlesSet,
            polylines: polyLinesSet,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) async
            {
              controllerGoogleMap = mapController;
              themeMethods.updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                googleMapPaddingFromBottom = 262;
              });

              var driverCurrentLocationLatLng = LatLng(
                  driverCurrentPosition!.latitude,
                  driverCurrentPosition!.longitude
              );

              var userPickUpLocationLatLng = widget.newTripDetailsInfo!.pickUpLatLng;

              await obtainDirectionAndDrawRoute(driverCurrentLocationLatLng, userPickUpLocationLatLng);

              getLiveLocationUpdatesOfDriver();
            },
          ),

          ///trip details
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F8FC),
                borderRadius: BorderRadius.only(topRight: Radius.circular(17), topLeft: Radius.circular(17)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 17,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: 290,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                                Center(
  child: Container(
    width: 200, // Adjust the width here
    child: Divider(
      height: 8,
      thickness: 4,
      color: Colors.grey[400],
    ),
  ),
),
const SizedBox(height: 9,),
                    //trip duration
                    Center(
                      child: Text(
                        durationText + " - " + distanceText,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5,),

                    //user name - call user icon btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        //user name
                        Text(
                          widget.newTripDetailsInfo!.userName!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        //call user icon btn
                        GestureDetector(
                          onTap: ()
                          {
                            launchUrl(
                              Uri.parse(
                                "tel://${widget.newTripDetailsInfo!.userPhone.toString()}"
                              ),
                            );
                          },
                          child: Padding(
  padding: const EdgeInsets.only(right: 10),
  child: Stack(
    alignment: Alignment.center,
    children: [
      // Container(
      //   height: 35,
      //   width: 35,
      //   decoration: BoxDecoration(
      //     borderRadius: const BorderRadius.all(
      //       Radius.circular(25),
      //     ),
      //     border: Border.all(
      //       width: 2,
      //       color: const Color(0xFF2E3192),
      //     ),
      //   ),
      // ),
      const Icon(
        Icons.phone,
        color: Color.fromARGB(255, 21, 20, 20),
      ),
    ],
  ),
),

                        ),

                      ],
                    ),

                    const SizedBox(height: 15,),


// Pickup icon and location
// Pickup icon and location
Row(
  crossAxisAlignment: CrossAxisAlignment.start, // Align text at the top
  children: [
    // Move the image down a bit
    Transform(
      transform: Matrix4.translationValues(0.0, 4.0, 0.0), // Adjust the vertical offset as needed
      child: Image.asset(
        "assets/images/initial.png",
        height: 16,
        width: 16,
      ),
    ),
    const SizedBox(width: 8), // Add space between image and text
    Flexible(
      child: Text(
        widget.newTripDetailsInfo!.pickupAddress.toString(),
        overflow: TextOverflow.visible, // Allow text to overflow and wrap
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black54,
          fontWeight: FontWeight.bold
        ),
      ),
    ),
  ],
),


                    const SizedBox(height: 15,),

                    //dropoff icon and location
                    Row(
                      children: [

                        Image.asset(
                          "assets/images/final.png",
                          height: 16,
                          width: 16,
                        ),
const SizedBox(width: 8), // Add space between image and text
                        Expanded(
                          child: Text(
                            widget.newTripDetailsInfo!.dropOffAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),

                      ],
                    ),


                    

                    const SizedBox(height: 20,),
Center(
  child: ElevatedButton(
    onPressed: () async {
      if (statusOfTrip == "accepted") {
        setState(() {
          buttonTitleText = "START TRIP";
          buttonColor = const Color(0xFF2E3192);
        });

        statusOfTrip = "arrived";

        await FirebaseDatabase.instance
            .ref()
            .child("tripRequests")
            .child(widget.newTripDetailsInfo!.tripID!)
            .child("status")
            .set("arrived");

        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => LoadingDialog(messageText: 'Please wait...'),
        );

        await obtainDirectionAndDrawRoute(
          widget.newTripDetailsInfo!.pickUpLatLng,
          widget.newTripDetailsInfo!.dropOffLatLng,
        );

        Navigator.pop(context);
      } else if (statusOfTrip == "arrived") {
        setState(() {
          buttonTitleText = "END TRIP";
          buttonColor = Colors.red;
        });

        statusOfTrip = "ontrip";

        await FirebaseDatabase.instance
            .ref()
            .child("tripRequests")
            .child(widget.newTripDetailsInfo!.tripID!)
            .child("status")
            .set("ontrip");
      } else if (statusOfTrip == "ontrip") {
        await endTripNow(); // Ensure this is awaited
      }
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
      backgroundColor: buttonColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    ),
    child: Text(
      buttonTitleText,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
  ),
),

                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
