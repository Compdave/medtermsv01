// lib/core/config/app_config.dart

import 'package:flutter/material.dart';

/// Base configuration class for each Flutter flavor.
/// Each app variant (MedTerms, MedGeneral, etc.) provides its own
/// instance of AppConfig, injected at startup in main_<flavor>.dart.
class AppConfig {
  /// Display name shown in the app UI and store listing.
  final String appName;

  /// Short subtitle shown on the login screen.
  final String appSubtitle;

  /// Unique integer identifying this app in the quiz.app_id column.
  /// Used to filter quizzes and modules to only this app's content.
  final int appId;

  /// The apptype prefix used when unlocking modules via insertnewmodule.
  /// Also matches the LemonSqueezy app_slug for purchase verification.
  /// Example: 'mt01_reichrev' (sample = mt01_reichrev_01s, full = mt01_reichrev_02)
  final String apptypePrefix;

  /// Primary brand color for this flavor.
  final Color primaryColor;

  /// Accent/action color for this flavor.
  final Color accentColor;

  /// Path to this flavor's launcher icon asset.
  final String iconAssetPath;

  /// App Store URL for this flavor (iOS).
  final String appStoreUrl;

  /// Play Store URL for this flavor (Android).
  final String playStoreUrl;

  /// FAQ web page URL for this flavor.
  final String faqUrl;

  const AppConfig({
    required this.appName,
    required this.appSubtitle,
    required this.appId,
    required this.apptypePrefix,
    required this.primaryColor,
    required this.accentColor,
    required this.iconAssetPath,
    required this.appStoreUrl,
    required this.playStoreUrl,
    required this.faqUrl,
  });

  /// Global singleton — set once at app startup in main_<flavor>.dart.
  static late AppConfig instance;
}
