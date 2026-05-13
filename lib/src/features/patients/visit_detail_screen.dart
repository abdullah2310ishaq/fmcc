import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/presentation/bp_reading_color.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

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

  static String _dashIfEmpty(String s) {
    final t = s.trim();
    return t.isEmpty ? '—' : t;
  }

  @override
  Widget build(BuildContext context) {
    final sys = visit.avgSystolicBp;
    final dia = visit.avgDiastolicBp;
    final bpPairColor = (sys != null && dia != null)
        ? BpReadingColor.forPair(sys, dia)
        : AppColors.textPrimary;
    final pulseColor = visit.pulse != null
        ? BpReadingColor.forPulse(visit.pulse!)
        : AppColors.textPrimary;

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
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 32.h),
        children: [
          _patientHeaderStrip(),
          SizedBox(height: 18.h),
          _sectionTitle('VISIT'),
          _sectionCard(
            children: [
              _readRow('Visit date', _formatDateTime(visit.visitDate)),
              _readRow(
                'Visit type',
                _dashIfEmpty(visit.visitTypeName),
              ),
              _readRow(
                'Follow-up visit',
                visit.isFollowUpVisit ? 'Yes' : 'No',
              ),
              _readRow(
                'Status',
                _dashIfEmpty(visit.visitStatusName),
              ),
              _readRow(
                'Action',
                _dashIfEmpty(visit.visitActionName),
              ),
              _readRow(
                'Reason for visit',
                _dashIfEmpty(visit.reasonForVisit),
                multiline: true,
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _sectionTitle('VITALS (VISIT RECORD)'),
          _sectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _vitalReadout(
                    label: 'Systolic',
                    unit: 'mmHg',
                    valueText: sys != null ? '$sys' : '—',
                    valueColor: bpPairColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _vitalReadout(
                    label: 'Diastolic',
                    unit: 'mmHg',
                    valueText: dia != null ? '$dia' : '—',
                    valueColor: bpPairColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _vitalReadout(
                    label: 'Pulse',
                    unit: 'bpm',
                    valueText: visit.pulse != null ? '${visit.pulse}' : '—',
                    valueColor: pulseColor,
                  ),
                ),
              ],
            ),
          ),
          if (visit.medicalAdherenceNote != null &&
              visit.medicalAdherenceNote!.trim().isNotEmpty) ...[
            SizedBox(height: 18.h),
            _sectionTitle('NOTES'),
            _sectionCard(
              children: [
                _readRow(
                  'Medical adherence note',
                  visit.medicalAdherenceNote!.trim(),
                  multiline: true,
                ),
              ],
            ),
          ],
          if (visit.nextVisitDate != null) ...[
            SizedBox(height: 18.h),
            _sectionTitle('NEXT VISIT'),
            _sectionCard(
              children: [
                _readRow(
                  'Planned date',
                  _formatDateTime(visit.nextVisitDate!),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          _sectionCard(
            children: [
              _readRow('Visit ID', visit.visitId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientHeaderStrip() {
    final initials = NameInitials.fromFullName(patientName);
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: const BoxDecoration(
        color: AppColors.dashboardChipBlueBg,
        border: Border(
          top: BorderSide(color: AppColors.registrationFieldBorder),
          bottom: BorderSide(color: AppColors.registrationFieldBorder),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.dashboardPrimary,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.surface,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Saved visit · read-only',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 2.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: AppColors.registrationSectionLabel,
        ),
      ),
    );
  }

  Widget _sectionCard({Widget? child, List<Widget>? children}) {
    assert(
      (child == null) != (children == null),
      'Pass either child or children',
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withRowDividers(children!),
          ),
    );
  }

  List<Widget> _withRowDividers(List<Widget> rows) {
    if (rows.isEmpty) return rows;
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i < rows.length - 1) {
        out.add(SizedBox(height: 12.h));
        out.add(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.registrationFieldBorder.withValues(alpha: 0.65),
          ),
        );
        out.add(SizedBox(height: 12.h));
      }
    }
    return out;
  }

  /// Same shell as filled fields on visit assessment ([_fieldDecoration] look).
  Widget _vitalReadout({
    required String label,
    required String unit,
    required String valueText,
    Color? valueColor,
  }) {
    final radius = BorderRadius.circular(12.r);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: AppColors.registrationFieldFill,
        borderRadius: radius,
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.registrationSectionLabel,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            valueText,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            unit,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.registrationSectionLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readRow(
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
            color: AppColors.registrationSectionLabel,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: multiline ? 1.4 : 1.25,
          ),
        ),
      ],
    );
  }
}