import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/auth/google_sign_in_config.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/patients/patient_detail_cache.dart';
import 'package:doctor_app/src/features/patients/patient_detail_disk_cache.dart';
import 'package:doctor_app/src/features/role/role_screen.dart';
import 'package:doctor_app/src/features/visits/visit_instructions_cache.dart';

/// Confirmed logout — branded loading overlay, cache clear, session sign-out.
class LogoutFlow {
  LogoutFlow._();

  static Future<void> run(
    BuildContext context, {
    bool keepRole = false,
  }) async {
    if (!context.mounted) return;

    // Let the confirm sheet finish closing first.
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!context.mounted) return;

    // Capture before async work — the calling route may unmount after logout.
    final rootNav = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    final session = context.read<SessionController>();
    PatientDetailCache? patientCache;
    VisitInstructionsCache? visitCache;
    try {
      patientCache = context.read<PatientDetailCache>();
    } on Object {
      // Provider may be unavailable on some routes.
    }
    try {
      visitCache = context.read<VisitInstructionsCache>();
    } on Object {
      // Optional cache — ignore if missing.
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      useRootNavigator: true,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: _LogoutLoadingDialog(),
      ),
    );

    try {
      patientCache?.clearAll();
      try {
        await PatientDetailDiskCache.clearAll();
      } on Object {
        // Disk cache is optional — ignore failures.
      }
      visitCache?.clear();

      await GoogleSignInConfig.signOutCachedAccount();
      await session.logout(keepRole: keepRole);
    } finally {
      // Close the loading dialog BEFORE navigating. Popping after
      // `context.go` can remove the new route and leave a black screen.
      if (rootNav.canPop()) {
        rootNav.pop();
      }
    }

    if (!keepRole) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      router.go(RoleScreen.routePath);
    }
  }
}

class _LogoutLoadingDialog extends StatelessWidget {
  const _LogoutLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Material(
          elevation: 8,
          shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(24.r),
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 46.r,
                  height: 46.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Signing out',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Please wait while we securely end your session…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
