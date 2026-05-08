import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    final session = context.select<SessionController, AppSession>((c) => c.state);

    final title = session.role == UserRole.doctor ? 'Doctor Home' : 'LHW Home';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () async => controller.logout(keepRole: true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.blueDark),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.registrationDetails.fullName.isEmpty
                            ? 'Profile: not set'
                            : 'Profile: ${session.registrationDetails.fullName}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.registrationDetails.phone.isEmpty
                            ? ''
                            : 'Phone: ${session.registrationDetails.phone}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'API integration will be added next.\n'
                    'This screen is the post-approval landing page.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

