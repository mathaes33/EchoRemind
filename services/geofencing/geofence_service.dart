// lib/services/geofencing/geofence_service.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:echo_remind/models/reminder.dart';
import 'package:echo_remind/services/database/database_helper.dart';
import 'package:echo_remind/services/notifications/notification_service.dart';
import 'package:echo_remind/services/purchase/purchase_service.dart'; // Import PurchaseService

@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  GeofenceService.initialize(
    callback: _geofenceCallbackDispatcher,
    notification: GeofenceNotification(
      title: 'EchoRemind is running in the background',
      androidNotificationChannelId: 'geofence_service_notification',
      androidNotificationChannelName: 'Geofence Service Notifications',
      androidNotificationChannelDescription: 'Notifications for geofence status changes',
      androidNotificationPriority: AndroidNotificationPriority.LOW,
      showWakeUp: true,
      showBigText: true,
    ),
    foreground: true,
  ).then((value) => print('GeofenceService initialize: $value'));
}

@pragma('vm:entry-point')
Future<void> _geofenceCallbackDispatcher(List<GeofenceStatus> statusList, Location? location, Activity? activity) async {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  await _notificationService.initialize(); // Ensure notification service is initialized

  for (final status in statusList) {
    print('Background Geofence Status: ${status.status}, Geofence ID: ${status.geofence.id}, Location: $location, Activity: $activity');
    final reminderId = int.tryParse(status.geofence.id);
    if (reminderId != null) {
      final reminder = await _databaseHelper.getReminder(reminderId);
      if (reminder != null) {
        if ((status.status == GeofenceStatus.ENTER && reminder.triggerType == 'arrive') ||
            (status.status == GeofenceStatus.EXIT && reminder.triggerType == 'leave')) {
          _notificationService.showNotification(
            id: reminder.id!,
            title: 'Reminder: ${reminder.title}',
            body: 'You have ${reminder.triggerType == 'arrive' ? 'arrived at' : 'left'} the location for "${reminder.title}".',
          );
        }
      }
    }
  }
}

class GeofenceServiceWrapper {
  final GeofenceService _geofenceService = GeofenceService.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  static const double defaultGeofenceRadius = 100.0; // in meters

  // Add a reference to PurchaseService
  late final PurchaseService _purchaseService;

  // Initialize with PurchaseService
  Future<void> initialize(PurchaseService purchaseService) async {
    _purchaseService = purchaseService;
    WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
    await _notificationService.initialize();

    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.addLocationChangeListener(_onLocationChanged);
    _geofenceService.addActivityChangeListener(_onActivityChanged);

    // Call the static callback dispatcher for the geofence service to run in background
    callbackDispatcher();
    await _startGeofencing();
  }

  Future<void> _startGeofencing() async {
    final reminders = await _databaseHelper.getActiveReminders();
    final bool isPremium = await _purchaseService.isPremiumUser; // Check premium status

    final geofenceList = reminders.map((reminder) {
      return Geofence(
        id: reminder.id.toString(),
        latitude: reminder.latitude,
        longitude: reminder.longitude,
        radius: isPremium && reminder.radius != null && reminder.radius! > 0
            ? reminder.radius!
            : defaultGeofenceRadius,
        loiteringDelay: const Duration(seconds: 10),
        androidSettings: const AndroidGeofenceSettings(
          initialTrigger: <GeofenceAndroidTransition>[
            GeofenceAndroidTransition.ENTER,
            GeofenceAndroidTransition.EXIT,
          ],
        ),
        iosSettings: const IOSGeofenceSettings(
          allowsBackgroundLocationUpdates: true,
          showsBackgroundLocationIndicator: true,
        ),
      );
    }).toList();

    if (geofenceList.isNotEmpty) {
      await _geofenceService.addGeofences(geofenceList).catchError((error) {
        print('Error adding geofences: $error');
      });
    }
  }

  Future<void> reloadGeofences() async {
    await _geofenceService.removeAllGeofences();
    await _startGeofencing();
  }

  void _onGeofenceStatusChanged(GeofenceStatus status, Geofence geofence, Location? location) async {
    print('Geofence Status: $status, Geofence ID: ${geofence.id}, Location: $location');
    final reminderId = int.tryParse(geofence.id);
    if (reminderId != null) {
      final reminder = await _databaseHelper.getReminder(reminderId);
      if (reminder != null) {
        if ((status == GeofenceStatus.ENTER && reminder.triggerType == 'arrive') ||
            (status == GeofenceStatus.EXIT && reminder.triggerType == 'leave')) {
          _notificationService.showNotification(
            id: reminder.id!,
            title: 'Reminder: ${reminder.title}',
            body: 'You have ${reminder.triggerType == 'arrive' ? 'arrived at' : 'left'} the location for "${reminder.title}".',
          );
        }
      }
    }
  }

  void _onLocationChanged(Location location) {
    print('Location changed: $location');
  }

  void _onActivityChanged(Activity activity) {
    print('Activity changed: $activity');
  }
}
