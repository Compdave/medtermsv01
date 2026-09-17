// lib/core/services/quiz_service.dart

import 'package:medtermsv01/models/models.dart';
import 'supabase_service.dart';

/// Handles all quiz-related data operations.
/// Errors are thrown — callers are responsible for try/catch.
class QuizService {
  QuizService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Quiz List
  // ---------------------------------------------------------------------------

  /// Fetch all quizzes for the given [appId].
  /// Returns both free sample quizzes and paid full quizzes for this app flavor.
  /// [appId] maps to the app_id column in the quiz table — each Flutter flavor
  /// has its own integer id (e.g. 1 = MedTerms, 2 = MedGeneral).
  static Future<List<QuizModel>> fetchQuizList(int appId) async {
    final response = await _client
        .from('quiz')
        .select()
        .eq('app_id', appId)
        .order('quiz_id');

    return (response as List)
        .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single quiz by [quizId].
  static Future<QuizModel> fetchQuiz(int quizId) async {
    final response =
        await _client.from('quiz').select().eq('quiz_id', quizId).single();

    return QuizModel.fromJson(response);
  }

  // ---------------------------------------------------------------------------
  // Quiz Session — Question List
  // ---------------------------------------------------------------------------

  /// Fetch the full question list for a user's quiz session.
  /// Returns all rows from the quiz_user view for [userId] + [quizId].
  /// This is the primary loader for the quiz screen.
  /// Calls: getquizuserviewlist(iuser_id, iquiz_id)
  static Future<List<QuizUserModel>> fetchQuizUserViewList({
    required String userId,
    required int quizId,
  }) async {
    final response = await _client.rpc(
      'getquizuserviewlist',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );

    return (response as List)
        .map((e) => QuizUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single question row from the quiz_user view.
  /// Calls: getquizuserview(iuser_id, iquiz_id, iquest_no)
  static Future<QuizUserModel?> fetchQuizUserView({
    required String userId,
    required int quizId,
    required int questNo,
  }) async {
    final response = await _client.rpc(
      'getquizuserview',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
        'iquest_no': questNo,
      },
    );

    final list = response as List;
    if (list.isEmpty) return null;
    return QuizUserModel.fromJson(list.first as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Quiz Session — Progress
  // ---------------------------------------------------------------------------

  /// Returns the count of answered questions and the last completed quest_no.
  /// Used to resume a session where the user left off.
  /// Calls: getlastusedquestion(iquiz_id, tuser_id)
  /// Returns a map with keys: 'no_done' (int), 'lastcompleted' (int)
  static Future<({int noDone, int lastCompleted})> fetchLastUsedQuestion({
    required int quizId,
    required String userId,
  }) async {
    final response = await _client.rpc(
      'getlastusedquestion',
      params: {
        'iquiz_id': quizId,
        'tuser_id': userId,
      },
    );

    final list = response as List;
    if (list.isEmpty) return (noDone: 0, lastCompleted: 0);

    final row = list.first as Map<String, dynamic>;
    return (
      noDone: (row['no_done'] as int?) ?? 0,
      lastCompleted: (row['lastcompleted'] as int?) ?? 0,
    );
  }

  /// Returns a list of quest_no values the user has not yet answered.
  /// Used for First Chance mode (user_answer = 0).
  /// Calls: get_first_chance(iquiz_id, iuser_id)
  static Future<List<int>> fetchFirstChanceQuestions({
    required int quizId,
    required String userId,
  }) async {
    final response = await _client.rpc(
      'get_first_chance',
      params: {
        'iquiz_id': quizId,
        'iuser_id': userId,
      },
    );

    return (response as List)
        .map((e) => (e as Map<String, dynamic>)['quest_no'] as int)
        .toList();
  }

  /// Returns a list of quest_no values the user got wrong or left incomplete.
  /// Used for Second Chance mode (is_correct = false OR is_complete = false).
  /// Calls: get_second_chance(iquiz_id, iuser_id)
  static Future<List<int>> fetchSecondChanceQuestions({
    required int quizId,
    required String userId,
  }) async {
    final response = await _client.rpc(
      'get_second_chance',
      params: {
        'iquiz_id': quizId,
        'iuser_id': userId,
      },
    );

    return (response as List)
        .map((e) => (e as Map<String, dynamic>)['quest_no'] as int)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Answer Submission
  // ---------------------------------------------------------------------------

  /// Check if a user's answer is correct.
  /// Done client-side — no DB round trip needed for simple equality.
  /// [userAnswer] and [corrAns] are 1-based answer indices.
  static bool checkAnswer({
    required int userAnswer,
    required int corrAns,
  }) {
    return userAnswer == corrAns;
  }

  /// Update a single user_answer record after the user submits an answer.
  /// Calls: update_user_answer(iuser_id, iquiz_id, iquest_no,
  ///          iis_complete, iis_correct, iis_expired, iuser_answer)
  static Future<void> updateUserAnswer({
    required String userId,
    required int quizId,
    required int questNo,
    required bool isComplete,
    required bool isCorrect,
    required bool isExpired,
    required int userAnswer,
  }) async {
    await _client.rpc(
      'update_user_answer',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
        'iquest_no': questNo,
        'iis_complete': isComplete,
        'iis_correct': isCorrect,
        'iis_expired': isExpired,
        'iuser_answer': userAnswer,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Quiz Reset / Restart
  // ---------------------------------------------------------------------------

  /// Reset all answer records for a user's quiz back to unanswered state.
  /// Called when the user chooses to restart a quiz from scratch.
  /// Calls: update_all_user_answers(iuser_id, iquiz_id)
  static Future<void> resetAllUserAnswers({
    required String userId,
    required int quizId,
  }) async {
    await _client.rpc(
      'update_all_user_answers',
      params: {
        'iuser_id': userId,
        'iquiz_id': quizId,
      },
    );
  }

  /// Fully remove all quiz records (user_answers, user_summary, modules)
  /// for a user/quiz combo. Used when re-purchasing or resetting a module.
  /// Calls: remove_user_quiz_records(iuser_id, iquiz_id)
  static Future<void> removeUserQuizRecords({
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
