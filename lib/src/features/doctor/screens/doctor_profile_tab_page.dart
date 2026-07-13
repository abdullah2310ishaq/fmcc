import 'package:flutter/material.dart';

import 'package:doctor_app/src/features/doctor/screens/doctor_profile_screen.dart';

/// Shell tab — profile without back arrow; system back returns to Home tab.
class DoctorProfileTabPage extends StatelessWidget {
  const DoctorProfileTabPage({super.key, this.onLeaveToHomeTab});

  final VoidCallback? onLeaveToHomeTab;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onLeaveToHomeTab?.call();
      },
      child: const DoctorProfileScreen(showBackButton: false),
    );
  }
}
