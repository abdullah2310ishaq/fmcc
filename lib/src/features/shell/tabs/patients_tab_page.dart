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
  _PatientDemo? _selectedPatient;

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
    setState(() => _selectedPatient = p);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPatient = _selectedPatient;

    if (selectedPatient != null) {
      return SafeArea(
        bottom: false,
        child: _PatientDetailView(
          key: ValueKey(selectedPatient.id),
          patient: selectedPatient,
          onBack: () => setState(() => _selectedPatient = null),
        ),
      );
    }

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
                        color: selected
                            ? Colors.white
                            : AppColors.dashboardPrimary,
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
                            : AppColors.dashboardPrimary
                                .withValues(alpha: 0.35),
                      ),
                    ),
                    selectedColor: AppColors.dashboardPrimary,
                    backgroundColor: AppColors.surface,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 14.h),
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
                    padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 96.h),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final p = visible[index];
                      final initials = NameInitials.fromFullName(p.name);
                      final (tag, avatarBg) = p.palette;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 14.h),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                AppColors.dashboardPrimaryDark,
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
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  p.conditionLabel(),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.55),
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

enum _PatientDetailSection {
  personalInfo,
  medicalHistory,
  vitals,
  visitHistory,
}

enum _PatientDetailGender { female, male, other }

extension on _PatientDetailSection {
  String get label => switch (this) {
        _PatientDetailSection.personalInfo => 'Personal Info',
        _PatientDetailSection.medicalHistory => 'Medical History',
        _PatientDetailSection.vitals => 'Vitals',
        _PatientDetailSection.visitHistory => 'Visit History',
      };
}

class _PatientDetailView extends StatefulWidget {
  const _PatientDetailView({
    super.key,
    required this.patient,
    required this.onBack,
  });

  final _PatientDemo patient;
  final VoidCallback onBack;

  @override
  State<_PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<_PatientDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _medicalHistoryFormKey = GlobalKey<FormState>();
  final _vitalsFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController(text: '15/03/1992');
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController(text: '0312-4567890');
  final _streetController = TextEditingController(
    text: 'House 14, Street 7, Satellite Town',
  );
  final _knownDrugAllergiesController = TextEditingController(
    text: 'Penicillin, Sulfa drugs',
  );
  final _pregnanciesController = TextEditingController(text: '3');
  final _liveBirthsController = TextEditingController(text: '3');
  final _weightController = TextEditingController(text: '68');
  final _heightController = TextEditingController(text: '157');

  _PatientDetailSection _selectedSection = _PatientDetailSection.personalInfo;
  _PatientDetailGender _gender = _PatientDetailGender.female;
  String _province = 'Punjab';
  String _district = 'Rawalpindi';
  String _tehsil = 'Rawalpindi';
  String _currentContraception = 'Oral Pills';
  final Set<String> _selectedChronicConditions = {
    'Hypertension',
    'Type 2 Diabetes',
  };
  final Set<String> _selectedSurgicalHistory = {'C-Section'};
  final Set<String> _selectedFamilyHistory = {'Hypertension', 'Diabetes'};

