import 'package:flutter/material.dart';

/// Bottom tabs for [HomeShell]; `.index` matches [IndexedStack] order (0–3).
enum HomeShellTab {
  home,
  patients,
  visit,
  profile;

  String get label => switch (this) {
        HomeShellTab.home => 'Home',
        HomeShellTab.patients => 'Patients',
        HomeShellTab.visit => 'Visit',
        HomeShellTab.profile => 'Profile',
      };

  IconData get icon => switch (this) {
        HomeShellTab.home => Icons.grid_view_rounded,
        HomeShellTab.patients => Icons.people_outline_rounded,
        HomeShellTab.visit => Icons.fact_check_outlined,
        HomeShellTab.profile => Icons.person_outline_rounded,
      };
}
