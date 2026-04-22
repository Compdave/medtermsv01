// lib/features/quiz/screens/quest_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtermsv01/core/providers/providers.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

class QuestPage extends ConsumerStatefulWidget {
  final int quizId;
  final String userId;
  final String apptype;

  const QuestPage({
    super.key,
    required this.quizId,
    required this.userId,
    required this.apptype,
  });

  @override
  ConsumerState<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends ConsumerState<QuestPage> {
  late final _sessionParams = (
    quizId: widget.quizId,
    userId: widget.userId,
    apptype: widget.apptype,
  );

  final _questJumpController = TextEditingController();
//  bool _showRationale = false;

  // ---------------------------------------------------------------------------
  // Answer Button Color Logic
  // ---------------------------------------------------------------------------

  _AnswerState _getAnswerState(
    QuizSessionState session,
    int answerIndex, // 1-based
  ) {
    final selected = session.selectedAnswer;
    final question = session.currentQuestion;
    final submitted = question?.isComplete ?? false;
    final corrAns = question?.corrAns ?? 0;

    if (!submitted) {
      // Pre-submission
      if (selected == answerIndex) return _AnswerState.selectedPending;
      return _AnswerState.neutral;
    }

    // Post-submission
    if (answerIndex == corrAns) {
      return _AnswerState.correct; // Always highlight correct in green
    }
    if (answerIndex == question?.userAnswer && answerIndex != corrAns) {
      return _AnswerState.wrongSelected; // User picked this and it was wrong
    }
    return _AnswerState.neutral;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _questJumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider(_sessionParams));
    final notifier = ref.read(quizSessionProvider(_sessionParams).notifier);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Fire and forget — never block back navigation
        if (didPop) notifier.saveSessionAndExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _buildAppBar(session, notifier),
        body: session.isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : session.error != null
                ? _buildError(session.error!)
                : _buildBody(session, notifier),
      ),
    );
  }

  AppBar _buildAppBar(QuizSessionState session, QuizSessionNotifier notifier) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () {
          // Fire save then navigate — don't await to avoid UI hang
          notifier.saveSessionAndExit();
          context.pop();
        },
      ),
      title: const Text(
        'Q&A',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        // Tappable mode chip — opens mode picker
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showModePicker(session, notifier),
            child: _ModeMiniChip(mode: session.mode),
          ),
        ),
      ],
    );
  }

  void _showModePicker(QuizSessionState session, QuizSessionNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2B24),
                ),
              ),
              const SizedBox(height: 12),
              _modeOption(
                context: context,
                label: 'All Questions',
                subtitle: 'Show all ${session.questions.length} questions',
                icon: Icons.list_rounded,
                isSelected: session.mode == QuizMode.allQuestions,
                onTap: () {
                  notifier.switchMode(QuizMode.allQuestions);
                  Navigator.pop(context);
//                  setState(() => _showRationale = false);
                },
              ),
              _modeOption(
                context: context,
                label: 'First Chance',
                subtitle: 'Unanswered questions only',
                icon: Icons.looks_one_rounded,
                isSelected: session.mode == QuizMode.firstChance,
                onTap: () {
                  notifier.switchMode(QuizMode.firstChance);
                  Navigator.pop(context);
//                  setState(() => _showRationale = false);
                },
              ),
              _modeOption(
                context: context,
                label: 'Second Chance',
                subtitle: 'Wrong or incomplete questions',
                icon: Icons.replay_rounded,
                isSelected: session.mode == QuizMode.secondChance,
                onTap: () {
                  notifier.switchMode(QuizMode.secondChance);
                  Navigator.pop(context);
//                  setState(() => _showRationale = false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOption({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isSelected ? AppColors.primary : Colors.grey.shade500,
            size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : const Color(0xFF0D2B24),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFF0D2B24).withValues(alpha: 0.5),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error loading quiz: $error',
            style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Body
  // ---------------------------------------------------------------------------

  Widget _buildBody(QuizSessionState session, QuizSessionNotifier notifier) {
    final question = session.currentQuestion;
    if (question == null) {
      return const Center(child: Text('No questions in this queue.'));
    }

    final submitted = question.isComplete ?? false;
    final hasRationale =
        question.rationale != null && question.rationale!.trim().isNotEmpty;

    return Column(
      children: [
        // Progress bar
        _buildProgressBar(session),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Counter
                _buildCounter(session),
                const SizedBox(height: 12),

                // Question card
                _buildQuestionCard(question.questText ?? ''),
                const SizedBox(height: 20),

                // Answer buttons
                _buildAnswerButton(
                    session, notifier, 1, question.answer1 ?? ''),
                const SizedBox(height: 10),
                _buildAnswerButton(
                    session, notifier, 2, question.answer2 ?? ''),
                const SizedBox(height: 10),
                _buildAnswerButton(
                    session, notifier, 3, question.answer3 ?? ''),
                const SizedBox(height: 10),
                _buildAnswerButton(
                    session, notifier, 4, question.answer4 ?? ''),
                const SizedBox(height: 16),

                // Result feedback
                if (submitted) _buildResultFeedback(session, question),
                if (submitted) const SizedBox(height: 10),

                // Rationale
                if (submitted && hasRationale)
                  _buildRationaleSection(question.rationale!),
                if (submitted && hasRationale) const SizedBox(height: 10),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Bottom controls — always visible
        _buildBottomControls(session, notifier, submitted),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Progress Bar
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar(QuizSessionState session) {
    final total = session.totalInQueue;
    final progress = total > 0 ? session.displayPosition / total : 0.0;

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white.withValues(alpha: 0.3),
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
      minHeight: 4,
    );
  }

  // ---------------------------------------------------------------------------
  // Counter
  // ---------------------------------------------------------------------------

  Widget _buildCounter(QuizSessionState session) {
    return Text(
      'Medical Terminology  •  Question ${session.displayPosition} of ${session.totalInQueue}',
      style: TextStyle(
        fontSize: 13,
        color: const Color(0xFF1A6B5A).withValues(alpha: 0.8),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ---------------------------------------------------------------------------
  // Question Card
  // ---------------------------------------------------------------------------

  Widget _buildQuestionCard(String questionText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        questionText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D2B24),
          height: 1.45,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Answer Button
  // ---------------------------------------------------------------------------

  Widget _buildAnswerButton(
    QuizSessionState session,
    QuizSessionNotifier notifier,
    int index,
    String text,
  ) {
    final answerState = _getAnswerState(session, index);
    final submitted = session.currentQuestion?.isComplete ?? false;

    // Colors per state
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color numberBgColor;
    Widget? trailingIcon;

    switch (answerState) {
      case _AnswerState.neutral:
        bgColor = Colors.white;
        borderColor = const Color(0xFFB2D8CE);
        textColor = const Color(0xFF0D2B24);
        numberBgColor = const Color(0xFFE8F5F1);
        trailingIcon = null;

      case _AnswerState.selectedPending:
        bgColor = const Color(0xFFE0F4EE);
        borderColor = AppColors.primary;
        textColor = AppColors.primary;
        numberBgColor = AppColors.primary;
        trailingIcon = null;

      case _AnswerState.correct:
        bgColor = const Color(0xFFE8F8EE);
        borderColor = const Color(0xFF2E9E5A);
        textColor = const Color(0xFF1A5C35);
        numberBgColor = const Color(0xFF2E9E5A);
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF2E9E5A), size: 26);

      case _AnswerState.wrongSelected:
        bgColor = const Color(0xFFFFF0F0);
        borderColor = const Color(0xFFD94040);
        textColor = const Color(0xFF8B2020);
        numberBgColor = const Color(0xFFD94040);
        trailingIcon = const Icon(Icons.cancel_rounded,
            color: Color(0xFFD94040), size: 26);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: submitted ? null : () => notifier.selectAnswer(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Number circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: answerState == _AnswerState.selectedPending
                        ? numberBgColor
                        : numberBgColor,
                    border: answerState == _AnswerState.neutral
                        ? Border.all(color: const Color(0xFFB2D8CE), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: answerState == _AnswerState.neutral
                            ? const Color(0xFF0D2B24)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Answer text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),

                // Trailing icon (shown post-submit)
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  trailingIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result Feedback
  // ---------------------------------------------------------------------------

  Widget _buildResultFeedback(QuizSessionState session, dynamic question) {
    final isCorrect = question.isCorrect as bool? ?? false;
    final corrAns = question.corrAns as int? ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFE8F8EE) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFF2E9E5A) : const Color(0xFFD94040),
          width: 1.5,
        ),
      ),
      child: Text(
        isCorrect ? 'Correct!' : 'Incorrect.  The correct answer is $corrAns.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isCorrect ? const Color(0xFF1A5C35) : const Color(0xFFD94040),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rationale
  // ---------------------------------------------------------------------------

  Widget _buildRationaleSection(String rationale) {
    return GestureDetector(
      onTap: () => _showRationaleModal(rationale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rationale',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showRationaleModal(String rationale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Rationale',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2B24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Rationale text — scrollable for long text
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Text(
                  rationale,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0D2B24),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Controls
  // ---------------------------------------------------------------------------

  Widget _buildBottomControls(
    QuizSessionState session,
    QuizSessionNotifier notifier,
    bool submitted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation bar
          _buildNavigationBar(session, notifier),
          const SizedBox(height: 10),

          // Clear + Submit
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitted || session.selectedAnswer == null
                      ? null
                      : () {
                          notifier.selectAnswer(0);
//                          setState(() => _showRationale = false);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: submitted || session.selectedAnswer == null
                          ? Colors.grey.shade300
                          : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Clear',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: session.selectedAnswer == null ||
                          session.selectedAnswer == 0 ||
                          submitted ||
                          session.isSubmitting
                      ? null
                      : () async {
//                          setState(() => _showRationale = false);
                          await notifier.submitAnswer();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  child: session.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Submit',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation Bar
  // ---------------------------------------------------------------------------

  Widget _buildNavigationBar(
      QuizSessionState session, QuizSessionNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // |< First
          _navIconButton(
            icon: Icons.first_page_rounded,
            onTap: session.isFirstQuestion ? null : notifier.goToFirst,
          ),
          // < Previous
          _navIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: session.isFirstQuestion ? null : notifier.goToPrevious,
          ),

          // Quest # text field
          Expanded(
            child: _buildQuestJumpField(session, notifier),
          ),

          // > Next
          _navIconButton(
            icon: Icons.chevron_right_rounded,
            onTap: session.isLastQuestion ? null : notifier.goToNext,
          ),
          // >| Last
          _navIconButton(
            icon: Icons.last_page_rounded,
            onTap: session.isLastQuestion ? null : notifier.goToLast,
          ),
        ],
      ),
    );
  }

  Widget _navIconButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      color: onTap == null ? Colors.grey.shade400 : AppColors.primary,
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildQuestJumpField(
      QuizSessionState session, QuizSessionNotifier notifier) {
    return TextField(
      controller: _questJumpController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0D2B24),
      ),
      decoration: InputDecoration(
        hintText: 'Quest #',
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
      onSubmitted: (value) {
        final n = int.tryParse(value);
        if (n != null && n >= 1 && n <= session.totalInQueue) {
          notifier.goToPosition(n);
//          setState(() => _showRationale = false);
        }
        _questJumpController.clear();
      },
    );
  }
}

// =============================================================================
// Answer State Enum
// =============================================================================

enum _AnswerState {
  neutral,
  selectedPending,
  correct,
  wrongSelected,
}

// =============================================================================
// Mode Mini Chip (AppBar)
// =============================================================================

class _ModeMiniChip extends StatelessWidget {
  final QuizMode mode;

  const _ModeMiniChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (mode) {
      case QuizMode.allQuestions:
        label = 'All';
      case QuizMode.firstChance:
        label = '1st';
      case QuizMode.secondChance:
        label = '2nd';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
