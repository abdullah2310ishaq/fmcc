import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_dashboard_controller.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;
    final controller = context.watch<DoctorDashboardController>();
    final stats = controller.stats;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => controller.refreshFromSession(
          context.read<SessionController>().state,
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor dashboard',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        session.hospitalName?.trim().isNotEmpty == true
                            ? session.hospitalName!
                            : 'Today\'s overview',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await context.read<SessionController>().logout();
                  },
                  icon: Icon(
                    CupertinoIcons.square_arrow_right,
                    color: AppColors.danger,
                    size: 22.sp,
                  ),
                  tooltip: 'Sign out',
                ),
              ],
            ),
            if (session.doctorSpeciality?.trim().isNotEmpty == true) ...[
              SizedBox(height: 8.h),
              Text(
                session.doctorSpeciality!,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dashboardPrimary,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            if (controller.loading && stats == null)
              Padding(
                padding: EdgeInsets.only(top: 80.h),
                child: const Center(child: CupertinoActivityIndicator()),
              )
            else if (controller.error != null && stats == null)
              Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 36.sp,
                      color: AppColors.danger,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => controller.refreshFromSession(
                        context.read<SessionController>().state,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1.15,
                children: [
                  DoctorMetricCard(
                    title: 'Emergency queue',
                    value: '${stats?.emergencyQueueCount ?? 0}',
                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                    accent: AppColors.danger,
                  ),
                  DoctorMetricCard(
                    title: 'Patients seen today',
                    value: '${stats?.patientsSeenToday ?? 0}',
                    icon: CupertinoIcons.person_2_fill,
                  ),
                  DoctorMetricCard(
                    title: 'Earnings today',
                    value: (stats?.earningsToday ?? 0).toStringAsFixed(0),
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    accent: AppColors.success,
                  ),
                  DoctorMetricCard(
                    title: 'Prescriptions today',
                    value: '${stats?.prescriptionsWrittenToday ?? 0}',
                    icon: CupertinoIcons.doc_text_fill,
                  ),
                ],
              ),
            if (session.pmdcNumber?.trim().isNotEmpty == true) ...[
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: AppColors.dashboardPrimary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'PMDC: ${session.pmdcNumber}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
