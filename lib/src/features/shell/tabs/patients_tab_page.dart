import 'package:flutter/material.dart';

import 'package:doctor_app/src/features/shell/shell_placeholder_page.dart';

/// Shell index **1** — patient list / search (API بعد میں).
class PatientsTabPage extends StatelessWidget {
  const PatientsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellPlaceholderPage(
      titleEn: 'Patients',
      hintEn: 'Patient list & search — API بعد میں',
    );
  }
}
