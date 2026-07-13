import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Branded confirmation sheets used across the app (logout, discard, exit).
abstract final class AppConfirmDialogs {
  AppConfirmDialogs._();

  static Future<bool?> showLogout(BuildContext context) {
    return _sheet(
      context,
      title: 'Log out?',
      message:
          'You will need to sign in again with your verified Google account.',
      confirmLabel: 'Logout',
      confirmColor: AppColors.danger,
      icon: CupertinoIcons.square_arrow_right,
    );
  }

  static Future<bool?> showDiscardChanges(BuildContext context) {
    return _sheet(
      context,
      title: 'Discard changes?',
      message:
          'You have unsaved information. Leaving now will lose your progress.',
      confirmLabel: 'Discard',
      confirmColor: AppColors.danger,
      icon: CupertinoIcons.exclamationmark_triangle_fill,
    );
  }

  static Future<bool?> showExitApp(BuildContext context) {
    return _sheet(
      context,
      title: 'Exit app?',
      message: 'Are you sure you want to close the doctor workspace?',
      confirmLabel: 'Exit',
      confirmColor: AppColors.dashboardPrimaryDark,
      icon: CupertinoIcons.power,
    );
  }

  static Future<bool?> showGoBack(BuildContext context, {String? message}) {
    return _sheet(
      context,
      title: 'Go back?',
      message: message ?? 'Any unsaved work on this screen may be lost.',
      confirmLabel: 'Go back',
      confirmColor: AppColors.dashboardPrimary,
      icon: CupertinoIcons.arrow_left,
    );
  }

  static Future<bool?> _sheet(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: EdgeInsets.all(14.w),
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: confirmColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(icon, color: confirmColor, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 18.h),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: AppColors.surface,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dashboardPrimaryDark,
                    side: const BorderSide(color: AppColors.registrationFieldBorder),
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> exitAppIfConfirmed(BuildContext context) async {
    final confirmed = await showExitApp(context);
    if (confirmed == true) {
      await SystemNavigator.pop();
    }
  }
}
