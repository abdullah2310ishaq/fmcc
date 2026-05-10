import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Shell index **2** — visit workflow.
class VisitTabPage extends StatefulWidget {
  const VisitTabPage({super.key});

  @override
  State<VisitTabPage> createState() => _VisitTabPageState();
}

class _VisitPatientDemo {
  const _VisitPatientDemo({
    required this.name,
    required this.id,
    required this.age,
    required this.gender,
    required this.lastVisit,
  });

  final String name;
  final String id;
  final int age;
  final String gender;
  final String lastVisit;
}

class _VisitTabPageState extends State<VisitTabPage> {
  static const List<_VisitPatientDemo> _patients = [
    _VisitPatientDemo(
      name: 'Zainab Khan',
      id: 'LHW-2026-0041',
      age: 34,
      gender: 'Female',
      lastVisit: '03 May 2026',
    ),
    _VisitPatientDemo(
      name: 'Sajida Akhtar',
      id: 'LHW-2026-0038',
      age: 28,
      gender: 'Female',
      lastVisit: '26 Apr 2026',
    ),
    _VisitPatientDemo(
      name: 'Muhammad Arif',
      id: 'LHW-2026-0029',
      age: 52,
      gender: 'Male',
      lastVisit: '01 May 2026',
    ),
    _VisitPatientDemo(
      name: 'Rubina Fatima',
      id: 'LHW-2026-0015',
      age: 41,
      gender: 'Female',
      lastVisit: '07 May 2026',
    ),
  ];

  _VisitPatientDemo? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final patient = _selectedPatient;

