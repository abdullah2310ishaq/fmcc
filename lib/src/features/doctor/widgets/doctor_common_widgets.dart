import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

class DoctorMetricCard extends StatelessWidget {
  const DoctorMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accent = AppColors.dashboardPrimary,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22.sp),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class VisitActionBadge extends StatelessWidget {
  const VisitActionBadge({super.key, required this.visitActionId});

  final int visitActionId;

  @override
  Widget build(BuildContext context) {
    final isEmergency = visitActionId == 4;
    final isNormal = visitActionId == 3;
    final label = isEmergency
        ? 'Emergency'
        : isNormal
            ? 'Normal'
            : 'Visit';
    final bg = isEmergency
        ? const Color(0xFFFFEBEE)
        : isNormal
            ? const Color(0xFFE8F5E9)
            : AppColors.dashboardChipBlueBg;
    final fg = isEmergency
        ? AppColors.danger
        : isNormal
            ? AppColors.success
            : AppColors.dashboardPrimary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmergency
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.checkmark_seal_fill,
            size: 12.sp,
            color: fg,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorQueueTile extends StatelessWidget {
  const DoctorQueueTile({
    super.key,
    required this.fullName,
    required this.patientNumber,
    required this.visitActionId,
    required this.onTap,
  });

  final String fullName;
  final int patientNumber;
  final int visitActionId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.dashboardChipBlueBg,
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: AppColors.dashboardPrimary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Patient #$patientNumber',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              VisitActionBadge(visitActionId: visitActionId),
              SizedBox(width: 6.w),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
