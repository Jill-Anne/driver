import 'dart:convert';
import 'package:driver/pushNotification/firebaseToken.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static Future<void> sendNotificationToPassenger(
      String deviceToken, String tripID, String status, String s) async {
    final notificationMap = {
      "title": "Trip Status Update",
      "body": "The driver has updated the status of your trip. Trip ID: $tripID",
    };

    final dataMapNotification = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": status,
      "tripID": tripID,
    };

    final messageMap = {
      "message": {
        "token": deviceToken,
        "notification": notificationMap,
        "data": dataMapNotification,
        "android": {
          "priority": "high",
        },
      }
    };

    print('Preparing to send FCM notification...');
    print('Device Token: $deviceToken');
    print('Notification Body: ${jsonEncode(messageMap)}');

    try {
      // Get FCM access token
      final String accessToken = await FirebaseAccessToken.getToken();
      print('Retrieved FCM access token: $accessToken');

      // Sending FCM notification
      final response = await http.post(
        Uri.parse("https://fcm.googleapis.com/v1/projects/passenger-signuplogin/messages:send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(messageMap),
      );

      print('FCM request sent.');
      print('Request Headers: ${jsonEncode({
            "Content-Type": "application/json",
            "Authorization": "Bearer $accessToken",
          })}');
      print('Request Body: ${jsonEncode(messageMap)}');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('FCM notification sent successfully.');
      } else {
        print('Error sending FCM notification. Status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error sending FCM notification: $e');
      print('Stack trace: $stackTrace');
    }
  }
}