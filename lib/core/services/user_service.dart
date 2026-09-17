// lib/core/services/user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtermsv01/models/models.dart';
import 'supabase_service.dart';

/// Handles all operations against public.users.
/// public.users is populated automatically via a trigger on auth.users.
/// Errors are thrown — callers are responsible for try/catch.
class UserService {
  UserService._();

  static final _client = SupabaseService.client;
  static const _table = 'users';

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the public.users row for the given [userId].
  /// Throws [PostgrestException] if the user is not found.
  static Future<UserModel> fetchUser(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Update the display name for the given [userId].
  static Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    await _client
        .from(_table)
        .update({'display_name': displayName.trim()})
        .eq('user_id', userId);
  }

  /// Update the last visited question number for the given [userId].
  /// Used to resume a quiz session where the user left off.
  static Future<void> updateLastQuestion({
    required String userId,
    required int questNo,
  }) async {
    await _client
        .from(_table)
        .update({'lastquestion': questNo})
        .eq('user_id', userId);
  }

  /// Update the premium status for the given [userId].
  /// Typically called after a successful purchase webhook confirms the unlock.
  static Future<void> updateIsPremium({
    required String userId,
    required bool isPremium,
  }) async {
    await _client
        .from(_table)
        .update({'is_premium': isPremium})
        .eq('user_id', userId);
  }

  /// Update email in public.users to stay in sync after an auth email change.
  /// Note: the auth email change itself is handled by AuthService.updateEmail().
  /// Call this after the user confirms the new email to keep public.users in sync.
  static Future<void> updateEmail({
    required String userId,
    required String newEmail,
  }) async {
    await _client
        .from(_table)
        .update({'email': newEmail.trim()})
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // Delete (via Postgres RPC)
  // ---------------------------------------------------------------------------

  /// Full deletion of all user data across all tables including auth.users.
  /// Calls the delete_user_data(p_email) Postgres function via RPC.
  /// SECURITY DEFINER on the DB function allows it to cascade into auth.users.
  /// Throws [PostgrestException] on failure.
  static Future<void> deleteUserData({
    required String email,
  }) async {
    await _client.rpc(
      'delete_user_data',
      params: {'p_email': email.trim()},
    );
  }
}
