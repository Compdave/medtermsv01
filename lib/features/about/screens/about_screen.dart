// lib/features/about/screens/about_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _darUrl = 'https://dardigitalsolutions.com';

  @override
  Widget build(BuildContext context) {
    final appName = AppConfig.instance.appName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About $appName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2B24),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$appName was designed and built by DAR Digital '
                  'Solutions, a studio that helps small businesses create '
                  'websites, apps, and digital systems.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: const Color(0xFF0D2B24).withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$appName is published by Reichard Reviews, LLC.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: const Color(0xFF0D2B24).withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Have an idea for an app or website of your own?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D2B24).withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse(_darUrl),
                      mode: LaunchMode.externalApplication),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'dardigitalsolutions.com',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
