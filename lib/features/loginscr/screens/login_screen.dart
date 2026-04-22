// lib/features/loginscr/screens/login_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/revenuecat_service.dart';
import 'dart:io';
import 'package:medtermsv01/core/services/module_service.dart';
import 'package:medtermsv01/core/services/quiz_service.dart';
import 'package:medtermsv01/core/services/user_service.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Always trim email and password
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    try {
      if (_isSignIn) {
        final response =
            await AuthService.signIn(email: email, password: password);
        // Log in to RevenueCat with Supabase user ID
        if (Platform.isIOS || Platform.isAndroid) {
          final userId = response.user?.id;
          if (userId != null) await RevenueCatService.logIn(userId);
        }
        if (mounted) context.go('/home');
      } else {
        await _handleSignUp(
            email: email, password: password, displayName: displayName);
      }
    } catch (e) {
      if (mounted) _showSnack(_friendlyAuthError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Full post-signup flow:
  /// 1. signUp() — Supabase creates auth.users record
  /// 2. DB trigger auto-creates public.users record
  /// 3. updateDisplayName() — sets display name on public.users
  /// 4. Fetch sample quiz_id from quiz table dynamically
  /// 5. insertnewmodule() — seeds user_answers, user_summary, modules
  /// 6. Route to home
  Future<void> _handleSignUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await AuthService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    final userId = response.user?.id;
    if (userId == null) throw Exception('Sign up failed — no user returned.');

    // Update display name on public.users (trigger already created the row)
    if (displayName.isNotEmpty) {
      await UserService.updateDisplayName(
        userId: userId,
        displayName: displayName,
      );
    }

    // Fetch sample quizzes dynamically — don't hardcode quiz_id
    final quizList = await QuizService.fetchQuizList(AppConfig.instance.appId);
    final sampleQuizzes = quizList.where((q) => q.sample).toList();

    // Seed each sample module for the new user
    for (final quiz in sampleQuizzes) {
      await ModuleService.unlockModule(
        apptype: quiz.apptype ?? AppConfig.instance.apptypePrefix,
        userId: userId,
        quizId: quiz.quizId,
      );
    }

    if (mounted) context.go('/home');
  }

  /// Convert raw Supabase/auth error messages into user-friendly text.
  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user already exists')) {
      return 'That email is already registered. Try signing in instead.';
    }
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (lower.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email address first.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showSnack('Password reset email sent!', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LOGIN gradientTop: ${AppConfig.instance.gradientTop}');
    debugPrint('LOGIN appName: ${AppConfig.instance.appName}');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConfig.instance.gradientTop,
              Color.lerp(AppConfig.instance.gradientTop,
                  AppConfig.instance.gradientBottom, 0.3)!,
              AppConfig.instance.gradientBottom,
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildLogo(),
                  const SizedBox(height: 16),
                  _buildTitle(),
                  const SizedBox(height: 24),
                  _buildToggle(),
                  const SizedBox(height: 28),
                  _buildFields(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                  if (_isSignIn) ...[
                    const SizedBox(height: 12),
                    _buildForgotPassword(),
                  ],
                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  Widget _buildLogo() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          AppConfig.instance.iconAssetPath, // ← flavor-aware icon
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      AppConfig.instance.appName, // ← flavor-aware app name
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0D2B24),
        letterSpacing: 0.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _toggleTab(
            'Sign In', _isSignIn, () => setState(() => _isSignIn = true)),
        const SizedBox(width: 32),
        _toggleTab(
            'Sign Up', !_isSignIn, () => setState(() => _isSignIn = false)),
      ],
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active
                  ? const Color(0xFF0D2B24)
                  : const Color(0xFF0D2B24).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 80,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        if (!_isSignIn) ...[
          _buildTextField(
            controller: _displayNameController,
            hint: 'Display names...',
            icon: Icons.person_outline,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Display name required' : null,
          ),
          const SizedBox(height: 14),
        ],
        _buildTextField(
          controller: _emailController,
          hint: 'email...',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              v == null || !v.contains('@') ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          toggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          validator: (v) => v == null || v.length < 6
              ? 'Password must be 6+ characters'
              : null,
        ),
        if (!_isSignIn) ...[
          const SizedBox(height: 14),
          _buildTextField(
            controller: _confirmController,
            hint: 'Confirm password',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            toggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Color(0xFF0D2B24)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isSignIn ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return GestureDetector(
      onTap: _forgotPassword,
      child: const Text(
        'Forgot Password?',
        style: TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: Color(0xFF0D2B24),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          AppConfig.instance.appSubtitle, // ← flavor-aware subtitle
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            color: const Color(0xFF0D2B24).withValues(alpha: 0.85),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _footerLink('Terms', 'https://reichardreviews.com/terms.html'),
            const SizedBox(width: 24),
            _footerLink('Privacy', 'https://reichardreviews.com/privacy.html'),
            const SizedBox(width: 24),
            _footerLink('EULA',
                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) {
            final version = snap.data?.version ?? '—';
            return Text(
              'Version: $version',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF0D2B24).withValues(alpha: 0.7),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
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
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: const Color(0xFF0D2B24).withValues(alpha: 0.75),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
