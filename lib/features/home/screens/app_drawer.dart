// lib/features/home/screens/app_drawer.dart

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/revenuecat_service.dart';
import 'package:medtermsv01/core/services/user_service.dart';
import 'package:medtermsv01/core/services/version_service.dart';
import 'package:medtermsv01/core/providers/providers.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';
import 'package:medtermsv01/shared/bottom_sheets/upgrade_option_bottom_sheet.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _faqUrl = 'https://reichardreviews.com/faq';
  static const _appStoreUrl =
      'https://apps.apple.com/us/app/medical-terminology-app/id6752959809';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.reichardreviews.medterms';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A6B5A),
              Color(0xFF2E9E7E),
              Color(0xFF3CC9A0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _drawerItem(
                icon: Icons.settings_outlined,
                label: 'FAQ',
                onTap: () => _launchUrl(_faqUrl, context),
              ),
              _drawerItem(
                icon: Icons.refresh_rounded,
                iconColor: AppColors.accent,
                label: 'Restore Purchase',
                onTap: () => _restorePurchase(context),
              ),
              _drawerItem(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red.shade400,
                label: 'Delete My Data',
                onTap: () => _confirmDeleteData(context, ref),
              ),
              _drawerItem(
                icon: Icons.update_rounded,
                label: 'Check for Updates',
                onTap: () => _checkForUpdates(context),
              ),
              _drawerItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                onTap: () => _logOut(context, ref),
              ),
              const Spacer(),
              _drawerItem(
                icon: Icons.cancel_outlined,
                label: 'Cancel',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer Item
  // ---------------------------------------------------------------------------

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 26),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        _showSnack(context, 'Could not open link.');
      }
    }
  }

  Future<void> _restorePurchase(BuildContext context) async {
    // LemonSqueezy does not have a native restore — direct user to their
    // purchase confirmation email or the LemonSqueezy customer portal.
    // For now show a guidance dialog.
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Purchase'),
        content: const Text(
          'To restore your purchase, please use the same email address '
          'you used when you originally purchased. Sign in with that email '
          'and your modules will be restored automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final stored = await VersionService.fetchLatestVersion();

      if (!context.mounted) return;

      if (stored == null) {
        _showSnack(context, 'Could not check for updates.');
        return;
      }

      final hasUpdate = VersionService.isNewerVersion(
        stored: currentVersion,
        current: stored,
      );

      if (hasUpdate) {
        if (context.mounted) {
          Navigator.of(context).pop(); // close drawer first
          await UpgradeOptionBottomSheet.show(context, newVersion: stored);
        }
      } else {
        _showSnack(context, 'You are on the latest version ($currentVersion).',
            isError: false);
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Update check failed.');
    }
  }

  Future<void> _confirmDeleteData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete My Data'),
        content: const Text(
          'This will permanently delete your account and all associated data '
          'including quiz progress, purchases, and profile information. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final user = ref.read(userProvider).value;
      if (user?.email == null) {
        _showSnack(context, 'Could not identify account.');
        return;
      }
      await UserService.deleteUserData(email: user!.email!);
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Delete failed: $e');
    }
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await RevenueCatService.logOut();
      }
      await AuthService.signOut();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Sign out failed.');
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
