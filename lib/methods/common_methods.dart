import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:driver/global/global_var.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/direction_details.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackBar(
          "your Internet is not Available. Check your connection. Try Again.",
          context);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  turnOffLocationUpdatesForHomePage() {
    if (positionStreamHomePage != null) {
      positionStreamHomePage!
          .cancel(); // Cancel the stream subscription if it's not null
      positionStreamHomePage =
          null; // Set it to null to indicate that it's no longer in use
    }

    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);
  }

  turnOnLocationUpdatesForHomePage() {
    positionStreamHomePage!.resume();

    Geofire.setLocation(
      FirebaseAuth.instance.currentUser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );
  }

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      return "error";
    }
  }

  ///Directions API
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    String urlDirectionsAPI =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";

    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    if (responseFromDirectionsAPI == "error") {
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints =
        responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }


  // calculateFareAmount(DirectionDetails directionDetails)
  // {
  //   double distancePerKmAmount = 0.4;
  //   double durationPerMinuteAmount = 0.3;
  //   double baseFareAmount = 2;

  //   double totalDistanceTravelFareAmount = (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmount;
  //   double totalDurationSpendFareAmount = (directionDetails.durationValueDigits! / 60) * durationPerMinuteAmount;

  //   double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelFareAmount + totalDurationSpendFareAmount;

  //   return overAllTotalFareAmount.toStringAsFixed(1);
  // }


Future<double> calculateFareAmount(DirectionDetails directionDetails) async {
  try {
    // Retrieve the fare parameters from Firebase Firestore
    DocumentSnapshot fareData = await FirebaseFirestore.instance
        .collection('fareParameters')
        .doc('currentParameters')
        .get();

    if (!fareData.exists) {
      throw Exception('Fare parameters not found');
    }

    // Log retrieved fare data for debugging
    print('Retrieved fare data: ${fareData.data()}');

    // Ensure values are retrieved as double, handle possible type issues
    double distancePerKmAmount;
    double baseFareAmount;

    try {
      distancePerKmAmount = (fareData['distancePerKmAmount'] as num).toDouble();
    } catch (e) {
      print("Error converting distancePerKmAmount: $e");
      distancePerKmAmount = 0.0;
    }

    try {
      baseFareAmount = (fareData['baseFareAmount'] as num).toDouble();
    } catch (e) {
      print("Error converting baseFareAmount: $e");
      baseFareAmount = 0.0;
    }

    // Distance in km
    double distanceInKm;
    try {
      distanceInKm = directionDetails.distanceValueDigits! / 1000;
    } catch (e) {
      print("Error calculating distanceInKm: $e");
      distanceInKm = 0.0;
    }

    // Determine if distance exceeds the base fare threshold
    double distanceThreshold = 1.87; // Distance threshold for base fare

    double totalDistanceTravelFareAmount;
    if (distanceInKm > distanceThreshold) {
      // Calculate the fare for the distance beyond the base threshold
      double distanceBeyondThreshold = distanceInKm - distanceThreshold;
      totalDistanceTravelFareAmount = distanceBeyondThreshold * distancePerKmAmount;
    } else {
      // No additional fare for distances within the base threshold
      totalDistanceTravelFareAmount = 0;
    }

    // Calculate the overall total fare amount (base fare + distance-based fare)
    double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelFareAmount;

    // Round the fare amount to the nearest whole number
    overAllTotalFareAmount = overAllTotalFareAmount.roundToDouble();

    // Save the calculated fare amount to Firestore
    await FirebaseFirestore.instance
        .collection('currentFare')
        .doc('latestFare')
        .set({'amount': overAllTotalFareAmount});

    print('Calculated fare amount: PHP $overAllTotalFareAmount');
    return overAllTotalFareAmount;
  } catch (e) {
    print("Error fetching fare parameters or calculating fare: $e");
    return 0.0; // Return a default value or handle the error appropriately
  }
}


  
}
