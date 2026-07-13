import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_screen_header.dart';
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
    return DoctorTopInset(
      child: DoctorScreenHeader(
        includeTopInset: false,
        title: title,
        subtitle: patientName,
        onBack: onBack,
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
            onChanged: (v) {
              form.tenureInDays = v;
              form.markDirty();
            },
          ),
          SizedBox(height: 16.h),
          PrescriptionFormField(
            label: 'Doctor notes',
            hint: 'Clinical notes for this prescription',
            icon: CupertinoIcons.text_alignleft,
            initialValue: form.doctorNotes,
            maxLines: 4,
            onChanged: (v) {
              form.doctorNotes = v;
              form.markDirty();
            },
          ),
        ],
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

  Future<void> _openMedicinePicker(BuildContext context) async {
    final result = await showModalBottomSheet<_MedicinePickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => _MedicinePickerSheet(
        medicines: form.activeMedicines,
        loading: form.loadingMedicines,
        loadError: form.medicinesLoadError,
      ),
    );
    if (result == null) return;
    if (result.isOther) {
      form.selectOtherMedicine(index);
    } else if (result.medicine != null) {
      form.selectMedicine(index, result.medicine!);
    }
  }

  String get _medicineDisplayLabel {
    final m = form.medicines[index];
    if (m.useCustomName) return 'Other (custom name)';
    if (m.medicineId > 0 && m.customMedicineName.trim().isNotEmpty) {
      return m.customMedicineName;
    }
    if (m.customMedicineName.trim().isNotEmpty) return m.customMedicineName;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final m = form.medicines[index];
    final selectedLabel = _medicineDisplayLabel;

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
          Text(
            'Medicine name',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          FormField<String>(
            initialValue: selectedLabel,
            validator: (_) {
              if (m.useCustomName) {
                return m.customMedicineName.trim().isEmpty ? 'Required' : null;
              }
              if (m.medicineId <= 0 && m.customMedicineName.trim().isEmpty) {
                return 'Select a medicine';
              }
              return null;
            },
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: form.loadingMedicines
                        ? null
                        : () => _openMedicinePicker(context),
                    borderRadius: BorderRadius.circular(12.r),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        hintText: form.loadingMedicines
                            ? 'Loading medicines…'
                            : 'Select medicine',
                        prefixIcon: Icon(
                          CupertinoIcons.capsule,
                          size: 18.sp,
                          color: AppColors.dashboardPrimary,
                        ),
                        suffixIcon: form.loadingMedicines
                            ? Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SizedBox(
                                  width: 16.r,
                                  height: 16.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Icon(
                                CupertinoIcons.chevron_down,
                                size: 16.sp,
                                color: AppColors.textSecondary,
                              ),
                        filled: true,
                        fillColor: AppColors.surface,
                        errorText: state.errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.registrationFieldBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.dashboardPrimary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                      ),
                      child: Text(
                        selectedLabel.isEmpty
                            ? (form.loadingMedicines
                                ? 'Loading medicines…'
                                : 'Select medicine')
                            : selectedLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: selectedLabel.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (form.medicinesLoadError != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      form.medicinesLoadError!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (m.useCustomName) ...[
            SizedBox(height: 14.h),
            PrescriptionFormField(
              key: ValueKey('custom-med-$index'),
              label: 'Custom medicine name',
              hint: 'Type medicine name',
              icon: CupertinoIcons.pencil,
              initialValue: m.customMedicineName,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (v) => form.setCustomMedicineName(index, v),
            ),
          ],
          SizedBox(height: 14.h),
          PrescriptionFormField(
            label: 'Dosage',
            hint: 'e.g. 500mg',
            icon: CupertinoIcons.drop_fill,
            initialValue: m.dosageAmount,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) {
              m.dosageAmount = v;
              form.markDirty();
            },
          ),
          SizedBox(height: 14.h),
          PrescriptionFormField(
            label: 'Frequency',
            hint: 'e.g. 1-0-1',
            icon: CupertinoIcons.clock_fill,
            initialValue: m.frequency,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) {
              m.frequency = v;
              form.markDirty();
            },
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
            onChanged: (v) {
              m.durationInDays = v;
              form.markDirty();
            },
          ),
        ],
      ),
    );
  }
}

class _MedicinePickResult {
  const _MedicinePickResult.other()
      : isOther = true,
        medicine = null;

  const _MedicinePickResult.medicine(this.medicine) : isOther = false;

  final bool isOther;
  final ActiveMedicine? medicine;
}

class _MedicinePickerSheet extends StatefulWidget {
  const _MedicinePickerSheet({
    required this.medicines,
    required this.loading,
    this.loadError,
  });

  final List<ActiveMedicine> medicines;
  final bool loading;
  final String? loadError;

  @override
  State<_MedicinePickerSheet> createState() => _MedicinePickerSheetState();
}

class _MedicinePickerSheetState extends State<_MedicinePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ActiveMedicine> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.medicines;
    return widget.medicines
        .where(
          (m) =>
              m.medicineName.toLowerCase().contains(q) ||
              m.categoryName.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.registrationFieldBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Select medicine',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search medicine…',
                      prefixIcon: const Icon(CupertinoIcons.search),
                      filled: true,
                      fillColor: AppColors.dashboardChipBlueBg.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.pencil_ellipsis_rectangle,
                color: AppColors.dashboardPrimary,
              ),
              title: Text(
                'Other',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
              subtitle: Text(
                'Type a custom medicine name',
                style: TextStyle(fontSize: 12.sp),
              ),
              onTap: () =>
                  Navigator.pop(context, const _MedicinePickResult.other()),
            ),
            Divider(height: 1.h, color: AppColors.registrationFieldBorder),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.loadError != null && widget.medicines.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Text(
                              widget.loadError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No medicines found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.sp,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1.h,
                                color: AppColors.registrationFieldBorder
                                    .withValues(alpha: 0.6),
                              ),
                              itemBuilder: (ctx, i) {
                                final med = filtered[i];
                                return ListTile(
                                  title: Text(
                                    med.medicineName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: med.categoryName.trim().isEmpty
                                      ? null
                                      : Text(
                                          med.categoryName,
                                          style: TextStyle(fontSize: 12.sp),
                                        ),
                                  onTap: () => Navigator.pop(
                                    context,
                                    _MedicinePickResult.medicine(med),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
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
