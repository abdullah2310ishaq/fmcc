import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';
import 'package:doctor_app/src/features/doctor/controllers/prescription_form_controller.dart';

class PrescriptionPatientBanner extends StatelessWidget {
  const PrescriptionPatientBanner({
    super.key,
    required this.patientName,
    required this.onBack,
    this.title = 'Write prescription',
  });

  final String patientName;
  final VoidCallback onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: DoctorTopInset(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 0, 16.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_fill,
                          size: 14.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            patientName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrescriptionFormSectionCard extends StatelessWidget {
  const PrescriptionFormSectionCard({
    super.key,
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
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
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
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 17.sp, color: accent),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dashboardPrimaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          child,
        ],
      ),
    );
  }
}

class PrescriptionDetailsSection extends StatelessWidget {
  const PrescriptionDetailsSection({super.key, required this.form});

  final PrescriptionFormController form;

  @override
  Widget build(BuildContext context) {
    return PrescriptionFormSectionCard(
      title: 'Prescription details',
      icon: CupertinoIcons.doc_text_fill,
      accent: AppColors.dashboardPrimary,
      child: Column(
        children: [
          PrescriptionFormField(
            label: 'Tenure (days)',
            hint: 'e.g. 30',
            icon: CupertinoIcons.calendar,
            initialValue: form.tenureInDays,
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'Enter valid days';
              return null;
            },
            onChanged: (v) => form.tenureInDays = v,
          ),
          SizedBox(height: 16.h),
          PrescriptionFormField(
            label: 'Doctor notes',
            hint: 'Clinical notes for this prescription',
            icon: CupertinoIcons.text_alignleft,
            initialValue: form.doctorNotes,
            maxLines: 4,
            onChanged: (v) => form.doctorNotes = v,
          ),
          SizedBox(height: 16.h),
          PrescriptionFormField(
            label: 'Continued from (optional)',
            hint: 'Previous prescription ID',
            icon: CupertinoIcons.link,
            initialValue: form.continuedFromPrescriptionId,
            onChanged: (v) => form.continuedFromPrescriptionId = v,
          ),
          SizedBox(height: 16.h),
          _NextVisitPicker(form: form),
        ],
      ),
    );
  }
}

class _NextVisitPicker extends StatelessWidget {
  const _NextVisitPicker({required this.form});

  final PrescriptionFormController form;

  @override
  Widget build(BuildContext context) {
    final dateLabel = form.nextVisitDate == null
        ? 'Select next visit date (optional)'
        : 'Next visit: ${form.nextVisitDate!.toLocal().toString().split(' ').first}';

    return Material(
      color: AppColors.registrationFieldFill,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate:
                form.nextVisitDate ?? now.add(const Duration(days: 7)),
            firstDate: now,
            lastDate: now.add(const Duration(days: 365 * 2)),
          );
          if (picked != null) form.setNextVisitDate(picked);
        },
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.calendar_today,
                size: 18.sp,
                color: AppColors.dashboardPrimary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (form.nextVisitDate != null)
                IconButton(
                  onPressed: () => form.setNextVisitDate(null),
                  icon: Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 20.sp,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrescriptionMedicinesSection extends StatelessWidget {
  const PrescriptionMedicinesSection({super.key, required this.form});

  final PrescriptionFormController form;

  @override
  Widget build(BuildContext context) {
    return PrescriptionFormSectionCard(
      title: 'Medicines',
      icon: CupertinoIcons.capsule_fill,
      accent: AppColors.followAccentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add each medicine with dosage, frequency, and duration.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14.h),
          for (var i = 0; i < form.medicines.length; i++) ...[
            if (i > 0) SizedBox(height: 14.h),
            PrescriptionMedicineFormCard(
              index: i,
              form: form,
              canRemove: form.medicines.length > 1,
            ),
          ],
          SizedBox(height: 14.h),
          OutlinedButton.icon(
            onPressed: form.addMedicine,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dashboardPrimary,
              side: BorderSide(color: AppColors.dashboardPrimary.withValues(alpha: 0.4)),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            icon: Icon(CupertinoIcons.plus_circle_fill, size: 18.sp),
            label: Text(
              'Add another medicine',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class PrescriptionMedicineFormCard extends StatelessWidget {
  const PrescriptionMedicineFormCard({
    super.key,
    required this.index,
    required this.form,
    required this.canRemove,
  });

  final int index;
  final PrescriptionFormController form;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final m = form.medicines[index];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.dashboardChipBlueBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.dashboardPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Medicine ${index + 1}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: () => form.removeMedicine(index),
                  icon: Icon(
                    CupertinoIcons.trash_fill,
                    color: AppColors.danger,
                    size: 20.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          PrescriptionFormField(
            label: 'Medicine name',
            hint: 'e.g. Metformin',
            icon: CupertinoIcons.capsule,
            initialValue: m.customMedicineName,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) => m.customMedicineName = v,
          ),
          SizedBox(height: 14.h),
          PrescriptionFormField(
            label: 'Dosage',
            hint: 'e.g. 500mg',
            icon: CupertinoIcons.drop_fill,
            initialValue: m.dosageAmount,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) => m.dosageAmount = v,
          ),
          SizedBox(height: 14.h),
          PrescriptionFormField(
            label: 'Frequency',
            hint: 'e.g. 1-0-1',
            icon: CupertinoIcons.clock_fill,
            initialValue: m.frequency,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) => m.frequency = v,
          ),
          SizedBox(height: 14.h),
          PrescriptionFormField(
            label: 'Duration (days)',
            hint: 'e.g. 14',
            icon: CupertinoIcons.calendar,
            initialValue: m.durationInDays,
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'Required';
              return null;
            },
            onChanged: (v) => m.durationInDays = v,
          ),
        ],
      ),
    );
  }
}

class PrescriptionFormField extends StatelessWidget {
  const PrescriptionFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.initialValue,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? initialValue;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(icon, size: 18.sp, color: AppColors.dashboardPrimary),
            filled: true,
            fillColor: AppColors.registrationFieldFill,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.registrationFieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.registrationFieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.dashboardPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

class PrescriptionSaveBar extends StatelessWidget {
  const PrescriptionSaveBar({
    super.key,
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool submitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: DoctorBottomInset(
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: FilledButton.icon(
            onPressed: submitting ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dashboardPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: submitting
                ? SizedBox(
                    width: 18.sp,
                    height: 18.sp,
                    child: const CupertinoActivityIndicator(color: Colors.white),
                  )
                : Icon(CupertinoIcons.checkmark_seal_fill, size: 20.sp),
            label: Text(
              label,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

/// Composed form body used by create & edit screens.
class PrescriptionFormBody extends StatelessWidget {
  const PrescriptionFormBody({
    super.key,
    required this.form,
    this.errorText,
  });

  final PrescriptionFormController form;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        PrescriptionDetailsSection(form: form),
        SizedBox(height: 16.h),
        PrescriptionMedicinesSection(form: form),
        if (errorText != null) ...[
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            ),
            child: Text(
              errorText!,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
