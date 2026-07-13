import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/core/theme/app_gradients.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';

class DoctorMetricDetailScaffold extends StatelessWidget {
  const DoctorMetricDetailScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onBack,
    required this.body,
    this.loading = false,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onBack;
  final Widget body;
  final bool loading;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final top = DoctorInsets.top(context);

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.header,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28.r),
                bottomRight: Radius.circular(28.r),
              ),
              border: Border.all(color: AppColors.registrationFieldBorder),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, top + 4.h, 16.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      CupertinoIcons.back,
                      color: AppColors.dashboardPrimaryDark,
                      size: 24.sp,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.registrationFieldBorder,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.dashboardPrimary,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dashboardPrimaryDark,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : onRefresh == null
                      ? body
                      : RefreshIndicator(
                          color: AppColors.dashboardPrimary,
                          onRefresh: onRefresh!,
                          child: body,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorMetricHeroStat extends StatelessWidget {
  const DoctorMetricHeroStat({
    super.key,
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w900,
              color: accent,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorMetricEmptyState extends StatelessWidget {
  const DoctorMetricEmptyState({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.tray,
    this.scrollable = true,
  });

  final String message;
  final IconData icon;

  /// When nested inside another scroll view, set to `false`.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: scrollable ? 48.h : 24.h),
        Icon(icon, size: 40.sp, color: AppColors.textSecondary),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        if (!scrollable) SizedBox(height: 24.h),
      ],
    );

    if (!scrollable) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
