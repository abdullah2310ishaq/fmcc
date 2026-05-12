import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/input_format/cnic_input_formatter.dart';
import 'package:doctor_app/src/core/input_format/pakistan_phone_input_formatter.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/patients/patient_directory_coordinator.dart';
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

  List<({int id, String name})> _provinces = const [];
  List<({int id, String name})> _districts = const [];
  List<({int id, String name})> _tehsils = const [];
  List<({int id, String name})> _maritalStatuses = const [];

  int? _provinceId;
  int? _districtId;
  int? _tehsilId;
  int? _maritalStatusId;

  bool _loadingRefs = false;
  bool _submitting = false;
  String? _refsError;

  PatientApi? _patientApi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadReferenceData());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _patientApi ??= PatientApi(context.read<SessionController>().apiClient);
  }

  Future<void> _loadReferenceData() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    setState(() {
      _loadingRefs = true;
      _refsError = null;
    });
    try {
      final provinces = await session.fetchProvinces();
      final marital = await session.fetchMaritalStatuses();
      if (!mounted) return;
      setState(() {
        _provinces = provinces.map((e) => (id: e.id, name: e.name)).toList();
        _maritalStatuses =
            marital.map((e) => (id: e.id, name: e.name)).toList();
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      setState(() => _refsError = session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _loadingRefs = false);
    }
  }

  Future<void> _onProvinceChanged(int? id) async {
    if (id == null) return;
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;
    setState(() {
      _provinceId = id;
      _districtId = null;
      _tehsilId = null;
      _districts = const [];
      _tehsils = const [];
    });
    try {
      final d = await session.fetchDistricts(provinceId: id);
      if (!mounted) return;
      setState(() {
        _districts = d.map((e) => (id: e.id, name: e.name)).toList();
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Future<void> _onDistrictChanged(int? id) async {
    if (id == null || _provinceId == null) return;
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;
    setState(() {
      _districtId = id;
      _tehsilId = null;
      _tehsils = const [];
    });
    try {
      final t = await session.fetchTehsils(
        provinceId: _provinceId!,
        districtId: id,
      );
      if (!mounted) return;
      setState(() {
        _tehsils = t.map((e) => (id: e.id, name: e.name)).toList();
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 14.sp))),
    );
  }

  String _genderApiValue() => switch (_gender) {
        _PatientGenderForm.female => 'Female',
        _PatientGenderForm.male => 'Male',
        _PatientGenderForm.other => 'Other',
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_provinceId == null ||
        _districtId == null ||
        _tehsilId == null ||
        _maritalStatusId == null) {
      _toast('Select province, district, tehsil, and marital status.');
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    final hwId = session.state.healthWorkerIdForPatientApis?.trim();
    if (hwId == null || hwId.isEmpty) {
      _toast(
        'Missing health worker id — open Profile or sign in again. • '
        'ہیلتھ ورکر آئی ڈی نہیں ملی — پروفائل کھولیں یا دوبارہ سائن اِن کریں۔',
      );
      return;
    }

    final cnicMasked = CnicInputFormatter.forApi(_cnicController.text);
    final body = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'gender': _genderApiValue(),
      'dateOfBirth': _dateOfBirth!.toIso8601String().split('T').first,
      'maritalStatusId': _maritalStatusId,
      'contactNumber': _phoneController.text.trim(),
      'address': _streetController.text.trim(),
      'provinceId': _provinceId,
      'districtId': _districtId,
      'tehsilId': _tehsilId,
      // Backend `PatientCreateModel.AssignedHealthWorkerId` (camelCase JSON).
      'assignedHealthWorkerId': hwId,
    };
    if (cnicMasked.length == 15) body['cnic'] = cnicMasked;

    setState(() => _submitting = true);
    try {
      await _patientApi!.createPatient(body: body, bearerToken: token);
      if (!mounted) return;
      _toast('Patient registered successfully.');
      context.read<PatientDirectoryCoordinator>().requestDashboardReload();
      context.pop(true);
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          if (_refsError != null)
            Material(
              color: AppColors.dashboardPeach,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  _refsError!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dashboardWarning,
                  ),
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
                    SizedBox(height: 14.h),
                    _labelRow('Marital status', 'ازدواجی حیثیت'),
                    DropdownButtonFormField<int>(
                      value: _maritalStatusId,
                      decoration: _fieldDecoration(
                        hint: _loadingRefs ? 'Loading…' : 'Select',
                      ),
                      items: _maritalStatuses
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _loadingRefs
                          ? null
                          : (v) => setState(() => _maritalStatusId = v),
                      validator: (v) =>
                          v == null ? 'Select marital status' : null,
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
                    DropdownButtonFormField<int>(
                      value: _provinceId,
                      decoration: _fieldDecoration(
                        hint: _loadingRefs ? 'Loading…' : 'Select province',
                      ),
                      items: _provinces
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _loadingRefs ? null : _onProvinceChanged,
                      validator: (v) =>
                          v == null ? 'Select province' : null,
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
                              DropdownButtonFormField<int>(
                                value: _districtId,
                                decoration: _fieldDecoration(
                                  hint: 'Select district',
                                ),
                                items: _districts
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          e.name,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged:
                                    _districts.isEmpty ? null : _onDistrictChanged,
                                validator: (v) =>
                                    v == null ? 'Select district' : null,
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
                              DropdownButtonFormField<int>(
                                value: _tehsilId,
                                decoration: _fieldDecoration(
                                  hint: 'Select tehsil',
                                ),
                                items: _tehsils
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          e.name,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _tehsils.isEmpty
                                    ? null
                                    : (v) => setState(() => _tehsilId = v),
                                validator: (v) =>
                                    v == null ? 'Select tehsil' : null,
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
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? SizedBox(
                        width: 22.sp,
                        height: 22.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.check_rounded, size: 22.sp),
                label: Text(
                  _submitting ? 'Saving…' : 'Save & Register Patient',
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
