import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
//String userPhone = "";
String googleMapKey = "AIzaSyCkLt8ILMXSFRP12xS8P7830kGNBeGn47s";

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(14.726650, 120.943440),
  zoom: 14.4746,
);

StreamSubscription<Position>? positionStreamHomePage;
StreamSubscription<Position>? positionStreamNewTripPage;

int driverTripRequestTimeout = 22;
final audioPlayer = AssetsAudioPlayer();
Position? driverCurrentPosition;

String firstName = "";
String lastName = "";
String idNumber = "";
String bodyNumber = "";

String driverPhone = "";
String driverPhoto = "";
String carColor = "";
String carModel = "";
String carNumber = "";




String currentTripID = ""; // Global variable for storing the trip ID
void setTripID(String tripID) {
  currentTripID = tripID; // Update the global trip ID variable
  print("setTripID called with: $tripID"); // Print the incoming trip ID
}
