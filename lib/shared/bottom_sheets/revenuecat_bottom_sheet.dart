// lib/shared/bottom_sheets/revenuecat_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:medtermsv01/core/providers/providers.dart';
import 'package:medtermsv01/core/services/revenuecat_service.dart';
import 'package:medtermsv01/core/services/supabase_service.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

/// Purchase bottom sheet — handles RevenueCat IAP for mobile.
/// Shows module details, fetches live price from RC, and processes purchase.
///
/// [onPurchaseComplete] — optional callback fired after a successful purchase.
/// Use this to set the newly purchased module as default and navigate home.
/// If not provided, falls back to the default snackbar behaviour.
class RevenuecatBottomSheet extends ConsumerStatefulWidget {
  final String moduleName;
  final int quizCount;
  final String apptype;
  final int quizId;
  final VoidCallback? onPurchaseComplete;

  const RevenuecatBottomSheet({
    super.key,
    required this.moduleName,
    required this.quizCount,
    required this.apptype,
    required this.quizId,
    this.onPurchaseComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required String moduleName,
    required int quizCount,
    required String apptype,
    required int quizId,
    VoidCallback? onPurchaseComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RevenuecatBottomSheet(
        moduleName: moduleName,
        quizCount: quizCount,
        apptype: apptype,
        quizId: quizId,
        onPurchaseComplete: onPurchaseComplete,
      ),
    );
  }

  @override
  ConsumerState<RevenuecatBottomSheet> createState() =>
      _RevenuecatBottomSheetState();
}

class _RevenuecatBottomSheetState extends ConsumerState<RevenuecatBottomSheet> {
  Package? _package;
  bool _isLoadingPackage = true;
  bool _isPurchasing = false;
  String? _priceString;

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    final package = await RevenueCatService.fetchPackage(widget.apptype);
    if (mounted) {
      setState(() {
        _package = package;
        _priceString = package?.storeProduct.priceString;
        _isLoadingPackage = false;
      });
    }
  }

  Future<void> _purchase() async {
    if (_package == null) return;
    setState(() => _isPurchasing = true);

    try {
      final success = await RevenueCatService.purchasePackage(_package!);
      if (!success) {
        if (mounted) setState(() => _isPurchasing = false);
        return;
      }

      final userId = SupabaseService.currentUserId ?? '';
      await RevenueCatService.ensureModuleUnlocked(
        userId: userId,
        quizId: widget.quizId,
        apptype: widget.apptype,
      );

      ref.invalidate(moduleListProvider);

      if (mounted) {
        Navigator.of(context).pop();

        // FIX: if a callback was provided (e.g. from selectMode), use it.
        // Otherwise fall back to default snackbar behaviour.
        if (widget.onPurchaseComplete != null) {
          widget.onPurchaseComplete!();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('"${widget.moduleName}" unlocked! Ready to study.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on PurchasesError catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.message}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red.shade700,
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A6B5A), Color(0xFF3A7A6A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Full Module: ${widget.moduleName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Get lifetime access to all ${widget.quizCount} practice questions',
              style: const TextStyle(
                  fontSize: 15, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: _isLoadingPackage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _priceString != null
                          ? 'One-time Purchase: $_priceString'
                          : 'Price unavailable',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_isPurchasing || _isLoadingPackage || _package == null)
                        ? null
                        : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.white.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Purchase Now',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed:
                    _isPurchasing ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
