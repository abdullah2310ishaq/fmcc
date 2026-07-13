import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/core/theme/app_gradients.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';

/// Branded screen header — same soft gradient as the LHW profile module.
class DoctorScreenHeader extends StatelessWidget {
  const DoctorScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
    this.includeTopInset = false,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;
  final bool includeTopInset;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final top = includeTopInset ? DoctorInsets.top(context) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        border: Border.all(color: AppColors.registrationFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, top + 10.h, 12.w, 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              Padding(
                padding: EdgeInsets.only(left: 2.w, bottom: 4.h),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onBack,
                  icon: Icon(
                    CupertinoIcons.back,
                    color: AppColors.dashboardPrimaryDark,
                    size: 22.sp,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.dashboardPrimaryDark,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (bottom != null) ...[
              SizedBox(height: 16.h),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

class DoctorHeaderRefreshButton extends StatelessWidget {
  const DoctorHeaderRefreshButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: loading
              ? SizedBox(
                  width: 20.sp,
                  height: 20.sp,
                  child: const CupertinoActivityIndicator(
                    color: AppColors.dashboardPrimary,
                  ),
                )
              : Icon(
                  CupertinoIcons.arrow_clockwise,
                  color: AppColors.dashboardPrimary,
                  size: 20.sp,
                ),
        ),
      ),
    );
  }
}

class DoctorHeaderCountBadge extends StatelessWidget {
  const DoctorHeaderCountBadge({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.dashboardPrimary, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
