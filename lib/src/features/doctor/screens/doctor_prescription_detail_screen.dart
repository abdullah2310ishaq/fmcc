import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/edit_prescription_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_screen_header.dart';

class DoctorPrescriptionDetailScreen extends StatelessWidget {
  const DoctorPrescriptionDetailScreen({super.key, required this.item});

  static const routePath = '/doctor/prescription/detail';

  final DoctorPrescriptionSummary item;

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final loc = d.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${loc.day} ${months[loc.month - 1]} ${loc.year}';
  }

  List<String> _medicineLines() {
    final raw = item.prescribedMedicinesString.trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[\n;|]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _openEdit(BuildContext context) async {
    final updated = await context.push<bool>(
      EditPrescriptionScreen.routePath,
      extra: {
        'prescriptionId': item.prescriptionId,
        'visitId': item.visitId,
        'patientId': '',
        'patientName': item.patientName,
        'initialNotes': item.doctorNotes,
        'medicinesString': item.prescribedMedicinesString,
      },
    );
    if (updated == true && context.mounted) {
      await context.read<DoctorPrescriptionsController>().refreshFromSession(
            context.read<SessionController>().state,
          );
      if (context.mounted) context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        item.patientName.trim().isEmpty ? 'Patient' : item.patientName.trim();
    final medicines = _medicineLines();

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Column(
        children: [
          _DetailHeader(
            name: name,
            dateLabel: _fmtDate(item.prescriptionDate),
            patientNumber: item.patientNumber,
            gender: GenderLabel.format(item.patientGender),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                if (item.reasonForVisit.trim().isNotEmpty)
                  _DetailSection(
                    title: 'Reason for visit',
                    icon: CupertinoIcons.heart_fill,
                    accent: AppColors.danger,
                    child: Text(
                      item.reasonForVisit,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                if (item.reasonForVisit.trim().isNotEmpty) SizedBox(height: 14.h),
                _DetailSection(
                  title: 'Medicines',
                  icon: CupertinoIcons.capsule_fill,
                  accent: AppColors.followAccentPurple,
                  child: medicines.isEmpty
                      ? Text(
                          'No medicines listed.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < medicines.length; i++) ...[
                              if (i > 0) SizedBox(height: 10.h),
                              _MedicineLineCard(
                                index: i + 1,
                                text: medicines[i],
                              ),
                            ],
                          ],
                        ),
                ),
                SizedBox(height: 14.h),
                _DetailSection(
                  title: 'Doctor notes',
                  icon: CupertinoIcons.doc_text_fill,
                  accent: AppColors.dashboardPrimary,
                  child: Text(
                    item.doctorNotes.trim().isEmpty
                        ? 'No clinical notes recorded.'
                        : item.doctorNotes,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: item.doctorNotes.trim().isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      height: 1.5,
                      fontStyle: item.doctorNotes.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                _DetailSection(
                  title: 'Visit reference',
                  icon: CupertinoIcons.link,
                  accent: AppColors.textSecondary,
                  child: Text(
                    'Visit ID: ${item.visitId.isEmpty ? '—' : item.visitId}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DoctorBottomInset(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openEdit(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dashboardPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: Icon(CupertinoIcons.pencil, size: 18.sp),
                  label: Text(
                    'Edit prescription',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.name,
    required this.dateLabel,
    required this.patientNumber,
    required this.gender,
    required this.onBack,
  });

  final String name;
  final String dateLabel;
  final int patientNumber;
  final String gender;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DoctorTopInset(
      child: DoctorScreenHeader(
        includeTopInset: false,
        title: name,
        subtitle: '#$patientNumber · $gender · $dateLabel',
        onBack: onBack,
        leading: Container(
          width: 52.r,
          height: 52.r,
          decoration: BoxDecoration(
            color: AppColors.dashboardChipBlueBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            NameInitials.fromFullName(name),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: accent),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dashboardPrimaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _MedicineLineCard extends StatelessWidget {
  const _MedicineLineCard({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.dashboardChipBlueBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.r,
            height: 24.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.followAccentPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.followAccentPurple,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
