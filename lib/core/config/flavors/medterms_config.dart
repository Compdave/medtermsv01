// lib/core/config/flavors/medterms_config.dart

import 'package:flutter/material.dart';
import 'package:medtermsv01/core/config/app_config.dart';

/// AppConfig for Medical Terminology Vol 1 (app_id = 1).
const medtermsConfig = AppConfig(
  appName: 'Medical Terminology Vol 1',
  appSubtitle: 'Medical Terminology Q&A',
  appId: 1,
  apptypePrefix: 'mt01_reichrev',
  primaryColor: Color(0xFF1A6B5A),
  accentColor: Color.fromARGB(255, 22, 71, 27),
  gradientTop: Color(0xFF1A6B5A), // deep forest green
  gradientBottom: Color(0xFFD4EFE8), // light mint
  iconAssetPath: 'assets/icons/app_launcher_icon.png',
  appStoreUrl:
      'https://apps.apple.com/us/app/medical-terminology-app/id6752959809',
  playStoreUrl:
      'https://play.google.com/store/apps/details?id=com.reichardreviews.medterms',
  faqUrl: 'https://reichardreviews.com/faq',
  revenueCatAppleApiKey: 'appl_TjYTNqPGuAouWCumGZtIQzqXhem',
  revenueCatGoogleApiKey: 'goog_NrxoyAnTCUEtfRywqFYUXVJeQwG',
);
