// lib/main.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/config/app_secrets.dart';
import 'package:medtermsv01/core/config/flavors/medterms_config.dart';
import 'package:medtermsv01/core/services/revenuecat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// ── Global Supabase client shortcut ──────────────────────────────────────────
final supabase = Supabase.instance.client;

// ── Shared Preferences instance ──────────────────────────────────────────────
late final SharedPreferences sharedPrefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Set flavor config
  AppConfig.instance = medtermsConfig;

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // 3. Initialize RevenueCat (mobile only — web uses LemonSqueezy)
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await RevenueCatService.initialize(
      userId: userId ?? 'anonymous',
    );
    // If already signed in, identify user in RC
    if (userId != null) {
      await RevenueCatService.logIn(userId);
    }
  }

  // 4. Initialize Shared Preferences
  sharedPrefs = await SharedPreferences.getInstance();

  // 5. Launch App
  runApp(const ProviderScope(child: App()));
}
