// lib/core/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper around the Supabase client.
/// Initialize once in main.dart via [SupabaseService.initialize].
/// Access the client anywhere via [SupabaseService.client].
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Call once in main.dart before runApp().
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  /// Currently authenticated Supabase user. Null if not signed in.
  static User? get currentUser => client.auth.currentUser;

  /// Current user's UUID as a String. Null if not signed in.
  static String? get currentUserId => client.auth.currentUser?.id;

  /// True if a user is currently signed in.
  static bool get isSignedIn => client.auth.currentUser != null;

  /// Stream of auth state changes for use in Riverpod/StreamProvider.
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
