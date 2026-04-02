// lib/shared/bottom_sheets/upgrade_option_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

/// Shown when an app update is available.
/// Displays store buttons for Google Play and App Store.
class UpgradeOptionBottomSheet extends StatelessWidget {
  final String newVersion;

  const UpgradeOptionBottomSheet({
    super.key,
    required this.newVersion,
  });

  /// Show this bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String newVersion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradeOptionBottomSheet(newVersion: newVersion),
    );
  }

  Future<void> _launchStore(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open store link.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F5EE),
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
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Update icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'An upgrade is available for this app.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D2B24),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Version $newVersion is now available.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF0D2B24).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            const Text(
              'Do you wish to upgrade now?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0D2B24),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Store buttons
            Row(
              children: [
                Expanded(
                  child: _StoreButton(
                    onTap: () => _launchStore(
                      context,
                      AppConfig.instance.playStoreUrl,
                    ),
                    isPlayStore: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StoreButton(
                    onTap: () => _launchStore(
                      context,
                      AppConfig.instance.appStoreUrl,
                    ),
                    isPlayStore: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cancel
            SizedBox(
              width: 160,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Store button widget
// =============================================================================

class _StoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isPlayStore;

  const _StoreButton({
    required this.onTap,
    required this.isPlayStore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPlayStore)
              // Google Play triangle icon approximation
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28)
            else
              const Icon(Icons.apple_rounded,
                  color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlayStore ? 'GET IT ON' : 'Download on the',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isPlayStore ? 'Google Play' : 'App Store',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
