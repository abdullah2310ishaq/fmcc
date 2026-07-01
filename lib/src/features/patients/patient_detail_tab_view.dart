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
import 'package:doctor_app/src/features/patients/patient_family_history_section.dart';
import 'package:doctor_app/src/features/patients/patient_directory_coordinator.dart';
import 'package:doctor_app/src/features/patients/visit_detail_screen.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';

/// Sentinel dropdown value for reference lists that support a custom name via API.
const int _kClinicalOtherChoiceId = -1;
const String _kClinicalOtherChoiceLabel = 'Other';

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
  familyHistory,
  baselineLifestyle,
  visitHistory,
}

extension on PatientDetailSection {
  String get label => switch (this) {
        PatientDetailSection.personalInfo => 'Personal Info',
        PatientDetailSection.medicalHistory => 'Medical History',
        PatientDetailSection.familyHistory => 'Family History',
        PatientDetailSection.baselineLifestyle => 'Baseline Lifestyle',
        PatientDetailSection.visitHistory => 'Visit History',
      };
}

enum _MedicalHistoryTab { chronic, surgical, drug, tobacco }

extension on _MedicalHistoryTab {
  String get label => switch (this) {
        _MedicalHistoryTab.chronic => 'Chronic History',
        _MedicalHistoryTab.surgical => 'Surgical History',
        _MedicalHistoryTab.drug => 'Drug History',
        _MedicalHistoryTab.tobacco => 'Tobacco History',
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
  final Map<int, TextEditingController> _medicalCustomNameCtl = {};
  final Map<int, TextEditingController> _surgicalNotesCtl = {};
  final Map<int, TextEditingController> _surgicalMonthCtl = {};
  final Map<int, TextEditingController> _surgicalYearCtl = {};
  final Map<int, TextEditingController> _surgicalCustomNameCtl = {};
  final Map<int, TextEditingController> _drugSideEffectsCtl = {};
  final Map<int, TextEditingController> _drugCustomNameCtl = {};
  final _tobaccoTypeController = TextEditingController();
  final _tobaccoQuantityController = TextEditingController();

  List<NamedReferenceItem> _medicalConditions = const [];
  List<NamedReferenceItem> _surgicalProcedures = const [];
  List<NamedReferenceItem> _medicineCategories = const [];
  List<NamedReferenceItem> _relationDegrees = const [];
  int _clinicalTempIdSeq = 0;

  PatientDetailSection _section = PatientDetailSection.personalInfo;
  _MedicalHistoryTab _medicalTab = _MedicalHistoryTab.chronic;
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
  bool _tobaccoUse = false;
  DateTime? _tobaccoDurationStart;
  DateTime? _tobaccoDurationEnd;
  bool _baselineLoaded = false;
  bool _clinicalBundleResolved = false;

  bool _savingPersonal = false;
  bool _savingMedical = false;
  bool _savingBaseline = false;

  final Set<int> _editingChronicIds = {};
  final Set<int> _editingSurgicalIds = {};
  final Set<int> _editingDrugIds = {};
  bool _editingTobacco = false;

  bool _isClinicalRowEditing(int rowId, Set<int> editingIds) =>
      editingIds.contains(rowId);

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
      final results = await Future.wait<List<NamedReferenceItem>>([
        ref.getComplianceLevels(bearerToken: token),
        ref.getAdherenceLevels(bearerToken: token),
        ref.getMedicalConditions(bearerToken: token),
        ref.getSurgicalProcedures(bearerToken: token),
        ref.getMedicineCategories(bearerToken: token),
        ref.getRelationDegrees(bearerToken: token),
      ]);
      if (!mounted) return;
      setState(() {
        _complianceLevels = results[0];
        _adherenceLevels = results[1];
        _medicalConditions = results[2];
        _surgicalProcedures = results[3];
        _medicineCategories = results[4];
        _relationDegrees = results[5];
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  void _deferDisposeControllers(Iterable<TextEditingController> controllers) {
    final pending = controllers.toList(growable: false);
    if (pending.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in pending) {
          c.dispose();
        }
      });
    });
  }

  void _rebuildClinicalTextControllers() {
    final toDispose = <TextEditingController>[];

    void syncMap<T>(
      Iterable<T> rows,
      int Function(T row) idOf,
      Map<int, TextEditingController> map,
      String Function(T row) textOf,
    ) {
      final keep = rows.map(idOf).toSet();
      for (final k in map.keys.toList()) {
        if (!keep.contains(k)) {
          final removed = map.remove(k);
          if (removed != null) toDispose.add(removed);
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
    syncMap<PatientMedicalHistoryRow>(
      _medical,
      (m) => m.id,
      _medicalCustomNameCtl,
      (m) => m.customConditionName,
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
      _surgicalCustomNameCtl,
      (s) => s.customProcedureName,
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
    syncMap<PatientDrugHistoryRow>(
      _drugs,
      (d) => d.id,
      _drugCustomNameCtl,
      (d) => d.customMedicineCategoryName,
    );
    _deferDisposeControllers(toDispose);
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
      _editingChronicIds.clear();
      _editingSurgicalIds.clear();
      _editingDrugIds.clear();
      _editingTobacco = false;
      if (history != null) {
        _medical = List<PatientMedicalHistoryRow>.from(history.medical);
        _surgical = List<PatientSurgicalHistoryRow>.from(history.surgical);
        _drugs = List<PatientDrugHistoryRow>.from(history.drugs);
        _clinicalBundleResolved = true;
        final baseline = history.baseline;
        if (baseline != null) {
          _familyHtn = baseline.familyHistoryOfHtnOrStroke;
          _tobaccoUse = baseline.tobaccoUse;
          _tobaccoTypeController.text = baseline.tobaccoType?.trim() ?? '';
          _tobaccoQuantityController.text =
              baseline.tobaccoQuantityPerDay?.toString() ?? '';
          _tobaccoDurationStart = baseline.tobaccoDurationStart;
          _tobaccoDurationEnd = baseline.tobaccoDurationEnd;
          _baselineLoaded = true;
        } else {
          _familyHtn = false;
          _tobaccoUse = false;
          _tobaccoTypeController.clear();
          _tobaccoQuantityController.clear();
          _tobaccoDurationStart = null;
          _tobaccoDurationEnd = null;
          _baselineLoaded = false;
        }
      } else if (!_clinicalBundleResolved) {
        _medical = const [];
        _surgical = const [];
        _drugs = const [];
        _familyHtn = false;
        _tobaccoUse = false;
        _tobaccoTypeController.clear();
        _tobaccoQuantityController.clear();
        _tobaccoDurationStart = null;
        _tobaccoDurationEnd = null;
        _baselineLoaded = false;
        _clinicalBundleResolved = true;
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
    for (final c in _medicalCustomNameCtl.values) {
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
    for (final c in _surgicalCustomNameCtl.values) {
      c.dispose();
    }
    for (final c in _drugSideEffectsCtl.values) {
      c.dispose();
    }
    for (final c in _drugCustomNameCtl.values) {
      c.dispose();
    }
    _tobaccoTypeController.dispose();
    _tobaccoQuantityController.dispose();
    _medicalDurationCtl.clear();
    _medicalCustomNameCtl.clear();
    _surgicalNotesCtl.clear();
    _surgicalMonthCtl.clear();
    _surgicalYearCtl.clear();
    _surgicalCustomNameCtl.clear();
    _drugSideEffectsCtl.clear();
    _drugCustomNameCtl.clear();
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

  Future<bool> _persistChronicRows({
    required String patientId,
    required PatientApi api,
    required String token,
  }) async {
    for (final row in _medical) {
      final durRaw = _medicalDurationCtl[row.id]?.text.trim() ?? '';
      final customName = _medicalCustomNameCtl[row.id]?.text.trim() ??
          row.customConditionName.trim();
      final isCustom = _isClinicalOtherSelection(
        refId: row.conditionId,
        customName: customName,
      );
      if (isCustom && customName.isEmpty) {
        _toast('Enter a custom condition name for each “Other” row.');
        return false;
      }
      if (!isCustom && row.conditionId <= 0) {
        _toast('Select a medical condition for each chronic row.');
        return false;
      }

      final body = <String, dynamic>{
        'patientId': patientId,
        'isOnMedication': row.isOnMedication,
      };
      if (isCustom) {
        body['customConditionName'] = customName;
      } else {
        body['conditionId'] = row.conditionId;
      }
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
    return true;
  }

  Future<bool> _persistSurgicalRows({
    required String patientId,
    required PatientApi api,
    required String token,
  }) async {
    for (final s in _surgical) {
      final customName = _surgicalCustomNameCtl[s.id]?.text.trim() ??
          s.customProcedureName.trim();
      final isCustom = _isClinicalOtherSelection(
        refId: s.procedureId,
        customName: customName,
      );
      if (isCustom && customName.isEmpty) {
        _toast('Enter a custom procedure name for each “Other” row.');
        return false;
      }
      if (!isCustom && s.procedureId <= 0) {
        _toast('Select a procedure for each surgical row.');
        return false;
      }

      final body = <String, dynamic>{
        'patientId': patientId,
      };
      if (isCustom) {
        body['customProcedureName'] = customName;
      } else {
        body['procedureId'] = s.procedureId;
      }
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
    return true;
  }

  Future<bool> _persistDrugRows({
    required String patientId,
    required PatientApi api,
    required String token,
  }) async {
    for (final d in _drugs) {
      final customName = _drugCustomNameCtl[d.id]?.text.trim() ??
          d.customMedicineCategoryName.trim();
      final isCustom = _isClinicalOtherSelection(
        refId: d.medicineCategoryId,
        customName: customName,
      );
      if (isCustom && customName.isEmpty) {
        _toast('Enter a custom category name for each “Other” drug row.');
        return false;
      }
      if (!isCustom && d.medicineCategoryId <= 0) {
        _toast('Select a medicine category for each drug row.');
        return false;
      }

      final body = <String, dynamic>{
        'patientId': patientId,
      };
      if (isCustom) {
        body['customMedicineCategoryName'] = customName;
      } else {
        body['medicineCategoryId'] = d.medicineCategoryId;
      }
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
    return true;
  }

  Future<void> _saveMedicalAndLifestyle() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }
    if (_medicalTab == _MedicalHistoryTab.tobacco) {
      return;
    }
    final pid = widget.summary.patientId;
    final api = _patientApi!;

    setState(() => _savingMedical = true);
    try {
      final saved = switch (_medicalTab) {
        _MedicalHistoryTab.chronic => await _persistChronicRows(
            patientId: pid,
            api: api,
            token: token,
          ),
        _MedicalHistoryTab.surgical => await _persistSurgicalRows(
            patientId: pid,
            api: api,
            token: token,
          ),
        _MedicalHistoryTab.drug => await _persistDrugRows(
            patientId: pid,
            api: api,
            token: token,
          ),
        _MedicalHistoryTab.tobacco => true,
      };
      if (!saved || !mounted) return;

      _toast('Medical history saved.');
      await _loadClinical(session, token);
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _savingMedical = false);
    }
  }

  String _apiDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _displayDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Map<String, dynamic> _buildBaselineLifestyleBody(String patientId) {
    final body = <String, dynamic>{
      'patientId': patientId,
      'familyHistoryOfHTNOrStroke': _familyHtn,
      'tobaccoUse': _tobaccoUse,
    };
    final type = _tobaccoTypeController.text.trim();
    if (type.isNotEmpty) body['tobaccoType'] = type;
    final qtyRaw = _tobaccoQuantityController.text.trim();
    if (qtyRaw.isNotEmpty) {
      final qty = int.tryParse(qtyRaw);
      if (qty != null && qty >= 0) {
        body['tobaccoQuantityPerDay'] = qty;
      }
    }
    final start = _tobaccoDurationStart;
    if (start != null) {
      body['tobaccoDurationStart'] = _apiDateOnly(start);
    }
    final end = _tobaccoDurationEnd;
    if (end != null) {
      body['tobaccoDurationEnd'] = _apiDateOnly(end);
    }
    return body;
  }

  Future<void> _pickTobaccoDate({
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_tobaccoDurationStart ?? now)
        : (_tobaccoDurationEnd ?? _tobaccoDurationStart ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
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
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _tobaccoDurationStart = picked;
      } else {
        _tobaccoDurationEnd = picked;
      }
    });
  }

  Future<void> _saveBaselineLifestyle({
    required String successMessage,
    bool validateTobacco = false,
  }) async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }
    if (validateTobacco &&
        _tobaccoUse &&
        _tobaccoTypeController.text.trim().isEmpty) {
      _toast('Enter tobacco type when tobacco use is enabled.');
      return;
    }

    final pid = widget.summary.patientId;
    final api = _patientApi!;
    final body = _buildBaselineLifestyleBody(pid);

    setState(() => _savingBaseline = true);
    try {
      if (_baselineLoaded) {
        await api.putBaselineLifestyle(body: body, bearerToken: token);
      } else {
        await api.postBaselineLifestyle(body: body, bearerToken: token);
      }
      if (!mounted) return;
      _toast(successMessage);
      setState(() => _editingTobacco = false);
      await _loadClinical(session, token);
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _savingBaseline = false);
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

  Widget _tobaccoDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: _fieldDecoration(hint: label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _displayDate(date),
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

  Widget _primaryCtaButton({
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.registrationSaveBlue,
          foregroundColor: AppColors.surface,
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        _primaryCtaButton(
          onPressed: _savingPersonal ? null : _savePersonal,
          label: _savingPersonal ? 'Saving…' : 'Save Changes',
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
      ],
    );
  }

  String _namedRefLabel(List<NamedReferenceItem> items, int id) {
    for (final e in items) {
      if (e.id == id) return e.name;
    }
    return '';
  }

  bool _isClinicalOtherSelection({
    required int refId,
    required String customName,
  }) {
    return refId == _kClinicalOtherChoiceId || customName.trim().isNotEmpty;
  }

  int? _clinicalRefDropdownSelectedValue({
    required int refId,
    required String customName,
    required List<NamedReferenceItem> choices,
  }) {
    if (_isClinicalOtherSelection(refId: refId, customName: customName)) {
      return _kClinicalOtherChoiceId;
    }
    if (refId > 0 && choices.any((e) => e.id == refId)) return refId;
    return null;
  }

  List<DropdownMenuItem<int>> _clinicalRefDropdownItems(
    List<NamedReferenceItem> choices,
  ) {
    return [
      ...choices.map(
        (e) => DropdownMenuItem<int>(
          value: e.id,
          child: Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      DropdownMenuItem<int>(
        value: _kClinicalOtherChoiceId,
        child: Text(
          _kClinicalOtherChoiceLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  Widget _clinicalCustomNameField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: _fieldDecoration(hint: hint),
    );
  }

  int? _clinicalRefDropdownValue(
    int? raw,
    List<NamedReferenceItem> items,
  ) {
    if (raw == null || raw <= 0) return null;
    return items.any((e) => e.id == raw) ? raw : null;
  }

  int _allocTempClinicalId() => --_clinicalTempIdSeq;

  Set<int> _usedConditionIdsExcludingIndex(int excludeIndex) {
    final o = <int>{};
    for (var j = 0; j < _medical.length; j++) {
      if (j == excludeIndex) continue;
      final c = _medical[j].conditionId;
      if (c > 0) o.add(c);
    }
    return o;
  }

  List<NamedReferenceItem> _conditionChoicesForRow(int index) {
    final selfId = _medical[index].conditionId;
    final blocked = _usedConditionIdsExcludingIndex(index);
    return _medicalConditions
        .where((e) => e.id > 0 && (!blocked.contains(e.id) || e.id == selfId))
        .toList(growable: false);
  }

  Set<int> _usedProcedureIdsExcludingIndex(int excludeIndex) {
    final o = <int>{};
    for (var j = 0; j < _surgical.length; j++) {
      if (j == excludeIndex) continue;
      final p = _surgical[j].procedureId;
      if (p > 0) o.add(p);
    }
    return o;
  }

  List<NamedReferenceItem> _procedureChoicesForRow(int index) {
    final selfId = _surgical[index].procedureId;
    final blocked = _usedProcedureIdsExcludingIndex(index);
    return _surgicalProcedures
        .where((e) => e.id > 0 && (!blocked.contains(e.id) || e.id == selfId))
        .toList(growable: false);
  }

  Set<int> _usedCategoryIdsExcludingIndex(int excludeIndex) {
    final o = <int>{};
    for (var j = 0; j < _drugs.length; j++) {
      if (j == excludeIndex) continue;
      final c = _drugs[j].medicineCategoryId;
      if (c > 0) o.add(c);
    }
    return o;
  }

  List<NamedReferenceItem> _categoryChoicesForRow(int index) {
    final selfId = _drugs[index].medicineCategoryId;
    final blocked = _usedCategoryIdsExcludingIndex(index);
    return _medicineCategories
        .where((e) => e.id > 0 && (!blocked.contains(e.id) || e.id == selfId))
        .toList(growable: false);
  }

  void _addMedicalDraft() {
    final used =
        _medical.map((e) => e.conditionId).where((id) => id > 0).toSet();
    final available = _medicalConditions
        .where((e) => e.id > 0 && !used.contains(e.id))
        .toList(growable: false);
    if (_medicalConditions.isEmpty) {
      _toast('Medical condition list is still loading or empty.');
      return;
    }
    unawaited(_showAddChronicDialog(available));
  }

  void _addSurgicalDraft() {
    final used =
        _surgical.map((e) => e.procedureId).where((id) => id > 0).toSet();
    final available = _surgicalProcedures
        .where((e) => e.id > 0 && !used.contains(e.id))
        .toList(growable: false);
    if (_surgicalProcedures.isEmpty) {
      _toast('Procedure list is still loading or empty.');
      return;
    }
    unawaited(_showAddSurgicalDialog(available));
  }

  void _addDrugDraft() {
    final used =
        _drugs.map((e) => e.medicineCategoryId).where((id) => id > 0).toSet();
    final available = _medicineCategories
        .where((e) => e.id > 0 && !used.contains(e.id))
        .toList(growable: false);
    if (_medicineCategories.isEmpty) {
      _toast('Medicine category list is still loading or empty.');
      return;
    }
    unawaited(_showAddDrugDialog(available));
  }

  Future<void> _showAddChronicDialog(
    List<NamedReferenceItem> available,
  ) async {
    final useOtherFirst = available.isEmpty;
    int conditionId =
        useOtherFirst ? _kClinicalOtherChoiceId : available.first.id;
    String conditionName = useOtherFirst ? '' : available.first.name;
    String customConditionName = '';
    bool onMedication = false;
    int? complianceLevelId;
    String complianceLevelName = '';

    final row = await showDialog<PatientMedicalHistoryRow>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) {
        return _DialogControllerScope(
          controllerCount: 2,
          builder: (context, ctrls) {
            final customNameCtl = ctrls[0];
            final durationCtl = ctrls[1];
            return StatefulBuilder(
              builder: (ctx, setLocal) {
                return Dialog(
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 6,
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 480.w),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyModalHeader(
                            icon: Icons.monitor_heart_outlined,
                            title: 'Add chronic condition',
                            subtitle:
                                'Saved when you tap Save Medical History.',
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _clinicalRefDropdownSelectedValue(
                                    refId: conditionId,
                                    customName: customConditionName,
                                    choices: available,
                                  ),
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                    hint: 'Medical condition',
                                  ),
                                  items: _clinicalRefDropdownItems(available),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setLocal(() {
                                      if (v == _kClinicalOtherChoiceId) {
                                        conditionId = _kClinicalOtherChoiceId;
                                        conditionName = '';
                                      } else {
                                        conditionId = v;
                                        conditionName =
                                            _namedRefLabel(available, v);
                                        customConditionName = '';
                                        customNameCtl.clear();
                                      }
                                    });
                                  },
                                ),
                                if (conditionId == _kClinicalOtherChoiceId) ...[
                                  SizedBox(height: 12.h),
                                  _clinicalCustomNameField(
                                    controller: customNameCtl,
                                    hint: 'Custom condition name',
                                    onChanged: (v) =>
                                        customConditionName = v.trim(),
                                  ),
                                ],
                                SizedBox(height: 12.h),
                                TextFormField(
                                  controller: durationCtl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _fieldDecoration(
                                    hint: 'Duration on treatment (months)',
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'On medication',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: onMedication,
                                  onChanged: (v) =>
                                      setLocal(() => onMedication = v),
                                ),
                                if (_complianceLevels.isNotEmpty)
                                  DropdownButtonFormField<int?>(
                                    value: complianceLevelId,
                                    isExpanded: true,
                                    decoration: _fieldDecoration(
                                      hint: 'Compliance level (optional)',
                                    ),
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          '—',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                    onChanged: (v) {
                                      setLocal(() {
                                        complianceLevelId = v;
                                        complianceLevelName = v == null
                                            ? ''
                                            : _complianceLevels
                                                .firstWhere((e) => e.id == v)
                                                .name;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                          _historyModalFooter(
                            onCancel: () => Navigator.of(dialogCtx).pop(),
                            onSubmit: () {
                              final isOther =
                                  conditionId == _kClinicalOtherChoiceId;
                              final custom = customNameCtl.text.trim();
                              if (isOther && custom.isEmpty) {
                                _toast('Enter a custom condition name.');
                                return;
                              }
                              if (!isOther && conditionId <= 0) {
                                _toast('Select a medical condition.');
                                return;
                              }
                              final dur = int.tryParse(durationCtl.text.trim());
                              Navigator.of(dialogCtx).pop(
                                PatientMedicalHistoryRow(
                                  id: _allocTempClinicalId(),
                                  patientId: widget.summary.patientId,
                                  conditionId: isOther
                                      ? _kClinicalOtherChoiceId
                                      : conditionId,
                                  conditionName: isOther ? '' : conditionName,
                                  customConditionName: isOther ? custom : '',
                                  durationInMonths: dur,
                                  isOnMedication: onMedication,
                                  complianceLevelId: complianceLevelId,
                                  complianceLevelName: complianceLevelName,
                                ),
                              );
                            },
                            submitLabel: 'Add condition',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (row == null || !mounted) return;
    setState(() {
      _medical = [..._medical, row];
    });
    _rebuildClinicalTextControllers();
  }

  Future<void> _showAddSurgicalDialog(
    List<NamedReferenceItem> available,
  ) async {
    final useOtherFirst = available.isEmpty;
    int procedureId =
        useOtherFirst ? _kClinicalOtherChoiceId : available.first.id;
    String procedureName = useOtherFirst ? '' : available.first.name;
    String customProcedureName = '';

    final row = await showDialog<PatientSurgicalHistoryRow>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) {
        return _DialogControllerScope(
          controllerCount: 4,
          builder: (context, ctrls) {
            final customNameCtl = ctrls[0];
            final notesCtl = ctrls[1];
            final monthCtl = ctrls[2];
            final yearCtl = ctrls[3];
            return StatefulBuilder(
              builder: (ctx, setLocal) {
                return Dialog(
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 6,
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 480.w),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyModalHeader(
                            icon: Icons.local_hospital_outlined,
                            title: 'Add surgical procedure',
                            subtitle: 'Approximate date is optional.',
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _clinicalRefDropdownSelectedValue(
                                    refId: procedureId,
                                    customName: customProcedureName,
                                    choices: available,
                                  ),
                                  isExpanded: true,
                                  decoration:
                                      _fieldDecoration(hint: 'Procedure'),
                                  items: _clinicalRefDropdownItems(available),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setLocal(() {
                                      if (v == _kClinicalOtherChoiceId) {
                                        procedureId = _kClinicalOtherChoiceId;
                                        procedureName = '';
                                      } else {
                                        procedureId = v;
                                        procedureName =
                                            _namedRefLabel(available, v);
                                        customProcedureName = '';
                                        customNameCtl.clear();
                                      }
                                    });
                                  },
                                ),
                                if (procedureId == _kClinicalOtherChoiceId) ...[
                                  SizedBox(height: 12.h),
                                  _clinicalCustomNameField(
                                    controller: customNameCtl,
                                    hint: 'Custom procedure name',
                                    onChanged: (v) =>
                                        customProcedureName = v.trim(),
                                  ),
                                ],
                                SizedBox(height: 12.h),
                                TextFormField(
                                  controller: notesCtl,
                                  maxLines: 3,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _fieldDecoration(
                                      hint: 'Notes (optional)'),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: monthCtl,
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
                                        controller: yearCtl,
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
                          ),
                          _historyModalFooter(
                            onCancel: () => Navigator.of(dialogCtx).pop(),
                            onSubmit: () {
                              final isOther =
                                  procedureId == _kClinicalOtherChoiceId;
                              final custom = customNameCtl.text.trim();
                              if (isOther && custom.isEmpty) {
                                _toast('Enter a custom procedure name.');
                                return;
                              }
                              if (!isOther && procedureId <= 0) {
                                _toast('Select a procedure.');
                                return;
                              }
                              final mo = int.tryParse(monthCtl.text.trim());
                              final yr = int.tryParse(yearCtl.text.trim());
                              Navigator.of(dialogCtx).pop(
                                PatientSurgicalHistoryRow(
                                  id: _allocTempClinicalId(),
                                  patientId: widget.summary.patientId,
                                  procedureId: isOther
                                      ? _kClinicalOtherChoiceId
                                      : procedureId,
                                  procedureName: isOther ? '' : procedureName,
                                  customProcedureName: isOther ? custom : '',
                                  approxMonth: mo,
                                  approxYear: yr,
                                  notes: notesCtl.text.trim(),
                                ),
                              );
                            },
                            submitLabel: 'Add procedure',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (row == null || !mounted) return;
    setState(() {
      _surgical = [..._surgical, row];
    });
    _rebuildClinicalTextControllers();
  }

  Future<void> _showAddDrugDialog(
    List<NamedReferenceItem> available,
  ) async {
    final useOtherFirst = available.isEmpty;
    int categoryId =
        useOtherFirst ? _kClinicalOtherChoiceId : available.first.id;
    String categoryName = useOtherFirst ? '' : available.first.name;
    String customCategoryName = '';
    int? adherenceLevelId;
    String adherenceLevelName = '';

    final row = await showDialog<PatientDrugHistoryRow>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) {
        return _DialogControllerScope(
          controllerCount: 2,
          builder: (context, ctrls) {
            final customNameCtl = ctrls[0];
            final sideEffectsCtl = ctrls[1];
            return StatefulBuilder(
              builder: (ctx, setLocal) {
                return Dialog(
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 6,
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 480.w),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyModalHeader(
                            icon: Icons.medication_liquid_outlined,
                            title: 'Add drug category',
                            subtitle:
                                'Adherence and side effects are optional.',
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _clinicalRefDropdownSelectedValue(
                                    refId: categoryId,
                                    customName: customCategoryName,
                                    choices: available,
                                  ),
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                    hint: 'Medicine category',
                                  ),
                                  items: _clinicalRefDropdownItems(available),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setLocal(() {
                                      if (v == _kClinicalOtherChoiceId) {
                                        categoryId = _kClinicalOtherChoiceId;
                                        categoryName = '';
                                      } else {
                                        categoryId = v;
                                        categoryName =
                                            _namedRefLabel(available, v);
                                        customCategoryName = '';
                                        customNameCtl.clear();
                                      }
                                    });
                                  },
                                ),
                                if (categoryId == _kClinicalOtherChoiceId) ...[
                                  SizedBox(height: 12.h),
                                  _clinicalCustomNameField(
                                    controller: customNameCtl,
                                    hint: 'Custom medicine category name',
                                    onChanged: (v) =>
                                        customCategoryName = v.trim(),
                                  ),
                                ],
                                if (_adherenceLevels.isNotEmpty) ...[
                                  SizedBox(height: 12.h),
                                  DropdownButtonFormField<int?>(
                                    value: adherenceLevelId,
                                    isExpanded: true,
                                    decoration: _fieldDecoration(
                                      hint: 'Adherence level (optional)',
                                    ),
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          '—',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                    onChanged: (v) {
                                      setLocal(() {
                                        adherenceLevelId = v;
                                        adherenceLevelName = v == null
                                            ? ''
                                            : _adherenceLevels
                                                .firstWhere((e) => e.id == v)
                                                .name;
                                      });
                                    },
                                  ),
                                ],
                                SizedBox(height: 12.h),
                                TextFormField(
                                  controller: sideEffectsCtl,
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
                          ),
                          _historyModalFooter(
                            onCancel: () => Navigator.of(dialogCtx).pop(),
                            onSubmit: () {
                              final isOther =
                                  categoryId == _kClinicalOtherChoiceId;
                              final custom = customNameCtl.text.trim();
                              if (isOther && custom.isEmpty) {
                                _toast(
                                    'Enter a custom medicine category name.');
                                return;
                              }
                              if (!isOther && categoryId <= 0) {
                                _toast('Select a medicine category.');
                                return;
                              }
                              Navigator.of(dialogCtx).pop(
                                PatientDrugHistoryRow(
                                  id: _allocTempClinicalId(),
                                  patientId: widget.summary.patientId,
                                  medicineCategoryId: isOther
                                      ? _kClinicalOtherChoiceId
                                      : categoryId,
                                  categoryName: isOther ? '' : categoryName,
                                  customMedicineCategoryName:
                                      isOther ? custom : '',
                                  adherenceLevelId: adherenceLevelId,
                                  adherenceLevelName: adherenceLevelName,
                                  sideEffects: sideEffectsCtl.text.trim(),
                                ),
                              );
                            },
                            submitLabel: 'Add category',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (row == null || !mounted) return;
    setState(() {
      _drugs = [..._drugs, row];
    });
    _rebuildClinicalTextControllers();
  }

  Widget _historyModalHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.registrationFieldFill.withValues(alpha: 0.65),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.85),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.dashboardChipBlueBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: AppColors.dashboardPrimary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      subtitle.trim(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyModalFooter({
    required VoidCallback onCancel,
    required VoidCallback? onSubmit,
    required String submitLabel,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dashboardPrimary,
              foregroundColor: AppColors.surface,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              submitLabel,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteHistoryEntry({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: AppColors.dashboardPeach.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/delete.png',
                        width: 28.r,
                        height: 28.r,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.delete_outline_rounded,
                            size: 28.sp,
                            color: AppColors.dashboardPrimaryDark,
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dashboardPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dashboardPrimaryDark,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Widget _historyEntryDeleteButton({required VoidCallback onPressed}) {
    return Tooltip(
      message: 'Delete',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Image.asset(
              'assets/delete.png',
              width: 24.r,
              height: 24.r,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.delete_outline_rounded,
                  size: 24.sp,
                  color: AppColors.dashboardPrimaryDark,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _cancelTobaccoEdit() {
    setState(() {
      _editingTobacco = false;
      if (!_baselineLoaded) {
        _tobaccoUse = false;
        _tobaccoTypeController.clear();
        _tobaccoQuantityController.clear();
        _tobaccoDurationStart = null;
        _tobaccoDurationEnd = null;
      }
    });
  }

  Widget _historyHeaderAddButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.dashboardPrimary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 16.sp,
                color: AppColors.surface,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyEntryUpdateButton({
    required VoidCallback onPressed,
    String label = 'Update',
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.dashboardPrimary,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _historyEntryViewActions({
    required VoidCallback onUpdate,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _historyEntryUpdateButton(onPressed: onUpdate),
        _historyEntryDeleteButton(onPressed: onDelete),
      ],
    );
  }

  Widget _historyViewLine({
    required String label,
    required String value,
  }) {
    final text = value.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCardHeader({
    required String title,
    required bool isDraft,
    required bool isEditing,
    required VoidCallback onUpdate,
    required VoidCallback onDelete,
  }) {
    final displayTitle =
        title.trim().isNotEmpty ? title.trim() : (isDraft ? 'New entry' : '—');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDraft) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.dashboardPeach.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'New',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dashboardWarning,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Text(
            displayTitle,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (isEditing)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _historyEntryUpdateButton(
                onPressed: onUpdate,
                label: 'View',
              ),
              _historyEntryDeleteButton(onPressed: onDelete),
            ],
          )
        else
          _historyEntryViewActions(onUpdate: onUpdate, onDelete: onDelete),
      ],
    );
  }

  String _formatSurgicalApproxDate(PatientSurgicalHistoryRow row) {
    final mo = row.approxMonth;
    final yr = row.approxYear;
    if (mo != null && yr != null) return '$mo/$yr';
    if (yr != null) return yr.toString();
    if (mo != null) return 'Month $mo';
    return '';
  }

  void _removeMedicalEntryAt(int index) {
    if (index < 0 || index >= _medical.length) return;
    setState(() {
      _medical = [..._medical]..removeAt(index);
    });
    _rebuildClinicalTextControllers();
  }

  void _removeSurgicalEntryAt(int index) {
    if (index < 0 || index >= _surgical.length) return;
    setState(() {
      _surgical = [..._surgical]..removeAt(index);
    });
    _rebuildClinicalTextControllers();
  }

  void _removeDrugEntryAt(int index) {
    if (index < 0 || index >= _drugs.length) return;
    setState(() {
      _drugs = [..._drugs]..removeAt(index);
    });
    _rebuildClinicalTextControllers();
  }

  Future<void> _offerDeleteMedicalRow(int index) async {
    if (index < 0 || index >= _medical.length) return;
    final row = _medical[index];
    final isDraft = row.id <= 0;
    final name = row.displayConditionName.trim().isNotEmpty
        ? row.displayConditionName.trim()
        : 'This entry';
    final ok = await _confirmDeleteHistoryEntry(
      title: isDraft ? 'Discard new condition?' : 'Delete chronic condition?',
      message: isDraft
          ? '“$name” will be removed. You can add another with “Add condition”.'
          : '“$name” will be permanently deleted on the server when you confirm.',
    );
    if (!mounted || !ok) return;

    if (isDraft) {
      _removeMedicalEntryAt(index);
      _editingChronicIds.remove(row.id);
      _toast('Draft removed.');
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    try {
      await _patientApi!.deleteMedicalHistory(id: row.id, bearerToken: token);
      if (!mounted) return;
      final idx = _medical.indexWhere((e) => e.id == row.id);
      if (idx >= 0) _removeMedicalEntryAt(idx);
      _editingChronicIds.remove(row.id);
      _toast('Chronic condition deleted.');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Future<void> _offerDeleteSurgicalRow(int index) async {
    if (index < 0 || index >= _surgical.length) return;
    final row = _surgical[index];
    final isDraft = row.id <= 0;
    final name = row.displayProcedureName.trim().isNotEmpty
        ? row.displayProcedureName.trim()
        : 'This entry';
    final ok = await _confirmDeleteHistoryEntry(
      title: isDraft ? 'Discard new procedure?' : 'Delete procedure?',
      message: isDraft
          ? '“$name” will be removed. You can add another with “Add procedure”.'
          : '“$name” will be permanently deleted on the server when you confirm.',
    );
    if (!mounted || !ok) return;

    if (isDraft) {
      _removeSurgicalEntryAt(index);
      _editingSurgicalIds.remove(row.id);
      _toast('Draft removed.');
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    try {
      await _patientApi!.deleteSurgicalHistory(id: row.id, bearerToken: token);
      if (!mounted) return;
      final idx = _surgical.indexWhere((e) => e.id == row.id);
      if (idx >= 0) _removeSurgicalEntryAt(idx);
      _editingSurgicalIds.remove(row.id);
      _toast('Surgical history deleted.');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Future<void> _offerDeleteDrugRow(int index) async {
    if (index < 0 || index >= _drugs.length) return;
    final row = _drugs[index];
    final isDraft = row.id <= 0;
    final name = row.displayCategoryName.trim().isNotEmpty
        ? row.displayCategoryName.trim()
        : 'This entry';
    final ok = await _confirmDeleteHistoryEntry(
      title: isDraft ? 'Discard new drug row?' : 'Delete drug history row?',
      message: isDraft
          ? '“$name” will be removed. You can add another with “Add category”.'
          : '“$name” will be permanently deleted on the server when you confirm.',
    );
    if (!mounted || !ok) return;

    if (isDraft) {
      _removeDrugEntryAt(index);
      _editingDrugIds.remove(row.id);
      _toast('Draft removed.');
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    try {
      await _patientApi!.deleteDrugHistory(id: row.id, bearerToken: token);
      if (!mounted) return;
      final idx = _drugs.indexWhere((e) => e.id == row.id);
      if (idx >= 0) _removeDrugEntryAt(idx);
      _editingDrugIds.remove(row.id);
      _toast('Drug history deleted.');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Future<void> _offerDeleteTobacco() async {
    final ok = await _confirmDeleteHistoryEntry(
      title: 'Clear tobacco history?',
      message:
          'Tobacco details will be removed for this patient when you confirm.',
    );
    if (!mounted || !ok) return;

    setState(() {
      _tobaccoUse = false;
      _tobaccoTypeController.clear();
      _tobaccoQuantityController.clear();
      _tobaccoDurationStart = null;
      _tobaccoDurationEnd = null;
      _editingTobacco = false;
    });

    await _saveBaselineLifestyle(
      successMessage: 'Tobacco history cleared.',
    );
  }

  Widget _historySectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? headerTrailing,
    Widget? footer,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    icon,
                    size: 20.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
                if (headerTrailing != null) headerTrailing,
              ],
            ),
          ),
          child,
          if (footer != null) ...[
            SizedBox(height: 12.h),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _medicalBody() {
    if (_loadingDetail &&
        _medical.isEmpty &&
        _surgical.isEmpty &&
        _drugs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.dashboardPrimary,
              ),
            ),
          ),
          _primaryCtaButton(
            onPressed: _savingMedical ? null : _saveMedicalAndLifestyle,
            label: _savingMedical ? 'Saving…' : 'Save Medical History',
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _medicalSubTabBar(),
        SizedBox(height: 14.h),
        if (_medicalTab == _MedicalHistoryTab.chronic)
          _historySectionCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Chronic conditions',
            headerTrailing: _medicalAddButton(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_medical.isEmpty)
                  Text(
                    'No chronic conditions on file yet. Use “Add condition” to create one.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  )
                else
                  ...List.generate(_medical.length, (i) {
                    final row = _medical[i];
                    final durCtl = _medicalDurationCtl[row.id];
                    final customNameCtl = _medicalCustomNameCtl[row.id];
                    if (durCtl == null || customNameCtl == null) {
                      return const SizedBox.shrink();
                    }
                    final isDraft = row.id <= 0;
                    final isEditing =
                        _isClinicalRowEditing(row.id, _editingChronicIds);
                    final choices = _conditionChoicesForRow(i);
                    final showCustomField = _isClinicalOtherSelection(
                      refId: row.conditionId,
                      customName: customNameCtl.text,
                    );
                    return Container(
                      key: ValueKey('chronic-${row.id}'),
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.registrationFieldFill
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                            color: AppColors.registrationFieldBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyCardHeader(
                            title: row.displayConditionName,
                            isDraft: isDraft,
                            isEditing: isEditing,
                            onUpdate: () => setState(() {
                              if (_editingChronicIds.contains(row.id)) {
                                _editingChronicIds.remove(row.id);
                              } else {
                                _editingChronicIds.add(row.id);
                              }
                            }),
                            onDelete: () =>
                                unawaited(_offerDeleteMedicalRow(i)),
                          ),
                          if (isEditing) ...[
                            if (isDraft) ...[
                              SizedBox(height: 8.h),
                              if (choices.isEmpty &&
                                  row.conditionId != _kClinicalOtherChoiceId)
                                Text(
                                  'No selectable conditions (lists loading or all already added). Choose Other.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.dashboardWarning,
                                  ),
                                )
                              else
                                DropdownButtonFormField<int>(
                                  value: _clinicalRefDropdownSelectedValue(
                                    refId: row.conditionId,
                                    customName: customNameCtl.text,
                                    choices: choices,
                                  ),
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                      hint: 'Medical condition'),
                                  items: _clinicalRefDropdownItems(choices),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      if (v == _kClinicalOtherChoiceId) {
                                        _medical[i] = _medical[i].copyWith(
                                          conditionId: _kClinicalOtherChoiceId,
                                          conditionName: '',
                                          clearCustomCondition: true,
                                        );
                                        customNameCtl.clear();
                                      } else {
                                        _medical[i] = _medical[i].copyWith(
                                          conditionId: v,
                                          conditionName:
                                              _namedRefLabel(choices, v),
                                          clearCustomCondition: true,
                                        );
                                        customNameCtl.clear();
                                      }
                                    });
                                  },
                                ),
                              if (showCustomField) ...[
                                SizedBox(height: 10.h),
                                _clinicalCustomNameField(
                                  controller: customNameCtl,
                                  hint: 'Custom condition name',
                                  onChanged: (v) {
                                    setState(() {
                                      _medical[i] = _medical[i].copyWith(
                                        customConditionName: v.trim(),
                                      );
                                    });
                                  },
                                ),
                              ],
                            ],
                            if (!isDraft) SizedBox(height: 8.h),
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
                                  _medical[i] =
                                      _medical[i].copyWith(isOnMedication: v);
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
                                hint:
                                    'Duration on treatment (months), optional',
                              ),
                            ),
                            if (_complianceLevels.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              DropdownButtonFormField<int?>(
                                value: _clinicalRefDropdownValue(
                                  row.complianceLevelId,
                                  _complianceLevels,
                                ),
                                isExpanded: true,
                                decoration:
                                    _fieldDecoration(hint: 'Compliance level'),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                        complianceLevelName: _namedRefLabel(
                                            _complianceLevels, v),
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ] else ...[
                            SizedBox(height: 8.h),
                            _historyViewLine(
                              label: 'On medication',
                              value: row.isOnMedication ? 'Yes' : 'No',
                            ),
                            _historyViewLine(
                              label: 'Duration on treatment (months)',
                              value: row.durationInMonths?.toString() ??
                                  durCtl.text.trim(),
                            ),
                            _historyViewLine(
                              label: 'Compliance level',
                              value: row.complianceLevelName,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        if (_medicalTab == _MedicalHistoryTab.surgical)
          _historySectionCard(
            icon: Icons.local_hospital_outlined,
            title: 'Surgical history',
            headerTrailing: _medicalAddButton(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_surgical.isEmpty)
                  Text(
                    'No surgical procedures on file yet. Use “Add procedure” to add one.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  )
                else
                  ...List.generate(_surgical.length, (i) {
                    final s = _surgical[i];
                    final notesCtl = _surgicalNotesCtl[s.id];
                    final moCtl = _surgicalMonthCtl[s.id];
                    final yrCtl = _surgicalYearCtl[s.id];
                    final customNameCtl = _surgicalCustomNameCtl[s.id];
                    if (notesCtl == null ||
                        moCtl == null ||
                        yrCtl == null ||
                        customNameCtl == null) {
                      return const SizedBox.shrink();
                    }
                    final isDraft = s.id <= 0;
                    final isEditing =
                        _isClinicalRowEditing(s.id, _editingSurgicalIds);
                    final procChoices = _procedureChoicesForRow(i);
                    final showCustomField = _isClinicalOtherSelection(
                      refId: s.procedureId,
                      customName: customNameCtl.text,
                    );
                    return Container(
                      key: ValueKey('surgical-${s.id}'),
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.registrationFieldFill
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                            color: AppColors.registrationFieldBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyCardHeader(
                            title: s.displayProcedureName,
                            isDraft: isDraft,
                            isEditing: isEditing,
                            onUpdate: () => setState(() {
                              if (_editingSurgicalIds.contains(s.id)) {
                                _editingSurgicalIds.remove(s.id);
                              } else {
                                _editingSurgicalIds.add(s.id);
                              }
                            }),
                            onDelete: () =>
                                unawaited(_offerDeleteSurgicalRow(i)),
                          ),
                          if (isEditing) ...[
                            if (isDraft) ...[
                              SizedBox(height: 8.h),
                              if (procChoices.isEmpty &&
                                  s.procedureId != _kClinicalOtherChoiceId)
                                Text(
                                  'No selectable procedures (lists loading or all already added). Choose Other.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.dashboardWarning,
                                  ),
                                )
                              else
                                DropdownButtonFormField<int>(
                                  value: _clinicalRefDropdownSelectedValue(
                                    refId: s.procedureId,
                                    customName: customNameCtl.text,
                                    choices: procChoices,
                                  ),
                                  isExpanded: true,
                                  decoration:
                                      _fieldDecoration(hint: 'Procedure'),
                                  items: _clinicalRefDropdownItems(procChoices),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      if (v == _kClinicalOtherChoiceId) {
                                        _surgical[i] = _surgical[i].copyWith(
                                          procedureId: _kClinicalOtherChoiceId,
                                          procedureName: '',
                                          clearCustomProcedure: true,
                                        );
                                        customNameCtl.clear();
                                      } else {
                                        _surgical[i] = _surgical[i].copyWith(
                                          procedureId: v,
                                          procedureName:
                                              _namedRefLabel(procChoices, v),
                                          clearCustomProcedure: true,
                                        );
                                        customNameCtl.clear();
                                      }
                                    });
                                  },
                                ),
                              if (showCustomField) ...[
                                SizedBox(height: 10.h),
                                _clinicalCustomNameField(
                                  controller: customNameCtl,
                                  hint: 'Custom procedure name',
                                  onChanged: (v) {
                                    setState(() {
                                      _surgical[i] = _surgical[i].copyWith(
                                        customProcedureName: v.trim(),
                                      );
                                    });
                                  },
                                ),
                              ],
                            ],
                            if (!isDraft) SizedBox(height: 8.h),
                            TextFormField(
                              controller: notesCtl,
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              decoration:
                                  _fieldDecoration(hint: 'Notes (optional)'),
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
                          ] else ...[
                            SizedBox(height: 8.h),
                            _historyViewLine(
                              label: 'Notes',
                              value: s.notes,
                            ),
                            _historyViewLine(
                              label: 'Approximate date',
                              value: _formatSurgicalApproxDate(s),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        if (_medicalTab == _MedicalHistoryTab.drug)
          _historySectionCard(
            icon: Icons.medication_liquid_outlined,
            title: 'Drug history',
            headerTrailing: _medicalAddButton(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_drugs.isEmpty)
                  Text(
                    'No drug history rows yet. Use “Add category” to add one.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  )
                else
                  ...List.generate(_drugs.length, (i) {
                    final d = _drugs[i];
                    final fxCtl = _drugSideEffectsCtl[d.id];
                    final customNameCtl = _drugCustomNameCtl[d.id];
                    if (fxCtl == null || customNameCtl == null) {
                      return const SizedBox.shrink();
                    }
                    final isDraft = d.id <= 0;
                    final isEditing =
                        _isClinicalRowEditing(d.id, _editingDrugIds);
                    final catChoices = _categoryChoicesForRow(i);
                    final showCustomField = _isClinicalOtherSelection(
                      refId: d.medicineCategoryId,
                      customName: customNameCtl.text,
                    );
                    return Container(
                      key: ValueKey('drug-${d.id}'),
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.registrationFieldFill
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                            color: AppColors.registrationFieldBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyCardHeader(
                            title: d.displayCategoryName,
                            isDraft: isDraft,
                            isEditing: isEditing,
                            onUpdate: () => setState(() {
                              if (_editingDrugIds.contains(d.id)) {
                                _editingDrugIds.remove(d.id);
                              } else {
                                _editingDrugIds.add(d.id);
                              }
                            }),
                            onDelete: () => unawaited(_offerDeleteDrugRow(i)),
                          ),
                          if (isEditing) ...[
                            if (isDraft) ...[
                              SizedBox(height: 8.h),
                              if (catChoices.isEmpty &&
                                  d.medicineCategoryId !=
                                      _kClinicalOtherChoiceId)
                                Text(
                                  'No selectable categories (lists loading or all already added). Choose Other.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.dashboardWarning,
                                  ),
                                )
                              else
                                DropdownButtonFormField<int>(
                                  value: _clinicalRefDropdownSelectedValue(
                                    refId: d.medicineCategoryId,
                                    customName: customNameCtl.text,
                                    choices: catChoices,
                                  ),
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                      hint: 'Medicine category'),
                                  items: _clinicalRefDropdownItems(catChoices),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      if (v == _kClinicalOtherChoiceId) {
                                        _drugs[i] = _drugs[i].copyWith(
                                          medicineCategoryId:
                                              _kClinicalOtherChoiceId,
                                          categoryName: '',
                                          clearCustomCategory: true,
                                        );
                                        customNameCtl.clear();
                                      } else {
                                        _drugs[i] = _drugs[i].copyWith(
                                          medicineCategoryId: v,
                                          categoryName:
                                              _namedRefLabel(catChoices, v),
                                          clearCustomCategory: true,
                                        );
                                        customNameCtl.clear();
                                      }
                                    });
                                  },
                                ),
                              if (showCustomField) ...[
                                SizedBox(height: 10.h),
                                _clinicalCustomNameField(
                                  controller: customNameCtl,
                                  hint: 'Custom medicine category name',
                                  onChanged: (v) {
                                    setState(() {
                                      _drugs[i] = _drugs[i].copyWith(
                                        customMedicineCategoryName: v.trim(),
                                      );
                                    });
                                  },
                                ),
                              ],
                            ],
                            if (_adherenceLevels.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              DropdownButtonFormField<int?>(
                                value: _clinicalRefDropdownValue(
                                  d.adherenceLevelId,
                                  _adherenceLevels,
                                ),
                                isExpanded: true,
                                decoration:
                                    _fieldDecoration(hint: 'Adherence level'),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                          ] else ...[
                            SizedBox(height: 8.h),
                            _historyViewLine(
                              label: 'Adherence level',
                              value: d.adherenceLevelName,
                            ),
                            _historyViewLine(
                              label: 'Side effects / notes',
                              value: d.sideEffects,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        if (_medicalTab == _MedicalHistoryTab.tobacco)
          _historySectionCard(
            icon: Icons.smoking_rooms_outlined,
            title: 'Tobacco history',
            headerTrailing: (!_baselineLoaded && !_editingTobacco)
                ? _historyHeaderAddButton(
                    label: 'Add new',
                    onPressed: () => setState(() => _editingTobacco = true),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_editingTobacco) ...[
                  if (!_baselineLoaded)
                    Text(
                      'Not recorded yet',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _tobaccoUse
                                ? 'Tobacco use recorded'
                                : 'No tobacco use',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _historyEntryViewActions(
                          onUpdate: () =>
                              setState(() => _editingTobacco = true),
                          onDelete: () => unawaited(_offerDeleteTobacco()),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _historyViewLine(
                      label: 'Tobacco use',
                      value: _tobaccoUse ? 'Yes' : 'No',
                    ),
                    if (_tobaccoUse) ...[
                      _historyViewLine(
                        label: 'Tobacco type',
                        value: _tobaccoTypeController.text,
                      ),
                      _historyViewLine(
                        label: 'Quantity per day',
                        value: _tobaccoQuantityController.text,
                      ),
                      _historyViewLine(
                        label: 'Duration start',
                        value: _tobaccoDurationStart != null
                            ? _displayDate(_tobaccoDurationStart)
                            : '',
                      ),
                      _historyViewLine(
                        label: 'Duration end',
                        value: _tobaccoDurationEnd != null
                            ? _displayDate(_tobaccoDurationEnd)
                            : '',
                      ),
                    ],
                  ],
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _baselineLoaded
                              ? 'Tobacco history'
                              : 'New tobacco record',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _historyEntryUpdateButton(
                        onPressed: _cancelTobaccoEdit,
                        label: 'View',
                      ),
                      if (_baselineLoaded)
                        _historyEntryDeleteButton(
                          onPressed: () => unawaited(_offerDeleteTobacco()),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tobacco use',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _tobaccoUse,
                    onChanged: (v) => setState(() => _tobaccoUse = v),
                  ),
                  if (_tobaccoUse) ...[
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _tobaccoTypeController,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Tobacco type (e.g. Cigarette, Huqqa)',
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _tobaccoQuantityController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Quantity per day (optional)',
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _tobaccoDateField(
                      label: 'Duration start',
                      date: _tobaccoDurationStart,
                      onTap: () => unawaited(_pickTobaccoDate(isStart: true)),
                    ),
                    SizedBox(height: 10.h),
                    _tobaccoDateField(
                      label: 'Duration end (optional)',
                      date: _tobaccoDurationEnd,
                      onTap: () => unawaited(_pickTobaccoDate(isStart: false)),
                      onClear: _tobaccoDurationEnd == null
                          ? null
                          : () => setState(() => _tobaccoDurationEnd = null),
                    ),
                  ],
                ],
              ],
            ),
          ),
        if (_medicalTab == _MedicalHistoryTab.tobacco && _editingTobacco)
          _primaryCtaButton(
            onPressed: _savingBaseline
                ? null
                : () => unawaited(
                      _saveBaselineLifestyle(
                        successMessage: 'Tobacco history saved.',
                        validateTobacco: true,
                      ),
                    ),
            label: _savingBaseline ? 'Saving…' : 'Save Tobacco History',
          )
        else
          _primaryCtaButton(
            onPressed: _savingMedical ? null : _saveMedicalAndLifestyle,
            label: _savingMedical ? 'Saving…' : 'Save Medical History',
          ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
      ],
    );
  }

  Widget _medicalSubTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _MedicalHistoryTab.values.map((tab) {
          final selected = _medicalTab == tab;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Material(
              color: selected
                  ? AppColors.dashboardPrimary
                  : AppColors.dashboardChipBlueBg,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _medicalTab = tab),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: selected
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

  Widget _medicalAddButton() {
    final ({VoidCallback onPressed, String label}) action =
        switch (_medicalTab) {
      _MedicalHistoryTab.chronic => (
          onPressed: _addMedicalDraft,
          label: 'Add condition'
        ),
      _MedicalHistoryTab.surgical => (
          onPressed: _addSurgicalDraft,
          label: 'Add procedure'
        ),
      _MedicalHistoryTab.drug => (
          onPressed: _addDrugDraft,
          label: 'Add category'
        ),
      _MedicalHistoryTab.tobacco => (onPressed: () {}, label: ''),
    };
    if (_medicalTab == _MedicalHistoryTab.tobacco) {
      return const SizedBox.shrink();
    }
    return _historyHeaderAddButton(
      label: action.label,
      onPressed: action.onPressed,
    );
  }

  Widget _baselineBody() {
    if (_loadingDetail && !_baselineLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.dashboardPrimary,
              ),
            ),
          ),
          _primaryCtaButton(
            onPressed: _savingBaseline
                ? null
                : () => unawaited(
                      _saveBaselineLifestyle(
                        successMessage: 'Baseline lifestyle saved.',
                      ),
                    ),
            label: _savingBaseline ? 'Saving…' : 'Save Baseline Lifestyle',
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _historySectionCard(
          icon: Icons.spa_outlined,
          title: 'Baseline lifestyle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Family history of HTN / stroke',
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                value: _familyHtn,
                onChanged: (v) => setState(() => _familyHtn = v),
              ),
            ],
          ),
        ),
        _primaryCtaButton(
          onPressed: _savingBaseline
              ? null
              : () => unawaited(
                    _saveBaselineLifestyle(
                      successMessage: 'Baseline lifestyle saved.',
                    ),
                  ),
          label: _savingBaseline ? 'Saving…' : 'Save Baseline Lifestyle',
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
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
      spans.add(TextSpan(text: 'BP ', style: base));
      spans.add(
        TextSpan(
          text: '${v.avgSystolicBp}/${v.avgDiastolicBp}',
          style: base.copyWith(color: c, fontWeight: FontWeight.w800),
        ),
      );
    }
    if (v.pulse != null) {
      appendSep();
      final pc = BpReadingColor.forPulse(v.pulse!);
      spans.add(TextSpan(text: 'Pulse ', style: base));
      spans.add(
        TextSpan(
          text: '${v.pulse}',
          style: base.copyWith(color: pc, fontWeight: FontWeight.w800),
        ),
      );
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
    final bottomInset = SizedBox(
      height: MediaQuery.paddingOf(context).bottom + 12.h,
    );
    final logVisitCta = _primaryCtaButton(
      onPressed: _openVisitAssessment,
      label: 'Log New Visit',
    );

    if (_loadingDetail && _visits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.dashboardPrimary,
              ),
            ),
          ),
          logVisitCta,
          bottomInset,
        ],
      );
    }
    if (_visits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No visits found.',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          logVisitCta,
          bottomInset,
        ],
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
        logVisitCta,
        bottomInset,
      ],
    );
  }

  Widget _sectionBody() {
    final api = _patientApi;
    return switch (_section) {
      PatientDetailSection.personalInfo => _personalForm(),
      PatientDetailSection.medicalHistory => _medicalBody(),
      PatientDetailSection.familyHistory => api == null
          ? const SizedBox.shrink()
          : PatientFamilyHistorySection(
              patientId: widget.summary.patientId,
              patientApi: api,
              medicalConditions: _medicalConditions,
              relationDegrees: _relationDegrees,
            ),
      PatientDetailSection.baselineLifestyle => _baselineBody(),
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

  Widget _patientDetailHeroBanner(HwPatientSummary s) {
    final initials = s.initials.trim().isNotEmpty
        ? s.initials
        : NameInitials.fromFullName(s.fullName);
    final avatarBg = _avatarForCondition(s.primaryCondition);
    return Container(
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
                          color: AppColors.surface.withValues(alpha: 0.85),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final slivers = <Widget>[
      SliverAppBar(
        primary: false,
        pinned: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.dashboardPrimaryDark.withValues(alpha: 0.08),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 52.h,
        leading: Padding(
          padding: EdgeInsets.only(left: 6.w),
          child: SizedBox(
            width: 40.r,
            height: 40.r,
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
        ),
        leadingWidth: 46.w,
        title: Text(
          s.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          SizedBox(width: 46.w),
        ],
      ),
      if (_detailLoadError != null)
        SliverToBoxAdapter(
          child: Material(
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
        ),
      SliverToBoxAdapter(child: _patientDetailHeroBanner(s)),
      SliverToBoxAdapter(
        child: ColoredBox(
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PatientDetailSection.values.map(_tab).toList(),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 24.h),
        sliver: SliverToBoxAdapter(
          child: _sectionBody(),
        ),
      ),
    ];

    return ColoredBox(
      color: AppColors.registrationScreenBg,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: slivers,
      ),
    );
  }
}

class _DialogControllerScope extends StatefulWidget {
  const _DialogControllerScope({
    required this.controllerCount,
    required this.builder,
  });

  final int controllerCount;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  ) builder;

  @override
  State<_DialogControllerScope> createState() => _DialogControllerScopeState();
}

class _DialogControllerScopeState extends State<_DialogControllerScope> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.controllerCount,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}
