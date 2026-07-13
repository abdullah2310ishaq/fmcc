import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_dashboard_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
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
    final rx = context.watch<DoctorPrescriptionsController>();
    final stats = controller.stats;
    final emergencyCount = queue.emergencyCount;
    final doctorName = session.registrationDetails.fullName.trim();
    final hospital = session.hospitalName?.trim() ?? '';
    final specialty = session.doctorSpeciality?.trim() ?? '';

    Future<void> refresh() async {
      final s = context.read<SessionController>().state;
      await Future.wait([
        controller.refreshFromSession(s),
        context.read<DoctorQueueController>().refreshFromSession(s),
        context.read<DoctorPrescriptionsController>().refreshFromSession(s),
      ]);
    }

    void openTab(int tab) {
      context.read<DoctorShellTabController>().selectTab(tab);
    }

    // Hero stays outside the scroll view so it never moves / never overflows
    // a fixed SliverPersistentHeader height.
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
            child: DoctorHomeHeroCard(
              doctorName: doctorName.isEmpty ? 'Doctor' : doctorName,
              hospitalName: hospital,
              specialty: specialty,
              onProfileTap: () => openTab(DoctorShellTabController.profileTab),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.dashboardPrimary,
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                children: [
                  if (controller.loading && stats == null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.h),
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
                    const DoctorSectionHeader(title: "Today's overview"),
                    SizedBox(height: 12.h),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 1.12,
                      children: [
                        DoctorMetricCard(
                          title: 'Emergency',
                          value: '$emergencyCount',
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          accent: AppColors.danger,
                          emphasized: true,
                          animateCount: true,
                          subtitle:
                              emergencyCount > 0 ? 'Needs attention' : 'Calm',
                          onTap: () => context.push(
                            DoctorEmergencyQueueDetailScreen.routePath,
                          ),
                        ),
                        DoctorMetricCard(
                          title: 'Patients seen',
                          value: '${stats?.patientsSeenToday ?? 0}',
                          icon: CupertinoIcons.person_2_fill,
                          animateCount: true,
                          subtitle: 'Today',
                          onTap: () => context.push(
                            DoctorPatientsSeenTodayScreen.routePath,
                          ),
                        ),
                        DoctorMetricCard(
                          title: 'Earnings',
                          value: (stats?.earningsToday ?? 0).toStringAsFixed(0),
                          icon: CupertinoIcons.money_dollar_circle_fill,
                          accent: AppColors.dashboardPrimary,
                          softMono: true,
                          subtitle: 'Today',
                          onTap: () => context.push(
                            DoctorEarningsTodayScreen.routePath,
                          ),
                        ),
                        DoctorMetricCard(
                          title: 'Prescriptions',
                          value: '${stats?.prescriptionsWrittenToday ?? 0}',
                          icon: CupertinoIcons.doc_text_fill,
                          accent: AppColors.followAccentPurple,
                          softMono: true,
                          animateCount: true,
                          subtitle: 'Today',
                          onTap: () => context.push(
                            DoctorPrescriptionsTodayScreen.routePath,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    DoctorDashboardQueuePreview(
                      patients: queue.patients,
                      loading: queue.loading,
                      onViewAll: () =>
                          openTab(DoctorShellTabController.patientsTab),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
      decoration: doctorPremiumCardDecoration(),
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
