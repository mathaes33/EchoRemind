// lib/ui/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:echo_remind/ui/screens/home_screen.dart'; // Import HomeScreen

class OnboardingScreen extends StatefulWidget {
  static const String id = 'onboarding_screen';

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _requestPermissions() async {
    // Request "When In Use" first, then "Always" if not granted for "Always".
    // This often yields better user acceptance for background location.
    var statusWhenInUse = await Permission.locationWhenInUse.request();

    if (statusWhenInUse.isGranted) {
      var statusAlways = await Permission.locationAlways.request();
      if (!statusAlways.isGranted) {
        // If "Always" is not granted, explain why it's needed
        _showPermissionRationalDialog(
          'Background Location Needed',
          'EchoRemind needs "Always" location access to trigger reminders even when the app is closed. Please grant this permission in settings.',
          Permission.locationAlways,
        );
      }
    } else if (statusWhenInUse.isDenied || statusWhenInUse.isPermanentlyDenied) {
      _showPermissionRationalDialog(
        'Location Permission Needed',
        'EchoRemind needs location access to function. Please grant "When In Use" or "Always" permission.',
        Permission.locationWhenInUse,
      );
    }

    // Request notification permission
    var notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted) {
      _showPermissionRationalDialog(
        'Notification Permission Needed',
        'EchoRemind needs notification permission to alert you about reminders.',
        Permission.notification,
      );
    }

    // Navigate to home screen only if critical permissions are granted or user dismissed rational
    if ((await Permission.locationWhenInUse.isGranted || await Permission.locationAlways.isGranted) &&
        await Permission.notification.isGranted) {
      Navigator.pushReplacementNamed(context, HomeScreen.id);
    } else {
      // Potentially show a persistent message or block functionality
      print('Not all critical permissions granted. Cannot proceed to home screen.');
    }
  }

  void _showPermissionRationalDialog(String title, String message, Permission permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Not Now'),
              onPressed: () {
                Navigator.of(context).pop();
                // If user declines, they might still be able to use limited features
                // or are stuck on onboarding. For MVP, we proceed if possible.
                if ((permissionType == Permission.locationWhenInUse && !permissionType.isGranted) ||
                    (permissionType == Permission.locationAlways && !permissionType.isGranted)) {
                  // If location permission is not granted, we might still allow them to home,
                  // but with a warning or disabled features. For now, we allow them to proceed.
                  Navigator.pushReplacementNamed(context, HomeScreen.id);
                } else if (permissionType == Permission.notification && !permissionType.isGranted) {
                   Navigator.pushReplacementNamed(context, HomeScreen.id);
                }
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Opens app settings for manual permission grant
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to EchoRemind'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.location_on, size: 80, color: Colors.blue),
            SizedBox(height: 20.0),
            Text(
              'EchoRemind helps you set location-based reminders. Get notified when you arrive or leave a specific place.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30.0),
            Text(
              'To work effectively, EchoRemind needs access to your location in the background and the ability to send notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
            ),
            SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Grant Permissions & Continue',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
