// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtermsv01/core/providers/providers.dart';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/quiz_service.dart';
import 'package:medtermsv01/core/services/user_summary_service.dart';
import 'package:medtermsv01/core/services/supabase_service.dart';
import 'package:medtermsv01/shared/bottom_sheets/scoring_bottom_sheet.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';
import 'package:medtermsv01/features/home/screens/app_drawer.dart';
import 'package:medtermsv01/core/services/module_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isGuest;

  const HomeScreen({super.key, this.isGuest = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _timerEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadTimerPref();
    _ensureModulesSeeded();
  }

  Future<void> _ensureModulesSeeded() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      await ModuleService.ensureAppModulesExist(
        userId: userId,
        appId: AppConfig.instance.appId,
      );
      ref.invalidate(moduleListProvider);
    } catch (e) {
      // Non-fatal — don't block home screen
    }
  }

  Future<void> _loadTimerPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _timerEnabled = prefs.getBool('timer_enabled') ?? true;
    });
  }

  Future<void> _setTimerPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_enabled', value);
    setState(() => _timerEnabled = value);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final moduleListAsync = ref.watch(moduleListProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: ref.watch(userProvider).value?.isGuest == true
          ? null
          : const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Home Page',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: ref.watch(userProvider).value?.isGuest == true
            ? null
            : IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: ref.watch(userProvider).value?.isGuest == true
            ? [
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ]
            : null,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(AppConfig.instance.gradientTop,
                  AppConfig.instance.gradientBottom, 0.2)!,
              Color.lerp(AppConfig.instance.gradientTop,
                  AppConfig.instance.gradientBottom, 0.6)!,
              AppConfig.instance.gradientBottom,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) {
            final isGuest = user?.isGuest ?? false;
            return SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(user?.displayName, isGuest),
                    const SizedBox(height: 20),
                    moduleListAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (e, _) =>
                          Center(child: Text('Error loading modules: $e')),
                      data: (modules) => _buildBody(modules, isGuest),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Welcome Header — FIX: name uses FittedBox to prevent overflow
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeHeader(String? displayName, bool isGuest) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppConfig.instance.iconAssetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // FIX: Expanded + FittedBox so long names shrink instead of overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isGuest ? 'Guest' : (displayName ?? 'Friend'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A3A6B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody(List<Map<String, dynamic>> modules, bool isGuest) {
    final sampleModule = modules.firstWhere(
      (m) => m['sample'] == true,
      orElse: () => {},
    );

    // FIX: track whether any paid module is purchased
    final purchasedModules = modules
        .where((m) => m['purchased'] == true && m['sample'] != true)
        .toList();
    final hasPurchasedModule = purchasedModules.isNotEmpty;

    return Column(
      children: [
        if (sampleModule.isNotEmpty) _buildSampleCard(sampleModule),
        const SizedBox(height: 20),
        _buildNavGrid(modules),
        const SizedBox(height: 20),
        if (!isGuest) _buildUnlockCard(hasPurchasedModule),
        if (!isGuest) const SizedBox(height: 20),
        if (!isGuest) _buildActionButtons(),
        const SizedBox(height: 32),
        _buildFooter(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sample Quiz Card
  // ---------------------------------------------------------------------------

  Widget _buildSampleCard(Map<String, dynamic> module) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module['quiz_name'] as String? ?? 'Sample Quiz',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D2B24),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ready to learn and review?',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF1A3A2A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _startQuiz(module),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Start Quiz',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startQuiz(Map<String, dynamic> module) {
    final quizId = module['quiz_id'] as int?;
    if (quizId == null) return;
    context.push('/quiz/$quizId?apptype=${module["apptype"] ?? ""}');
  }

  // ---------------------------------------------------------------------------
  // Nav Grid
  // ---------------------------------------------------------------------------

  Future<void> _showTimerDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Quiz Timer'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The timer tracks how long you spend on each quiz session '
                'and calculates your seconds-per-correct-item score for '
                'the leaderboard.',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF0D2B24).withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'When the timer is OFF, duration is not tracked and your '
                'leaderboard score will not include timing data. '
                'Existing duration data will be reset to zero.',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF0D2B24).withValues(alpha: 0.6),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _timerEnabled ? 'Timer is ON' : 'Timer is OFF',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _timerEnabled
                          ? AppColors.primary
                          : Colors.grey.shade500,
                    ),
                  ),
                  Switch(
                    value: _timerEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      setDialogState(() {});
                      await _setTimerPref(val);
                      if (!val) {
                        final userId = SupabaseService.currentUserId ?? '';
                        final modules =
                            ref.read(moduleListProvider).value ?? [];
                        for (final m in modules) {
                          final quizId = m['quiz_id'] as int?;
                          if (quizId != null && userId.isNotEmpty) {
                            try {
                              await UserSummaryService.resetDuration(
                                userId: userId,
                                quizId: quizId,
                              );
                            } catch (_) {}
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStats(int? quizId) async {
    if (quizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No quiz data available yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final userId = SupabaseService.currentUserId ?? '';
    try {
      final summary = await UserSummaryService.fetchUserSummary(
        userId: userId,
        quizId: quizId,
      );
      if (summary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No stats yet — complete some questions first!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (mounted) {
        await ScoringBottomSheet.show(
          context,
          noInQuiz: summary.noInQuiz,
          noCompleted: summary.noCompleted,
          noCorrect: summary.noCorrect,
          durationSeconds: summary.durationSeconds,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading stats: \$e')),
        );
      }
    }
  }

  Widget _buildNavGrid(List<Map<String, dynamic>> modules) {
    final firstUnlocked = modules.firstWhere(
      (m) => m['purchased'] == true || m['sample'] == true,
      orElse: () => {},
    );
    final statsQuizId = firstUnlocked['quiz_id'] as int?;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        _navButton(
          icon: Icons.emoji_events_outlined,
          label: 'Leader Board',
          iconColor: const Color(0xFFD4A017),
          onTap: () => context.push('/leaderboard'),
        ),
        _navButton(
          icon: Icons.bar_chart_rounded,
          label: 'Stats',
          iconColor: AppColors.primary,
          onTap: () => _showStats(statsQuizId),
        ),
        _navButton(
          icon: Icons.timer_outlined,
          label: 'Timer',
          iconColor: AppColors.primary,
          onTap: () => _showTimerDialog(),
        ),
        _navButton(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          iconColor: const Color(0xFF1A3A6B),
          onTap: () => context.push('/profile'),
        ),
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D2B24),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFF0D2B24).withValues(alpha: 0.4),
                size: 18),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Unlock Card
  // FIX: shows different title/subtitle/button depending on purchase state
  // ---------------------------------------------------------------------------

  Widget _buildUnlockCard(bool hasPurchasedModule) {
    // When modules are purchased: show "Select Working Module"
    // When nothing purchased: show "Unlock Full Course"
    final title =
        hasPurchasedModule ? 'Select Working Module' : 'Unlock Full Course';
    final subtitle = hasPurchasedModule
        ? 'Switch your active module'
        : 'Get Access to the full module';
    final buttonLabel = hasPurchasedModule ? 'Change Module' : 'Select Module';
    final icon = hasPurchasedModule
        ? Icons.swap_horiz_rounded
        : Icons.lock_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              // FIX: pass selectMode=true when user already has a module,
              // so the modules list sets default instead of launching quiz
              onPressed: () => context.push(
                hasPurchasedModule ? '/modules?selectMode=true' : '/modules',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Buttons
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.refresh_rounded,
            label: 'Reset Modules',
            onTap: _confirmResetModules,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.power_settings_new_rounded,
            label: 'Log Out',
            onTap: _logOut,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    return Column(
      children: [
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) => Text(
            'Version: ${snap.data?.version ?? '—'}',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF0D2B24).withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _footerLink('Terms', 'https://reichardreviews.com/terms.html'),
            const SizedBox(width: 20),
            _footerLink('Privacy', 'https://reichardreviews.com/privacy.html'),
            const SizedBox(width: 20),
            _footerLink('EULA',
                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
            const SizedBox(width: 20),
            _licensesLink(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Copyright © 2026 Reichard Reviews, LLC.\nAll Rights Reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF0D2B24).withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _footerLink(String label, String url) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFF0D2B24).withValues(alpha: 0.75),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _licensesLink() {
    return GestureDetector(
      onTap: () async {
        final info = await PackageInfo.fromPlatform();
        if (mounted) {
          showLicensePage(
            context: context,
            applicationName: AppConfig.instance.appName,
            applicationVersion: info.version,
            applicationIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                AppConfig.instance.iconAssetPath,
                width: 48,
                height: 48,
              ),
            ),
          );
        }
      },
      child: Text(
        'Licenses',
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFF0D2B24).withValues(alpha: 0.75),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmResetModules() async {
    final modules = ref.read(moduleListProvider).value ?? [];
    final unlocked = modules
        .where((m) => m['purchased'] == true || m['sample'] == true)
        .toList();

    if (unlocked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No modules to reset.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedModule = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Module to Reset',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress will be cleared but your module will stay unlocked.',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF0D2B24).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              ...unlocked.map((m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.quiz_outlined, color: AppColors.primary),
                    title: Text(
                      m['quiz_name'] as String? ?? 'Module',
                      style: const TextStyle(fontSize: 15),
                    ),
                    subtitle: Text(
                      m['sample'] == true ? 'Free Sample' : 'Purchased',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0D2B24).withValues(alpha: 0.5),
                      ),
                    ),
                    onTap: () => Navigator.pop(context, m),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedModule == null || !mounted) return;

    final quizId = selectedModule['quiz_id'] as int?;
    final quizName = selectedModule['quiz_name'] as String? ?? 'this module';
    if (quizId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Reset'),
        content: Text(
          'This will clear all your answers and progress for "$quizName". '
          'Your module will stay unlocked. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final userId = SupabaseService.currentUserId ?? '';
    try {
      await QuizService.resetAllUserAnswers(
        userId: userId,
        quizId: quizId,
      );
      await UserSummaryService.resetDuration(
        userId: userId,
        quizId: quizId,
      );
      await UserSummaryService.updateQuizSummary(
        quizId: quizId,
        userId: userId,
      );
      ref.invalidate(moduleListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$quizName" has been reset.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logOut() async {
    try {
      await AuthService.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }
}
