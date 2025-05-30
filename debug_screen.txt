// lib/ui/screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:echo_remind/models/reminder.dart';
import 'package:echo_remind/services/database/database_helper.dart';
import 'package:echo_remind/services/notifications/notification_service.dart';

class DebugScreen extends StatefulWidget {
  static const String id = 'debug_screen';

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  List<Reminder> _activeReminders = [];
  Reminder? _selectedReminder;

  @override
  void initState() {
    super.initState();
    _loadActiveReminders();
  }

  Future<void> _loadActiveReminders() async {
    final reminders = await _dbHelper.getActiveReminders();
    setState(() {
      _activeReminders = reminders;
      if (reminders.isNotEmpty && _selectedReminder == null) {
        _selectedReminder = reminders.first;
      }
    });
  }

  void _simulateArrival() {
    if (_selectedReminder != null) {
      _notificationService.showNotification(
        id: _selectedReminder!.id!,
        title: 'DEBUG Arrival: ${_selectedReminder!.title}',
        body: 'Simulated arrival at the location for "${_selectedReminder!.title}".',
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated Arrival notification sent!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No reminder selected.')));
    }
  }

  void _simulateLeaving() {
    if (_selectedReminder != null) {
      _notificationService.showNotification(
        id: _selectedReminder!.id!,
        title: 'DEBUG Leaving: ${_selectedReminder!.title}',
        body: 'Simulated leaving the location for "${_selectedReminder!.title}".',
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated Leaving notification sent!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No reminder selected.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Tools'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Select Active Reminder:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButton<Reminder>(
              value: _selectedReminder,
              hint: Text('Choose a reminder'),
              isExpanded: true,
              items: _activeReminders.map((Reminder reminder) {
                return DropdownMenuItem<Reminder>(
                  value: reminder,
                  child: Text(reminder.title),
                );
              }).toList(),
              onChanged: (Reminder? newValue) {
                setState(() {
                  _selectedReminder = newValue;
                });
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _simulateArrival,
              child: Text('Simulate Arrival'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(40),
              ),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _simulateLeaving,
              child: Text('Simulate Leaving'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(40),
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Note: These actions only trigger local notifications. They do not interact with the actual geofencing service or location providers.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
