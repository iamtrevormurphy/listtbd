import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/config/theme_config.dart';
import '../../widgets/animated_background.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  SvgPicture.asset(
                    'assets/provisions_logo.svg',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Provisions',
                    style: ThemeConfig.youngSerifStyle(
                      fontSize: 28,
                      color: ThemeConfig.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 56,
                      color: ThemeConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Check your email',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'We sent a confirmation link to',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ThemeConfig.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeConfig.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildStep(
                          context,
                          number: '1',
                          text: 'Open your email inbox',
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          context,
                          number: '2',
                          text: 'Click the confirmation link',
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          context,
                          number: '3',
                          text: 'Return here to sign in',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Back to sign in button
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      child: Text('Back to Sign In'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Help text
                  Text(
                    "Didn't receive the email? Check your spam folder.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, {required String number, required String text}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ThemeConfig.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeConfig.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
