import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_metric_scaffold.dart';

class DoctorEarningsTodayScreen extends StatefulWidget {
  const DoctorEarningsTodayScreen({super.key});

  static const routePath = '/doctor/metrics/earnings';

  @override
  State<DoctorEarningsTodayScreen> createState() =>
      _DoctorEarningsTodayScreenState();
}

class _DoctorEarningsTodayScreenState extends State<DoctorEarningsTodayScreen> {
  bool _loading = true;
  String? _error;
  double _earnings = 0;
  int _prescriptionsToday = 0;
  int _patientsSeen = 0;

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    final doctorId = session.state.doctorIdForApis;
    if (token == null || token.isEmpty || doctorId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please sign in again.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await DoctorApi(session.apiClient).getDashboard(
        doctorId: doctorId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _earnings = stats.earningsToday;
        _prescriptionsToday = stats.prescriptionsWrittenToday;
        _patientsSeen = stats.patientsSeenToday;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = session.apiClient.mapError(e).message;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return DoctorMetricDetailScaffold(
      title: 'Earnings today',
      subtitle: 'Your revenue summary',
      icon: CupertinoIcons.money_dollar_circle_fill,
      accent: AppColors.success,
      onBack: () => context.pop(),
      loading: _loading,
      onRefresh: _load,
      body: _error != null
          ? DoctorMetricEmptyState(message: _error!)
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DoctorMetricHeroStat(
                  value: _earnings.toStringAsFixed(0),
                  label: 'Total earnings today',
                  accent: AppColors.success,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
                  child: Text(
                    'Breakdown',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
                _BreakdownRow(
                  icon: CupertinoIcons.doc_text_fill,
                  label: 'Prescriptions written',
                  value: '$_prescriptionsToday',
                ),
                _BreakdownRow(
                  icon: CupertinoIcons.person_2_fill,
                  label: 'Patients seen',
                  value: '$_patientsSeen',
                ),
                _BreakdownRow(
                  icon: CupertinoIcons.money_dollar,
                  label: 'Average per prescription',
                  value: _prescriptionsToday > 0
                      ? (_earnings / _prescriptionsToday).toStringAsFixed(0)
                      : '—',
                ),
                SizedBox(height: 24.h),
              ],
            ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.success),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
