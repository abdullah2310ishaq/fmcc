import 'package:flutter/material.dart';

import 'package:doctor_app/src/features/shell/shell_placeholder_page.dart';

/// Shell index **2** — visit workflow (API بعد میں).
class VisitTabPage extends StatelessWidget {
  const VisitTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellPlaceholderPage(
      titleEn: 'Visit',
      hintEn: 'Visit workflow — API بعد میں',
    );
  }
}
