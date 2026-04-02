// lib/core/services/module_service.dart

import 'supabase_service.dart';

/// Handles all module unlock and access operations.
/// Errors are thrown — callers are responsible for try/catch.
class ModuleService {
  ModuleService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the full module list for a user, including purchase status.
  /// Returns quiz metadata joined with whether the user has unlocked each module.
  /// Filtered by [appId] — each Flutter flavor passes its own app_id constant.
  /// Calls: get_modules(new_user_id, iapp_id)
  static Future<List<Map<String, dynamic>>> fetchModules({
    required String userId,
    required int appId,
  }) async {
    final response = await _client.rpc(
      'get_modules',
      params: {
        'new_user_id': userId,
        'iapp_id': appId,
      },
    );

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Check whether a user has a module record for the given [quizId].
  /// Calls: get_modules_count(iuser_id, iquiz_id)
  /// Returns true if count > 0.
  static Future<bool> hasModule({
    required String userId,
    required int quizId,
  }) async {
    final response = await _client.rpc(
      'get_modules_count',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );

    final list = response as List;
    if (list.isEmpty) return false;
    final count = (list.first as Map<String, dynamic>)['record_count'] as int;
    return count > 0;
  }

  /// Check whether a user has purchased a product by [appSlug].
  /// Used to verify purchase status before granting module access.
  /// Calls: has_user_purchased_product(puser_id, papp_slug)
  static Future<bool> hasPurchasedProduct({
    required String userId,
    required String appSlug,
  }) async {
    final response = await _client.rpc(
      'has_user_purchased_product',
      params: {
        'puser_id': userId,
        'papp_slug': appSlug,
      },
    );

    return response as bool? ?? false;
  }

  // ---------------------------------------------------------------------------
  // Unlock
  // ---------------------------------------------------------------------------

  /// Unlock a module for a user after a successful purchase.
  /// Clears any existing records for this quiz then inserts fresh
  /// user_answers, user_summary, and modules rows in one atomic call.
  /// Calls: insertnewmodule(iapptype, iuser_id, iquiz_id)
  static Future<void> unlockModule({
    required String apptype,
    required String userId,
    required int quizId,
  }) async {
    await _client.rpc(
      'insertnewmodule',
      params: {
        'iapptype': apptype,
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Remove
  // ---------------------------------------------------------------------------

  /// Remove all records for a user/quiz combo from modules,
  /// user_answers, and user_summary.
  /// Used when resetting or re-purchasing a module.
  /// Calls: remove_user_quiz_records(iuser_id, iquiz_id)
  static Future<void> removeModule({
    required String userId,
    required int quizId,
  }) async {
    await _client.rpc(
      'remove_user_quiz_records',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );
  }
}
