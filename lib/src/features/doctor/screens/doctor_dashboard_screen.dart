import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_dashboard_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_queue_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_shell_tab_controller.dart';
import 'package:doctor_app/src/features/doctor/screens/metrics/doctor_earnings_today_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/metrics/doctor_emergency_queue_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/metrics/doctor_patients_seen_today_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/metrics/doctor_prescriptions_today_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_dashboard_widgets.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;
    final controller = context.watch<DoctorDashboardController>();
    final queue = context.watch<DoctorQueueController>();
    final stats = controller.stats;
    final emergencyCount = queue.emergencyCount;

    Future<void> refresh() async {
      final s = context.read<SessionController>().state;
      await Future.wait([
        controller.refreshFromSession(s),
        context.read<DoctorQueueController>().refreshFromSession(s),
      ]);
    }

    void openPatientsTab() {
      context.read<DoctorShellTabController>().selectTab(
            DoctorShellTabController.patientsTab,
          );
    }

    return ColoredBox(
      color: AppColors.dashboardBackground,
      child: RefreshIndicator(
          color: AppColors.dashboardPrimary,
          onRefresh: refresh,
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
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimaryDark,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          session.hospitalName?.trim().isNotEmpty == true
                              ? session.hospitalName!
                              : 'Today\'s overview',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<DoctorShellTabController>().selectTab(
                            DoctorShellTabController.profileTab,
                          );
                    },
                    icon: Icon(
                      CupertinoIcons.person_crop_circle,
                      color: AppColors.dashboardPrimary,
                      size: 24.sp,
                    ),
                    tooltip: 'Profile',
                  ),
                ],
              ),
              if (session.doctorSpeciality?.trim().isNotEmpty == true) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    session.doctorSpeciality!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dashboardPrimary,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              if (controller.loading && stats == null)
                Padding(
                  padding: EdgeInsets.only(top: 60.h),
                  child: const Center(child: CupertinoActivityIndicator()),
                )
              else if (controller.error != null && stats == null)
                _ErrorCard(
                  message: controller.error!,
                  onRetry: () => controller.refreshFromSession(
                    context.read<SessionController>().state,
                  ),
                )
              else ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 1.05,
                  children: [
                    DoctorMetricCard(
                      title: 'Emergency queue',
                      value: '$emergencyCount',
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      accent: AppColors.danger,
                      onTap: () => context.push(
                        DoctorEmergencyQueueDetailScreen.routePath,
                      ),
                    ),
                    DoctorMetricCard(
                      title: 'Patients seen today',
                      value: '${stats?.patientsSeenToday ?? 0}',
                      icon: CupertinoIcons.person_2_fill,
                      onTap: () => context.push(
                        DoctorPatientsSeenTodayScreen.routePath,
                      ),
                    ),
                    DoctorMetricCard(
                      title: 'Earnings today',
                      value: (stats?.earningsToday ?? 0).toStringAsFixed(0),
                      icon: CupertinoIcons.money_dollar_circle_fill,
                      accent: AppColors.success,
                      onTap: () => context.push(
                        DoctorEarningsTodayScreen.routePath,
                      ),
                    ),
                    DoctorMetricCard(
                      title: 'Prescriptions today',
                      value: '${stats?.prescriptionsWrittenToday ?? 0}',
                      icon: CupertinoIcons.doc_text_fill,
                      onTap: () => context.push(
                        DoctorPrescriptionsTodayScreen.routePath,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                DoctorDashboardQueuePreview(
                  patients: queue.patients,
                  loading: queue.loading,
                  onViewAll: openPatientsTab,
                ),
              ],
              if (session.pmdcNumber?.trim().isNotEmpty == true) ...[
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: AppColors.dashboardPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'PMDC: ${session.pmdcNumber}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 32.sp,
            color: AppColors.danger,
          ),
          SizedBox(height: 10.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
