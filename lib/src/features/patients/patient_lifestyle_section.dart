import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

enum BaselineLifestyleTab {
  tobacco,
  meals,
  sleep,
  exercises,
  habits,
}

extension BaselineLifestyleTabUi on BaselineLifestyleTab {
  String get label => switch (this) {
        BaselineLifestyleTab.tobacco => 'Tobacco',
        BaselineLifestyleTab.meals => 'Meals',
        BaselineLifestyleTab.sleep => 'Sleep',
        BaselineLifestyleTab.exercises => 'Exercises',
        BaselineLifestyleTab.habits => 'Habits',
      };
}

/// Display snapshot for baseline + patient lifestyle (read-only).
class PatientLifestyleViewData {
  const PatientLifestyleViewData({
    required this.tobaccoUse,
    this.tobaccoType = '',
    this.tobaccoQuantityPerDay = '',
    this.tobaccoDurationStart = '',
    this.tobaccoDurationEnd = '',
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

  final bool tobaccoUse;
  final String tobaccoType;
  final String tobaccoQuantityPerDay;
  final String tobaccoDurationStart;
  final String tobaccoDurationEnd;
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

/// Flat baseline + lifestyle read-only layout with filter chips.
class PatientLifestyleView extends StatefulWidget {
  const PatientLifestyleView({
    super.key,
    required this.data,
    this.onRecordTap,
  });

  final PatientLifestyleViewData? data;
  final VoidCallback? onRecordTap;

  @override
  State<PatientLifestyleView> createState() => _PatientLifestyleViewState();
}

class _PatientLifestyleViewState extends State<PatientLifestyleView> {
  BaselineLifestyleTab _tab = BaselineLifestyleTab.tobacco;

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return _LifestyleEmptyState(onRecordTap: widget.onRecordTap);
    }

    final d = widget.data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BaselineLifestyleTabBar(
          selected: _tab,
          onSelected: (t) => setState(() => _tab = t),
        ),
        SizedBox(height: 14.h),
        switch (_tab) {
          BaselineLifestyleTab.tobacco => _tobaccoView(d),
          BaselineLifestyleTab.meals => _mealsView(d),
          BaselineLifestyleTab.sleep => _sleepView(d),
          BaselineLifestyleTab.exercises => _exercisesView(d),
          BaselineLifestyleTab.habits => _habitsView(d),
        },
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.h),
      ],
    );
  }

  Widget _tobaccoView(PatientLifestyleViewData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LifestyleFieldRow(
          label: 'Tobacco use',
          value: d.tobaccoUse ? 'Yes' : 'No',
          valueColor: d.tobaccoUse
              ? AppColors.dashboardWarning
              : AppColors.followAccentGreen,
          showDivider: d.tobaccoUse,
        ),
        if (d.tobaccoUse) ...[
          _LifestyleFieldRow(
            label: 'Tobacco type',
            value: _dash(d.tobaccoType),
          ),
          _LifestyleFieldRow(
            label: 'Qty / day',
            value: _dash(d.tobaccoQuantityPerDay),
          ),
          _LifestyleFieldRow(
            label: 'Duration start',
            value: _dash(d.tobaccoDurationStart),
          ),
          _LifestyleFieldRow(
            label: 'Duration end',
            value: _dash(d.tobaccoDurationEnd),
            showDivider: false,
          ),
        ],
      ],
    );
  }

  Widget _mealsView(PatientLifestyleViewData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LifestyleFieldRow(label: 'Breakfast', value: d.breakfast),
        _LifestyleFieldRow(label: 'Lunch', value: d.lunch),
        _LifestyleFieldRow(label: 'Snacks', value: d.snacks),
        _LifestyleFieldRow(label: 'Dinner', value: d.dinner, showDivider: false),
      ],
    );
  }

  Widget _sleepView(PatientLifestyleViewData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LifestyleFieldRow(
          label: 'Night sleep',
          value: _hoursValue(d.nightSleepHours),
        ),
        _LifestyleFieldRow(
          label: 'Day sleep',
          value: _hoursValue(d.daySleepHours),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _exercisesView(PatientLifestyleViewData d) {
    return _LifestyleFieldRow(
      label: 'Exercise level',
      value: _dash(d.exerciseLevelName),
      showDivider: false,
    );
  }

  Widget _habitsView(PatientLifestyleViewData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

/// Baseline + lifestyle edit form with filter chips.
class PatientLifestyleForm extends StatefulWidget {
  const PatientLifestyleForm({
    super.key,
    required this.tobaccoUse,
    required this.onTobaccoUseChanged,
    required this.tobaccoTypeController,
    required this.tobaccoQuantityController,
    required this.tobaccoDurationStart,
    required this.tobaccoDurationEnd,
    required this.onPickTobaccoDate,
    required this.onClearTobaccoEnd,
    required this.formatDate,
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

  final bool tobaccoUse;
  final ValueChanged<bool> onTobaccoUseChanged;
  final TextEditingController tobaccoTypeController;
  final TextEditingController tobaccoQuantityController;
  final DateTime? tobaccoDurationStart;
  final DateTime? tobaccoDurationEnd;
  final Future<void> Function({required bool isStart}) onPickTobaccoDate;
  final VoidCallback? onClearTobaccoEnd;
  final String Function(DateTime?) formatDate;
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
  State<PatientLifestyleForm> createState() => _PatientLifestyleFormState();
}

class _PatientLifestyleFormState extends State<PatientLifestyleForm> {
  BaselineLifestyleTab _tab = BaselineLifestyleTab.tobacco;

  @override
  Widget build(BuildContext context) {
    final exerciseItems = widget.exerciseLevels
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
        _BaselineLifestyleTabBar(
          selected: _tab,
          onSelected: (t) => setState(() => _tab = t),
        ),
        SizedBox(height: 14.h),
        switch (_tab) {
          BaselineLifestyleTab.tobacco => _tobaccoEditBody(),
          BaselineLifestyleTab.meals => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('Breakfast'),
                _textField(widget.breakfastController, hint: 'Breakfast details'),
                SizedBox(height: 14.h),
                _fieldLabel('Lunch'),
                _textField(widget.lunchController, hint: 'Lunch details'),
                SizedBox(height: 14.h),
                _fieldLabel('Snacks'),
                _textField(widget.snacksController, hint: 'Snacks details'),
                SizedBox(height: 14.h),
                _fieldLabel('Dinner'),
                _textField(widget.dinnerController, hint: 'Dinner details'),
              ],
            ),
          BaselineLifestyleTab.sleep => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('Night sleep hours'),
                _textField(
                  widget.nightSleepController,
                  hint: 'e.g. 7.5',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  maxLines: 1,
                ),
                SizedBox(height: 14.h),
                _fieldLabel('Day sleep hours'),
                _textField(
                  widget.daySleepController,
                  hint: 'e.g. 1',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  maxLines: 1,
                ),
              ],
            ),
          BaselineLifestyleTab.exercises => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('Exercise level'),
                DropdownButtonFormField<int>(
                  value: exerciseItems
                          .any((e) => e.value == widget.exerciseLevelId)
                      ? widget.exerciseLevelId
                      : null,
                  decoration: widget.fieldDecoration(),
                  items: exerciseItems,
                  onChanged: widget.onExerciseChanged,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          BaselineLifestyleTab.habits => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'High salt diet',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                  value: widget.highSaltDiet,
                  onChanged: (v) => widget.onHighSaltChanged(v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Alcohol use',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                  value: widget.alcoholUse,
                  onChanged: (v) => widget.onAlcoholChanged(v ?? false),
                ),
              ],
            ),
        },
        SizedBox(height: 20.h),
        FilledButton(
          onPressed: widget.saving ? null : widget.onSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.registrationSaveBlue,
            foregroundColor: AppColors.surface,
            minimumSize: Size(double.infinity, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            widget.saving ? 'Saving…' : 'Save Baseline Lifestyle',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
      ],
    );
  }

  Widget _tobaccoEditBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Tobacco use',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            widget.tobaccoUse
                ? 'Add tobacco details below'
                : 'Turn on if patient uses tobacco',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          value: widget.tobaccoUse,
          onChanged: widget.onTobaccoUseChanged,
        ),
        if (widget.tobaccoUse) ...[
          SizedBox(height: 8.h),
          _fieldLabel('Tobacco type'),
          _textField(
            widget.tobaccoTypeController,
            hint: 'e.g. Cigarette, Huqqa',
            maxLines: 1,
          ),
          SizedBox(height: 14.h),
          _fieldLabel('Quantity per day'),
          _textField(
            widget.tobaccoQuantityController,
            hint: 'Optional',
            keyboardType: TextInputType.number,
            maxLines: 1,
          ),
          SizedBox(height: 14.h),
          _fieldLabel('Duration start'),
          _tobaccoDateField(
            date: widget.tobaccoDurationStart,
            hint: 'Select start date',
            onTap: () => widget.onPickTobaccoDate(isStart: true),
          ),
          SizedBox(height: 14.h),
          _fieldLabel('Duration end (optional)'),
          _tobaccoDateField(
            date: widget.tobaccoDurationEnd,
            hint: 'Select end date',
            onTap: () => widget.onPickTobaccoDate(isStart: false),
            onClear: widget.onClearTobaccoEnd,
          ),
        ],
      ],
    );
  }

  Widget _tobaccoDateField({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: widget.fieldDecoration(hint: hint),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.formatDate(date),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: date == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18.sp),
                tooltip: 'Clear',
              ),
            Icon(
              Icons.calendar_today_outlined,
              size: 18.sp,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
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
      decoration: widget.fieldDecoration(hint: hint),
    );
  }
}

class _BaselineLifestyleTabBar extends StatelessWidget {
  const _BaselineLifestyleTabBar({
    required this.selected,
    required this.onSelected,
  });

  final BaselineLifestyleTab selected;
  final ValueChanged<BaselineLifestyleTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BaselineLifestyleTab.values.map((tab) {
          final isSelected = selected == tab;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Material(
              color: isSelected
                  ? AppColors.dashboardPrimary
                  : AppColors.dashboardChipBlueBg,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(tab),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.surface
                          : AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

  static const double _labelWidth = 108;

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
                width: _labelWidth.w,
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
            Icons.spa_outlined,
            size: 34.sp,
            color: AppColors.dashboardPrimary.withValues(alpha: 0.55),
          ),
          SizedBox(height: 12.h),
          Text(
            'No baseline lifestyle recorded yet.',
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
                'Record baseline',
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
