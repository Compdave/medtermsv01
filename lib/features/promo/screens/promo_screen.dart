// lib/features/promo/screens/promo_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:medtermsv01/core/providers/providers.dart';
import 'package:medtermsv01/core/services/supabase_service.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

/// Promo screen — opens the LemonSqueezy checkout page in a WebView.
/// The [apptype] param is the LemonSqueezy app_slug / product identifier.
/// After purchase, the LS webhook fires and seeds the module server-side.
/// On return, the module list is invalidated so it refreshes automatically.
class PromoScreen extends ConsumerStatefulWidget {
  final String apptype;
  final int? quizId;

  const PromoScreen({
    super.key,
    required this.apptype,
    this.quizId,
  });

  @override
  ConsumerState<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends ConsumerState<PromoScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  // LemonSqueezy checkout URL with custom metadata for webhook processing.
  // user_id, app_slug, apptype, quiz_id are received by the LS webhook
  // to identify the user and unlock the correct module.
  //
  String get _checkoutUrl {
    final userId = SupabaseService.currentUserId ?? '';
    final email = SupabaseService.client.auth.currentUser?.email ?? '';
    final quizId = widget.quizId?.toString() ?? '';
    const baseProductId = 'b5cdab8b-5b86-4ec0-ab7a-642214368cca';
    final uri = Uri(
      scheme: 'https',
      host: 'reichardreviews.lemonsqueezy.com',
      path: '/buy/$baseProductId',
      queryParameters: {
        'checkout[custom][user_id]': userId,
        'checkout[custom][app_slug]': widget.apptype,
        'checkout[custom][apptype]': widget.apptype,
        'checkout[custom][quiz_id]': quizId,
        'checkout[email]': email,
      },
    );
    return uri.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
          onNavigationRequest: (request) {
            // Detect successful purchase redirect — LS redirects to a
            // success URL after purchase. Intercept and return to app.
            if (request.url.contains('success') ||
                request.url.contains('thank') ||
                request.url.contains('confirmation')) {
              _onPurchaseComplete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_checkoutUrl));
  }

  void _onPurchaseComplete() {
    // Invalidate module list so home screen refreshes with new unlock
    ref.invalidate(moduleListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase complete! Your module is being unlocked...'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Give webhook a moment then pop back to modules list
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/modules');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () {
            // Invalidate on close too — purchase may have completed
            ref.invalidate(moduleListProvider);
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Get Access',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Reload button in case of network issues
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            _buildErrorState()
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFFF0FAF7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading checkout...',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Could not load the checkout page.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D2B24),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF0D2B24).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasError = false);
                _controller.reload();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
