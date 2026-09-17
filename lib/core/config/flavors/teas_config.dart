// lib/core/config/flavors/teas_config.dart

import 'package:flutter/material.dart';
import 'package:medtermsv01/core/config/app_config.dart';

/// AppConfig for TEAS Prep (app_id = 2).
const teasConfig = AppConfig(
  appName: 'TEAS Science Q&A 2026',
  appSubtitle: 'ATI TEAS Science Practice Q&A',
  appId: 2,
  apptypePrefix: 'ts02_reichrev',
  primaryColor: Color(0xFF7092BE),
  accentColor: Color(0xFF4A6FA5),
  gradientTop: Color(0xFF3D6491),
  gradientBottom: Color(0xFFD6E4F0),
  iconAssetPath: 'assets/icons/app_launcher_icon_TEAS.png',
  appStoreUrl:
      'https://apps.apple.com/us/app/teas-science-qa-2026/id6762864989',
  playStoreUrl:
      'https://play.google.com/store/apps/details?id=com.reichardreviews.teassci26',
  faqUrl: 'https://reichardreviews.com/faq-teas',
  revenueCatAppleApiKey: 'appl_QoVPqRfjzPsvSxGCVUNAMcOHkqK',
  revenueCatGoogleApiKey: 'goog_WccTLSJxiXZZfrKermONJlHZdqR',
);
