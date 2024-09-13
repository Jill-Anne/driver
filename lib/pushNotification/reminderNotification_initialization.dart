import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart'; // Ensure this import is present for date formatting

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

static Future<void> onDidReceiveNotification(
    NotificationResponse notificationResponse) async {
  print("Notification received: ${notificationResponse.payload}");

  // Parse the payload if you want to handle deep links or navigate to a specific page
  if (notificationResponse.payload != null) {
    // Example: Navigate to a screen based on the payload data
    // Navigate to the page or perform some action
  }
}


  static Future<void> init() async {
    print("Initializing notification service");

    try {
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings(
              "@mipmap/ic_launcher"); // Replace with your icon name if needed
      const DarwinInitializationSettings iOSInitializationSettings =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotification,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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
            icon: 'logo', // Ensure 'logo' is a valid drawable resource name
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

  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder Channel',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'logo',
            fullScreenIntent:
                true,
            styleInformation: BigTextStyleInformation(''), 
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print("Scheduled notification for $scheduledTime: $title - $body");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  static DateTime combineDateAndTime(
      Timestamp dateTimestamp, String timeString) {
    DateTime date = dateTimestamp.toDate();
    final timeFormat = DateFormat("h:mm a");
    final time = timeFormat.parse(timeString);
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }


//ADDED
  static Future<void> showFCMNotification(RemoteMessage message) async {
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'fcm_channel_id',
        'FCM Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'logo', // Replace with your logo asset
      ),
      iOS: DarwinNotificationDetails());

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'Title',
    message.notification?.body ?? 'Body',
    platformChannelSpecifics,
  );
}


  static Future<void> scheduleReminderForAcceptedBookings() async {
    final firestore = FirebaseFirestore.instance;

    firestore
        .collection('Advance Bookings')
        .where('status', isEqualTo: 'Accepted')
        .snapshots()
        .listen((querySnapshot) {
      for (final doc in querySnapshot.docs) {
        final dateField = doc.data()['date'];
        final timeField = doc.data()['time'];
        final nameField = doc.data()['name'];
        final fromField = doc.data()['from'];
        final toField = doc.data()['to'];

        if (dateField is Timestamp && timeField is String) {
          final notificationTime = combineDateAndTime(dateField, timeField)
              .subtract(Duration(minutes: 1));

          final notificationBody = 'Passenger: $nameField\n'
              'Date and Time: ${DateFormat.yMMMd().format(dateField.toDate())} $timeField\n'
              'From: $fromField\n'
              'To: $toField\n';

          scheduleNotification(
            doc.id.hashCode,
            'Upcoming Trip Reminder',
            notificationBody,
            notificationTime,
          );
        } else {
          print(
              "Error: 'date' or 'time' field is not of the expected type for booking ID ${doc.id}");
        }
      }
    });
  }
}
