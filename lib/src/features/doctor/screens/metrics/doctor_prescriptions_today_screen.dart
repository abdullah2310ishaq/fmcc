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
import 'package:doctor_app/src/features/doctor/screens/edit_prescription_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_metric_scaffold.dart';

class DoctorPrescriptionsTodayScreen extends StatefulWidget {
  const DoctorPrescriptionsTodayScreen({super.key});

  static const routePath = '/doctor/metrics/prescriptions-today';

  @override
  State<DoctorPrescriptionsTodayScreen> createState() =>
      _DoctorPrescriptionsTodayScreenState();
}

class _DoctorPrescriptionsTodayScreenState
    extends State<DoctorPrescriptionsTodayScreen> {
  bool _loading = true;
  String? _error;
  List<DoctorPrescriptionSummary> _today = const [];

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
      final all = await DoctorApi(session.apiClient).getDoctorPrescriptions(
        doctorId: doctorId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _today = all.where((r) => _isToday(r.prescriptionDate)).toList();
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

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final loc = d.toLocal();
    return '${loc.day}/${loc.month}/${loc.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DoctorMetricDetailScaffold(
      title: 'Prescriptions today',
      subtitle: '${_today.length} written today',
      icon: CupertinoIcons.doc_text_fill,
      accent: AppColors.dashboardPrimary,
      onBack: () => context.pop(),
      loading: _loading,
      onRefresh: _load,
      body: _error != null
          ? DoctorMetricEmptyState(message: _error!)
          : _today.isEmpty
              ? const DoctorMetricEmptyState(
                  message: 'No prescriptions written today yet.',
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  itemCount: _today.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final item = _today[index];
                    return Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      child: InkWell(
                        onTap: () => context.push(
                          EditPrescriptionScreen.routePath,
                          extra: {
                            'prescriptionId': item.prescriptionId,
                            'visitId': item.visitId,
                            'patientId': '',
                            'patientName': item.patientName,
                            'initialNotes': item.doctorNotes,
                          },
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.patientName.isEmpty
                                    ? 'Patient'
                                    : item.patientName,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dashboardPrimaryDark,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${_fmtDate(item.prescriptionDate)} · #${item.patientNumber} · ${GenderLabel.format(item.patientGender)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (item.prescribedMedicinesString
                                  .trim()
                                  .isNotEmpty) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  item.prescribedMedicinesString,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
