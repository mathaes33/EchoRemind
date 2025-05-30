// lib/services/purchase/purchase_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class PurchaseService {
  static const premiumEntitlement = 'premium'; // Your premium entitlement identifier in RevenueCat

  final Purchases _purchases = Purchases.instance;
  // BehaviorSubject to stream premium status changes
  final BehaviorSubject<bool> _isPremium = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get isPremiumStream => _isPremium.stream;
  bool get isPremiumUser => _isPremium.value; // Synchronous getter for current status

  Future<void> initialize() async {
    await _purchases.setLogLevel(LogLevel.DEBUG); // Optional: Enable debug logging
    // Replace 'YOUR_REVENUECAT_APP_ID' with your actual RevenueCat App ID for your project
    await _purchases.configure(Configuration('YOUR_REVENUECAT_APP_ID'));
    _purchases.addCustomerInfoUpdateListener((customerInfo) {
      _isPremium.add(customerInfo.entitlements.all[premiumEntitlement]?.isActive == true);
      print('Customer info updated. Premium status: ${_isPremium.value}');
    });
    await _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final customerInfo = await _purchases.getCustomerInfo();
      _isPremium.add(customerInfo.entitlements.all[premiumEntitlement]?.isActive == true);
    } catch (e) {
      print('Error checking premium status: $e');
      _isPremium.add(false); // Assume not premium on error
    }
  }

  Future<List<Offering>> getOfferings() async {
    try {
      final offerings = await _purchases.getOfferings();
      if (offerings.current != null) {
        return [offerings.current!]; // Return the current offering
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching offerings: $e');
      return [];
    }
  }

  Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final customerInfo = await _purchases.purchasePackage(package);
      if (customerInfo.entitlements.all[premiumEntitlement]?.isActive == true) {
        _isPremium.add(true);
        return PurchaseResult.success;
      } else {
        // Purchase might have gone through but entitlement not granted
        // This could happen if you have specific entitlement rules in RevenueCat
        print('Purchase successful but entitlement not active.');
        return PurchaseResult.error;
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.get == PurchasesErrorCode.purchaseCancelled;
      if (errorCode == PurchasesErrorCode.purchaseCancelled) {
        print('Purchase cancelled.');
        return PurchaseResult.cancelled;
      } else {
        print('Error purchasing: ${e.message}');
        return PurchaseResult.error;
      }
    } catch (e) {
      print('Error purchasing package: $e');
      return PurchaseResult.error;
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await _purchases.restorePurchases();
      _isPremium.add(customerInfo.entitlements.all[premiumEntitlement]?.isActive == true);
      if (_isPremium.value) {
        print('Purchases restored successfully.');
      } else {
        print('No active purchases to restore.');
      }
    } on PlatformException catch (e) {
      print('Error restoring purchases: ${e.message}');
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }
}

enum PurchaseResult {
  success,
  cancelled,
  error,
}
