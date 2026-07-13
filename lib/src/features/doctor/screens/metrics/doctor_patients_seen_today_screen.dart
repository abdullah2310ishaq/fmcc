import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_metric_scaffold.dart';

class DoctorPatientsSeenTodayScreen extends StatefulWidget {
  const DoctorPatientsSeenTodayScreen({super.key});

  static const routePath = '/doctor/metrics/patients-seen';

  @override
  State<DoctorPatientsSeenTodayScreen> createState() =>
      _DoctorPatientsSeenTodayScreenState();
}

class _DoctorPatientsSeenTodayScreenState
    extends State<DoctorPatientsSeenTodayScreen> {
  bool _loading = true;
  String? _error;
  int _seenCount = 0;
  List<DoctorPrescriptionSummary> _todayRx = const [];

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final loc = d.toLocal();
    final now = DateTime.now();
    return loc.year == now.year &&
        loc.month == now.month &&
        loc.day == now.day;
  }

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
      final api = DoctorApi(session.apiClient);
      final stats = await api.getDashboard(
        doctorId: doctorId,
        bearerToken: token,
      );
      final rx = await api.getDoctorPrescriptions(
        doctorId: doctorId,
        bearerToken: token,
      );
      final today = rx.where((r) => _isToday(r.prescriptionDate)).toList();
      if (!mounted) return;
      setState(() {
        _seenCount = stats.patientsSeenToday;
        _todayRx = today;
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
    final uniquePatients = <String>{};
    for (final r in _todayRx) {
      final name = r.patientName.trim();
      if (name.isNotEmpty) uniquePatients.add(name);
    }

    return DoctorMetricDetailScaffold(
      title: 'Patients seen today',
      subtitle: 'Clinical activity for today',
      icon: CupertinoIcons.person_2_fill,
      accent: AppColors.dashboardPrimary,
      onBack: () => context.pop(),
      loading: _loading,
      onRefresh: _load,
      body: _error != null
          ? DoctorMetricEmptyState(message: _error!)
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DoctorMetricHeroStat(
                  value: '$_seenCount',
                  label: 'Patients seen today',
                  accent: AppColors.dashboardPrimary,
                ),
                if (_todayRx.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
                    child: Text(
                      'Today\'s prescriptions (${uniquePatients.length} patients)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                  ),
                  ..._todayRx.map(_rxTile),
                ] else
                  const DoctorMetricEmptyState(
                    message:
                        'No prescription activity recorded for today yet.',
                    scrollable: false,
                  ),
                SizedBox(height: 24.h),
              ],
            ),
    );
  }

  Widget _rxTile(DoctorPrescriptionSummary item) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.patientName.isEmpty ? 'Patient' : item.patientName,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '#${item.patientNumber} · ${GenderLabel.format(item.patientGender)}',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          if (item.reasonForVisit.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              item.reasonForVisit,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}
