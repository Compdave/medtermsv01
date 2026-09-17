// lib/core/services/user_summary_service.dart

import 'package:medtermsv01/models/models.dart';
import 'package:medtermsv01/core/services/supabase_service.dart';

/// Handles all user_summary operations — progress tracking and duration.
/// Errors are thrown — callers are responsible for try/catch.
class UserSummaryService {
  UserSummaryService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the user summary for a given [userId] and [quizId].
  /// Returns null if no summary record exists yet.
  /// Calls: getusersummary(iuser_id, iquiz_id)
  static Future<UserSummaryModel?> fetchUserSummary({
    required String userId,
    required int quizId,
  }) async {
    final response = await _client.rpc(
      'getusersummary',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );

    final list = response as List;
    if (list.isEmpty) return null;
    return UserSummaryModel.fromJson(list.first as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Insert
  // ---------------------------------------------------------------------------

  /// Insert a new user_summary record for a user/quiz combo.
  /// Typically called as part of the module unlock flow,
  /// but available standalone if needed.
  /// Calls: insert_user_summary(p_user_id, p_quiz_id, p_no_in_quiz)
  static Future<void> insertUserSummary({
    required String userId,
    required int quizId,
    required int noInQuiz,
  }) async {
    await _client.rpc(
      'insert_user_summary',
      params: {
        'p_user_id': userId,
        'p_quiz_id': quizId,
        'p_no_in_quiz': noInQuiz,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Update — Progress
  // ---------------------------------------------------------------------------

  /// Recalculate and update all progress counters for a user/quiz.
  /// Counts completed, correct, expired, and present answers from user_answers.
  /// Also updates last_accessed to now().
  /// Call this after each answer submission to keep summary in sync.
  /// Calls: update_quiz_summary(iquiz_id, iuser_id)
  static Future<void> updateQuizSummary({
    required int quizId,
    required String userId,
  }) async {
    await _client.rpc(
      'update_quiz_summary',
      params: {
        'iquiz_id': quizId,
        'iuser_id': userId,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Update — Duration
  // ---------------------------------------------------------------------------

  /// Add [durationSeconds] to the accumulated duration for a user/quiz.
  /// Called periodically during a quiz session to track elapsed time.
  /// The DB function uses duration_seconds = duration_seconds + iduration
  /// so this is always an increment, never an overwrite.
  /// Calls: update_duration(iuser_id, iquiz_id, iduration)
  static Future<void> updateDuration({
    required String userId,
    required int quizId,
    required double durationSeconds,
  }) async {
    await _client.rpc(
      'update_duration',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
        'iduration': durationSeconds,
      },
    );
  }

  /// Reset accumulated duration to zero for a user/quiz.
  /// Called when the user restarts a quiz from scratch.
  /// Calls: reset_duration(iuser_id, iquiz_id)
  static Future<void> resetDuration({
    required String userId,
    required int quizId,
  }) async {
    await _client.rpc(
      'reset_duration',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------------

  /// Fetch computed stats for a user/quiz including percentage completed
  /// and percentage correct. Pass current counts from the summary record.
  /// Returns null if no matching summary row is found.
  /// Calls: get_stats(new_user_id, new_quiz_id, new_no_completed,
  ///           new_no_correct, new_no_in_quiz)
  static Future<Map<String, dynamic>?> fetchStats({
    required String userId,
    required int quizId,
    required int noCompleted,
    required int noCorrect,
    required int noInQuiz,
  }) async {
    final response = await _client.rpc(
      'get_stats',
      params: {
        'new_user_id': userId,
        'new_quiz_id': quizId,
        'new_no_completed': noCompleted,
        'new_no_correct': noCorrect,
        'new_no_in_quiz': noInQuiz,
      },
    );

    final list = response as List;
    if (list.isEmpty) return null;
    return list.first as Map<String, dynamic>;
  }
}
