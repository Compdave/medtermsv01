import 'package:flutter/foundation.dart';
// lib/core/services/revenuecat_service.dart

import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:medtermsv01/core/config/app_secrets.dart';
import 'package:medtermsv01/core/services/module_service.dart';

/// Handles all RevenueCat operations — initialization, offerings, purchase,
/// restore. Used for mobile IAP (iOS App Store + Google Play).
/// Web purchases are handled separately via LemonSqueezy + promo_screen.
class RevenueCatService {
  RevenueCatService._();

  // ---------------------------------------------------------------------------
  // Initialize
  // ---------------------------------------------------------------------------

  /// Call once in main.dart before runApp().
  /// Uses platform-specific API key from AppSecrets.
  static Future<void> initialize({required String userId}) async {
    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(
      Platform.isIOS
          ? AppSecrets.revenueCatAppleApiKey
          : AppSecrets.revenueCatGoogleApiKey,
    )..appUserID = userId;

    await Purchases.configure(configuration);
  }

  /// Update the RC user ID after sign in — links purchases to Supabase user.
  static Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  /// Reset RC to anonymous user on sign out.
  static Future<void> logOut() async {
    await Purchases.logOut();
  }

  // ---------------------------------------------------------------------------
  // Offerings
  // ---------------------------------------------------------------------------

  /// Fetch available offerings from RevenueCat.
  /// Returns null if no offerings are configured or network error.
  static Future<Offerings?> fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      // Debug — log what RC returns
      debugPrint('RC current offering: \${offerings.current?.identifier}');
      debugPrint('RC all offerings: \${offerings.all.keys.toList()}');
      if (offerings.current != null) {
        for (final p in offerings.current!.availablePackages) {
          debugPrint('RC package: \${p.identifier} / product: \${p.storeProduct.identifier} / price: \${p.storeProduct.priceString}');
        }
      }
      return offerings;
    } catch (e) {
      debugPrint('RC fetchOfferings error: \$e');
      return null;
    }
  }

  /// Fetch a specific package by product identifier.
  /// Searches all offerings — current first, then all others.
  /// Matches on storeProduct.identifier OR package.identifier.
  static Future<Package?> fetchPackage(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      
      // Search current offering first
      if (offerings.current != null) {
        for (final package in offerings.current!.availablePackages) {
          if (package.storeProduct.identifier == productId ||
              package.identifier == productId) {
            return package;
          }
        }
      }

      // Search all offerings
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          if (package.storeProduct.identifier == productId ||
              package.identifier == productId) {
            return package;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase
  // ---------------------------------------------------------------------------

  /// Purchase a package via RevenueCat.
  /// Returns true if purchase was successful or already owned.
  /// Throws [PurchasesErrorCode] on failure.
  ///
  /// After a successful purchase:
  /// 1. RC webhook fires → Supabase Edge Function → insertnewmodule (primary)
  /// 2. Client-side fallback checks hasModule() and calls insertnewmodule
  ///    directly if webhook hasn't fired yet.
  static Future<bool> purchasePackage(Package package) async {
    try {
      // v9 API: PurchaseParams takes package as positional argument
      await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.isNotEmpty;
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        return false; // User cancelled — not an error
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Restore Purchases
  // ---------------------------------------------------------------------------

  /// Restore previously purchased products.
  /// Returns list of active entitlement identifiers.
  /// Throws on network/store error.
  static Future<List<String>> restorePurchases() async {
    final result = await Purchases.restorePurchases();
    return result.entitlements.active.keys.toList();
  }

  /// Check if user currently has an active entitlement for [entitlementId].
  static Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Post-purchase module unlock (client-side fallback)
  // ---------------------------------------------------------------------------

  /// Called after a successful RC purchase.
  /// Waits briefly for the webhook to fire, then checks if module is unlocked.
  /// If not yet unlocked, calls insertnewmodule directly as a fallback.
  static Future<void> ensureModuleUnlocked({
    required String userId,
    required int quizId,
    required String apptype,
    Duration webhookDelay = const Duration(seconds: 3),
  }) async {
    // Give webhook time to fire
    await Future.delayed(webhookDelay);

    // Check if module is already unlocked by webhook
    final alreadyUnlocked = await ModuleService.hasModule(
      userId: userId,
      quizId: quizId,
    );

    if (!alreadyUnlocked) {
      // Webhook hasn't fired yet — unlock directly as fallback
      await ModuleService.unlockModule(
        apptype: apptype,
        userId: userId,
        quizId: quizId,
      );
    }
  }
}
