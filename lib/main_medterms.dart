// lib/main_medterms.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/config/flavors/medterms_config.dart';
import 'package:medtermsv01/core/services/supabase_service.dart';
import 'package:medtermsv01/core/services/revenuecat_service.dart';
import 'package:medtermsv01/core/config/app_secrets.dart';
import 'package:medtermsv01/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Set flavor config
  AppConfig.instance = medtermsConfig;

  // 2. Initialize Supabase
  await SupabaseService.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );

  // 3. Initialize RevenueCat (mobile only)
  if (Platform.isIOS || Platform.isAndroid) {
    final userId = SupabaseService.currentUserId;
    await RevenueCatService.initialize(
      userId: userId ?? 'anonymous',
    );
  }

  runApp(const App());
}
