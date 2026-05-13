import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/input_format/cnic_input_formatter.dart';
import 'package:doctor_app/src/core/input_format/pakistan_phone_input_formatter.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/presentation/bp_reading_color.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';
import 'package:doctor_app/src/features/patients/patient_directory_coordinator.dart';
import 'package:doctor_app/src/features/patients/visit_detail_screen.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';

String patientDetailShortVisit(DateTime? d) {
  if (d == null) return '—';
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
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

Color _avatarForCondition(String primary) {
  final p = primary.toLowerCase();
  if (p.contains('antenatal') || p.contains('pregnan')) {
    return AppColors.patientAvatarBlue;
  }
  if (p.contains('diabet')) return AppColors.patientAvatarPurple;
  if (p.contains('post') || p.contains('surg')) {
    return AppColors.patientAvatarGreen;
  }
  if (p.contains('hypertension') ||
      p.contains('pressure') ||
      p.contains('asthma')) {
    return AppColors.patientAvatarOrange;
  }
  return AppColors.patientAvatarBlue;
}

enum _VisitHistorySegment {
  all,
  followUps,
  routine,
}

extension on _VisitHistorySegment {
  String get chipLine => switch (this) {
        _VisitHistorySegment.all => 'All · تمام',
        _VisitHistorySegment.followUps => 'Follow-ups · فالو اپ',
        _VisitHistorySegment.routine => 'Routine · معمول',
      };
}

enum PatientDetailSection {
  personalInfo,
  medicalHistory,
  visitHistory,
}

extension on PatientDetailSection {
  String get label => switch (this) {
        PatientDetailSection.personalInfo => 'Personal Info',
        PatientDetailSection.medicalHistory => 'Medical History',
        PatientDetailSection.visitHistory => 'Visit History',
      };
}

enum _PatientDetailGender { female, male, other }

class PatientDetailTabView extends StatefulWidget {
  const PatientDetailTabView({
    super.key,
    required this.summary,
    required this.onBack,
    this.onStartVisit,
  });

  final HwPatientSummary summary;
  final VoidCallback onBack;
  final ValueChanged<VisitPatientSeed>? onStartVisit;

  @override
  State<PatientDetailTabView> createState() => _PatientDetailTabViewState();
}

class _PatientDetailTabViewState extends State<PatientDetailTabView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();

  PatientApi? _patientApi;
  ReferenceApi? _referenceApi;

  List<NamedReferenceItem> _complianceLevels = const [];
  List<NamedReferenceItem> _adherenceLevels = const [];
  final Map<int, TextEditingController> _medicalDurationCtl = {};
  final Map<int, TextEditingController> _surgicalNotesCtl = {};
  final Map<int, TextEditingController> _surgicalMonthCtl = {};
  final Map<int, TextEditingController> _surgicalYearCtl = {};
  final Map<int, TextEditingController> _drugSideEffectsCtl = {};

  PatientDetailSection _section = PatientDetailSection.personalInfo;
  _PatientDetailGender _gender = _PatientDetailGender.female;
  DateTime? _dateOfBirth;

  List<({int id, String name})> _provinces = const [];
  List<({int id, String name})> _districts = const [];
  List<({int id, String name})> _tehsils = const [];
  List<({int id, String name})> _maritalStatuses = const [];
  int? _provinceId;
  int? _districtId;
  int? _tehsilId;
  int? _maritalStatusId;

  bool _loadingRefs = false;
  bool _loadingDetail = false;
  String? _detailLoadError;

  List<PatientMedicalHistoryRow> _medical = const [];
  List<PatientSurgicalHistoryRow> _surgical = const [];
  List<PatientDrugHistoryRow> _drugs = const [];
  List<PatientVisitRow> _visits = const [];
  _VisitHistorySegment _visitHistorySegment = _VisitHistorySegment.all;
  bool _familyHtn = false;
  bool _tobacco = false;
  bool _baselineLoaded = false;

  bool _savingPersonal = false;
  bool _savingMedical = false;

  @override
  void initState() {
    super.initState();
    final name = widget.summary.fullName.trim();
    final parts =
        name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    _firstNameController.text = parts.isNotEmpty ? parts.first : '';
    _lastNameController.text = parts.length > 1 ? parts.skip(1).join(' ') : '';
    _gender = _genderFromApi(widget.summary.gender);
    final cnicFromList = widget.summary.cnic?.trim();
    if (cnicFromList != null && cnicFromList.isNotEmpty) {
      _cnicController.text = CnicInputFormatter.formatFromRaw(cnicFromList);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = context.read<SessionController>().apiClient;
    _patientApi ??= PatientApi(client);
    _referenceApi ??= ReferenceApi(client);
  }

  _PatientDetailGender _genderFromApi(String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'male' || g == 'm') return _PatientDetailGender.male;
    if (g == 'female' || g == 'f') return _PatientDetailGender.female;
    return _PatientDetailGender.other;
  }

  String _genderApiValue() => switch (_gender) {
        _PatientDetailGender.female => 'Female',
        _PatientDetailGender.male => 'Male',
        _PatientDetailGender.other => 'Other',
      };

  Future<void> _bootstrap() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    setState(() {
      _loadingRefs = true;
      _loadingDetail = true;
      _detailLoadError = null;
    });

    try {
      await _loadReference(session, token);
      await _loadClinicalDropdownRefs(session, token);
      await _loadProfileAndCascadeLocation(session, token);
      await _loadClinical(session, token);
    } on Object catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) return;
      setState(() {
        _detailLoadError = session.apiClient.mapError(e).message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRefs = false;
          _loadingDetail = false;
        });
      }
    }
  }

  void _applyProfileToForm(PatientProfileData p) {
    _firstNameController.text = p.firstName.trim();
    _lastNameController.text = p.lastName.trim();
    _gender = _genderFromApi(p.gender);
    final dob = p.dateOfBirth;
    if (dob != null) {
      _dateOfBirth = dob;
      _dobController.text =
          '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
    } else {
      _dateOfBirth = null;
      _dobController.clear();
    }
    final rawCnic = p.cnic.trim();
    if (rawCnic.isNotEmpty) {
      _cnicController.text = CnicInputFormatter.formatFromRaw(rawCnic);
    } else {
      _cnicController.clear();
    }
    _phoneController.text = p.contactNumber.trim();
    _streetController.text = p.address.trim();
    _maritalStatusId = p.maritalStatusId;
    _provinceId = p.provinceId;
    _districtId = p.districtId;
    _tehsilId = p.tehsilId;
  }

  Future<void> _cascadeDistrictsAndTehsils(SessionController session) async {
    final pid = _provinceId;
    if (pid == null || pid <= 0) return;
    try {
      final d = await session.fetchDistricts(provinceId: pid);
      if (!mounted) return;
      setState(() {
        _districts = d.map((e) => (id: e.id, name: e.name)).toList();
      });
      final did = _districtId;
      if (did != null && did > 0) {
        final t = await session.fetchTehsils(
          provinceId: pid,
          districtId: did,
        );
        if (!mounted) return;
        setState(() {
          _tehsils = t.map((e) => (id: e.id, name: e.name)).toList();
        });
      }
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Future<void> _loadProfileAndCascadeLocation(
    SessionController session,
    String token,
  ) async {
    final profile = await _patientApi!.getPatientProfile(
      patientId: widget.summary.patientId,
      bearerToken: token,
    );
    if (!mounted) return;
    setState(() => _applyProfileToForm(profile));
    await _cascadeDistrictsAndTehsils(session);
  }

  Future<void> _loadReference(SessionController session, String token) async {
    final provinces = await session.fetchProvinces();
    final marital = await session.fetchMaritalStatuses();
    if (!mounted) return;
    setState(() {
      _provinces = provinces.map((e) => (id: e.id, name: e.name)).toList();
      _maritalStatuses = marital.map((e) => (id: e.id, name: e.name)).toList();
    });
  }

  Future<void> _loadClinicalDropdownRefs(
    SessionController session,
    String token,
  ) async {
    final ref = _referenceApi;
    if (ref == null) return;
    try {
      final results = await Future.wait([
        ref.getComplianceLevels(bearerToken: token),
        ref.getAdherenceLevels(bearerToken: token),
      ]);
      if (!mounted) return;
      setState(() {
        _complianceLevels = results[0];
        _adherenceLevels = results[1];
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  void _rebuildClinicalTextControllers() {
    void syncMap<T>(
      Iterable<T> rows,
      int Function(T row) idOf,
      Map<int, TextEditingController> map,
      String Function(T row) textOf,
    ) {
      final keep = rows.map(idOf).toSet();
      for (final k in map.keys.toList()) {
        if (!keep.contains(k)) {
          map.remove(k)?.dispose();
        }
      }
      for (final row in rows) {
        final id = idOf(row);
        final want = textOf(row);
        final ex = map[id];
        if (ex == null) {
          map[id] = TextEditingController(text: want);
        } else if (ex.text != want) {
          ex.text = want;
        }
      }
    }

    syncMap<PatientMedicalHistoryRow>(
      _medical,
      (m) => m.id,
      _medicalDurationCtl,
      (m) => m.durationInMonths?.toString() ?? '',
    );
    syncMap<PatientSurgicalHistoryRow>(
      _surgical,
      (s) => s.id,
      _surgicalNotesCtl,
      (s) => s.notes,
    );
    syncMap<PatientSurgicalHistoryRow>(
      _surgical,
      (s) => s.id,
      _surgicalMonthCtl,
      (s) => s.approxMonth?.toString() ?? '',
    );
    syncMap<PatientSurgicalHistoryRow>(
      _surgical,
      (s) => s.id,
      _surgicalYearCtl,
      (s) => s.approxYear?.toString() ?? '',
    );
    syncMap<PatientDrugHistoryRow>(
      _drugs,
      (d) => d.id,
      _drugSideEffectsCtl,
      (d) => d.sideEffects,
    );
  }

  Future<void> _loadClinical(SessionController session, String token) async {
    final pid = widget.summary.patientId;

    PatientCompleteHistoryData? history;
    try {
      history = await _patientApi!.getCompleteHistory(
        patientId: pid,
        bearerToken: token,
      );
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }

    List<PatientVisitRow> visits = const [];
    try {
      visits = await _patientApi!.getVisits(
        patientId: pid,
        bearerToken: token,
      );
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }

    if (!mounted) return;
    setState(() {
      if (history != null) {
        _medical = List<PatientMedicalHistoryRow>.from(history.medical);
        _surgical = List<PatientSurgicalHistoryRow>.from(history.surgical);
        _drugs = List<PatientDrugHistoryRow>.from(history.drugs);
        final baseline = history.baseline;
        if (baseline != null) {
          _familyHtn = baseline.familyHistoryOfHtnOrStroke;
          _tobacco = baseline.tobaccoUse;
          _baselineLoaded = true;
        } else {
          _familyHtn = false;
          _tobacco = false;
          _baselineLoaded = false;
        }
      } else {
        _medical = const [];
        _surgical = const [];
        _drugs = const [];
        _familyHtn = false;
        _tobacco = false;
        _baselineLoaded = false;
      }
      _visits = List<PatientVisitRow>.from(visits)
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    });
    _rebuildClinicalTextControllers();
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

  @override
  void dispose() {
    for (final c in _medicalDurationCtl.values) {
      c.dispose();
    }
    for (final c in _surgicalNotesCtl.values) {
      c.dispose();
    }
    for (final c in _surgicalMonthCtl.values) {
      c.dispose();
    }
    for (final c in _surgicalYearCtl.values) {
      c.dispose();
    }
    for (final c in _drugSideEffectsCtl.values) {
      c.dispose();
    }
    _medicalDurationCtl.clear();
    _surgicalNotesCtl.clear();
    _surgicalMonthCtl.clear();
    _surgicalYearCtl.clear();
    _drugSideEffectsCtl.clear();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 14.sp))),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime(now.year - widget.summary.age, now.month, now.day),
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
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _savePersonal() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    final hwKey = session.state.healthWorkerIdForPatientApis?.trim();
    if (hwKey == null || hwKey.isEmpty) {
      _toast('Missing health worker id. Sign in again or complete profile.');
      return;
    }

    final cnicMasked = CnicInputFormatter.forApi(_cnicController.text);
    final body = <String, dynamic>{
      'id': widget.summary.patientId,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'gender': _genderApiValue(),
      'contactNumber': _phoneController.text.trim(),
      'address': _streetController.text.trim(),
      'assignedHealthWorkerId': hwKey,
    };
    if (cnicMasked.length == 15) body['cnic'] = cnicMasked;
    if (_dateOfBirth != null) {
      body['dateOfBirth'] = _dateOfBirth!.toIso8601String().split('T').first;
    }
    if (_provinceId != null && _provinceId! > 0) {
      body['provinceId'] = _provinceId;
    }
    if (_districtId != null && _districtId! > 0) {
      body['districtId'] = _districtId;
    }
    if (_tehsilId != null && _tehsilId! > 0) {
      body['tehsilId'] = _tehsilId;
    }
    if (_maritalStatusId != null && _maritalStatusId! > 0) {
      body['maritalStatusId'] = _maritalStatusId;
    }

    setState(() => _savingPersonal = true);
    try {
      await _patientApi!.updatePatient(body: body, bearerToken: token);
      if (!mounted) return;
      _toast('Patient updated successfully.');
      context.read<PatientDirectoryCoordinator>().requestDashboardReload();
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _savingPersonal = false);
    }
  }

  Future<void> _saveMedicalAndLifestyle() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }
    final pid = widget.summary.patientId;
    final api = _patientApi!;

    setState(() => _savingMedical = true);
    try {
      for (final row in _medical) {
        final durRaw = _medicalDurationCtl[row.id]?.text.trim() ?? '';
        final body = <String, dynamic>{
          'patientId': pid,
          'conditionId': row.conditionId,
          'isOnMedication': row.isOnMedication,
        };
        if (durRaw.isNotEmpty) {
          final d = int.tryParse(durRaw);
          if (d != null && d > 0) body['durationInMonths'] = d;
        }
        if (row.complianceLevelId != null && row.complianceLevelId! > 0) {
          body['complianceLevelId'] = row.complianceLevelId;
        }
        if (row.id > 0) {
          body['id'] = row.id;
          await api.putMedicalHistory(body: body, bearerToken: token);
        } else {
          await api.postMedicalHistory(body: body, bearerToken: token);
        }
      }

      for (final s in _surgical) {
        final body = <String, dynamic>{
          'patientId': pid,
          'procedureId': s.procedureId,
        };
        final notes = _surgicalNotesCtl[s.id]?.text ?? s.notes;
        final notesTrim = notes.trim();
        if (notesTrim.isNotEmpty) body['notes'] = notesTrim;

        final moRaw = _surgicalMonthCtl[s.id]?.text.trim() ?? '';
        if (moRaw.isNotEmpty) {
          final mo = int.tryParse(moRaw);
          if (mo != null && mo >= 1 && mo <= 12) body['approxMonth'] = mo;
        }
        final yrRaw = _surgicalYearCtl[s.id]?.text.trim() ?? '';
        if (yrRaw.isNotEmpty) {
          final yr = int.tryParse(yrRaw);
          if (yr != null && yr >= 1900 && yr <= 2200) body['approxYear'] = yr;
        }

        if (s.id > 0) {
          body['id'] = s.id;
          await api.putSurgicalHistory(body: body, bearerToken: token);
        } else {
          await api.postSurgicalHistory(body: body, bearerToken: token);
        }
      }

      for (final d in _drugs) {
        final body = <String, dynamic>{
          'patientId': pid,
          'medicineCategoryId': d.medicineCategoryId,
        };
        if (d.adherenceLevelId != null && d.adherenceLevelId! > 0) {
          body['adherenceLevelId'] = d.adherenceLevelId;
        }
        final fx = _drugSideEffectsCtl[d.id]?.text.trim() ?? '';
        if (fx.isNotEmpty) body['sideEffects'] = fx;

        if (d.id > 0) {
          body['id'] = d.id;
          await api.putDrugHistory(body: body, bearerToken: token);
        } else {
          await api.postDrugHistory(body: body, bearerToken: token);
        }
      }

      final baselineBody = <String, dynamic>{
        'patientId': pid,
        'familyHistoryOfHTNOrStroke': _familyHtn,
        'tobaccoUse': _tobacco,
      };
      if (_baselineLoaded) {
        await api.putBaselineLifestyle(
          body: baselineBody,
          bearerToken: token,
        );
      } else {
        await api.postBaselineLifestyle(
          body: baselineBody,
          bearerToken: token,
        );
      }
      if (mounted) setState(() => _baselineLoaded = true);

      if (!mounted) return;
      _toast('Medical data saved.');
      await _loadClinical(session, token);
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _savingMedical = false);
    }
  }

  void _openVisitAssessment() {
    widget.onStartVisit?.call(
      VisitPatientSeed(
        name: widget.summary.fullName,
        id: widget.summary.displayId,
        apiPatientId: widget.summary.patientId,
        age: widget.summary.age,
        gender: widget.summary.gender.trim().isNotEmpty
            ? widget.summary.gender
            : '—',
        lastVisit: patientDetailShortVisit(widget.summary.lastVisitDate),
      ),
    );
  }

  bool get _showsBottomSaveButton =>
      _section == PatientDetailSection.personalInfo ||
      _section == PatientDetailSection.medicalHistory ||
      _section == PatientDetailSection.visitHistory;

  VoidCallback? get _bottomAction => switch (_section) {
        PatientDetailSection.personalInfo =>
          _savingPersonal ? null : _savePersonal,
        PatientDetailSection.medicalHistory =>
          _savingMedical ? null : _saveMedicalAndLifestyle,
        PatientDetailSection.visitHistory => _openVisitAssessment,
      };

  String get _bottomLabel => switch (_section) {
        PatientDetailSection.personalInfo =>
          _savingPersonal ? 'Saving…' : 'Save Changes',
        PatientDetailSection.medicalHistory =>
          _savingMedical ? 'Saving…' : 'Save Medical History',
        PatientDetailSection.visitHistory => 'Log New Visit',
      };

  InputDecoration _fieldDecoration({Widget? suffix, String? hint}) {
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

  Widget _personalForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('BASIC INFORMATION'),
          _label('First Name'),
          TextFormField(
            controller: _firstNameController,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _fieldDecoration(),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 16.h),
          _label('Last Name'),
          TextFormField(
            controller: _lastNameController,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _fieldDecoration(),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 16.h),
          _label('Age (from records)'),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.registrationFieldFill,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.registrationFieldBorder),
            ),
            child: Text(
              '${widget.summary.age}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _label('Date of Birth (update)'),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _pickDob,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _fieldDecoration(
              suffix: IconButton(
                icon: Icon(
                  Icons.calendar_today_rounded,
                  size: 18.sp,
                  color: AppColors.dashboardPrimary,
                ),
                onPressed: _pickDob,
              ),
            ),
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
          TextFormField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            inputFormatters: [CnicInputFormatter()],
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _fieldDecoration(hint: '35202-1234567-1'),
            validator: (v) {
              final masked = CnicInputFormatter.forApi(v ?? '');
              if (masked.isEmpty) return null;
              if (masked.length != 15) return 'Enter complete CNIC';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          if (_maritalStatuses.isNotEmpty) ...[
            _label('Marital status'),
            DropdownButtonFormField<int>(
              value: _maritalStatusId,
              decoration: _fieldDecoration(),
              hint: Text('Select', style: TextStyle(fontSize: 13.sp)),
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
              onChanged: (v) => setState(() => _maritalStatusId = v),
            ),
            SizedBox(height: 16.h),
          ],
          _sectionTitle('CONTACT & LOCATION'),
          _label('Phone Number'),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [PakistanPhoneInputFormatter()],
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _fieldDecoration(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!PakistanPhoneInputFormatter.isValidPakistaniMobile(v)) {
                return 'Enter valid Pakistani mobile';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _label('Province'),
          DropdownButtonFormField<int>(
            value: _provinceId,
            decoration: _fieldDecoration(),
            hint: Text(
              _loadingRefs ? 'Loading…' : 'Select province',
              style: TextStyle(fontSize: 13.sp),
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
            onChanged: _onProvinceChanged,
          ),
          SizedBox(height: 16.h),
          _label('District'),
          DropdownButtonFormField<int>(
            value: _districtId,
            decoration: _fieldDecoration(),
            hint: const Text('Select district'),
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
            onChanged: (v) => _onDistrictChanged(v),
          ),
          SizedBox(height: 16.h),
          _label('Tehsil'),
          DropdownButtonFormField<int>(
            value: _tehsilId,
            decoration: _fieldDecoration(),
            hint: const Text('Select tehsil'),
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
            onChanged: (v) => setState(() => _tehsilId = v),
          ),
          SizedBox(height: 16.h),
          _label('Street Address'),
          TextFormField(
            controller: _streetController,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _fieldDecoration(),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  String _namedRefLabel(List<NamedReferenceItem> items, int id) {
    for (final e in items) {
      if (e.id == id) return e.name;
    }
    return '';
  }

  int? _clinicalRefDropdownValue(
    int? raw,
    List<NamedReferenceItem> items,
  ) {
    if (raw == null || raw <= 0) return null;
    return items.any((e) => e.id == raw) ? raw : null;
  }

  Widget _medicalBody() {
    if (_loadingDetail && _medical.isEmpty && _surgical.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: CircularProgressIndicator(color: AppColors.dashboardPrimary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('CHRONIC CONDITIONS (SERVER)'),
        if (_medical.isEmpty)
          Text(
            'No chronic condition rows yet.',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          )
        else
          ...List.generate(_medical.length, (i) {
            final row = _medical[i];
            final durCtl = _medicalDurationCtl[row.id];
            if (durCtl == null) return const SizedBox.shrink();
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.registrationFieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.conditionName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'On medication',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: row.isOnMedication,
                    onChanged: (v) {
                      setState(() {
                        _medical[i] = _medical[i].copyWith(isOnMedication: v);
                      });
                    },
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: durCtl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _fieldDecoration(
                      hint: 'Duration on treatment (months), optional',
                    ),
                  ),
                  if (_complianceLevels.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    DropdownButtonFormField<int?>(
                      value: _clinicalRefDropdownValue(
                        row.complianceLevelId,
                        _complianceLevels,
                      ),
                      decoration: _fieldDecoration(hint: 'Compliance level'),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            '—',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ..._complianceLevels
                            .where((e) => e.id > 0)
                            .map(
                              (e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          if (v == null) {
                            _medical[i] = _medical[i].copyWith(
                              clearComplianceLevel: true,
                            );
                          } else {
                            _medical[i] = _medical[i].copyWith(
                              complianceLevelId: v,
                              complianceLevelName:
                                  _namedRefLabel(_complianceLevels, v),
                            );
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
        SizedBox(height: 18.h),
        _sectionTitle('SURGICAL HISTORY'),
        if (_surgical.isEmpty)
          Text(
            'No surgical history rows.',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          )
        else
          ...List.generate(_surgical.length, (i) {
            final s = _surgical[i];
            final notesCtl = _surgicalNotesCtl[s.id];
            final moCtl = _surgicalMonthCtl[s.id];
            final yrCtl = _surgicalYearCtl[s.id];
            if (notesCtl == null || moCtl == null || yrCtl == null) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.registrationFieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.procedureName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: notesCtl,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _fieldDecoration(hint: 'Notes (optional)'),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: moCtl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: _fieldDecoration(
                            hint: 'Month (1–12)',
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextFormField(
                          controller: yrCtl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: _fieldDecoration(
                            hint: 'Year (approx.)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        SizedBox(height: 18.h),
        _sectionTitle('DRUG HISTORY'),
        if (_drugs.isEmpty)
          Text(
            'No drug history rows.',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          )
        else
          ...List.generate(_drugs.length, (i) {
            final d = _drugs[i];
            final fxCtl = _drugSideEffectsCtl[d.id];
            if (fxCtl == null) return const SizedBox.shrink();
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.registrationFieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.categoryName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_adherenceLevels.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    DropdownButtonFormField<int?>(
                      value: _clinicalRefDropdownValue(
                        d.adherenceLevelId,
                        _adherenceLevels,
                      ),
                      decoration: _fieldDecoration(hint: 'Adherence level'),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            '—',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ..._adherenceLevels
                            .where((e) => e.id > 0)
                            .map(
                              (e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          if (v == null) {
                            _drugs[i] = _drugs[i].copyWith(
                              clearAdherenceLevel: true,
                            );
                          } else {
                            _drugs[i] = _drugs[i].copyWith(
                              adherenceLevelId: v,
                              adherenceLevelName:
                                  _namedRefLabel(_adherenceLevels, v),
                            );
                          }
                        });
                      },
                    ),
                  ],
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: fxCtl,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _fieldDecoration(
                      hint: 'Side effects / notes (optional)',
                    ),
                  ),
                ],
              ),
            );
          }),
        SizedBox(height: 18.h),
        _sectionTitle('BASELINE LIFESTYLE'),
        if (!_baselineLoaded)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'No baseline lifestyle on record yet — first save uses POST; later saves use PUT.',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Family history of HTN / stroke',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          value: _familyHtn,
          onChanged: (v) => setState(() => _familyHtn = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Tobacco use',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          value: _tobacco,
          onChanged: (v) => setState(() => _tobacco = v),
        ),
      ],
    );
  }

  Widget _visitHistoryMetaLine(PatientVisitRow v) {
    final base = TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.35,
    );
    final spans = <InlineSpan>[];

    void appendSep() {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' • ', style: base));
      }
    }

    if (v.avgSystolicBp != null && v.avgDiastolicBp != null) {
      appendSep();
      final c = BpReadingColor.forPair(
        v.avgSystolicBp!,
        v.avgDiastolicBp!,
      );
      spans.add(
        TextSpan(
          text: 'BP ${v.avgSystolicBp}/${v.avgDiastolicBp}',
          style: base.copyWith(color: c, fontWeight: FontWeight.w800),
        ),
      );
    }
    if (v.pulse != null) {
      appendSep();
      spans.add(TextSpan(text: 'Pulse ${v.pulse}', style: base));
    }
    final reason = v.reasonForVisit.trim();
    if (reason.isNotEmpty) {
      appendSep();
      spans.add(TextSpan(text: reason, style: base));
    }

    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text.rich(TextSpan(children: spans));
  }

  int _visitCountForSegment(_VisitHistorySegment s) {
    switch (s) {
      case _VisitHistorySegment.all:
        return _visits.length;
      case _VisitHistorySegment.followUps:
        return _visits.where((v) => v.isFollowUpVisit).length;
      case _VisitHistorySegment.routine:
        return _visits.where((v) => !v.isFollowUpVisit).length;
    }
  }

  List<PatientVisitRow> _visitsForCurrentSegment() {
    switch (_visitHistorySegment) {
      case _VisitHistorySegment.all:
        return _visits;
      case _VisitHistorySegment.followUps:
        return _visits.where((v) => v.isFollowUpVisit).toList();
      case _VisitHistorySegment.routine:
        return _visits.where((v) => !v.isFollowUpVisit).toList();
    }
  }

  Widget _visitsBody() {
    if (_loadingDetail && _visits.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.dashboardPrimary),
      );
    }
    if (_visits.isEmpty) {
      return Text(
        'No visits found.',
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }
    final shown = _visitsForCurrentSegment();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('VISIT HISTORY')),
            Text(
              _visitHistorySegment == _VisitHistorySegment.all
                  ? '${_visits.length} visits'
                  : '${shown.length} / ${_visits.length}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.registrationSectionLabel,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final seg in _VisitHistorySegment.values)
              ChoiceChip(
                label: Text(
                  '${seg.chipLine} (${_visitCountForSegment(seg)})',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: _visitHistorySegment == seg
                        ? Colors.white
                        : AppColors.dashboardPrimary,
                  ),
                ),
                selected: _visitHistorySegment == seg,
                onSelected: (v) {
                  if (v) setState(() => _visitHistorySegment = seg);
                },
                showCheckmark: false,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: _visitHistorySegment == seg
                        ? AppColors.dashboardPrimary
                        : AppColors.dashboardPrimary.withValues(alpha: 0.35),
                  ),
                ),
                selectedColor: AppColors.dashboardPrimary,
                backgroundColor: AppColors.surface,
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 6.h, bottom: 8.h),
          child: Text(
            'امور / ریکارڈ (وزٹ ہسٹری)',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.registrationSectionLabel,
            ),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Text(
              switch (_visitHistorySegment) {
                _VisitHistorySegment.followUps =>
                  'No follow-up visits in history yet.\nابھی فالو اپ کا کوئی ریکارڈ نہیں۔',
                _VisitHistorySegment.routine =>
                  'No routine / other visits in this filter.\nاس فلٹر میں معمول وزٹ نہیں۔',
                _VisitHistorySegment.all =>
                  'No visits in this view.\nاس فہرست میں کوئی وزٹ نہیں۔',
              },
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          )
        else
          ...shown.map(
            (v) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Material(
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  side: const BorderSide(
                      color: AppColors.registrationFieldBorder),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (ctx) => VisitDetailScreen(
                          patientName: widget.summary.fullName,
                          visit: v,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patientDetailShortVisit(v.visitDate),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dashboardPrimaryDark,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.followUpcomingBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                v.visitStatusName.isNotEmpty
                                    ? v.visitStatusName
                                    : '—',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.followAccentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                v.visitTypeName,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (v.isFollowUpVisit)
                              Padding(
                                padding: EdgeInsets.only(left: 6.w),
                                child: Text(
                                  'فالو اپ',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dashboardWarning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        _visitHistoryMetaLine(v),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(height: 8.h),
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

  Widget _sectionBody() {
    return switch (_section) {
      PatientDetailSection.personalInfo => _personalForm(),
      PatientDetailSection.medicalHistory => _medicalBody(),
      PatientDetailSection.visitHistory => _visitsBody(),
    };
  }

  Widget _tab(PatientDetailSection s) {
    final selected = _section == s;
    return InkWell(
      onTap: () => setState(() => _section = s),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.label,
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

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final initials = s.initials.trim().isNotEmpty
        ? s.initials
        : NameInitials.fromFullName(s.fullName);

    final avatarBg = _avatarForCondition(s.primaryCondition);

    return ColoredBox(
      color: AppColors.registrationScreenBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_detailLoadError != null)
            Material(
              color: AppColors.dashboardPeach,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Text(
                  _detailLoadError!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dashboardWarning,
                  ),
                ),
              ),
            ),
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
                    s.fullName,
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
                        s.fullName,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.surface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Age ${s.age} • ${s.gender} • ${s.displayId}',
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
                              s.primaryCondition.isNotEmpty
                                  ? s.primaryCondition
                                  : '—',
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
                              'Last: ${patientDetailShortVisit(s.lastVisitDate)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface
                                    .withValues(alpha: 0.85),
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
                children: PatientDetailSection.values.map(_tab).toList(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 110.h),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: _sectionBody(),
            ),
          ),
          if (_showsBottomSaveButton)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 12.h),
                child: FilledButton(
                  onPressed: _bottomAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.registrationSaveBlue,
                    foregroundColor: AppColors.surface,
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    _bottomLabel,
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
}
