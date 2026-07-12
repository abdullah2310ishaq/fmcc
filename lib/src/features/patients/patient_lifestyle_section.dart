import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Display snapshot for lifestyle read-only view.
class PatientLifestyleViewData {
  const PatientLifestyleViewData({
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
    required this.nightSleepHours,
    required this.daySleepHours,
    required this.exerciseLevelName,
    required this.highSaltDiet,
    required this.alcoholUse,
  });

  final String breakfast;
  final String lunch;
  final String snacks;
  final String dinner;
  final String nightSleepHours;
  final String daySleepHours;
  final String exerciseLevelName;
  final bool highSaltDiet;
  final bool alcoholUse;
}

/// Flat, evenly spaced lifestyle read-only layout (no cards / boxes).
class PatientLifestyleView extends StatelessWidget {
  const PatientLifestyleView({
    super.key,
    required this.data,
    this.onRecordTap,
  });

  final PatientLifestyleViewData? data;
  final VoidCallback? onRecordTap;

  static const double _labelWidth = 108;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return _LifestyleEmptyState(onRecordTap: onRecordTap);
    }

    final d = data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LifestyleSectionHeader(
          icon: Icons.restaurant_menu_rounded,
          title: 'Daily meals',
        ),
        _LifestyleFieldRow(label: 'Breakfast', value: d.breakfast),
        _LifestyleFieldRow(label: 'Lunch', value: d.lunch),
        _LifestyleFieldRow(label: 'Snacks', value: d.snacks),
        _LifestyleFieldRow(label: 'Dinner', value: d.dinner, showDivider: false),
        SizedBox(height: 18.h),
        const _LifestyleSectionHeader(
          icon: Icons.bedtime_outlined,
          title: 'Sleep',
        ),
        _LifestyleFieldRow(
          label: 'Night sleep',
          value: _hoursValue(d.nightSleepHours),
        ),
        _LifestyleFieldRow(
          label: 'Day sleep',
          value: _hoursValue(d.daySleepHours),
          showDivider: false,
        ),
        SizedBox(height: 18.h),
        const _LifestyleSectionHeader(
          icon: Icons.fitness_center_rounded,
          title: 'Activity & habits',
        ),
        _LifestyleFieldRow(
          label: 'Exercise',
          value: _dash(d.exerciseLevelName),
        ),
        _LifestyleFieldRow(
          label: 'High salt diet',
          value: d.highSaltDiet ? 'Yes' : 'No',
          valueColor: d.highSaltDiet
              ? AppColors.dashboardWarning
              : AppColors.followAccentGreen,
        ),
        _LifestyleFieldRow(
          label: 'Alcohol use',
          value: d.alcoholUse ? 'Yes' : 'No',
          valueColor: d.alcoholUse
              ? AppColors.dashboardWarning
              : AppColors.followAccentGreen,
          showDivider: false,
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.h),
      ],
    );
  }

  static String _dash(String raw) {
    final t = raw.trim();
    return t.isEmpty || t == '—' ? '—' : t;
  }

  static String _hoursValue(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t == '—') return '—';
    return '$t hrs';
  }
}

/// Lifestyle edit form UI — state stays with the parent.
class PatientLifestyleForm extends StatelessWidget {
  const PatientLifestyleForm({
    super.key,
    required this.breakfastController,
    required this.lunchController,
    required this.snacksController,
    required this.dinnerController,
    required this.nightSleepController,
    required this.daySleepController,
    required this.exerciseLevels,
    required this.exerciseLevelId,
    required this.highSaltDiet,
    required this.alcoholUse,
    required this.saving,
    required this.onExerciseChanged,
    required this.onHighSaltChanged,
    required this.onAlcoholChanged,
    required this.onSave,
    required this.fieldDecoration,
  });

