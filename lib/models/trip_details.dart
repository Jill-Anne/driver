import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class TripDetails {
  String? tripID;
  LatLng? pickUpLatLng;
  String? pickupAddress;
  LatLng? dropOffLatLng;
  String? dropOffAddress;
  String? userName;
  String? userPhone;
  String tripStartDate;  // Ensure these are String
  String tripEndDate;    // Ensure these are String
  String tripTime;     

  TripDetails({
    this.tripID,
    this.pickUpLatLng,
    this.pickupAddress,
    this.dropOffLatLng,
    this.dropOffAddress,
    this.userName,
    this.userPhone,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.tripTime,
  });
}
