import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';

/// Read-only prescription history for Health Workers.
class PatientPrescriptionHistoryPage extends StatefulWidget {
  const PatientPrescriptionHistoryPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<PatientPrescriptionHistoryPage> createState() =>
      _PatientPrescriptionHistoryPageState();
}

class _PatientPrescriptionHistoryPageState
    extends State<PatientPrescriptionHistoryPage> {
  bool _loading = true;
  String? _error;
  List<PatientPrescriptionHistoryItem> _items = const [];

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
      final items = await PatientApi(session.apiClient).getPrescriptionHistory(
        patientId: widget.patientId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final loc = d.toLocal();
    return '${loc.day}/${loc.month}/${loc.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: Text(
          'Prescription history',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                  child: _items.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 100.h),
                            Icon(
                              Icons.medication_liquid_outlined,
                              size: 40.sp,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No prescriptions for ${widget.patientName}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final item = _items[index];
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
                                      Expanded(
                                        child: Text(
                                          item.doctorName.isEmpty
                                              ? 'Doctor'
                                              : item.doctorName,
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _fmtDate(item.prescriptionDate),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.doctorSpecialty
                                      .trim()
                                      .isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      item.doctorSpecialty,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dashboardPrimary,
                                      ),
                                    ),
                                  ],
                                  if (item.reasonForVisit
                                      .trim()
                                      .isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    Text(
                                      item.reasonForVisit,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                  if (item.medicinesDetailString
                                      .trim()
                                      .isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    Text(
                                      item.medicinesDetailString,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (item.doctorNotes.trim().isNotEmpty) ...[
                                    SizedBox(height: 6.h),
                                    Text(
                                      item.doctorNotes,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
