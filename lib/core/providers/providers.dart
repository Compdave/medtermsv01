// lib/core/providers/providers.dart

// ignore_for_file: unused_field

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtermsv01/models/models.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/quiz_service.dart';
import 'package:medtermsv01/core/services/module_service.dart';
import 'package:medtermsv01/core/services/user_service.dart';
import 'package:medtermsv01/core/services/user_summary_service.dart';
import 'package:medtermsv01/core/services/leaderboard_service.dart';
import 'package:medtermsv01/core/services/version_service.dart';

// =============================================================================
// AUTH PROVIDERS
// =============================================================================

/// Streams all auth state changes (sign in, sign out, token refresh).
/// Use this as the root of any auth-gated navigation logic.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.authStateChanges;
});

/// Derives the current user's UUID string from the auth stream.
/// Null when signed out.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user.id).value;
});

/// Fetches the public.users row for the currently signed-in user.
/// Automatically re-fetches when the userId changes.
final userProvider = FutureProvider<UserModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return UserService.fetchUser(userId);
});

// =============================================================================
// MODULE PROVIDERS
// =============================================================================

/// Fetches the full module list for the current user including purchase status.
/// Returns a list of raw maps as returned by get_modules() —
/// each map contains: quiz_id, quiz_name, quiz_count, apptype,
/// sample (bool), purchased (bool), price.
/// Filtered by AppConfig.instance.appId — flavor-aware.
final moduleListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ModuleService.fetchModules(
    userId: userId,
    appId: AppConfig.instance.appId,
  );
});

// =============================================================================
// QUIZ PROVIDERS
// =============================================================================

/// Fetches a single QuizModel by quizId.
final quizProvider =
    FutureProvider.family<QuizModel?, int>((ref, quizId) async {
  return QuizService.fetchQuiz(quizId);
});

/// Fetches all quizzes for the current app flavor.
final quizListProvider = FutureProvider<List<QuizModel>>((ref) async {
  return QuizService.fetchQuizList(AppConfig.instance.appId);
});

/// Fetches the user summary for a given quizId.
/// Re-fetches when invalidated after answer submission.
final userSummaryProvider =
    FutureProvider.family<UserSummaryModel?, int>((ref, quizId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return UserSummaryService.fetchUserSummary(
    userId: userId,
    quizId: quizId,
  );
});

// =============================================================================
// QUIZ SESSION
// =============================================================================

/// The mode the user has selected for the current quiz session.
enum QuizMode { allQuestions, firstChance, secondChance }

/// Immutable state for the active quiz session.
class QuizSessionState {
  final List<QuizUserModel> questions; // Full question list loaded upfront
  final List<int> queue; // Ordered list of quest_no for this mode
  final int currentIndex; // Index into queue (not quest_no)
  final QuizMode mode;
  final bool isLoading;
  final bool isSubmitting;
  final int? selectedAnswer; // 1-4, null if not yet selected
  final bool? lastAnswerCorrect; // Result of last submission, null before first
  final double accumulatedSeconds; // Session timer — saved to DB on exit
  final String? error;

  const QuizSessionState({
    this.questions = const [],
    this.queue = const [],
    this.currentIndex = 0,
    this.mode = QuizMode.allQuestions,
    this.isLoading = true,
    this.isSubmitting = false,
    this.selectedAnswer,
    this.lastAnswerCorrect,
    this.accumulatedSeconds = 0,
    this.error,
  });

  /// The current question being displayed, derived from queue + currentIndex.
  QuizUserModel? get currentQuestion {
    if (queue.isEmpty || questions.isEmpty) return null;
    final questNo = queue[currentIndex];
    try {
      return questions.firstWhere((q) => q.questNo == questNo);
    } catch (_) {
      return null;
    }
  }

  /// Total number of questions in the current queue.
  int get totalInQueue => queue.length;

  /// 1-based position for display ("Question 3 of 47").
  int get displayPosition => currentIndex + 1;

  bool get isFirstQuestion => currentIndex == 0;
  bool get isLastQuestion => currentIndex == queue.length - 1;
  bool get hasQuestions => queue.isNotEmpty;

