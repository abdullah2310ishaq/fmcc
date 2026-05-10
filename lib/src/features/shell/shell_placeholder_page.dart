import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Temporary full-screen body until the feature API is wired.
class ShellPlaceholderPage extends StatelessWidget {
  const ShellPlaceholderPage({
    super.key,
    required this.titleEn,
    required this.hintEn,
  });

  final String titleEn;
  final String hintEn;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 48.sp,
                color: AppColors.dashboardPrimary.withValues(alpha: 0.45),
              ),
              SizedBox(height: 16.h),
              Text(
                titleEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                hintEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
