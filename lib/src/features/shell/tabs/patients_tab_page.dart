import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/features/patients/new_patient_registration_screen.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Shell index **1** — All Patients (demo list, search & chip filters).
class PatientsTabPage extends StatefulWidget {
  const PatientsTabPage({super.key});

  @override
  State<PatientsTabPage> createState() => _PatientsTabPageState();
}

enum _PatientGender { male, female }

typedef _ColorPair = ({Color fg, Color bg});

enum _DemoCondition {
  hypertension,
  antenatal,
  diabetes,
  postOp,
  asthma,
}

class _PatientDemo {
  const _PatientDemo({
    required this.name,
    required this.age,
    required this.gender,
    required this.id,
    required this.cnic,
    required this.condition,
    required this.lastVisit,
  });

  final String name;
  final int age;
  final _PatientGender gender;
  final String id;
  final String cnic;
  final _DemoCondition condition;
  final DateTime lastVisit;

  bool get _isChronic =>
      condition == _DemoCondition.hypertension ||
      condition == _DemoCondition.diabetes ||
      condition == _DemoCondition.asthma;

  bool get _isAntenatal => condition == _DemoCondition.antenatal;

  bool matchesFilter(_PatientFilter f) {
    switch (f) {
      case _PatientFilter.all:
        return true;
      case _PatientFilter.male:
        return gender == _PatientGender.male;
      case _PatientFilter.female:
        return gender == _PatientGender.female;
      case _PatientFilter.chronic:
        return _isChronic;
      case _PatientFilter.antenatal:
        return _isAntenatal;
    }
  }

  bool matchesSearch(String q) {
    if (q.isEmpty) return true;
    final n = name.toLowerCase();
    final i = id.toLowerCase();
    final c = cnic.replaceAll(RegExp(r'\s|-'), '').toLowerCase();
    final qq = q.trim().toLowerCase();
    final qqDigits = qq.replaceAll(RegExp(r'\s|-'), '');
    return n.contains(qq) ||
        i.contains(qq) ||
        (qqDigits.isNotEmpty && c.contains(qqDigits));
  }

  String conditionLabel() => switch (condition) {
        _DemoCondition.hypertension => 'Hypertension',
        _DemoCondition.antenatal => 'Antenatal',
        _DemoCondition.diabetes => 'Diabetes',
        _DemoCondition.postOp => 'Post-Op',
        _DemoCondition.asthma => 'Asthma',
      };

  (_ColorPair tag, Color avatarBg) get palette => switch (condition) {
        _DemoCondition.hypertension => (
            (
              fg: AppColors.dashboardWarning,
              bg: AppColors.dashboardPeach,
            ),
            AppColors.patientAvatarOrange,
          ),
        _DemoCondition.antenatal => (
            (
              fg: AppColors.dashboardPrimary,
              bg: AppColors.dashboardChipBlueBg,
            ),
            AppColors.patientAvatarBlue,
          ),
        _DemoCondition.diabetes => (
            (
              fg: AppColors.followAccentPurple,
              bg: const Color(0xFFF3E8FF),
            ),
            AppColors.patientAvatarPurple,
          ),
        _DemoCondition.postOp => (
            (
              fg: AppColors.followAccentGreen,
              bg: AppColors.followUpcomingBg,
            ),
            AppColors.patientAvatarGreen,
          ),
        _DemoCondition.asthma => (
            (
              fg: AppColors.dashboardWarning,
              bg: AppColors.dashboardPeach,
            ),
            AppColors.patientAvatarOrange,
          ),
      };
}

enum _PatientFilter {
  all,
  male,
  female,
  chronic,
  antenatal,
}

extension on _PatientFilter {
  String chipLabel(int totalPatients) => switch (this) {
        _PatientFilter.all => 'All ($totalPatients)',
        _PatientFilter.male => 'Male',
        _PatientFilter.female => 'Female',
        _PatientFilter.chronic => 'Chronic',
        _PatientFilter.antenatal => 'Antenatal',
      };
}