  QuizSessionState copyWith({
    List<QuizUserModel>? questions,
    List<int>? queue,
    int? currentIndex,
    QuizMode? mode,
    bool? isLoading,
    bool? isSubmitting,
    int? selectedAnswer,
    bool? lastAnswerCorrect,
    double? accumulatedSeconds,
    String? error,
    bool clearSelectedAnswer = false,
    bool clearLastAnswerCorrect = false,
    bool clearError = false,
  }) {
    return QuizSessionState(
      questions: questions ?? this.questions,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedAnswer:
          clearSelectedAnswer ? null : selectedAnswer ?? this.selectedAnswer,
      lastAnswerCorrect: clearLastAnswerCorrect
          ? null
          : lastAnswerCorrect ?? this.lastAnswerCorrect,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Manages the full quiz session lifecycle for a given quizId.
/// Handles question loading, mode switching, navigation, answer submission,
/// and timer accumulation.
class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  final String _userId;
  final int _quizId;
  final String _apptype;
  Timer? _timer;

  QuizSessionNotifier({
    required String userId,
    required int quizId,
    required String apptype,
  })  : _userId = userId,
        _quizId = quizId,
        _apptype = apptype,
        super(const QuizSessionState()) {
    _init();
  }

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    try {
      final questions = await QuizService.fetchQuizUserViewList(
        userId: _userId,
        quizId: _quizId,
      );
      final queue = _buildQueue(questions, QuizMode.allQuestions);
      state = state.copyWith(
        questions: questions,
        queue: queue,
        currentIndex: 0,
        isLoading: false,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Queue Building
  // ---------------------------------------------------------------------------

  List<int> _buildQueue(List<QuizUserModel> questions, QuizMode mode) {
    switch (mode) {
      case QuizMode.allQuestions:
        return questions
            .map((q) => q.questNo ?? 0)
            .where((n) => n > 0)
            .toList();
      case QuizMode.firstChance:
        return questions
            .where((q) => (q.userAnswer ?? 0) == 0)
            .map((q) => q.questNo ?? 0)
            .where((n) => n > 0)
            .toList();
      case QuizMode.secondChance:
        return questions
            .where((q) => q.isCorrect == false || q.isComplete == false)
            .map((q) => q.questNo ?? 0)
            .where((n) => n > 0)
            .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // Mode Switching
  // ---------------------------------------------------------------------------

  /// Switch quiz mode and rebuild the question queue from in-memory data.
  /// Resets navigation to the first question in the new queue.
  void switchMode(QuizMode mode) {
    final queue = _buildQueue(state.questions, mode);
    state = state.copyWith(
      mode: mode,
      queue: queue,
      currentIndex: 0,
      clearSelectedAnswer: true,
      clearLastAnswerCorrect: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void goToFirst() => _navigateTo(0);
  void goToLast() => _navigateTo(state.queue.length - 1);
  void goToNext() => _navigateTo(state.currentIndex + 1);
  void goToPrevious() => _navigateTo(state.currentIndex - 1);

  /// Jump directly to a question by its 1-based position in the queue.
  void goToPosition(int position) => _navigateTo(position - 1);

  void _navigateTo(int index) {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(
      currentIndex: index,
      clearSelectedAnswer: true,
      clearLastAnswerCorrect: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Answer Selection & Submission
  // ---------------------------------------------------------------------------

  /// Record the user's selected answer (1-4) before submission.
  void selectAnswer(int answer) {
    state = state.copyWith(selectedAnswer: answer);
  }

  /// Submit the currently selected answer to the DB.
  /// Updates the local question state and refreshes the in-memory list.
  Future<void> submitAnswer() async {
    final question = state.currentQuestion;
    final selected = state.selectedAnswer;
    if (question == null || selected == null || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final isCorrect = QuizService.checkAnswer(
        userAnswer: selected,
        corrAns: question.corrAns ?? 0,
      );

      await QuizService.updateUserAnswer(
        userId: _userId,
        quizId: _quizId,
        questNo: question.questNo ?? 0,
        isComplete: true,
        isCorrect: isCorrect,
        isExpired: false,
        userAnswer: selected,
      );

      // Update the in-memory question list to reflect the new answer
      final updatedQuestions = state.questions.map((q) {
        if (q.questNo == question.questNo) {
          return QuizUserModel(
            answer1: q.answer1,
            answer2: q.answer2,
            answer3: q.answer3,
            answer4: q.answer4,
            category: q.category,
            corrAns: q.corrAns,
            questNo: q.questNo,
            questText: q.questText,
            quizId: q.quizId,
            isComplete: true,
            isCorrect: isCorrect,
            isExpired: false,
            userAnswer: selected,
            userId: q.userId,
            apptype: q.apptype,
            rationale: q.rationale,
          );
        }
        return q;
      }).toList();

      state = state.copyWith(
        questions: updatedQuestions,
        isSubmitting: false,
        lastAnswerCorrect: isCorrect,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final timerEnabled = prefs.getBool('timer_enabled') ?? true;
    if (!timerEnabled) return; // timer is off — don't track
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        accumulatedSeconds: state.accumulatedSeconds + 1,
      );
    });
  }

  void pauseTimer() => _timer?.cancel();

  void resumeTimer() => _startTimer();

  /// Save accumulated duration to DB and reset the session counter.
  /// Call this on screen exit, app pause, or session end.
  Future<void> saveAndResetTimer() async {
    _timer?.cancel();
    if (state.accumulatedSeconds > 0) {
      final prefs = await SharedPreferences.getInstance();
      final timerEnabled = prefs.getBool('timer_enabled') ?? true;
      if (timerEnabled) {
        try {
          await UserSummaryService.updateDuration(
            userId: _userId,
            quizId: _quizId,
            durationSeconds: state.accumulatedSeconds,
          ).timeout(const Duration(seconds: 5));
        } catch (_) {
          // Non-fatal — timer loss is acceptable on crash/force quit
        }
      }
      state = state.copyWith(accumulatedSeconds: 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Save Session and Exit  (replaces existing saveSessionAndExit)
  // ---------------------------------------------------------------------------

  /// Save duration, update the quiz summary, and submit to leaderboard if eligible.
  /// Use this on intentional exit (back button, session complete).
  /// Runs with a timeout so back navigation never hangs the UI.
  Future<void> saveSessionAndExit({String? displayName}) async {
    try {
      await Future.wait([
        saveAndResetTimer(),
        UserSummaryService.updateQuizSummary(
          quizId: _quizId,
          userId: _userId,
        ).timeout(const Duration(seconds: 5)),
      ]);
    } catch (_) {
      // Non-fatal — always allow navigation even if save fails
    }

    // Submit to leaderboard if user has enough correct answers
    try {
      final summary = await UserSummaryService.fetchUserSummary(
        userId: _userId,
        quizId: _quizId,
      );
      if (summary != null && summary.noCorrect >= 100) {
        final secPerItem = summary.durationSeconds > 0 && summary.noCorrect > 0
            ? summary.durationSeconds / summary.noCorrect
            : 0.0;
        await LeaderboardService.submitScore(
          displayName: displayName ?? _userId,
          secPerItem: secPerItem,
          noOfItems: summary.noCompleted,
          noCorrect: summary.noCorrect,
          userId: _userId,
          apptype: AppConfig.instance.apptypePrefix,
        );
      }
    } catch (_) {
      // Non-fatal — leaderboard failure should never block navigation
    }
  }

// =============================================================================
// LEADERBOARD PROVIDERS  (replaces existing leadersProvider)
// =============================================================================

  /// Fetches the top leaderboard entries filtered by the current app flavor.
  final leadersProvider = FutureProvider<List<LeadersModel>>((ref) async {
    return LeaderboardService.fetchLeaders(
      apptype: AppConfig.instance.apptypePrefix,
    );
  });

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Reset all answers for this quiz and reload the session.
  Future<void> resetQuiz() async {
    _timer?.cancel();
    state = const QuizSessionState();
    try {
      await QuizService.resetAllUserAnswers(
        userId: _userId,
        quizId: _quizId,
      );
      await UserSummaryService.resetDuration(
        userId: _userId,
        quizId: _quizId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }
    await _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Family provider keyed by quizId.
/// Also requires userId and apptype — pass as a record.
final quizSessionProvider = StateNotifierProvider.family<QuizSessionNotifier,
    QuizSessionState, ({int quizId, String userId, String apptype})>(
  (ref, params) => QuizSessionNotifier(
    userId: params.userId,
    quizId: params.quizId,
    apptype: params.apptype,
  ),
);

// =============================================================================
// LEADERBOARD PROVIDERS
// =============================================================================

/// Fetches the top leaderboard entries filtered by the current app flavor.
final leadersProvider = FutureProvider<List<LeadersModel>>((ref) async {
  return LeaderboardService.fetchLeaders(
    apptype: AppConfig.instance.apptypePrefix,
  );
});

// =============================================================================
// VERSION PROVIDER
// =============================================================================

/// Fetches the latest version string from the DB.
final latestVersionProvider = FutureProvider<String?>((ref) async {
  return VersionService.fetchLatestVersion();
});