  final TextEditingController breakfastController;
  final TextEditingController lunchController;
  final TextEditingController snacksController;
  final TextEditingController dinnerController;
  final TextEditingController nightSleepController;
  final TextEditingController daySleepController;
  final List<NamedReferenceItem> exerciseLevels;
  final int? exerciseLevelId;
  final bool highSaltDiet;
  final bool alcoholUse;
  final bool saving;
  final ValueChanged<int?> onExerciseChanged;
  final ValueChanged<bool> onHighSaltChanged;
  final ValueChanged<bool> onAlcoholChanged;
  final VoidCallback onSave;
  final InputDecoration Function({String? hint}) fieldDecoration;

  @override
  Widget build(BuildContext context) {
    final exerciseItems = exerciseLevels
        .where((e) => e.id > 0)
        .map(
          (e) => DropdownMenuItem<int>(
            value: e.id,
            child: Text(
              e.name,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LifestyleSectionHeader(
          icon: Icons.restaurant_menu_rounded,
          title: 'Daily meals',
        ),
        _fieldLabel('Breakfast'),
        _textField(breakfastController, hint: 'Breakfast details'),
        SizedBox(height: 14.h),
        _fieldLabel('Lunch'),
        _textField(lunchController, hint: 'Lunch details'),
        SizedBox(height: 14.h),
        _fieldLabel('Snacks'),
        _textField(snacksController, hint: 'Snacks details'),
        SizedBox(height: 14.h),
        _fieldLabel('Dinner'),
        _textField(dinnerController, hint: 'Dinner details'),
        SizedBox(height: 20.h),
        const _LifestyleSectionHeader(
          icon: Icons.bedtime_outlined,
          title: 'Sleep',
        ),
        _fieldLabel('Night sleep hours'),
        _textField(
          nightSleepController,
          hint: 'e.g. 7.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLines: 1,
        ),
        SizedBox(height: 14.h),
        _fieldLabel('Day sleep hours'),
        _textField(
          daySleepController,
          hint: 'e.g. 1',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLines: 1,
        ),
        SizedBox(height: 20.h),
        const _LifestyleSectionHeader(
          icon: Icons.fitness_center_rounded,
          title: 'Activity & habits',
        ),
        _fieldLabel('Exercise level'),
        DropdownButtonFormField<int>(
          value: exerciseItems.any((e) => e.value == exerciseLevelId)
              ? exerciseLevelId
              : null,
          decoration: fieldDecoration(),
          items: exerciseItems,
          onChanged: onExerciseChanged,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            'High salt diet',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          value: highSaltDiet,
          onChanged: (v) => onHighSaltChanged(v ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            'Alcohol use',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          value: alcoholUse,
          onChanged: (v) => onAlcoholChanged(v ?? false),
        ),
        SizedBox(height: 8.h),
        FilledButton(
          onPressed: saving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.registrationSaveBlue,
            foregroundColor: AppColors.surface,
            minimumSize: Size(double.infinity, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            saving ? 'Saving…' : 'Save Lifestyle',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.dashboardPrimaryDark,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 2,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      decoration: fieldDecoration(hint: hint),
    );
  }
}

class _LifestyleSectionHeader extends StatelessWidget {
  const _LifestyleSectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 17.sp, color: AppColors.dashboardPrimary),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifestyleFieldRow extends StatelessWidget {
  const _LifestyleFieldRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty || value.trim() == '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: PatientLifestyleView._labelWidth.w,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppColors.registrationSectionLabel,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  empty ? '—' : value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: valueColor ??
                        (empty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withValues(alpha: 0.9),
          ),
      ],
    );
  }
}

class _LifestyleEmptyState extends StatelessWidget {
  const _LifestyleEmptyState({this.onRecordTap});

  final VoidCallback? onRecordTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 28.h),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 34.sp,
            color: AppColors.dashboardPrimary.withValues(alpha: 0.55),
          ),
          SizedBox(height: 12.h),
          Text(
            'No lifestyle details recorded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (onRecordTap != null) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onRecordTap,
              child: Text(
                'Record lifestyle',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dashboardPrimary,
                ),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
        ],
      ),
    );
  }
}
