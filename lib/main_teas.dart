// lib/main_teas.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/config/flavors/teas_config.dart';
import 'package:medtermsv01/core/services/revenuecat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtermsv01/core/config/app_secrets.dart';
import 'app.dart';

late final SharedPreferences sharedPrefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.instance = teasConfig; // ← only line that differs from main.dart

  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
    authOptions:
        const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

/*
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await RevenueCatService.initialize(userId: userId ?? 'anonymous');
    if (userId != null) await RevenueCatService.logIn(userId);
  }
  */

  sharedPrefs = await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: App()));
}
