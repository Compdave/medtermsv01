// lib/shared/bottom_sheets/scoring_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

/// Displays quiz stats summary — shown after quiz completion or via Stats button.
/// Pass current [UserSummaryModel] values directly.
class ScoringBottomSheet extends StatelessWidget {
  final int noInQuiz;
  final int noCompleted;
  final int noCorrect;
  final double durationSeconds;

  const ScoringBottomSheet({
    super.key,
    required this.noInQuiz,
    required this.noCompleted,
    required this.noCorrect,
    required this.durationSeconds,
  });

  /// Show this bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int noInQuiz,
    required int noCompleted,
    required int noCorrect,
    required double durationSeconds,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScoringBottomSheet(
        noInQuiz: noInQuiz,
        noCompleted: noCompleted,
        noCorrect: noCorrect,
        durationSeconds: durationSeconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Computed stats
  // ---------------------------------------------------------------------------

  double get _pctCompleted =>
      noInQuiz > 0 ? (noCompleted / noInQuiz) * 100 : 0;

  double get _pctCorrect =>
      noCompleted > 0 ? (noCorrect / noCompleted) * 100 : 0;

  double get _secPerItem =>
      noCorrect > 0 ? durationSeconds / noCorrect : 0;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A6B5A),
            Color(0xFF2E9E7E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Stats',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            _statRow('# of questions', '$noInQuiz'),
            _divider(),
            _statRow('# completed', '$noCompleted'),
            _divider(),
            _statRow('% completed', '${_pctCompleted.toStringAsFixed(1)}%'),
            _divider(),
            _statRow('# correct', '$noCorrect'),
            _divider(),
            _statRow('% correct', '${_pctCorrect.toStringAsFixed(1)}%'),
            _divider(),
            _statRow('Seconds per item', _secPerItem.toStringAsFixed(2)),

            const SizedBox(height: 28),

            // Done button
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.white.withValues(alpha: 0.15),
        height: 1,
      );
}
