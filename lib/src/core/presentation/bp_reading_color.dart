import 'package:flutter/material.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// BP text color when both systolic and diastolic are known (LHW rules).
abstract final class BpReadingColor {
  BpReadingColor._();

  /// Red: crisis (both thresholds). Orange: elevated (both). Green: below both.
  /// Otherwise [fallback] (e.g. mixed high/low).
  static Color forPair(
    int sbp,
    int dbp, {
    Color fallback = AppColors.textPrimary,
  }) {
    if (sbp >= 180 && dbp >= 120) return AppColors.danger;
    if (sbp >= 140 && dbp >= 90) return AppColors.dashboardWarning;
    if (sbp < 140 && dbp < 90) return AppColors.success;
    return fallback;
  }
}
