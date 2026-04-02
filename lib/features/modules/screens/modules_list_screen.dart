// lib/features/modules/screens/modules_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtermsv01/core/providers/providers.dart';
//import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';
import 'package:medtermsv01/shared/bottom_sheets/revenuecat_bottom_sheet.dart';

class ModulesListScreen extends ConsumerWidget {
  const ModulesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleListAsync = ref.watch(moduleListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Module',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: moduleListAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error loading modules: $e')),
        data: (modules) => modules.isEmpty
            ? _buildEmptyState()
            : _buildList(context, ref, modules),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List
  // ---------------------------------------------------------------------------

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> modules,
  ) {
    // Separate sample and paid
    final samples = modules.where((m) => m['sample'] == true).toList();
    final paid = modules.where((m) => m['sample'] != true).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (samples.isNotEmpty) ...[
          _sectionHeader('Free Sample'),
          const SizedBox(height: 8),
          ...samples.map((m) => _ModuleCard(
                module: m,
                onTap: () => _handleModuleTap(context, ref, m),
              )),
          const SizedBox(height: 20),
        ],
        if (paid.isNotEmpty) ...[
          _sectionHeader('Full Modules'),
          const SizedBox(height: 8),
          ...paid.map((m) => _ModuleCard(
                module: m,
                onTap: () => _handleModuleTap(context, ref, m),
              )),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Module tap handler
  // ---------------------------------------------------------------------------

  void _handleModuleTap(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> module,
  ) {
    final purchased = module['purchased'] as bool? ?? false;
    final sample = module['sample'] as bool? ?? false;
    final quizId = module['quiz_id'] as int?;
    final userId = ref.read(currentUserIdProvider);

    if (purchased || sample) {
      // Unlocked — go straight to quiz
      if (quizId != null && userId != null) {
        context.go('/quiz/$quizId?apptype=${module["apptype"] ?? ""}');
      }
    } else {
      // Locked — show purchase dialog
      _showPurchaseDialog(context, module);
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase dialog
  // ---------------------------------------------------------------------------

  void _showPurchaseDialog(
    BuildContext context,
    Map<String, dynamic> module,
  ) {
    final quizName = module['quiz_name'] as String? ?? 'This Module';
    final quizCount = module['quiz_count'] as int? ?? 0;
    final apptype = module['apptype'] as String? ?? '';
    final quizId = module['quiz_id'] as int? ?? 0;

    RevenuecatBottomSheet.show(
      context,
      moduleName: quizName,
      quizCount: quizCount,
      apptype: apptype,
      quizId: quizId,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No modules available.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D2B24).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Module Card
// =============================================================================

class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final quizName = module['quiz_name'] as String? ?? 'Module';
    final quizCount = module['quiz_count'] as int? ?? 0;
    final sample = module['sample'] as bool? ?? false;
    final purchased = module['purchased'] as bool? ?? false;
    final price = module['price'] as String? ?? '';
    final unlocked = purchased || sample;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: unlocked ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFFB2D8CE),
              width: unlocked ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Lock/unlock icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: unlocked ? AppColors.primary : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quizName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? const Color(0xFF0D2B24)
                              : const Color(0xFF0D2B24).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$quizCount questions',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF0D2B24).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side — price or status badge
                if (unlocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sample
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sample ? 'Free' : 'Unlocked',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sample
                            ? const Color(0xFF1A7A2A)
                            : AppColors.primary,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
