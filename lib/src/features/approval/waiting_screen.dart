import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  static const routePath = '/waiting';

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting for approval'),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.logout(keepRole: true);
            },
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
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request sent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your request has been sent to the admin.\n'
                        'Once approved, we will automatically redirect you to the home screen.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_bottom, color: AppColors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: Pending approval',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (kDebugMode) ...[
                const Text(
                  'Debug (remove when API ready)',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async => controller.debugApprove(),
                  child: const Text('Simulate Approved'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async => controller.debugDecline(),
                  child: const Text('Simulate Declined'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

