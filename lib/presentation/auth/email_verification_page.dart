import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../salon/salon_setup_page.dart';

class EmailVerificationPage extends StatelessWidget {
  final String email;
  const EmailVerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(28)),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 52, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text('Check your email',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                  'We sent a verification link to\n$email\n\nPlease verify your email to continue.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) =>
                            const SalonSetupPage(isOnboarding: true)),
                    (route) => false,
                  ),
                  child: const Text('Continue to Setup'),
                ),
              ),
              const SizedBox(height: 12),
              Text('You can verify your email later from settings.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
