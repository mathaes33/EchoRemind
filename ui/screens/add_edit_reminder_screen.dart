// lib/ui/screens/add_edit_reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:Maps_flutter/Maps_flutter.dart';
import 'package:echo_remind/models/reminder.dart';
import 'package:echo_remind/services/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:echo_remind/services/purchase/purchase_service.dart';
import 'package:echo_remind/services/geofencing/geofence_service.dart'; // Import for default radius
import 'package:location/location.dart' as loc; // For current location

class AddEditReminderScreen extends StatefulWidget {
  static const String id = 'add_edit_reminder_screen';

  final Reminder? reminder;

  AddEditReminderScreen({this.reminder});

  @override
  _AddEditReminderScreenState createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  LatLng? _selectedLocation;
  String _triggerType = 'arrive';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _radiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _selectedLocation = LatLng(widget.reminder!.latitude, widget.reminder!.longitude);
      _triggerType = widget.reminder!.triggerType;
      // Set radius from existing reminder or default
      _radiusController.text = widget.reminder!.radius != null
          ? widget.reminder!.radius!.toStringAsFixed(0)
          : GeofenceServiceWrapper.defaultGeofenceRadius.toStringAsFixed(0);
    } else {
      // Set default radius for new reminder
      _radiusController.text = GeofenceServiceWrapper.defaultGeofenceRadius.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(BuildContext context) async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPickerScreen(initialLocation: _selectedLocation)),
    );
    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  Future<void> _saveReminder(BuildContext context) async {
    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      final purchaseService = Provider.of<PurchaseService>(context, listen: false);
      final bool isPremium = purchaseService.isPremiumUser; // Get current premium status
      final activeReminderCount = await _dbHelper.getActiveReminderCount();

      double? radius;
      if (isPremium) {
        radius = double.tryParse(_radiusController.text);
        if (radius == null || radius <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter a valid radius (e.g., > 0).')),
          );
          return;
        }
      } else {
        radius = GeofenceServiceWrapper.defaultGeofenceRadius;
      }

      // Check reminder limit only for new active reminders and non-premium users
      if (!isPremium && widget.reminder == null && activeReminderCount >= 5) {
        _showUpgradePrompt(context);
        return;
      }

      final reminder = Reminder(
        id: widget.reminder?.id,
        title: _titleController.text,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        triggerType: _triggerType,
        isActive: widget.reminder?.isActive ?? true,
        radius: radius, // Save the chosen or default radius
      );

      if (widget.reminder == null) {
        await _dbHelper.insertReminder(reminder);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder added successfully!')),
        );
      } else {
        await _dbHelper.updateReminder(reminder);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder updated successfully!')),
        );
      }
      Navigator.pop(context, true); // Indicate success and pop
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields and select a location.')),
      );
    }
  }

  void _showUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Free Reminder Limit Reached'),
          content: Text('You have reached the limit of 5 active reminders for free users. Upgrade to premium to create more reminders.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Upgrade Now'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to the subscription screen
                // Navigator.pushNamed(context, SubscriptionScreen.id);
                print('Navigate to Subscription Screen for upgrade');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context); // Listen to premium status changes
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add New Reminder' : 'Edit Reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Reminder Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),
              Text('Trigger Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Arrive'),
                      value: 'arrive',
                      groupValue: _triggerType,
                      onChanged: (value) {
                        setState(() {
                          _triggerType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Leave'),
                      value: 'leave',
                      groupValue: _triggerType,
                      onChanged: (value) {
                        setState(() {
                          _triggerType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              ElevatedButton.icon(
                icon: Icon(Icons.map),
                label: Text(_selectedLocation == null
                    ? 'Select Location on Map'
                    : 'Change Selected Location (${_selectedLocation!.latitude.toStringAsFixed(2)}, ${_selectedLocation!.longitude.toStringAsFixed(2)})'),
                onPressed: () => _selectLocation(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(40), // Make button full width
                ),
              ),
              SizedBox(height: 20.0),
              // StreamBuilder to react to premium status changes for radius input
              StreamBuilder<bool>(
                stream: purchaseService.isPremiumStream,
                initialData: purchaseService.isPremiumUser, // Initial data from current value
                builder: (context, snapshot) {
                  final bool isPremium = snapshot.data ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Geofence Radius:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8.0),
                      if (isPremium)
                        TextFormField(
                          controller: _radiusController,
                          keyboardType: TextInputType.numberWithOptions(decimal: false), // Radius is integer
                          decoration: InputDecoration(
                            labelText: 'Radius in meters',
                            hintText: 'e.g., 150',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                              return 'Please enter a valid positive radius (e.g., 50-500)';
                            }
                            return null;
                          },
                        )
                      else
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Radius fixed at ${GeofenceServiceWrapper.defaultGeofenceRadius}m (Unlock adjustable radius with Premium)',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 20.0),
                      // TODO: Add Custom Notification Sound selection for premium users
                      // This would involve another StreamBuilder or checking isPremiumUser here
                      // and then presenting a UI for sound selection/toggling.
                      // For MVP, we'll indicate this is a premium feature.
                      if (!isPremium)
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Custom Notification Sounds (Premium Feature)',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: () => _saveReminder(context),
                child: Text('Save Reminder'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50), // Make button full width
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Location Picker Screen - for selecting coordinates on a map
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  LocationPickerScreen({this.initialLocation});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _pickedLocation;
  static const double _defaultLatitude = 37.7749; // Example: San Francisco
  static const double _defaultLongitude = -122.4194;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    if (widget.initialLocation != null) {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(widget.initialLocation!, 15));
    } else {
      _getCurrentLocation(); // Try to get current location if no initial location
    }
  }

  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;
    loc.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.requestPermission();
    if (_permissionGranted == loc.PermissionStatus.granted) {
      _locationData = await location.getLocation();
      setState(() {
        _pickedLocation = LatLng(_locationData.latitude!, _locationData.longitude!);
      });
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_pickedLocation!, 15));
    }
  }

  void _onTap(LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick a Location'),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _pickedLocation);
              },
            ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ?? LatLng(_defaultLatitude, _defaultLongitude),
          zoom: 12.0,
        ),
        onTap: _onTap,
        markers: _pickedLocation == null
            ? {}
            : {
                Marker(
                  markerId: MarkerId('selected_location'),
                  position: _pickedLocation!,
                ),
              },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.my_location),
        tooltip: 'Go to my current location',
      ),
    );
  }
}
