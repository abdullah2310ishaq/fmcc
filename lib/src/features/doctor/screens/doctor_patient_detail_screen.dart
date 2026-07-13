import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/screens/create_prescription_screen.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  const DoctorPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.visitId,
    required this.patientNumber,
    required this.fullName,
  });

  static const routePath = '/doctor/patient';

  final String patientId;
  final String visitId;
  final int patientNumber;
  final String fullName;

  @override
  State<DoctorPatientDetailScreen> createState() =>
      _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  bool _loading = true;
  String? _error;
  PatientProfileData? _profile;
  PatientCompleteHistoryData? _history;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Unauthorized. Please sign in again.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = PatientApi(session.apiClient);
      final profile = await api.getPatientProfile(
        patientId: widget.patientId,
        bearerToken: token,
      );
      PatientCompleteHistoryData? history;
      try {
        history = await api.getCompleteHistory(
          patientId: widget.patientId,
          bearerToken: token,
        );
      } catch (_) {
        history = null;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _history = history;
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
  Widget build(BuildContext context) {
    final name = _profile != null
        ? '${_profile!.firstName} ${_profile!.lastName}'.trim()
        : widget.fullName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, size: 22.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Patient details',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  CreatePrescriptionScreen.routePath,
                  extra: {
                    'patientId': widget.patientId,
                    'visitId': widget.visitId,
                    'patientName': name,
                  },
                );
              },
              backgroundColor: AppColors.dashboardPrimary,
              icon: Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 18.sp),
              label: const Text('Prescribe'),
            ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: AppColors.danger,
                          size: 36.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                    children: [
                      _InfoCard(
                        title: name.isEmpty ? 'Patient' : name,
                        subtitle: 'Patient #${_profile?.patientNumber ?? widget.patientNumber}',
                        rows: [
                          if (_profile != null) ...[
                            _row('Gender', _profile!.gender),
                            _row('CNIC', _profile!.cnic),
                            _row('Contact', _profile!.contactNumber),
                            _row('Address', _profile!.address),
                          ],
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _HistorySection(
                        title: 'Medical history',
                        icon: CupertinoIcons.heart,
                        empty: _history?.medical.isEmpty != false,
                        children: [
                          for (final row in _history?.medical ?? const [])
                            _bullet(
                              '${row.conditionName.isNotEmpty ? row.conditionName : 'Condition'}'
                              '${row.isOnMedication ? ' · on medication' : ''}',
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _HistorySection(
                        title: 'Surgical history',
                        icon: CupertinoIcons.bandage,
                        empty: _history?.surgical.isEmpty != false,
                        children: [
                          for (final row in _history?.surgical ?? const [])
                            _bullet(
                              row.procedureName.isNotEmpty
                                  ? row.procedureName
                                  : 'Procedure',
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _HistorySection(
                        title: 'Drug history',
                        icon: CupertinoIcons.capsule,
                        empty: _history?.drugs.isEmpty != false,
                        children: [
                          for (final row in _history?.drugs ?? const [])
                            _bullet(
                              row.categoryName.isNotEmpty
                                  ? row.categoryName
                                  : 'Medication',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  static MapEntry<String, String> _row(String k, String v) => MapEntry(k, v);

  static Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: AppColors.dashboardPrimary)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          if (rows.isNotEmpty) ...[
            SizedBox(height: 12.h),
            for (final r in rows)
              if (r.value.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72.w,
                        child: Text(
                          r.key,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.value,
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
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.icon,
    required this.empty,
    required this.children,
  });

  final String title;
  final IconData icon;
  final bool empty;
  final List<Widget> children;

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
          Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColors.dashboardPrimary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (empty)
            Text(
              'No records',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            )
          else
            ...children,
        ],
      ),
    );
  }
}
