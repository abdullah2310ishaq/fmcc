import 'package:flutter/material.dart';

import 'package:doctor_app/src/features/profile/profile_view_screen.dart';

/// Shell index **3** — same profile as `/profile`, without shell back button.
class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key, this.onLeaveToHomeTab});

  /// System back from profile root → Home tab (pushed routes like edit still pop first).
  final VoidCallback? onLeaveToHomeTab;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onLeaveToHomeTab?.call();
      },
      child: const ProfileViewScreen(showBackButton: false),
    );
  }
}
