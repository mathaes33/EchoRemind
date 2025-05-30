import 'package:flutter/material.dart';
import 'package:echo_remind/ui/screens/onboarding_screen.dart';
import 'package:echo_remind/ui/screens/home_screen.dart';
import 'package:echo_remind/ui/screens/add_edit_reminder_screen.dart';
import 'package:echo_remind/ui/screens/debug_screen.dart'; // Import debug screen
import 'package:echo_remind/services/geofencing/geofence_service.dart';
import 'package:provider/provider.dart';
import 'package:echo_remind/services/purchase/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize PurchaseService first as it's needed by GeofenceServiceWrapper to determine premium status
  final purchaseService = PurchaseService();
  await purchaseService.initialize();

  // Pass BuildContext to GeofenceServiceWrapper for Provider access
  // This requires a bit of a trick for `main()` which doesn't have a BuildContext.
  // We'll initialize GeofenceServiceWrapper inside a StatefulWidget's initState or on a root widget.
  // For simplicity and immediate startup, we'll pass a dummy context or
  // refactor initialize() in GeofenceServiceWrapper to directly take purchaseService.
  // For this bundled package, we'll refine the GeofenceServiceWrapper.initialize
  // to directly use the purchaseService instance.

  runApp(
    MultiProvider(
      providers: [
        Provider<PurchaseService>(create: (_) => purchaseService),
        // Providing GeofenceServiceWrapper as a value for simplicity,
        // it initializes itself within its constructor/init method.
        // Or better, it can be initialized outside and provided.
        // For geofence_service, the background isolate requires a static callback.
        // The foreground service wrapper needs to be initialized.
        Provider<GeofenceServiceWrapper>(
          create: (context) {
            final geoService = GeofenceServiceWrapper();
            // This might cause an issue if context is not fully built.
            // A common pattern is to call initialization on the first screen.
            // For now, let's keep the initialization in main and ensure
            // the GeofenceServiceWrapper itself pulls PurchaseService if needed.
            // Let's modify GeofenceServiceWrapper's initialize to take PurchaseService directly.
            geoService.initialize(purchaseService); // Pass the initialized purchase service
            return geoService;
          },
          lazy: false, // Eagerly create the service
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoRemind',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: OnboardingScreen.id,
      routes: {
        OnboardingScreen.id: (context) => OnboardingScreen(),
        HomeScreen.id: (context) => HomeScreen(),
        AddEditReminderScreen.id: (context) => AddEditReminderScreen(),
        DebugScreen.id: (context) => DebugScreen(), // Debug Screen Route
        // Add SubscriptionScreen.id when it's implemented
        // SubscriptionScreen.id: (context) => SubscriptionScreen(),
      },
    );
  }
}