class _PatientsTabPageState extends State<PatientsTabPage> {
  static final List<_PatientDemo> _allPatients = [
    _PatientDemo(
      name: 'Zainab Khan',
      age: 34,
      gender: _PatientGender.female,
      id: 'LHW-2026-0041',
      cnic: '35202-1234567-8',
      condition: _DemoCondition.hypertension,
      lastVisit: DateTime(2026, 5, 3),
    ),
    _PatientDemo(
      name: 'Sajida Akhtar',
      age: 28,
      gender: _PatientGender.female,
      id: 'LHW-2026-0038',
      cnic: '35101-9876543-2',
      condition: _DemoCondition.antenatal,
      lastVisit: DateTime(2026, 4, 26),
    ),
    _PatientDemo(
      name: 'Muhammad Arif',
      age: 52,
      gender: _PatientGender.male,
      id: 'LHW-2026-0029',
      cnic: '36302-1122334-5',
      condition: _DemoCondition.diabetes,
      lastVisit: DateTime(2026, 5, 1),
    ),
    _PatientDemo(
      name: 'Rubina Fatima',
      age: 41,
      gender: _PatientGender.female,
      id: 'LHW-2026-0015',
      cnic: '37403-5566778-1',
      condition: _DemoCondition.postOp,
      lastVisit: DateTime(2026, 5, 7),
    ),
    _PatientDemo(
      name: 'Naseem Kousar',
      age: 38,
      gender: _PatientGender.female,
      id: 'LHW-2026-0061',
      cnic: '38104-9988776-3',
      condition: _DemoCondition.asthma,
      lastVisit: DateTime(2026, 4, 28),
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chipScrollController = ScrollController();

  _PatientFilter _selectedFilter = _PatientFilter.female;

  @override
  void dispose() {
    _searchController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  static String _shortVisit(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]}';
  }

  static String _genderLabel(_PatientGender g) =>
      g == _PatientGender.male ? 'Male' : 'Female';

  List<_PatientDemo> get _visible {
    final q = _searchController.text;
    return _allPatients
        .where((p) => p.matchesFilter(_selectedFilter))
        .where((p) => p.matchesSearch(q))
        .toList();
  }

  void _onCreatePatient() {
    context.push(NewPatientRegistrationScreen.routePath);
  }

  void _onPatientTap(_PatientDemo p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${p.name} — details API بعد میں',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = _PatientFilter.values;
    final visible = _visible;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            child: Row(
              children: [
                Material(
                  color: AppColors.dashboardChipBlueBg,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => Navigator.maybePop(context),
                    child: SizedBox(
                      width: 42.r,
                      height: 42.r,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'All Patients',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.dashboardPrimaryDark,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: _onCreatePatient,
                    child: SizedBox(
                      width: 42.r,
                      height: 42.r,
                      child: Icon(
                        Icons.add_rounded,
                        size: 26.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by name, CNIC or ID…',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 22.sp,
                ),
                filled: true,
                fillColor: AppColors.patientSearchFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: AppColors.dashboardPrimary.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 14.h,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 40.h,
            child: Scrollbar(
              controller: _chipScrollController,
              thumbVisibility: false,
              thickness: 3,
              radius: Radius.circular(99.r),
              child: ListView.separated(
                controller: _chipScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: filters.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final f = filters[index];
                  final selected = f == _selectedFilter;
                  return ChoiceChip(
                    label: Text(
                      f.chipLabel(_allPatients.length),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : AppColors.dashboardPrimary,
                      ),
                    ),
                    selected: selected,
                    onSelected: (v) {
                      if (v) setState(() => _selectedFilter = f);
                    },
                    showCheckmark: false,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: selected
                            ? AppColors.dashboardPrimary
                            : AppColors.dashboardPrimary.withValues(alpha: 0.35),
                      ),
                    ),
                    selectedColor: AppColors.dashboardPrimary,
                    backgroundColor: AppColors.surface,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_left_rounded,
                  size: 18.sp,
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final thumbW = w * 0.38;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Container(
                              width: w,
                              height: 3.h,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (w - thumbW) / 2,
                            top: -1,
                            child: Container(
                              width: thumbW,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  size: 18.sp,
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      'No patients match — try another filter or search',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final p = visible[index];
                final initials = NameInitials.fromFullName(p.name);
                final (tag, avatarBg) = p.palette;

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _onPatientTap(p),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48.r,
                              height: 48.r,
                              decoration: BoxDecoration(
                                color: avatarBg,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: tag.fg,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.dashboardPrimaryDark,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Age ${p.age} • ${_genderLabel(p.gender)} • ID: ${p.id}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      height: 1.25,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tag.bg,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            p.conditionLabel(),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w800,
                                              color: tag.fg,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Last: ${_shortVisit(p.lastVisit)}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary.withValues(alpha: 0.55),
                              size: 26.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
