import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/presentation/bp_reading_color.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

/// Read-only detail for one row from `GET /api/Patient/visits/{patientId}` (`PatientVisitResponseModel`).
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({
    super.key,
    required this.patientName,
    required this.visit,
  });

  final String patientName;
  final PatientVisitRow visit;

  static String _formatDateTime(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.sp,
            color: AppColors.dashboardPrimaryDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Visit details',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 32.h),
        children: [
          Text(
            patientName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Visit ID: ${visit.visitId}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          _tile('Visit date', _formatDateTime(visit.visitDate)),
          _tile('Visit type',
              visit.visitTypeName.isNotEmpty ? visit.visitTypeName : '—'),
          _tile('Follow-up visit', visit.isFollowUpVisit ? 'Yes' : 'No'),
          _tile('Status',
              visit.visitStatusName.isNotEmpty ? visit.visitStatusName : '—'),
          _tile('Action',
              visit.visitActionName.isNotEmpty ? visit.visitActionName : '—'),
          _tile(
              'Reason',
              visit.reasonForVisit.trim().isNotEmpty
                  ? visit.reasonForVisit
                  : '—'),
          if (visit.avgSystolicBp != null && visit.avgDiastolicBp != null)
            _tile(
              'Blood pressure',
              '${visit.avgSystolicBp}/${visit.avgDiastolicBp} mmHg',
              valueColor: BpReadingColor.forPair(
                visit.avgSystolicBp!,
                visit.avgDiastolicBp!,
              ),
            ),
          if (visit.pulse != null) _tile('Pulse', '${visit.pulse} bpm'),
          if (visit.medicalAdherenceNote != null &&
              visit.medicalAdherenceNote!.trim().isNotEmpty)
            _tile('Adherence note', visit.medicalAdherenceNote!),
          if (visit.nextVisitDate != null)
            _tile(
              'Next visit (planned)',
              _formatDateTime(visit.nextVisitDate!),
            ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.registrationSectionLabel,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
