import 'package:flutter/material.dart';

import 'package:doctor_app/src/features/profile/profile_view_screen.dart';

/// Shell index **3** — same profile as `/profile`, without shell back button.
class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileViewScreen(showBackButton: false);
  }
}
