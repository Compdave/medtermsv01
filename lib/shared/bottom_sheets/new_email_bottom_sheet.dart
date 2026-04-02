// lib/shared/bottom_sheets/new_email_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/user_service.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

/// Bottom sheet for changing the user's email address.
/// Shows current email, security notice, and new email input.
class NewEmailBottomSheet extends StatefulWidget {
  final String currentEmail;
  final String userId;

  const NewEmailBottomSheet({
    super.key,
    required this.currentEmail,
    required this.userId,
  });

  /// Show this bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String currentEmail,
    required String userId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewEmailBottomSheet(
        currentEmail: currentEmail,
        userId: userId,
      ),
    );
  }

  @override
  State<NewEmailBottomSheet> createState() =>
      _NewEmailBottomSheetState();
}

class _NewEmailBottomSheetState extends State<NewEmailBottomSheet> {
  final _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    final newEmail = _emailController.text.trim();
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      _showSnack('Please enter a valid email address.');
      return;
    }
    if (newEmail == widget.currentEmail) {
      _showSnack('New email is the same as your current email.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AuthService.updateEmail(newEmail: newEmail);
      await UserService.updateEmail(
        userId: widget.userId,
        newEmail: newEmail,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email updated successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to update email: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  'Change Email Address',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2B24),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security notice
              Text(
                'Please note: This app only sends emails for password resets '
                'and email address changes. Your email address must be valid '
                'to receive these important security communications.',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF0D2B24).withValues(alpha: 0.65),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Current email display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB2D8CE)),
                ),
                child: Text(
                  widget.currentEmail,
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFF0D2B24).withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // New email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0D2B24),
                ),
                decoration: InputDecoration(
                  labelText: 'New Email Address',
                  labelStyle: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFB2D8CE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFB2D8CE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0D2B24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Update Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
