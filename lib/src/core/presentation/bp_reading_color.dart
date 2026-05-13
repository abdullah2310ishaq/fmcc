import 'package:flutter/material.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Colors for **BP pair** (systolic + diastolic) and **pulse** (bpm) in vitals UI.
///
/// **Blood pressure (both must match the band):**
/// - **Severe HTN:** SBP ≥ 180 **and** DBP ≥ 120 → red ([AppColors.danger])
/// - **Uncontrolled HTN:** SBP ≥ 140 **and** DBP ≥ 90 → orange ([AppColors.dashboardWarning])
/// - **Controlled:** SBP < 140 **and** DBP < 90 → green ([AppColors.success])
/// - Otherwise (e.g. isolated systolic/diastolic elevation) → [fallback]
abstract final class BpReadingColor {
  BpReadingColor._();

  /// BP text color when both systolic and diastolic are known.
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

  /// Resting pulse (bpm) for numeric tint — separate from BP rules.
  ///
  /// - **Urgent:** &lt; 50 or ≥ 120 → red
  /// - **Caution:** 50–59 or 101–119 → orange
  /// - **Typical:** 60–100 → green
  static Color forPulse(int pulse) {
    if (pulse < 50 || pulse >= 120) return AppColors.danger;
    if (pulse <= 59 || pulse >= 101) return AppColors.dashboardWarning;
    return AppColors.success;
  }
}
