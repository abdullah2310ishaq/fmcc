import 'package:flutter/material.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Shared gradients — keep doctor & LHW modules visually aligned.
abstract final class AppGradients {
  AppGradients._();

  /// Soft light-blue → white band (LHW profile hero, home greeting, doctor headers).
  static const LinearGradient header = LinearGradient(
    colors: [AppColors.dashboardChipBlueBg, AppColors.surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerSoft = LinearGradient(
    colors: [AppColors.dashboardChipBlueBg, AppColors.surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.85],
  );
}
