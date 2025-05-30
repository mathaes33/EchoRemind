// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:echo_remind/models/reminder.dart';
import 'package:echo_remind/services/database/database_helper.dart';
import 'package:echo_remind/ui/screens/add_edit_reminder_screen.dart';
import 'package:echo_remind/services/geofencing/geofence_service.dart'; // To reload geofences
import 'package:echo_remind/ui/screens/debug_screen.dart'; // Import debug screen
import 'package:provider/provider.dart';
import 'package:echo_remind/services/purchase/purchase_service.dart'; // Import PurchaseService

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Reminder>> _activeReminders;
  late Future<List<Reminder>> _inactiveReminders;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _activeReminders = _dbHelper.getActiveReminders();
      _inactiveReminders = _dbHelper.getAllReminders().then((list) => list.where((r) => !r.isActive).toList());
    });
    // Ensure geofences are reloaded after any change to reminders
    Provider.of<GeofenceServiceWrapper>(context, listen: false).reloadGeofences();
  }

  void _showDeleteConfirmationDialog(int reminderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Reminder?'),
          content: Text('Are you sure you want to delete this reminder? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                await _dbHelper.deleteReminder(reminderId);
                _loadReminders(); // Reload reminders after deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reminder deleted.')),
                );
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
        title: Text('EchoRemind'),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report), // Debug button
            onPressed: () {
              Navigator.pushNamed(context, DebugScreen.id);
            },
          ),
          // TODO: Add a button for Subscription Screen
          IconButton(
            icon: Icon(Icons.workspace_premium),
            onPressed: () {
              // Navigator.pushNamed(context, SubscriptionScreen.id);
              print('Navigate to Subscription Screen');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReminders,
        child: ListView(
          children: <Widget>[
            _buildReminderList(
              title: 'Active Reminders',
              future: _activeReminders,
              isActiveList: true,
            ),
            Divider(),
            _buildReminderList(
              title: 'Inactive Reminders',
              future: _inactiveReminders,
              isActiveList: false,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Pass null for a new reminder
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditReminderScreen()),
          );
          if (result == true) {
            _loadReminders(); // Reload reminders if a new one was added/edited
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Add New Reminder',
      ),
    );
  }

  Widget _buildReminderList({
    required String title,
    required Future<List<Reminder>> future,
    required bool isActiveList,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder<List<Reminder>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading reminders: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      isActiveList ? 'No active reminders.' : 'No inactive reminders.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final reminder = snapshot.data![index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      elevation: 2.0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActiveList ? Colors.green[400] : Colors.grey[400],
                          child: Icon(
                            isActiveList ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          reminder.title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trigger: ${reminder.triggerType.toUpperCase()}'),
                            Text('Lat: ${reminder.latitude.toStringAsFixed(4)}, Lon: ${reminder.longitude.toStringAsFixed(4)}'),
                            if (reminder.radius != null)
                              Text('Radius: ${reminder.radius!.toStringAsFixed(0)} m'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isActiveList ? Icons.pause_circle_filled : Icons.play_circle_fill),
                              color: isActiveList ? Colors.orange : Colors.green,
                              tooltip: isActiveList ? 'Deactivate' : 'Activate',
                              onPressed: () async {
                                reminder.isActive = !reminder.isActive;
                                await _dbHelper.updateReminder(reminder);
                                _loadReminders(); // Reload after status change
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Reminder status updated.')),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              color: Colors.blue,
                              tooltip: 'Edit Reminder',
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditReminderScreen(reminder: reminder),
                                  ),
                                );
                                if (result == true) {
                                  _loadReminders(); // Reload reminders if edited
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Delete Reminder',
                              onPressed: () => _showDeleteConfirmationDialog(reminder.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
