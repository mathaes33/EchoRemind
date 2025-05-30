// lib/services/notifications/notification_service.dart
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final BehaviorSubject<String?> selectNotificationSubject =
      BehaviorSubject<String?>();

  Future<void> initialize() async {
    // Make sure 'app_icon' exists in android/app/src/main/res/drawable/
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification:
                (int id, String? title, String? body, String? payload) async {
      // Handle iOS notifications received while the app is in the foreground
      // You might want to display a dialog or update UI for this scenario.
    });

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        selectNotificationSubject.add(response.payload);
      }
    });
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool playCustomSound = false, // Add option for custom sound
    String? customSoundFileName, // Name of the custom sound file
  }) async {
    // Android sound configuration
    AndroidNotificationDetails androidNotificationDetails;
    if (playCustomSound && customSoundFileName != null) {
      androidNotificationDetails = AndroidNotificationDetails(
        'reminder_notifications_custom_sound', // Different channel for custom sound
        'Reminder Notifications (Custom Sound)',
        channelDescription: 'Notifications for location-based reminders with custom sound',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        playSound: true,
        sound: RawResourceAndroidNotificationSound(customSoundFileName.split('.').first), // Assuming file is in raw folder
      );
    } else {
      androidNotificationDetails = const AndroidNotificationDetails(
        'reminder_notifications_default', // Default channel
        'Reminder Notifications (Default)',
        channelDescription: 'Notifications for location-based reminders with default sound',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        playSound: true, // Default sound
      );
    }

    // iOS sound configuration
    final DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // For custom sounds on iOS, you need to add the sound file to your Xcode project.
      // The sound parameter expects the filename including its extension.
      sound: playCustomSound && customSoundFileName != null ? customSoundFileName : null,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidNotificationDetails, iOS: iOSNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