    if (patient != null) {
      return _VisitAssessmentView(
        patient: patient,
        onBack: () => setState(() => _selectedPatient = null),
      );
    }

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: AppColors.registrationScreenBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 14.h),
              child: Text(
                'Select Patient for Visit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
                itemCount: _patients.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  return _VisitPatientCard(
                    patient: patient,
                    onTap: () => setState(() => _selectedPatient = patient),
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

class _VisitPatientCard extends StatelessWidget {
  const _VisitPatientCard({
    required this.patient,
    required this.onTap,
  });

  final _VisitPatientDemo patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = NameInitials.fromFullName(patient.name);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.dashboardPrimary,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.surface,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dashboardPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Patient ID: ${patient.id} • Age ${patient.age} • ${patient.gender}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Last visit: ${patient.lastVisit}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.registrationSectionLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 26.sp,
                color: AppColors.textSecondary.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _VisitStatus { completed, followUp, referred }

extension on _VisitStatus {
  String get label => switch (this) {
        _VisitStatus.completed => '✓ Completed',
        _VisitStatus.followUp => '⏱ Follow-up',
        _VisitStatus.referred => '🏥 Referred',
      };
}

class _VisitAssessmentView extends StatefulWidget {
  const _VisitAssessmentView({
    required this.patient,
    required this.onBack,
  });

  final _VisitPatientDemo patient;
  final VoidCallback onBack;

  @override
  State<_VisitAssessmentView> createState() => _VisitAssessmentViewState();
}

class _VisitAssessmentViewState extends State<_VisitAssessmentView> {
  final _formKey = GlobalKey<FormState>();
  final _bloodPressureController = TextEditingController(text: '120/80');
  final _temperatureController = TextEditingController(text: '98.6');
  final _heartRateController = TextEditingController(text: '78');

  final Set<String> _selectedSymptoms = {'Headache', 'Fever'};
  final Set<String> _selectedMedicineCategories = {
    'Antibiotics',
    'Analgesics',
  };

  String _medicalCondition = 'Type 2 Diabetes';
  String _surgicalProcedure = 'None';
  String _physicalActivityLevel = 'Sedentary';
  String _visitAction = 'Examination & Counseling';
  _VisitStatus _visitStatus = _VisitStatus.completed;

  static const List<String> _symptoms = [
    'Headache',
    'Fever',
    'Cough',
    'Nausea',
    'Fatigue',
    'Dizziness',
    'Chest Pain',
    'Shortness of Breath',
  ];

  static const List<String> _medicalConditions = [
    'None',
    'Hypertension',
    'Type 2 Diabetes',
    'Asthma',
    'Anemia',
    'Heart Disease',
  ];

  static const List<String> _surgicalProcedures = [
    'None',
    'Appendectomy',
    'C-Section',
    'Gallbladder',
  ];

  static const List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
  ];

  static const List<String> _visitActions = [
    'Examination & Counseling',
    'Medication Review',
    'BP Monitoring',
    'Referral',
    'Health Education',
  ];

  static const List<String> _medicineCategories = [
    'Antibiotics',
    'Analgesics',
    'Antihypertensive',
    'Vitamins',
  ];

  @override
  void dispose() {
    _bloodPressureController.dispose();
    _temperatureController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    final radius = BorderRadius.circular(12.r);
    return InputDecoration(
      filled: true,
      fillColor: AppColors.registrationFieldFill,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.registrationFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: AppColors.dashboardPrimary.withValues(alpha: 0.75),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppColors.registrationSectionLabel,
            ),
          ),
          SizedBox(width: 8.w),
          CircleAvatar(
            radius: 9.r,
            backgroundColor: AppColors.dashboardChipBlueBg,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dashboardPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.dashboardPrimaryDark,
        ),
      ),
    );
  }

  Widget _vitalField({
    required String label,
    required String unit,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
      decoration: _fieldDecoration().copyWith(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.registrationSectionLabel,
        ),
        helperText: unit,
        helperStyle: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.registrationSectionLabel,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? AppColors.dashboardPrimary;
    return Material(
      color: selected
          ? activeColor.withValues(alpha: 0.08)
          : AppColors.registrationFieldFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? activeColor : AppColors.registrationFieldBorder,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: selected ? activeColor : AppColors.dashboardPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(label),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _fieldDecoration(),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _toggleSetValue(Set<String> values, String value) {
    setState(() {
      if (!values.add(value)) {
        values.remove(value);
      }
    });
  }

  void _submitVisitRecord() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Visit record submitted for ${widget.patient.name}.',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = NameInitials.fromFullName(widget.patient.name);

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: AppColors.registrationScreenBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 36.r,
                    height: 36.r,
                    child: Material(
                      color: AppColors.dashboardChipBlueBg,
                      borderRadius: BorderRadius.circular(10.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.r),
                        onTap: widget.onBack,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 17.sp,
                          color: AppColors.dashboardPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Visit Assessment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 36.w),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
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
                          widget.patient.name,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Patient ID: ${widget.patient.id} • Age ${widget.patient.age} • ${widget.patient.gender}',
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 96.h),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle('VITALS'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _vitalField(
                              label: 'Blood Pressure',
                              unit: 'mmHg',
                              controller: _bloodPressureController,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _vitalField(
                              label: 'Temperature',
                              unit: '°F',
                              controller: _temperatureController,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _vitalField(
                              label: 'Heart Rate',
                              unit: 'bpm',
                              controller: _heartRateController,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      _sectionTitle('SYMPTOMS'),
                      Wrap(
                        spacing: 9.w,
                        runSpacing: 9.h,
                        children: _symptoms
                            .map(
                              (symptom) => _chip(
                                label: symptom,
                                selected: _selectedSymptoms.contains(symptom),
                                onTap: () =>
                                    _toggleSetValue(_selectedSymptoms, symptom),
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(height: 22.h),
                      _sectionTitle('MEDICAL HISTORY'),
                      _dropdown(
                        label: 'Medical Conditions',
                        value: _medicalCondition,
                        items: _medicalConditions,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _medicalCondition = value);
                          }
                        },
                      ),
                      SizedBox(height: 14.h),
                      _dropdown(
                        label: 'Surgical Procedures',
                        value: _surgicalProcedure,
                        items: _surgicalProcedures,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _surgicalProcedure = value);
                          }
                        },
                      ),
                      SizedBox(height: 22.h),
                      _sectionTitle('LIFESTYLE'),
                      _dropdown(
                        label: 'Physical Activity Level',
                        value: _physicalActivityLevel,
                        items: _activityLevels,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _physicalActivityLevel = value);
                          }
                        },
                      ),
                      SizedBox(height: 22.h),
                      _sectionTitle('ACTION & OUTCOME'),
                      _dropdown(
                        label: 'Visit Actions',
                        value: _visitAction,
                        items: _visitActions,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _visitAction = value);
                          }
                        },
                      ),
                      SizedBox(height: 14.h),
                      _label('Medicine Categories'),
                      Wrap(
                        spacing: 9.w,
                        runSpacing: 9.h,
                        children: _medicineCategories
                            .map(
                              (category) => _chip(
                                label: category,
                                selected: _selectedMedicineCategories
                                    .contains(category),
                                onTap: () => _toggleSetValue(
                                  _selectedMedicineCategories,
                                  category,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(height: 18.h),
                      _label('Visit Status'),
                      Wrap(
                        spacing: 9.w,
                        runSpacing: 9.h,
                        children: _VisitStatus.values.map((status) {
                          final isReferred = status == _VisitStatus.referred;
                          return _chip(
                            label: status.label,
                            selected: _visitStatus == status,
                            selectedColor: isReferred
                                ? AppColors.dashboardWarning
                                : AppColors.dashboardPrimary,
                            onTap: () => setState(() => _visitStatus = status),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24.h),
                      FilledButton.icon(
                        onPressed: _submitVisitRecord,
                        icon: Icon(Icons.check_rounded, size: 22.sp),
                        label: Text(
                          'Submit Visit Record',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.registrationSaveBlue,
                          foregroundColor: AppColors.surface,
                          minimumSize: Size(double.infinity, 52.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
