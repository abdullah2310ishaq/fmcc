import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doctor_app/src/core/input_format/cnic_input_formatter.dart';
import 'package:doctor_app/src/core/input_format/pakistan_phone_input_formatter.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/widgets/urdu_help_suffix.dart';

/// Full-screen new patient form — pushed from Patients tab (+).
class NewPatientRegistrationScreen extends StatefulWidget {
  const NewPatientRegistrationScreen({super.key});

  static const routePath = '/patients/register';

  @override
  State<NewPatientRegistrationScreen> createState() =>
      _NewPatientRegistrationScreenState();
}

enum _PatientGenderForm { female, male, other }

class _NewPatientRegistrationScreenState
    extends State<NewPatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();

  DateTime? _dateOfBirth;
  _PatientGenderForm _gender = _PatientGenderForm.female;

  static const List<String> _provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
  ];

  late final Map<String, List<String>> _districtsByProvince;
  late final Map<String, List<String>> _tehsilsByDistrict;

  late String _province;
  late String _district;
  late String _tehsil;

  @override
  void initState() {
    super.initState();
    _districtsByProvince = {
      'Punjab': ['Rawalpindi', 'Lahore', 'Multan'],
      'Sindh': ['Karachi', 'Hyderabad'],
      'Khyber Pakhtunkhwa': ['Peshawar', 'Mardan'],
      'Balochistan': ['Quetta', 'Gwadar'],
      'Islamabad Capital Territory': ['Islamabad'],
    };
    _tehsilsByDistrict = {
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
    _province = 'Punjab';
    _district = _districtsByProvince[_province]!.first;
    _tehsil = _tehsilsByDistrict[_district]!.first;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  String _formatDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  InputDecoration _fieldDecoration({
    String? hint,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(12.r);
    return InputDecoration(
      hintText: (hint != null && hint.isNotEmpty) ? hint : null,
      hintStyle: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary.withValues(alpha: 0.85),
      ),
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.registrationSectionLabel,
        ),
      ),
    );
  }

  Widget _labelRow(String en, String urduHelp) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            en,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          UrduHelpSuffix(urduText: urduHelp),
        ],
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.registrationSaveBlue,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = _formatDob(picked);
      });
    }
  }

  void _onProvinceChanged(String? v) {
    if (v == null) return;
    setState(() {
      _province = v;
      final districts = _districtsByProvince[v]!;
      _district = districts.first;
      _tehsil = _tehsilsByDistrict[_district]!.first;
    });
  }

  void _onDistrictChanged(String? v) {
    if (v == null) return;
    setState(() {
      _district = v;
      _tehsil = _tehsilsByDistrict[v]!.first;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: POST new patient to API.
    context.pop();
  }

  Widget _genderChip(String label, _PatientGenderForm value) {
    final selected = _gender == value;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Material(
          color:
              selected ? AppColors.registrationFieldFill : AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: () => setState(() => _gender = value),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: selected
                      ? AppColors.dashboardPrimary
                      : AppColors.border,
                  width: selected ? 1.8 : 1,
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
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 42.r,
                    height: 42.r,
                    child: Material(
                      color: AppColors.dashboardChipBlueBg,
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => context.pop(),
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
                      'New Patient Registration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                  ),
                  SizedBox(width: 42.w),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('SECTION 1 — BASIC INFORMATION'),
                    _labelRow('First Name', 'مریض کا پہلا نام'),
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(hint: 'e.g. Zainab'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _labelRow('Last Name', 'آخری نام'),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(hint: 'e.g. Khan'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter last name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _labelRow('CNIC', 'شناختی کارڈ نمبر'),
                    TextFormField(
                      controller: _cnicController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CnicInputFormatter()],
                      decoration: _fieldDecoration(hint: '35202-1234567-1'),
                      validator: (v) {
                        final masked = CnicInputFormatter.forApi(v ?? '');
                        if (masked.length != 15) {
                          return 'Enter complete CNIC';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 6.h, left: 4.w),
                      child: Text(
                        'Format: XXXXX-XXXXXXX-X',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _labelRow('Date of Birth', 'تاریخ پیدائش'),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDob,
                      decoration: _fieldDecoration(
                        hint: 'dd/mm/yyyy',
                        suffix: IconButton(
                          icon: Icon(
                            Icons.calendar_today_rounded,
                            size: 18.sp,
                            color: AppColors.dashboardPrimary,
                          ),
                          onPressed: _pickDob,
                        ),
                      ),
                      validator: (_) =>
                          _dateOfBirth == null ? 'Select date of birth' : null,
                    ),
                    SizedBox(height: 14.h),
                    _labelRow('Gender', 'جنس'),
                    Row(
                      children: [
                        _genderChip('Female', _PatientGenderForm.female),
                        _genderChip('Male', _PatientGenderForm.male),
                        _genderChip('Other', _PatientGenderForm.other),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    _sectionTitle('SECTION 2 — CONTACT & LOCATION'),
                    _labelRow('Phone Number', 'فون نمبر'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PakistanPhoneInputFormatter()],
                      decoration:
                          _fieldDecoration(hint: '03001234567'),
                      validator: (v) {
                        if (!PakistanPhoneInputFormatter.isValidPakistaniMobile(
                          v ?? '',
                        )) {
                          return 'Enter valid Pakistani mobile (03XXXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _labelRow('Province', 'صوبہ'),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use — controlled dropdown until DropdownMenu migration.
                      value: _province,
                      decoration: _fieldDecoration(),
                      items: _provinces
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: _onProvinceChanged,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select province' : null,
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _labelRow('District', 'ضلع'),
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _district,
                                decoration: _fieldDecoration(),
                                items: _districtsByProvince[_province]!
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _onDistrictChanged,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _labelRow('Tehsil', 'تحصیل'),
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _tehsil,
                                decoration: _fieldDecoration(),
                                items: _tehsilsByDistrict[_district]!
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _tehsil = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _labelRow('Street Address', 'گھر کا پتہ'),
                    TextFormField(
                      controller: _streetController,
                      maxLines: 2,
                      decoration:
                          _fieldDecoration(hint: 'House #, Street, Mohalla'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter street address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h + bottomInset),
              child: FilledButton.icon(
                onPressed: _submit,
                icon: Icon(Icons.check_rounded, size: 22.sp),
                label: Text(
                  'Save & Register Patient',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.registrationSaveBlue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
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
