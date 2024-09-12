import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart'; // Ensure this import is present for date formatting

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {
    print("Notification received: ${notificationResponse.payload}");
  }

  static Future<void> init() async {
    print("Initializing notification service");

    try {
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings("@mipmap/ic_launcher");
      const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotification,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      print("Notification service initialized successfully");
    } catch (e) {
      print("Error initializing notification service: $e");
    }
  }

  static Future<void> showInstantNotification(String title, String body) async {
    try {
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_notification_channel_id',
            'Instant Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'logo',
          ),
          iOS: DarwinNotificationDetails());

      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'instant_notification',
      );
      print("Instant notification shown: $title - $body");
    } catch (e) {
      print("Error showing instant notification: $e");
    }
  }

static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title, // Notification title (e.g., 'Upcoming Trip Reminder')
        body,  // Custom body with the passenger name, date, time, and locations
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder Channel',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'logo',
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print("Scheduled notification for $scheduledTime: $title - $body");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  static DateTime combineDateAndTime(Timestamp dateTimestamp, String timeString) {
    // Convert Timestamp to DateTime
    DateTime date = dateTimestamp.toDate();

    // Parse the time string and combine with the date
    final timeFormat = DateFormat("h:mm a"); // Define the format of your time string
    final time = timeFormat.parse(timeString); // Parse the time string

    // Combine date and time
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static Future<void> scheduleReminderForAcceptedBookings() async {
    final firestore = FirebaseFirestore.instance;

    try {
      print("Querying Firestore for accepted bookings");
      final querySnapshot = await firestore.collection('Advance Bookings')
          .where('status', isEqualTo: 'Accepted')
          .get();

      print("Found ${querySnapshot.docs.length} accepted bookings");

      for (final doc in querySnapshot.docs) {
        // Ensure 'date', 'time', and other fields are correctly fetched
        final dateField = doc.data()['date'];
        final timeField = doc.data()['time'];
        final nameField = doc.data()['name'];
        final fromField = doc.data()['from'];
        final toField = doc.data()['to'];

        if (dateField is Timestamp && timeField is String) {
          final notificationTime = combineDateAndTime(dateField, timeField).subtract(Duration(minutes: 1));

          // Construct the custom notification body with passenger name, date, time, from, and to
final notificationBody = 'Passenger: $nameField\n'
    'Date and Time: ${DateFormat.yMMMd().format(dateField.toDate())} $timeField\n'
    'From: $fromField\n'
    'To: $toField\n';


          print("Scheduling notification for booking ID ${doc.id} at $notificationTime");

          // Schedule the notification with the custom body
          await scheduleNotification(
            doc.id.hashCode, // Use a unique ID for each notification
            'Upcoming Trip Reminder', // Custom title
            notificationBody, // Custom body message
            notificationTime,
          );
        } else {
          print("Error: 'date' or 'time' field is not of the expected type for booking ID ${doc.id}");
        }
      }
    } catch (e) {
      print("Error scheduling reminders: $e");
    }
  }

}
