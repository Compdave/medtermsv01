// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:medtermsv01/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtermsv01/core/providers/providers.dart';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/user_service.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingName = false;
  bool _isSavingEmail = false;
  bool _isSavingPassword = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showEmailSection = false;
  bool _showPasswordSection = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          // Pre-fill display name on first load
          if (_displayNameController.text.isEmpty &&
              user?.displayName != null) {
            _displayNameController.text = user!.displayName!;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDisplayNameCard(user),
                const SizedBox(height: 16),
                _buildEmailCard(user),
                const SizedBox(height: 16),
                _buildPasswordCard(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Display Name Card
  // ---------------------------------------------------------------------------

  Widget _buildDisplayNameCard(UserModel? user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF2E9E7E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
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
          const SizedBox(height: 16),

          // Title
          const Text(
            'Display Name',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Explanation
          const Text(
            'Choose a display name that will be shown to other users. '
            'This can be different from your email address and is just '
            'for identification purposes. We don\'t need your real name — '
            'if left blank, your email address will be used.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Display name field
          TextField(
            controller: _displayNameController,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0D2B24),
            ),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: const TextStyle(color: AppColors.primary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.95),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSavingName ? null : () => _saveDisplayName(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSavingName
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(
                      'Save Display Name',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Email Card
  // ---------------------------------------------------------------------------

  Widget _buildEmailCard(UserModel? user) {
    return _SettingsCard(
      title: 'Email Address',
      icon: Icons.email_outlined,
      subtitle: user?.email ?? '—',
      isExpanded: _showEmailSection,
      onToggle: () => setState(() => _showEmailSection = !_showEmailSection),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildTextField(
            controller: _newEmailController,
            label: 'New Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSavingEmail ? null : () => _saveEmail(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSavingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update Email',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Password Card
  // ---------------------------------------------------------------------------

  Widget _buildPasswordCard() {
    return _SettingsCard(
      title: 'Change Password',
      icon: Icons.lock_outline_rounded,
      subtitle: '••••••••',
      isExpanded: _showPasswordSection,
      onToggle: () =>
          setState(() => _showPasswordSection = !_showPasswordSection),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildTextField(
            controller: _newPasswordController,
            label: 'New Password',
            obscure: _obscureNew,
            toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            obscure: _obscureConfirm,
            toggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSavingPassword ? null : _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSavingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update Password',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared text field
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF0D2B24)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.8), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB2D8CE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB2D8CE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _saveDisplayName(UserModel? user) async {
    if (user == null) return;
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Display name cannot be empty.');
      return;
    }
    setState(() => _isSavingName = true);
    try {
      await UserService.updateDisplayName(
        userId: user.userId,
        displayName: name,
      );
      ref.invalidate(userProvider);
      if (mounted) _showSnack('Display name updated!', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Failed to update name: $e');
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _saveEmail(UserModel? user) async {
    if (user == null) return;
    final newEmail = _newEmailController.text.trim();
    if (!newEmail.contains('@')) {
      _showSnack('Enter a valid email address.');
      return;
    }
    setState(() => _isSavingEmail = true);
    try {
      // Update auth email
      await AuthService.updateEmail(newEmail: newEmail);
      // Keep public.users in sync
      await UserService.updateEmail(
        userId: user.userId,
        newEmail: newEmail,
      );
      ref.invalidate(userProvider);
      _newEmailController.clear();
      setState(() => _showEmailSection = false);
      if (mounted) {
        _showSnack('Email updated successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to update email: $e');
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      _showSnack('Passwords do not match.');
      return;
    }
    setState(() => _isSavingPassword = true);
    try {
      await AuthService.updatePassword(newPassword: newPass);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordSection = false);
      if (mounted) {
        _showSnack('Password updated successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to update password: $e');
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
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
}

// =============================================================================
// Reusable collapsible settings card
// =============================================================================

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2D8CE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D2B24),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                const Color(0xFF0D2B24).withValues(alpha: 0.55),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}
