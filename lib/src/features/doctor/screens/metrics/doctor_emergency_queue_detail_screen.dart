import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_metric_scaffold.dart';

class DoctorEmergencyQueueDetailScreen extends StatefulWidget {
  const DoctorEmergencyQueueDetailScreen({super.key});

  static const routePath = '/doctor/metrics/emergency-queue';

  @override
  State<DoctorEmergencyQueueDetailScreen> createState() =>
      _DoctorEmergencyQueueDetailScreenState();
}

class _DoctorEmergencyQueueDetailScreenState
    extends State<DoctorEmergencyQueueDetailScreen> {
  bool _loading = true;
  String? _error;
  List<DoctorQueuePatient> _patients = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      final patients = await DoctorApi(session.apiClient).getEmergencyQueue(
        doctorId: doctorId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _patients = patients.where((p) => p.isEmergency).toList();
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
    return DoctorMetricDetailScaffold(
      title: 'Emergency queue',
      subtitle: '${_patients.length} priority patients',
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      accent: AppColors.danger,
      onBack: () => context.pop(),
      loading: _loading,
      onRefresh: _load,
      body: _error != null
          ? DoctorMetricEmptyState(message: _error!)
          : _patients.isEmpty
              ? const DoctorMetricEmptyState(
                  message: 'No emergency patients in your queue right now.',
                  icon: CupertinoIcons.checkmark_seal_fill,
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  itemCount: _patients.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final p = _patients[index];
                    return DoctorAssignedPatientCard(
                      fullName: p.fullName,
                      firstName: p.firstName,
                      lastName: p.lastName,
                      patientNumber: p.patientNumber,
                      visitActionId: p.visitActionId,
                      onTap: () => context.push(
                        DoctorPatientDetailScreen.routePath,
                        extra: {
                          'patientId': p.patientId,
                          'visitId': p.visitId,
                          'patientNumber': p.patientNumber,
                          'fullName': p.fullName,
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
