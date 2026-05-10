import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/input_format/cnic_input_formatter.dart';
import 'package:doctor_app/src/core/input_format/pakistan_phone_input_formatter.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routePath = '/profile/edit';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController(text: 'M');
  DateTime? _dateOfBirth;
  String? _dobError;
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _educationLevelIdController = TextEditingController();
  final _trainingCertificateController = TextEditingController();
  final _provinceIdController = TextEditingController();
  final _districtIdController = TextEditingController();
  final _tehsilIdController = TextEditingController();
  final _addressController = TextEditingController();

  List<({int id, String name})>? _educationLevels;
  List<({int id, String name})>? _provinces;
  List<({int id, String name})>? _districts;
  List<({int id, String name})>? _tehsils;

  String? _educationLevelsError;
  String? _provincesError;
  String? _districtsError;
  String? _tehsilsError;

  bool _loadingEducationLevels = false;
  bool _loadingProvinces = false;
  bool _loadingDistricts = false;
  bool _loadingTehsils = false;

  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _educationLevelIdController.dispose();
    _trainingCertificateController.dispose();
    _provinceIdController.dispose();
    _districtIdController.dispose();
    _tehsilIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final today = DateTime.now();
    final lastDate = DateTime(today.year, today.month, today.day);
    final firstDate = DateTime(today.year - 120);
    var initial = _dateOfBirth ?? DateTime(today.year - 25, today.month, today.day);
    if (initial.isAfter(lastDate)) {
      initial = DateTime(today.year - 25, today.month, today.day);
    }
    if (initial.isBefore(firstDate)) initial = firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !context.mounted) return;
    setState(() {
      _dateOfBirth = picked;
      _dobError = validateProfileDateOfBirth(picked);
    });
  }

  String _dateOfBirthDisplay() {
    final d = _dateOfBirth;
    if (d == null) return 'Tap to select • منتخب کریں';
    final ref = DateTime.now();
    final years = ageCompletedYears(d, ref);
    final suffix = years >= 0 ? ' • Age عمر $years' : '';
    return '${formatIsoDateOnly(d)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    _tryPrefill(controller);
    _ensureReferencesLoaded(controller);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Edit profile',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'پروفائل میں ترمیم',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'اپنی معلومات اپڈیٹ کریں۔',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 24.h),
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          label: _BilingualLabel(en: 'First name', ur: 'پہلا نام'),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                      ),
                      SizedBox(height: 18.h),
                      TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          label: _BilingualLabel(en: 'Last name', ur: 'آخری نام'),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
                      ),
                      SizedBox(height: 18.h),
                      DropdownButtonFormField<String>(
                        key: ValueKey<String>(
                          _genderController.text.trim().isEmpty
                              ? 'M'
                              : _genderController.text.trim().toUpperCase(),
                        ),
                        initialValue: _genderController.text.trim().isEmpty
                            ? 'M'
                            : _genderController.text.trim().toUpperCase(),
                        decoration: const InputDecoration(
                          label: _BilingualLabel(en: 'Gender', ur: 'جنس'),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _genderController.text = v;
                        },
                      ),
                      SizedBox(height: 18.h),
                      InkWell(
                        onTap: () => _pickDateOfBirth(context),
                        borderRadius: BorderRadius.circular(12.r),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            label: const _BilingualLabel(
                              en: 'Date of birth',
                              ur: 'تاریخ پیدائش',
                            ),
                            errorText: _dobError,
                            suffixIcon: Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.blueDark,
                              size: 22.sp,
                            ),
                          ),
                          child: Text(
                            _dateOfBirthDisplay(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: _dateOfBirth == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      TextFormField(
                        controller: _cnicController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [CnicInputFormatter()],
                        decoration: const InputDecoration(
                          label: _BilingualLabel(en: 'CNIC', ur: 'شناختی کارڈ'),
                          hintText: '#####-#######-#',
                        ),
                        validator: (v) {
                          final d = CnicInputFormatter.digitsOnly(v ?? '');
                          if (d.length != CnicInputFormatter.maxDigits) {
                            return 'Enter valid 13-digit CNIC';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 18.h),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [PakistanPhoneInputFormatter()],
                        decoration: const InputDecoration(
                          label: _BilingualLabel(en: 'Phone number', ur: 'فون نمبر'),
                          hintText: '03XXXXXXXXX',
                        ),
                        validator: (v) {
                          if (!PakistanPhoneInputFormatter.isValidPakistaniMobile(
                              v ?? '')) {
                            return 'Enter valid 11-digit mobile (03XXXXXXXXX)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 18.h),
                      DropdownButtonFormField<int>(
                        key: ValueKey<Object>(
                          'edu_${_educationLevels?.length ?? 0}_${_educationLevelIdController.text}',
                        ),
                        initialValue: _matchedItemId(_educationLevels, _educationLevelIdController),
                        decoration: InputDecoration(
                          label: const _BilingualLabel(
                            en: 'Education level',
                            ur: 'تعلیمی معیار',
                          ),
                          helperText: _refHelper(
                            loading: _loadingEducationLevels,
                            error: _educationLevelsError,
                          ),
                        ),
                        items: (_educationLevels ?? const [])
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: _dropdownItemLabel(e.name, e.id),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (v) {
                          _educationLevelIdController.text = v?.toString() ?? '';
                        },
                        validator: (v) =>
                            (v == null || v <= 0) ? 'Select education level' : null,
                      ),
                      SizedBox(height: 18.h),
                      TextFormField(
                        controller: _trainingCertificateController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          label: _BilingualLabel(
                            en: 'LHW training certificate',
                            ur: 'ایل ایچ ڈبلیو ٹریننگ سرٹیفکیٹ',
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter training certificate'
                            : null,
                      ),
                      SizedBox(height: 18.h),
                      DropdownButtonFormField<int>(
                        key: ValueKey<Object>(
                          'pv_${_provinces?.length ?? 0}_${_provinceIdController.text}',
                        ),
                        initialValue: _matchedItemId(_provinces, _provinceIdController),
                        decoration: InputDecoration(
                          label: const _BilingualLabel(en: 'Province', ur: 'صوبہ'),
                          helperText: _refHelper(
                            loading: _loadingProvinces,
                            error: _provincesError,
                          ),
                        ),
                        items: (_provinces ?? const [])
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: _dropdownItemLabel(p.name, p.id),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (v) {
                          _provinceIdController.text = v?.toString() ?? '';
                          _districtIdController.clear();
                          _tehsilIdController.clear();
                          _districts = null;
                          _tehsils = null;
                          _districtsError = null;
                          _tehsilsError = null;
                          _loadDistricts(controller);
                        },
                        validator: (v) => (v == null || v <= 0) ? 'Select province' : null,
                      ),
                      SizedBox(height: 18.h),
                      DropdownButtonFormField<int>(
                        key: ValueKey<Object>(
                          'dc_${_districts?.length ?? 0}_${_districtIdController.text}',
                        ),
                        initialValue: _matchedItemId(_districts, _districtIdController),
                        decoration: InputDecoration(
                          label: const _BilingualLabel(en: 'District', ur: 'ضلع'),
                          helperText: _refHelper(
                            loading: _loadingDistricts,
                            error: _districtsError,
                          ),
                        ),
                        items: (_districts ?? const [])
                            .map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: _dropdownItemLabel(d.name, d.id),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (v) {
                          _districtIdController.text = v?.toString() ?? '';
                          _tehsilIdController.clear();
                          _tehsils = null;
                          _tehsilsError = null;
                          _loadTehsils(controller);
                        },
                        validator: (v) => (v == null || v <= 0) ? 'Select district' : null,
                      ),
                      SizedBox(height: 18.h),
                      DropdownButtonFormField<int>(
                        key: ValueKey<Object>(
                          'th_${_tehsils?.length ?? 0}_${_tehsilIdController.text}',
                        ),
                        initialValue: _matchedItemId(_tehsils, _tehsilIdController),
                        decoration: InputDecoration(
                          label: const _BilingualLabel(en: 'Tehsil', ur: 'تحصیل'),
                          helperText: _refHelper(
                            loading: _loadingTehsils,
                            error: _tehsilsError,
                          ),
                        ),
                        items: (_tehsils ?? const [])
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: _dropdownItemLabel(t.name, t.id),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (v) {
                          _tehsilIdController.text = v?.toString() ?? '';
                        },
                        validator: (v) => (v == null || v <= 0) ? 'Select tehsil' : null,
                      ),
                      SizedBox(height: 18.h),
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          label: _BilingualLabel(en: 'Address', ur: 'پتہ'),
                        ),
                        maxLines: 2,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter address' : null,
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final ok = _formKey.currentState?.validate() ?? false;
                          if (!ok) return;
                          setState(() => _saving = true);
                          try {
                            final userId = controller.state.userId;
                            if (userId == null || userId.trim().isEmpty) {
                              throw StateError('Missing user id. Please login again.');
                            }

                            final profile = HealthWorkerProfileUpsert(
                              userId: userId,
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              gender: _genderController.text.trim().toUpperCase(),
                              dateOfBirth: _dateOfBirth!,
                              cnic: CnicInputFormatter.forApi(_cnicController.text),
                              phoneNumber:
                                  PakistanPhoneInputFormatter.normalizeFromRaw(
                                _phoneController.text,
                              ),
                              educationLevelId:
                                  int.parse(_educationLevelIdController.text.trim()),
                              lhwTrainingCertificate:
                                  _trainingCertificateController.text.trim(),
                              provinceId: int.parse(_provinceIdController.text.trim()),
                              districtId: int.parse(_districtIdController.text.trim()),
                              tehsilId: int.parse(_tehsilIdController.text.trim()),
                              address: _addressController.text.trim(),
                            );

                            await controller.completeRegistrationDetails(profile: profile);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Profile updated • پروفائل اپڈیٹ ہوگیا'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(16.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            );
                            Navigator.of(context).maybePop();
                          } catch (e) {
                            if (!context.mounted) return;
                            if (e is SessionEndedFailure) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: Text(_saving ? 'Saving…' : 'Save changes • محفوظ کریں'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _matchedItemId(
    List<({int id, String name})>? items,
    TextEditingController field,
  ) {
    if (items == null || items.isEmpty) return null;
    final v = int.tryParse(field.text.trim());
    if (v == null || v <= 0) return null;
    for (final e in items) {
      if (e.id == v) return v;
    }
    return null;
  }

  String? _refHelper({required bool loading, String? error}) {
    if (error != null && error.isNotEmpty) return error;
    if (loading) return 'Loading…';
    return null;
  }

  Widget _dropdownItemLabel(String name, int id) {
    final label = name.trim().isEmpty ? 'Option $id' : name.trim();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _tryPrefill(SessionController controller) {
    if (_prefilled) return;
    _prefilled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final existing = await controller.fetchHealthWorkerProfile();
        if (!mounted || existing == null) return;

        _firstNameController.text = existing.firstName;
        _lastNameController.text = existing.lastName;
        _genderController.text = existing.gender.isEmpty ? 'M' : existing.gender;
        _dateOfBirth = existing.dateOfBirth;
        _dobError = null;
        _cnicController.text = CnicInputFormatter.formatFromRaw(existing.cnic);
        _phoneController.text =
            PakistanPhoneInputFormatter.normalizeFromRaw(existing.phoneNumber);
        _educationLevelIdController.text =
            existing.educationLevelId == 0 ? '' : existing.educationLevelId.toString();
        _trainingCertificateController.text = existing.lhwTrainingCertificate;
        _provinceIdController.text =
            existing.provinceId == 0 ? '' : existing.provinceId.toString();
        _districtIdController.text =
            existing.districtId == 0 ? '' : existing.districtId.toString();
        _tehsilIdController.text =
            existing.tehsilId == 0 ? '' : existing.tehsilId.toString();
        _addressController.text = existing.address;

        final provinceId = existing.provinceId;
        final districtId = existing.districtId;
        setState(() {});
        if (provinceId > 0) {
          _districts = null;
          await _loadDistricts(controller);
        }
        if (mounted && provinceId > 0 && districtId > 0) {
          _tehsils = null;
          await _loadTehsils(controller);
        }
      } catch (_) {
        // ignore
      }
    });
  }

  void _ensureReferencesLoaded(SessionController controller) {
    final provinceId = int.tryParse(_provinceIdController.text.trim());
    final districtId = int.tryParse(_districtIdController.text.trim());

    if (_educationLevels == null && !_loadingEducationLevels) {
      unawaited(_loadEducationLevels(controller));
    }
    if (_provinces == null && !_loadingProvinces) {
      unawaited(_loadProvinces(controller));
    }
    if (_districts == null &&
        !_loadingDistricts &&
        provinceId != null &&
        provinceId > 0) {
      unawaited(_loadDistricts(controller));
    }
    if (_tehsils == null &&
        !_loadingTehsils &&
        provinceId != null &&
        provinceId > 0 &&
        districtId != null &&
        districtId > 0) {
      unawaited(_loadTehsils(controller));
    }
  }

  Future<void> _loadEducationLevels(SessionController controller) async {
    setState(() {
      _loadingEducationLevels = true;
      _educationLevelsError = null;
    });
    try {
      final levels = await controller.fetchEducationLevels();
      if (!mounted) return;
      setState(() {
        _educationLevels = levels.map((e) => (id: e.id, name: e.name)).toList(
              growable: false,
            );
      });
    } catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) return;
      setState(() => _educationLevelsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEducationLevels = false);
    }
  }

  Future<void> _loadProvinces(SessionController controller) async {
    setState(() {
      _loadingProvinces = true;
      _provincesError = null;
    });
    try {
      final items = await controller.fetchProvinces();
      if (!mounted) return;
      setState(() {
        _provinces =
            items.map((p) => (id: p.id, name: p.name)).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) return;
      setState(() => _provincesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadDistricts(SessionController controller) async {
    final pid = int.tryParse(_provinceIdController.text.trim());
    if (pid == null || pid <= 0) return;
    setState(() {
      _loadingDistricts = true;
      _districtsError = null;
    });
    try {
      final items = await controller.fetchDistricts(provinceId: pid);
      if (!mounted) return;
      setState(() {
        _districts =
            items.map((d) => (id: d.id, name: d.name)).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) return;
      setState(() => _districtsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadTehsils(SessionController controller) async {
    final pid = int.tryParse(_provinceIdController.text.trim());
    final did = int.tryParse(_districtIdController.text.trim());
    if (pid == null || pid <= 0 || did == null || did <= 0) return;
    setState(() {
      _loadingTehsils = true;
      _tehsilsError = null;
    });
    try {
      final items =
          await controller.fetchTehsils(provinceId: pid, districtId: did);
      if (!mounted) return;
      setState(() {
        _tehsils =
            items.map((t) => (id: t.id, name: t.name)).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) return;
      setState(() => _tehsilsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingTehsils = false);
    }
  }
}

class _BilingualLabel extends StatelessWidget {
  const _BilingualLabel({required this.en, required this.ur});

  final String en;
  final String ur;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: en,
        children: [
          TextSpan(
            text: ' - \u200F$ur',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

