// lib/models/reminder.dart
class Reminder {
  int? id;
  String title;
  double latitude;
  double longitude;
  String triggerType; // 'arrive' or 'leave'
  bool isActive;
  DateTime createdAt;
  double? radius; // Add an optional radius for premium users

  Reminder({
    this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.triggerType,
    this.isActive = true,
    DateTime? createdAt,
    this.radius, // Initialize radius
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
      'triggerType': triggerType,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'radius': radius, // Include radius in map
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      triggerType: map['triggerType'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      radius: map['radius'] as double?, // Retrieve radius from map
    );
  }
}