  static const List<String> _provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
  ];

  static const Map<String, List<String>> _districtsByProvince = {
    'Punjab': ['Rawalpindi', 'Lahore', 'Multan'],
    'Sindh': ['Karachi', 'Hyderabad'],
    'Khyber Pakhtunkhwa': ['Peshawar', 'Mardan'],
    'Balochistan': ['Quetta', 'Gwadar'],
    'Islamabad Capital Territory': ['Islamabad'],
  };

  static const Map<String, List<String>> _tehsilsByDistrict = {
    'Rawalpindi': ['Rawalpindi', 'Murree'],
    'Lahore': ['Lahore', 'Model Town'],
    'Multan': ['Multan', 'Shujabad'],
    'Karachi': ['Karachi South', 'Karachi East'],
    'Hyderabad': ['Hyderabad', 'Latifabad'],
    'Peshawar': ['Peshawar', 'Mathura'],
    'Mardan': ['Mardan', 'Toru'],
    'Quetta': ['Quetta', 'Chiltan'],
    'Gwadar': ['Gwadar', 'Ormara'],
    'Islamabad': ['Islamabad'],
  };

  static const List<String> _chronicConditionOptions = [
    'Hypertension',
    'Type 2 Diabetes',
    'Asthma',
    'Anemia',
    'Heart Disease',
    'Thyroid',
    'Hepatitis B/C',
  ];

  static const List<String> _surgicalHistoryOptions = [
    'Appendectomy',
    'C-Section',
    'Gallbladder',
    'None',
  ];

  static const List<String> _familyHistoryOptions = [
    'Hypertension',
    'Diabetes',
    'Cancer',
    'Heart Disease',
  ];

  static const List<String> _contraceptionOptions = [
    'None',
    'Oral Pills',
    'Injectable',
    'IUCD',
    'Implant',
    'Condoms',
  ];

  @override
  void initState() {
    super.initState();
    final nameParts = widget.patient.name.trim().split(RegExp(r'\s+'));
    _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
    _lastNameController.text =
        nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    _ageController.text = widget.patient.age.toString();
    _cnicController.text = widget.patient.cnic;
    _gender = switch (widget.patient.gender) {
      _PatientGender.female => _PatientDetailGender.female,
      _PatientGender.male => _PatientDetailGender.male,
    };
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _knownDrugAllergiesController.dispose();
    _pregnanciesController.dispose();
    _liveBirthsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({Widget? suffix}) {
    final radius = BorderRadius.circular(12.r);
    return InputDecoration(
      filled: true,
      fillColor: AppColors.registrationFieldFill,
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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

  Widget _label(String text) {
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.registrationSectionLabel,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    TextInputType? keyboardType,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: _fieldDecoration(suffix: suffix),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _genderChip(String label, _PatientDetailGender value) {
    final selected = _gender == value;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Material(
          color: selected ? AppColors.registrationFieldFill : AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: () => setState(() => _gender = value),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: selected
                      ? AppColors.dashboardPrimary
                      : AppColors.registrationFieldBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.dashboardPrimary
                      : AppColors.dashboardPrimaryDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.dashboardChipBlueBg : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.dashboardPrimary
                  : AppColors.registrationFieldBorder,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.dashboardPrimary
                  : AppColors.dashboardPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipWrap({
    required List<String> options,
    required Set<String> selectedValues,
  }) {
    return Wrap(
      spacing: 9.w,
      runSpacing: 9.h,
      children: options.map((option) {
        return _optionChip(
          label: option,
          selected: selectedValues.contains(option),
          onTap: () => _toggleOption(selectedValues, option),
        );
      }).toList(),
    );
  }

  void _toggleOption(Set<String> selectedValues, String option) {
    setState(() {
      if (option == 'None') {
        selectedValues
          ..clear()
          ..add(option);
        return;
      }

      selectedValues.remove('None');
      if (!selectedValues.add(option)) {
        selectedValues.remove(option);
      }
    });
  }

  void _onProvinceChanged(String? value) {
    if (value == null) return;
    setState(() {
      _province = value;
      _district = _districtsByProvince[value]!.first;
      _tehsil = _tehsilsByDistrict[_district]!.first;
    });
  }

  void _onDistrictChanged(String? value) {
    if (value == null) return;
    setState(() {
      _district = value;
      _tehsil = _tehsilsByDistrict[value]!.first;
    });
  }

  void _openVisitAssessment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening visit assessment for ${widget.patient.name}.',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Patient personal info saved.',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  void _saveMedicalHistory() {
    if (!_medicalHistoryFormKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Medical history saved.',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  void _saveVitals() {
    if (!_vitalsFormKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vitals saved.',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _selectedSectionBody() {
    return switch (_selectedSection) {
      _PatientDetailSection.personalInfo => _personalInfoSection(),
      _PatientDetailSection.medicalHistory => _medicalHistorySection(),
      _PatientDetailSection.vitals => _vitalsSection(),
      _PatientDetailSection.visitHistory => _visitHistorySection(),
    };
  }

  bool get _showsBottomSaveButton =>
      _selectedSection == _PatientDetailSection.personalInfo ||
      _selectedSection == _PatientDetailSection.medicalHistory ||
      _selectedSection == _PatientDetailSection.vitals;

  VoidCallback get _currentSaveAction => switch (_selectedSection) {
        _PatientDetailSection.personalInfo => _saveChanges,
        _PatientDetailSection.medicalHistory => _saveMedicalHistory,
        _PatientDetailSection.vitals => _saveVitals,
        _PatientDetailSection.visitHistory => _openVisitAssessment,
      };

  String get _currentSaveLabel => switch (_selectedSection) {
        _PatientDetailSection.personalInfo => 'Save Changes',
        _PatientDetailSection.medicalHistory => 'Save Medical History',
        _PatientDetailSection.vitals => 'Save Vitals',
        _PatientDetailSection.visitHistory => 'Log New Visit',
      };

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final initials = NameInitials.fromFullName(patient.name);
    final (tag, avatarBg) = patient.palette;

    return ColoredBox(
      color: AppColors.registrationScreenBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 12.h),
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
                    patient.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36.r,
                  height: 36.r,
                  child: Material(
                    color: AppColors.followUpcomingBg,
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: _openVisitAssessment,
                      child: Icon(
                        Icons.note_add_outlined,
                        size: 19.sp,
                        color: AppColors.followAccentGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 24.h),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dashboardPrimary,
                  AppColors.followAccentGreen,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58.r,
                  height: 58.r,
                  decoration: BoxDecoration(
                    color: avatarBg.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.surface,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.surface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Age ${patient.age} • ${_PatientsTabPageState._genderLabel(patient.gender)} • ${patient.id}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              patient.conditionLabel(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Last: ${_PatientsTabPageState._shortVisit(patient.lastVisit)} 2026',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color:
                                    AppColors.surface.withValues(alpha: 0.85),
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
          Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _PatientDetailSection.values
                    .map((section) => _detailTab(section))
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 110.h),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: _selectedSectionBody(),
            ),
          ),
          if (_showsBottomSaveButton)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 12.h),
                child: FilledButton(
                  onPressed: _currentSaveAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.registrationSaveBlue,
                    foregroundColor: AppColors.surface,
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    _currentSaveLabel,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailTab(_PatientDetailSection section) {
    final selected = _selectedSection == section;
    return InkWell(
      onTap: () => setState(() => _selectedSection = section),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              section.label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.dashboardPrimary
                    : AppColors.dashboardPrimaryDark,
              ),
            ),
            SizedBox(height: 11.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 2.h,
              width: 84.w,
              color: selected ? AppColors.dashboardPrimary : AppColors.surface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalInfoSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('BASIC INFORMATION'),
          _label('First Name'),
          _textField(_firstNameController),
          SizedBox(height: 16.h),
          _label('Last Name'),
          _textField(_lastNameController),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Age'),
                    _textField(
                      _ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Date of Birth'),
                    _textField(
                      _dobController,
                      keyboardType: TextInputType.datetime,
                      suffix: Icon(
                        Icons.calendar_today_rounded,
                        size: 18.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _label('Gender'),
          Row(
            children: [
              _genderChip('Female', _PatientDetailGender.female),
              _genderChip('Male', _PatientDetailGender.male),
              _genderChip('Other', _PatientDetailGender.other),
            ],
          ),
          SizedBox(height: 16.h),
          _label('CNIC'),
          _textField(
            _cnicController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 22.h),
          _sectionTitle('CONTACT & LOCATION'),
          _label('Phone Number'),
          _textField(
            _phoneController,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16.h),
          _label('Province'),
          _dropdownField(
            value: _province,
            items: _provinces,
            onChanged: _onProvinceChanged,
          ),
          SizedBox(height: 16.h),
          _label('District'),
          _dropdownField(
            value: _district,
            items: _districtsByProvince[_province]!,
            onChanged: _onDistrictChanged,
          ),
          SizedBox(height: 16.h),
          _label('Tehsil'),
          _dropdownField(
            value: _tehsil,
            items: _tehsilsByDistrict[_district]!,
            onChanged: (value) {
              if (value != null) setState(() => _tehsil = value);
            },
          ),
          SizedBox(height: 16.h),
          _label('Street Address'),
          _textField(_streetController, maxLines: 2),
        ],
      ),
    );
  }

  Widget _medicalHistorySection() {
    return Form(
      key: _medicalHistoryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('CHRONIC CONDITIONS'),
          _chipWrap(
            options: _chronicConditionOptions,
            selectedValues: _selectedChronicConditions,
          ),
          SizedBox(height: 22.h),
          _sectionTitle('SURGICAL HISTORY'),
          _chipWrap(
            options: _surgicalHistoryOptions,
            selectedValues: _selectedSurgicalHistory,
          ),
          SizedBox(height: 22.h),
          _sectionTitle('ALLERGIES'),
          _label('Known Drug Allergies'),
          _textField(_knownDrugAllergiesController),
          SizedBox(height: 22.h),
          _sectionTitle('FAMILY HISTORY'),
          _chipWrap(
            options: _familyHistoryOptions,
            selectedValues: _selectedFamilyHistory,
          ),
          SizedBox(height: 22.h),
          _sectionTitle('REPRODUCTIVE HEALTH'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Pregnancies'),
                    _textField(
                      _pregnanciesController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Live Births'),
                    _textField(
                      _liveBirthsController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _label('Current Contraception'),
          _dropdownField(
            value: _currentContraception,
            items: _contraceptionOptions,
            onChanged: (value) {
              if (value != null) {
                setState(() => _currentContraception = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _vitalsSection() {
    return Form(
      key: _vitalsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('LATEST VITALS')),
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  'Recorded: 03 May 2026',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.registrationSectionLabel,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _vitalSummaryCard(
                  title: 'BLOOD PRESSURE',
                  value: '145/92',
                  status: 'High',
                  statusIcon: Icons.warning_amber_rounded,
                  accent: AppColors.dashboardActionRed,
                  background: AppColors.dashboardChipBlueBg,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _vitalSummaryCard(
                  title: 'TEMPERATURE',
                  value: '98.4°F',
                  status: 'Normal',
                  statusIcon: Icons.check_rounded,
                  accent: AppColors.followAccentGreen,
                  background: AppColors.followUpcomingBg,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _vitalSummaryCard(
                  title: 'HEART RATE',
                  value: '88 bpm',
                  status: 'Normal',
                  statusIcon: Icons.check_rounded,
                  accent: AppColors.followAccentPurple,
                  background:
                      AppColors.followAccentPurple.withValues(alpha: 0.08),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _vitalSummaryCard(
                  title: 'WEIGHT',
                  value: '68 kg',
                  status: 'BMI: 27.4',
                  statusIcon: null,
                  accent: AppColors.dashboardWarning,
                  background: AppColors.dashboardPeach,
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          _sectionTitle('UPDATE VITALS'),
          Row(
            children: [
              Expanded(
                child: _readOnlyVitalField(
                  label: 'Blood Pressure',
                  value: '145/92',
                  unit: 'mmHg',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _readOnlyVitalField(
                  label: 'Temperature',
                  value: '98.4',
                  unit: '°F',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _readOnlyVitalField(
                  label: 'Heart Rate',
                  value: '88',
                  unit: 'bpm',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Weight (kg)'),
                    _textField(
                      _weightController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Height (cm)'),
                    _textField(
                      _heightController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalSummaryCard({
    required String title,
    required String value,
    required String status,
    required IconData? statusIcon,
    required Color accent,
    required Color background,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              if (statusIcon != null)
                Icon(
                  statusIcon,
                  size: 13.sp,
                  color: accent,
                ),
              if (statusIcon != null) SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readOnlyVitalField({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.registrationFieldFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.registrationSectionLabel,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            unit,
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

  Widget _visitHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('VISIT HISTORY')),
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                '8 Visits',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.registrationSectionLabel,
                ),
              ),
            ),
          ],
        ),
        _visitHistoryCard(
          date: '03 May 2026',
          status: 'Completed',
          title: 'BP Monitoring & Medication review',
          details: 'BP: 145/92 • Temp: 98.4°F • Medication adjusted',
        ),
        _visitHistoryCard(
          date: '19 Apr 2026',
          status: 'Follow-up',
          title: 'Hypertension check & counseling',
          details: 'BP: 150/96 • Referred for lab tests',
        ),
        _visitHistoryCard(
          date: '05 Apr 2026',
          status: 'Completed',
          title: 'Routine health screening',
          details: 'BP: 138/88 • Weight stable • Education given',
        ),
        _visitHistoryCard(
          date: '22 Mar 2026',
          status: 'Completed',
          title: 'First registration & baseline assessment',
          details: 'BP: 155/100 • Diagnosed Hypertension',
        ),
        SizedBox(height: 14.h),
        FilledButton.icon(
          onPressed: _openVisitAssessment,
          icon: Icon(Icons.add_rounded, size: 21.sp),
          label: Text(
            'Log New Visit',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
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
    );
  }

  Widget _visitHistoryCard({
    required String date,
    required String status,
    required String title,
    required String details,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: status == 'Follow-up'
                      ? AppColors.dashboardPeach
                      : AppColors.followUpcomingBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: status == 'Follow-up'
                        ? AppColors.dashboardWarning
                        : AppColors.followAccentGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            details,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
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
    );
  }
}
