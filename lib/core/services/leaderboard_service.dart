// lib/core/services/leaderboard_service.dart

import 'package:medtermsv01/models/models.dart';
import 'supabase_service.dart';

/// Handles leaderboard read and write operations.
/// Errors are thrown — callers are responsible for try/catch.
class LeaderboardService {
  LeaderboardService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the top leaderboard entries from the leaders view.
  /// [limit] defaults to 20. Results are ordered by the view definition.
  /// [apptype] filters results to only show entries for the current app flavor.
  static Future<List<LeadersModel>> fetchLeaders({
    int limit = 20,
    required String apptype,
  }) async {
    final response = await _client
        .from('leaders')
        .select()
        .eq('apptype', apptype)
        .limit(limit);

    return (response as List)
        .map((e) => LeadersModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Submit Score
  // ---------------------------------------------------------------------------

  /// Submit or update a leaderboard entry for a user.
  /// If the user already has an entry it is updated in place.
  /// If not, a new row is inserted.
  /// [secPerItem] is the average seconds per question (lower = better).
  /// [apptype] identifies which app flavor this score belongs to.
  /// Calls: update_or_insert_leaderboard(new_display_name, new_sec_per_item,
  ///           new_no_of_items, new_no_correct, new_user_id, new_apptype)
  static Future<void> submitScore({
    required String displayName,
    required double secPerItem,
    required int noOfItems,
    required int noCorrect,
    required String userId,
    required String apptype,
  }) async {
    await _client.rpc(
      'update_or_insert_leaderboard',
      params: {
        'new_display_name': displayName,
        'new_sec_per_item': secPerItem,
        'new_no_of_items': noOfItems,
        'new_no_correct': noCorrect,
        'new_user_id': userId,
        'new_apptype': apptype,
      },
    );
  }
}
