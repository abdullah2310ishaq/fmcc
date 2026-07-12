import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/input_format/cnic_input_formatter.dart';
import 'package:doctor_app/src/core/input_format/pakistan_phone_input_formatter.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/presentation/dialog_controller_scope.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/presentation/bp_reading_color.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';
import 'package:doctor_app/src/features/patients/patient_family_history_section.dart';
import 'package:doctor_app/src/features/patients/patient_lifestyle_section.dart';
import 'package:doctor_app/src/features/patients/patient_detail_cache.dart';
import 'package:doctor_app/src/features/patients/patient_detail_disk_cache.dart';
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

String _summaryGenderLabel(String gender) {
  final g = gender.trim().toLowerCase();
  if (g == 'male' || g == 'm') return 'Male';
  if (g == 'female' || g == 'f') return 'Female';
  return gender.trim().isNotEmpty ? gender.trim() : '—';
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

extension PatientDetailSectionUi on PatientDetailSection {
  String get label => switch (this) {
        PatientDetailSection.personalInfo => 'Personal Info',
        PatientDetailSection.medicalHistory => 'Medical History',
        PatientDetailSection.familyHistory => 'Family History',
        PatientDetailSection.baselineLifestyle => 'Baseline Lifestyle',
        PatientDetailSection.visitHistory => 'Visit History',
      };

  String get subtitle => switch (this) {
        PatientDetailSection.personalInfo =>
          'Demographics, contact & address',
        PatientDetailSection.medicalHistory =>
          'Chronic, surgical, drug & tobacco history',
        PatientDetailSection.familyHistory =>
          'Family relatives & hereditary conditions',
        PatientDetailSection.baselineLifestyle =>
          'Meals, sleep, exercise, tobacco & habits',
        PatientDetailSection.visitHistory => 'Past visits & follow-ups',
      };

  IconData get icon => switch (this) {
        PatientDetailSection.personalInfo => Icons.person_outline_rounded,
        PatientDetailSection.medicalHistory =>
          Icons.medical_information_outlined,
        PatientDetailSection.familyHistory => Icons.family_restroom_outlined,
        PatientDetailSection.baselineLifestyle => Icons.spa_outlined,
        PatientDetailSection.visitHistory => Icons.event_note_rounded,
      };

  Color get accentColor => switch (this) {
        PatientDetailSection.personalInfo => AppColors.dashboardPrimary,
        PatientDetailSection.medicalHistory => AppColors.followAccentPurple,
        PatientDetailSection.familyHistory => AppColors.dashboardWarning,
        PatientDetailSection.baselineLifestyle => AppColors.followAccentGreen,
        PatientDetailSection.visitHistory => AppColors.dashboardPrimaryDark,
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
    this.fixedSection,
    this.showProfileBanner = true,
    this.showSectionTabs = true,
  });

  final HwPatientSummary summary;
  final VoidCallback onBack;
  final ValueChanged<VisitPatientSeed>? onStartVisit;
  final PatientDetailSection? fixedSection;
  final bool showProfileBanner;
  final bool showSectionTabs;

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
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _snacksController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _nightSleepController = TextEditingController();
  final _daySleepController = TextEditingController();

  List<NamedReferenceItem> _medicalConditions = const [];
  List<NamedReferenceItem> _surgicalProcedures = const [];
  List<NamedReferenceItem> _medicineCategories = const [];
  List<NamedReferenceItem> _relationDegrees = const [];
  List<NamedReferenceItem> _exerciseLevels = const [];
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
  bool _bundleReady = false;
  String? _detailLoadError;

  List<PatientFamilyRelativeRow>? _cachedFamilyRelatives;
  PatientProfileData? _cachedProfile;
  PatientCompleteHistoryData? _cachedHistory;

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

  bool _highSaltDiet = false;
  bool _alcoholUse = false;
  int? _exerciseLevelId;
  String _exerciseLevelLabel = '';
  bool _lifestyleLoaded = false;

  bool _savingPersonal = false;
  bool _savingMedical = false;
  bool _savingBaseline = false;
  bool _savingLifestyle = false;

  final Set<int> _editingChronicIds = {};
  final Set<int> _editingSurgicalIds = {};
  final Set<int> _editingDrugIds = {};

  /// When opened from the hub as a single section, starts read-only until Edit.
  bool _sectionReadOnly = false;

  bool get _sectionEditable => widget.fixedSection == null || !_sectionReadOnly;

  bool get _initialLoading => _loadingDetail && !_bundleReady;

  PatientDetailCache get _cache => context.read<PatientDetailCache>();

  void _invalidatePatientCache() {
    _cache.invalidatePatient(widget.summary.patientId);
  }

  Future<void> _refreshFromNetwork({bool invalidate = true}) async {
    if (invalidate) _invalidatePatientCache();
    await _bootstrap(forceRefresh: true);
  }

  void _toggleSectionReadOnly() {
    setState(() {
      _sectionReadOnly = !_sectionReadOnly;
      if (_sectionReadOnly) {
        _editingChronicIds.clear();
        _editingSurgicalIds.clear();
        _editingDrugIds.clear();
      }
    });
  }

  bool _isClinicalRowEditing(int rowId, Set<int> editingIds) =>
      editingIds.contains(rowId);

  @override
  void initState() {
    super.initState();
    if (widget.fixedSection != null) {
      _section = widget.fixedSection!;
      _sectionReadOnly = true;
    }
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

  Future<void> _bootstrap({bool forceRefresh = false}) async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    final pid = widget.summary.patientId;
    final cache = _cache;

    if (!forceRefresh && cache.hasPatient(pid)) {
      final bundle = cache.bundleFor(pid)!;
      if (cache.hasReferences) {
        _applyReferences(cache.references!);
      }
      _hydrateFromBundle(bundle);
      if (_medical.isEmpty && _surgical.isEmpty && _drugs.isEmpty) {
        final diskHistory = await PatientDetailDiskCache.load(pid);
        if (diskHistory != null && mounted) {
          setState(() {
            _applyClinicalHistory(diskHistory);
            _rebuildClinicalTextControllers();
          });
          _updateCacheFromState();
        }
      }
      if (mounted) {
        setState(() {
          _bundleReady = true;
          _loadingDetail = false;
          _loadingRefs = false;
          _detailLoadError = null;
        });
      }
      if (!cache.hasReferences) {
        unawaited(_fetchAndCacheReferences(session, token));
      }
      // Stale-while-revalidate: show cache immediately, always hit GET APIs.
      unawaited(_refreshClinicalAndFamilyFromNetwork(session, token));
      return;
    }

    if (mounted) {
      setState(() {
        _loadingRefs = true;
        _loadingDetail = true;
        _bundleReady = false;
        _detailLoadError = null;
      });
    }

    try {
      if (cache.hasReferences) {
        _applyReferences(cache.references!);
      } else {
        await _fetchAndCacheReferences(session, token);
      }
      await _fetchAndCachePatientBundle(session, token);
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

  void _applyReferences(PatientDetailReferences refs) {
    _provinces = refs.provinces;
    _maritalStatuses = refs.maritalStatuses;
    _complianceLevels = refs.complianceLevels;
    _adherenceLevels = refs.adherenceLevels;
    _medicalConditions = refs.medicalConditions;
    _surgicalProcedures = refs.surgicalProcedures;
    _medicineCategories = refs.medicineCategories;
    _relationDegrees = refs.relationDegrees;
  }

  void _applyClinicalHistory(PatientCompleteHistoryData? history) {
    if (history == null) return;
    _cachedHistory = history;
    _medical = List<PatientMedicalHistoryRow>.from(history.medical);
    _surgical = List<PatientSurgicalHistoryRow>.from(history.surgical);
    _drugs = List<PatientDrugHistoryRow>.from(history.drugs);
    _clinicalBundleResolved = true;
    if (history.baseline != null) {
      _applyBaselineToForm(history.baseline!);
    }
    if (history.patientLifeStyle != null && !_lifestyleLoaded) {
      _applyLifestyleToForm(history.patientLifeStyle!);
    }
  }

  void _hydrateFromBundle(PatientDetailBundle bundle) {
    _cachedProfile = bundle.profile;
    _cachedHistory = bundle.history;
    _applyProfileToForm(bundle.profile);
    _districts = bundle.districts;
    _tehsils = bundle.tehsils;
    _cachedFamilyRelatives = bundle.familyRelatives;

    _editingChronicIds.clear();
    _editingSurgicalIds.clear();
    _editingDrugIds.clear();

    final history = bundle.history;
    if (history != null) {
      _applyClinicalHistory(history);
    } else if (!_clinicalBundleResolved) {
      if (_medical.isEmpty &&
          _surgical.isEmpty &&
          _drugs.isEmpty &&
          !_baselineLoaded) {
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
        if (!_lifestyleLoaded) {
          _clearLifestyleForm();
        }
      }
      _clinicalBundleResolved = true;
    }

    _visits = List<PatientVisitRow>.from(bundle.visits)
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    _rebuildClinicalTextControllers();
    _bundleReady = true;
  }

  Future<void> _fetchAndCacheReferences(
    SessionController session,
    String token,
  ) async {
    await _loadReference(session, token);
    final ref = _referenceApi;
    if (ref == null) return;
    await _loadClinicalDropdownRefs(session, token);
    _cache.setReferences(
      PatientDetailReferences(
        provinces: _provinces,
        maritalStatuses: _maritalStatuses,
        complianceLevels: _complianceLevels,
        adherenceLevels: _adherenceLevels,
        medicalConditions: _medicalConditions,
        surgicalProcedures: _surgicalProcedures,
        medicineCategories: _medicineCategories,
        relationDegrees: _relationDegrees,
      ),
    );
  }

  Future<void> _fetchAndCachePatientBundle(
    SessionController session,
    String token,
  ) async {
    final pid = widget.summary.patientId;

    final diskHistory = await PatientDetailDiskCache.load(pid);
    if (diskHistory != null && mounted) {
      setState(() => _applyClinicalHistory(diskHistory));
      _rebuildClinicalTextControllers();
    }

    await _loadProfileAndCascadeLocation(session, token);
    await _refreshClinicalAndFamilyFromNetwork(session, token);

    if (!mounted) return;

    final profile = _cachedProfile;
    if (profile == null) return;

    final bundle = PatientDetailBundle(
      profile: profile,
      districts: _districts,
      tehsils: _tehsils,
      history: _cachedHistory,
      visits: _visits,
      familyRelatives: _cachedFamilyRelatives,
    );

    _cache.setPatientBundle(pid, bundle);
    if (mounted) setState(() => _bundleReady = true);
  }

  /// Always calls server GETs for clinical history, visits, and family history.
  Future<void> _refreshClinicalAndFamilyFromNetwork(
    SessionController session,
    String token,
  ) async {
    await _loadClinical(session, token);
    if (!mounted) return;

    final pid = widget.summary.patientId;
    try {
      final family = await _patientApi!.getFamilyHistory(
        patientId: pid,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _cachedFamilyRelatives = family?.relatives;
      });
      _updateCacheFromState();
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
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
    _cachedProfile = profile;
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
        ref.getExerciseLevels(bearerToken: token),
      ]);
      if (!mounted) return;
      setState(() {
        _complianceLevels = results[0];
        _adherenceLevels = results[1];
        _medicalConditions = results[2];
        _surgicalProcedures = results[3];
        _medicineCategories = results[4];
        _relationDegrees = results[5];
        _exerciseLevels = results[6];
        if (_exerciseLevelId != null && _exerciseLevelLabel.trim().isEmpty) {
          _exerciseLevelLabel = _exerciseLevelName(_exerciseLevelId);
        }
      });
      AppLogger.instance.i(
        '[PatientDetail] clinical refs loaded — '
        'conditions=${_medicalConditions.length} '
        'relationDegrees=${_relationDegrees.length} '
        'procedures=${_surgicalProcedures.length} '
        'categories=${_medicineCategories.length}',
      );
      if (_relationDegrees.isEmpty) {
        AppLogger.instance.w(
          '[PatientDetail] relationDegrees EMPTY after /api/Reference/relation-degrees',
        );
      } else {
        AppLogger.instance.i(
          '[PatientDetail] relationDegrees → '
          '${_relationDegrees.map((e) => '${e.id}:${e.name}').join(', ')}',
        );
      }
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

  List<PatientMedicalHistoryRow> _mergeMedicalRows(
    List<PatientMedicalHistoryRow> server,
    List<PatientMedicalHistoryRow> local,
  ) {
    final byId = {for (final r in server) r.id: r};
    final out = List<PatientMedicalHistoryRow>.from(server);
    for (final row in local) {
      if (row.id <= 0) {
        out.add(row);
        continue;
      }
      if (!byId.containsKey(row.id)) {
        out.add(row);
      }
    }
    return out;
  }

  List<PatientSurgicalHistoryRow> _mergeSurgicalRows(
    List<PatientSurgicalHistoryRow> server,
    List<PatientSurgicalHistoryRow> local,
  ) {
    final byId = {for (final r in server) r.id: r};
    final out = List<PatientSurgicalHistoryRow>.from(server);
    for (final row in local) {
      if (row.id <= 0) {
        out.add(row);
        continue;
      }
      if (!byId.containsKey(row.id)) {
        out.add(row);
      }
    }
    return out;
  }

  List<PatientDrugHistoryRow> _mergeDrugRows(
    List<PatientDrugHistoryRow> server,
    List<PatientDrugHistoryRow> local,
  ) {
    final byId = {for (final r in server) r.id: r};
    final out = List<PatientDrugHistoryRow>.from(server);
    for (final row in local) {
      if (row.id <= 0) {
        out.add(row);
        continue;
      }
      if (!byId.containsKey(row.id)) {
        out.add(row);
      }
    }
    return out;
  }

  PatientBaselineLifestyle? _mergeBaselineLifestyle(
    PatientBaselineLifestyle? local,
    PatientBaselineLifestyle? remote,
  ) {
    if (local == null) return remote;
    if (remote == null) return local;

    String? pickString(String? fromRemote, String? fromLocal) {
      final remote = fromRemote?.trim();
      if (remote != null && remote.isNotEmpty) return remote;
      final local = fromLocal?.trim();
      if (local != null && local.isNotEmpty) return local;
      return null;
    }

    return PatientBaselineLifestyle(
      patientId:
          remote.patientId.isNotEmpty ? remote.patientId : local.patientId,
      familyHistoryOfHtnOrStroke: remote.familyHistoryOfHtnOrStroke,
      tobaccoUse: remote.tobaccoUse,
      tobaccoType: pickString(remote.tobaccoType, local.tobaccoType),
      tobaccoQuantityPerDay:
          remote.tobaccoQuantityPerDay ?? local.tobaccoQuantityPerDay,
      tobaccoDurationStart:
          remote.tobaccoDurationStart ?? local.tobaccoDurationStart,
      tobaccoDurationEnd: remote.tobaccoDurationEnd ?? local.tobaccoDurationEnd,
    );
  }

  void _applyBaselineToForm(PatientBaselineLifestyle baseline) {
    _familyHtn = baseline.familyHistoryOfHtnOrStroke;
    _tobaccoUse = baseline.tobaccoUse;
    _tobaccoTypeController.text = baseline.tobaccoType?.trim() ?? '';
    _tobaccoQuantityController.text =
        baseline.tobaccoQuantityPerDay?.toString() ?? '';
    _tobaccoDurationStart = baseline.tobaccoDurationStart;
    _tobaccoDurationEnd = baseline.tobaccoDurationEnd;
    _baselineLoaded = true;
  }

  void _clearBaselineForm() {
    _familyHtn = false;
    _tobaccoUse = false;
    _tobaccoTypeController.clear();
    _tobaccoQuantityController.clear();
    _tobaccoDurationStart = null;
    _tobaccoDurationEnd = null;
    _baselineLoaded = false;
  }

  void _applyLifestyleToForm(PatientLifeStyle lifestyle) {
    _breakfastController.text = lifestyle.breakfast;
    _lunchController.text = lifestyle.lunch;
    _snacksController.text = lifestyle.snacks;
    _dinnerController.text = lifestyle.dinner;
    _nightSleepController.text = lifestyle.nightSleepHours == null
        ? ''
        : _formatSleepHours(lifestyle.nightSleepHours!);
    _daySleepController.text = lifestyle.daySleepHours == null
        ? ''
        : _formatSleepHours(lifestyle.daySleepHours!);
    _exerciseLevelId = lifestyle.exerciseLevelId;
    final apiName = lifestyle.exerciseLevelName.trim();
    final lookedUp = _exerciseLevelName(lifestyle.exerciseLevelId);
    _exerciseLevelLabel = apiName.isNotEmpty ? apiName : lookedUp;
    _alcoholUse = lifestyle.alcoholUse;
    _highSaltDiet = lifestyle.highSaltDiet;
    _lifestyleLoaded = true;
  }

  void _clearLifestyleForm() {
    _breakfastController.clear();
    _lunchController.clear();
    _snacksController.clear();
    _dinnerController.clear();
    _nightSleepController.clear();
    _daySleepController.clear();
    _exerciseLevelId = null;
    _exerciseLevelLabel = '';
    _alcoholUse = false;
    _highSaltDiet = false;
    _lifestyleLoaded = false;
  }

  String _formatSleepHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return hours.round().toString();
    }
    return hours.toString();
  }

  bool get _lifestyleFormTouched =>
      _breakfastController.text.trim().isNotEmpty ||
      _lunchController.text.trim().isNotEmpty ||
      _snacksController.text.trim().isNotEmpty ||
      _dinnerController.text.trim().isNotEmpty ||
      _nightSleepController.text.trim().isNotEmpty ||
      _daySleepController.text.trim().isNotEmpty ||
      _exerciseLevelId != null ||
      _alcoholUse ||
      _highSaltDiet;

  PatientLifeStyle? _lifestyleFromLocalForm() {
    if (!_lifestyleLoaded && !_lifestyleFormTouched) {
      return _cachedHistory?.patientLifeStyle;
    }
    final name = _displayExerciseLevelName();
    return PatientLifeStyle(
      patientId: widget.summary.patientId,
      breakfast: _breakfastController.text.trim(),
      lunch: _lunchController.text.trim(),
      snacks: _snacksController.text.trim(),
      dinner: _dinnerController.text.trim(),
      nightSleepHours: double.tryParse(_nightSleepController.text.trim()),
      daySleepHours: double.tryParse(_daySleepController.text.trim()),
      exerciseLevelId: _exerciseLevelId,
      exerciseLevelName: name == '—' ? '' : name,
      alcoholUse: _alcoholUse,
      highSaltDiet: _highSaltDiet,
    );
  }

  String _exerciseLevelName(int? id) {
    if (id == null) return '';
    for (final item in _exerciseLevels) {
      if (item.id == id) return item.name;
    }
    return '';
  }

  String _displayExerciseLevelName() {
    final label = _exerciseLevelLabel.trim();
    if (label.isNotEmpty) return label;
    final lookedUp = _exerciseLevelName(_exerciseLevelId);
    if (lookedUp.isNotEmpty) return lookedUp;
    return '—';
  }

  void _setExerciseLevel(int? id) {
    _exerciseLevelId = id;
    _exerciseLevelLabel = _exerciseLevelName(id);
  }

  bool get _tobaccoFormTouched =>
      _tobaccoUse ||
      _tobaccoTypeController.text.trim().isNotEmpty ||
      _tobaccoQuantityController.text.trim().isNotEmpty ||
      _tobaccoDurationStart != null ||
      _tobaccoDurationEnd != null;

  bool get _tobaccoFieldsEditable => _sectionEditable;

  PatientBaselineLifestyle? _baselineFromLocalForm() {
    if (!_baselineLoaded && !_tobaccoFormTouched) {
      return _cachedHistory?.baseline;
    }
    final qtyRaw = _tobaccoQuantityController.text.trim();
    final qty = int.tryParse(qtyRaw);
    return PatientBaselineLifestyle(
      patientId: widget.summary.patientId,
      familyHistoryOfHtnOrStroke: _familyHtn,
      tobaccoUse: _tobaccoUse,
      tobaccoType: _tobaccoTypeController.text.trim().isEmpty
          ? null
          : _tobaccoTypeController.text.trim(),
      tobaccoQuantityPerDay: qty,
      tobaccoDurationStart: _tobaccoDurationStart,
      tobaccoDurationEnd: _tobaccoDurationEnd,
    );
  }

  String _displayDateOrDash(DateTime? date) {
    if (date == null) return '—';
    return _displayDate(date);
  }

  void _syncCachedHistoryFromLocal() {
    _cachedHistory = PatientCompleteHistoryData(
      baseline: _baselineFromLocalForm(),
      patientLifeStyle: _lifestyleFromLocalForm(),
      medical: List<PatientMedicalHistoryRow>.from(_medical),
      surgical: List<PatientSurgicalHistoryRow>.from(_surgical),
      drugs: List<PatientDrugHistoryRow>.from(_drugs),
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

    if (history == null && !_baselineLoaded) {
      await _ensureBaselineShell(
        api: _patientApi!,
        patientId: pid,
        token: token,
      );
      if (mounted) {
        try {
          history = await _patientApi!.getCompleteHistory(
            patientId: pid,
            bearerToken: token,
          );
        } on Object catch (e) {
          if (!mounted || e is SessionEndedFailure) return;
          _toast(session.apiClient.mapError(e).message);
        }
      }
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

    final localMedical = List<PatientMedicalHistoryRow>.from(_medical);
    final localSurgical = List<PatientSurgicalHistoryRow>.from(_surgical);
    final localDrugs = List<PatientDrugHistoryRow>.from(_drugs);
    final localBaseline = _baselineFromLocalForm();

    if (history != null) {
      _cachedHistory = history;
    }
    setState(() {
      _editingChronicIds.clear();
      _editingSurgicalIds.clear();
      _editingDrugIds.clear();
      if (history != null) {
        _medical = _mergeMedicalRows(history.medical, localMedical);
        _surgical = _mergeSurgicalRows(history.surgical, localSurgical);
        _drugs = _mergeDrugRows(history.drugs, localDrugs);
        _clinicalBundleResolved = true;
        final baseline =
            _mergeBaselineLifestyle(localBaseline, history.baseline);
        if (baseline != null) {
          _applyBaselineToForm(baseline);
        } else if (!_baselineLoaded) {
          _clearBaselineForm();
        }
      } else if (!_clinicalBundleResolved) {
        if (_medical.isEmpty &&
            _surgical.isEmpty &&
            _drugs.isEmpty &&
            !_baselineLoaded) {
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
          if (!_lifestyleLoaded) {
            _clearLifestyleForm();
          }
        }
        _clinicalBundleResolved = true;
      }
      _visits = List<PatientVisitRow>.from(visits)
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    });
    _rebuildClinicalTextControllers();
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
    await _loadLifestyle(session, token);
  }

  Future<void> _loadLifestyle(
    SessionController session,
    String token,
  ) async {
    final pid = widget.summary.patientId;
    try {
      final lifestyle = await _patientApi!.getLifestyle(
        patientId: pid,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        if (lifestyle != null) {
          _applyLifestyleToForm(lifestyle);
        } else if (!_lifestyleLoaded) {
          final fromHistory = _cachedHistory?.patientLifeStyle;
          if (fromHistory != null) {
            _applyLifestyleToForm(fromHistory);
          }
        }
      });
      _syncCachedHistoryFromLocal();
      _updateCacheFromState();
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  void _updateCacheFromState() {
    final profile = _cachedProfile;
    if (profile == null) return;
    _syncCachedHistoryFromLocal();
    final pid = widget.summary.patientId;
    unawaited(PatientDetailDiskCache.save(pid, _cachedHistory));
    _cache.setPatientBundle(
      widget.summary.patientId,
      PatientDetailBundle(
        profile: profile,
        districts: _districts,
        tehsils: _tehsils,
        history: _cachedHistory,
        visits: _visits,
        familyRelatives: _cachedFamilyRelatives,
      ),
    );
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
    _breakfastController.dispose();
    _lunchController.dispose();
    _snacksController.dispose();
    _dinnerController.dispose();
    _nightSleepController.dispose();
    _daySleepController.dispose();
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
      await _loadProfileAndCascadeLocation(session, token);
      _updateCacheFromState();
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
    final updated = <PatientMedicalHistoryRow>[];
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

      final dur = int.tryParse(durRaw);
      final resolved = row.copyWith(
        customConditionName: isCustom ? customName : '',
        durationInMonths: dur,
      );

      if (row.id > 0) {
        body['id'] = row.id;
        await api.putMedicalHistory(body: body, bearerToken: token);
        updated.add(resolved);
      } else {
        final newId = await api.postMedicalHistory(
          body: body,
          bearerToken: token,
        );
        updated.add(resolved.copyWith(id: newId));
      }
    }
    _medical = updated;
    return true;
  }

  Future<bool> _persistSurgicalRows({
    required String patientId,
    required PatientApi api,
    required String token,
  }) async {
    final updated = <PatientSurgicalHistoryRow>[];
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
      int? mo;
      if (moRaw.isNotEmpty) {
        mo = int.tryParse(moRaw);
        if (mo != null && mo >= 1 && mo <= 12) body['approxMonth'] = mo;
      }
      final yrRaw = _surgicalYearCtl[s.id]?.text.trim() ?? '';
      int? yr;
      if (yrRaw.isNotEmpty) {
        yr = int.tryParse(yrRaw);
        if (yr != null && yr >= 1900 && yr <= 2200) body['approxYear'] = yr;
      }

      final resolved = s.copyWith(
        customProcedureName: isCustom ? customName : '',
        notes: notesTrim,
        approxMonth: mo,
        approxYear: yr,
      );

      if (s.id > 0) {
        body['id'] = s.id;
        await api.putSurgicalHistory(body: body, bearerToken: token);
        updated.add(resolved);
      } else {
        final newId = await api.postSurgicalHistory(
          body: body,
          bearerToken: token,
        );
        updated.add(resolved.copyWith(id: newId));
      }
    }
    _surgical = updated;
    return true;
  }

  Future<bool> _persistDrugRows({
    required String patientId,
    required PatientApi api,
    required String token,
  }) async {
    final updated = <PatientDrugHistoryRow>[];
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

      final resolved = d.copyWith(
        customMedicineCategoryName: isCustom ? customName : '',
        sideEffects: fx,
      );

      if (d.id > 0) {
        body['id'] = d.id;
        await api.putDrugHistory(body: body, bearerToken: token);
        updated.add(resolved);
      } else {
        final newId = await api.postDrugHistory(
          body: body,
          bearerToken: token,
        );
        updated.add(resolved.copyWith(id: newId));
      }
    }
    _drugs = updated;
    return true;
  }

  Future<void> _ensureBaselineShell({
    required PatientApi api,
    required String patientId,
    required String token,
  }) async {
    if (_baselineLoaded) return;
    try {
      await api.postBaselineLifestyle(
        body: {
          'patientId': patientId,
          'familyHistoryOfHTNOrStroke': false,
          'tobaccoUse': false,
        },
        bearerToken: token,
      );
      if (mounted) {
        setState(() => _baselineLoaded = true);
      }
    } on Object {
      // Non-fatal — disk cache still preserves rows if complete-history 404s.
    }
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

      await _ensureBaselineShell(api: api, patientId: pid, token: token);

      setState(() {});
      _rebuildClinicalTextControllers();
      _syncCachedHistoryFromLocal();
      _updateCacheFromState();

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
    bool includeLifestyle = false,
    bool popOnSuccess = false,
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

    if (includeLifestyle &&
        _exerciseLevelLabel.trim().isEmpty &&
        _exerciseLevelId != null) {
      _exerciseLevelLabel = _exerciseLevelName(_exerciseLevelId);
    }

    setState(() {
      _savingBaseline = true;
      if (includeLifestyle) _savingLifestyle = true;
    });
    try {
      if (_baselineLoaded) {
        await api.putBaselineLifestyle(body: body, bearerToken: token);
      } else {
        await api.postBaselineLifestyle(body: body, bearerToken: token);
      }
      if (includeLifestyle) {
        await api.upsertLifestyle(
          body: _buildLifestyleBody(pid),
          bearerToken: token,
        );
      }
      if (!mounted) return;
      setState(() {
        _baselineLoaded = true;
        if (includeLifestyle) _lifestyleLoaded = true;
      });
      _syncCachedHistoryFromLocal();
      _updateCacheFromState();
      _toast(successMessage);
      if (popOnSuccess && widget.fixedSection != null) {
        widget.onBack();
        return;
      }
      if (includeLifestyle) {
        setState(() => _sectionReadOnly = true);
      }
      await _loadClinical(session, token);
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) {
        setState(() {
          _savingBaseline = false;
          _savingLifestyle = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildLifestyleBody(String patientId) {
    final body = <String, dynamic>{
      'patientId': patientId,
      'breakfast': _breakfastController.text.trim(),
      'lunch': _lunchController.text.trim(),
      'snacks': _snacksController.text.trim(),
      'dinner': _dinnerController.text.trim(),
      'alcoholUse': _alcoholUse,
      'highSaltDiet': _highSaltDiet,
    };
    final night = double.tryParse(_nightSleepController.text.trim());
    if (night != null) body['nightSleepHours'] = night;
    final day = double.tryParse(_daySleepController.text.trim());
    if (day != null) body['daySleepHours'] = day;
    final exerciseId = _exerciseLevelId;
    if (exerciseId != null && exerciseId > 0) {
      body['exerciseLevelId'] = exerciseId;
    }
    return body;
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

  String _refName(List<({int id, String name})> items, int? id) {
    if (id == null || id <= 0) return '—';
    for (final e in items) {
      if (e.id == id) return e.name;
    }
    return '—';
  }

  String _genderDisplayLabel() => switch (_gender) {
        _PatientDetailGender.female => 'Female',
        _PatientDetailGender.male => 'Male',
        _PatientDetailGender.other => 'Other',
      };

  Widget _infoGroupCard({
    required IconData icon,
    required String title,
    required List<(String, String)> rows,
  }) {
    return Material(
      elevation: 2.5,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(18.r),
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    icon,
                    size: 18.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            for (int i = 0; i < rows.length; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 11.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        rows[i].$1,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 3,
                      child: Text(
                        rows[i].$2.trim().isEmpty ? '—' : rows[i].$2.trim(),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i != rows.length - 1)
                Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }

  Widget _personalView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoGroupCard(
          icon: Icons.badge_outlined,
          title: 'Basic Information',
          rows: [
            ('First name', _firstNameController.text),
            ('Last name', _lastNameController.text),
            ('Age', '${widget.summary.age}'),
            ('Date of birth', _dobController.text),
            ('Gender', _genderDisplayLabel()),
            ('CNIC', _cnicController.text),
            if (_maritalStatuses.isNotEmpty)
              ('Marital status', _refName(_maritalStatuses, _maritalStatusId)),
          ],
        ),
        SizedBox(height: 16.h),
        _infoGroupCard(
          icon: Icons.location_on_outlined,
          title: 'Contact & Location',
          rows: [
            ('Phone', _phoneController.text),
            ('Province', _refName(_provinces, _provinceId)),
            ('District', _refName(_districts, _districtId)),
            ('Tehsil', _refName(_tehsils, _tehsilId)),
            ('Street address', _streetController.text),
          ],
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 12.h),
      ],
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
        if (_sectionEditable)
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
        return DialogControllerScope(
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
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
    if (!_sectionEditable) {
      unawaited(_saveMedicalAndLifestyle());
    }
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
        return DialogControllerScope(
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
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
    if (!_sectionEditable) {
      unawaited(_saveMedicalAndLifestyle());
    }
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
        return DialogControllerScope(
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
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
    if (!_sectionEditable) {
      unawaited(_saveMedicalAndLifestyle());
    }
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
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 28.sp,
                        color: AppColors.dashboardPrimaryDark,
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

  Widget _historyEntryMoreMenu({required VoidCallback onDelete}) {
    return PopupMenuButton<String>(
      tooltip: 'More options',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 140.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: AppColors.surface,
      elevation: 4,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 22.sp,
        color: AppColors.dashboardPrimaryDark,
      ),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'delete',
          height: 44.h,
          child: Text(
            'Delete',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
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

  Widget _historyEmptyState({
    required IconData icon,
    required String viewMessage,
    required String addLabel,
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.registrationFieldFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30.sp,
            color: AppColors.dashboardPrimary.withValues(alpha: 0.65),
          ),
          SizedBox(height: 10.h),
          Text(
            viewMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: 14.h),
          _historyHeaderAddButton(label: addLabel, onPressed: onAdd),
        ],
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
        _historyEntryMoreMenu(onDelete: onDelete),
      ],
    );
  }

  String _formatOptionalMonths(int? months, String controllerText) {
    final raw = months?.toString() ?? controllerText.trim();
    if (raw.isEmpty) return '';
    return '$raw mo';
  }

  Widget _historyMetaPill({
    required String label,
    required String value,
    Color? accent,
  }) {
    final text = value.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final color = accent ?? AppColors.dashboardPrimary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyEntryCardShell({
    required Key key,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        key: key,
        color: AppColors.surface,
        elevation: 2.5,
        shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
          ),
          child: child,
        ),
      ),
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
    bool showActions = true,
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
        if (showActions)
          if (isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _historyEntryUpdateButton(
                  onPressed: onUpdate,
                  label: 'View',
                ),
                _historyEntryMoreMenu(onDelete: onDelete),
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
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
  }

  void _removeSurgicalEntryAt(int index) {
    if (index < 0 || index >= _surgical.length) return;
    setState(() {
      _surgical = [..._surgical]..removeAt(index);
    });
    _rebuildClinicalTextControllers();
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
  }

  void _removeDrugEntryAt(int index) {
    if (index < 0 || index >= _drugs.length) return;
    setState(() {
      _drugs = [..._drugs]..removeAt(index);
    });
    _rebuildClinicalTextControllers();
    _syncCachedHistoryFromLocal();
    _updateCacheFromState();
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
      _syncCachedHistoryFromLocal();
      _updateCacheFromState();
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
      _syncCachedHistoryFromLocal();
      _updateCacheFromState();
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
      _syncCachedHistoryFromLocal();
      _updateCacheFromState();
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
    });

    await _saveBaselineLifestyle(
      successMessage: 'Tobacco history cleared.',
    );
  }

  Widget _tobaccoHistoryBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_baselineLoaded && _sectionEditable)
          Align(
            alignment: Alignment.centerRight,
            child: _historyEntryMoreMenu(
              onDelete: () => unawaited(_offerDeleteTobacco()),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Tobacco use',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _sectionEditable
                ? (_tobaccoUse
                    ? 'Add tobacco details below'
                    : 'Turn on if patient uses tobacco')
                : (!_baselineLoaded
                    ? 'Tap Edit above to record tobacco history'
                    : (_tobaccoUse
                        ? 'Patient uses tobacco'
                        : 'No tobacco use recorded')),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          value: _tobaccoUse,
          onChanged: _tobaccoFieldsEditable
              ? (v) => setState(() => _tobaccoUse = v)
              : null,
        ),
        if (_tobaccoUse) ...[
          SizedBox(height: 8.h),
          if (_tobaccoFieldsEditable) ...[
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
          ] else
            _infoGroupCard(
              icon: Icons.smoking_rooms_outlined,
              title: 'Tobacco details',
              rows: [
                ('Type', _tobaccoTypeController.text),
                ('Quantity per day', _tobaccoQuantityController.text),
                ('Duration start', _displayDateOrDash(_tobaccoDurationStart)),
                ('Duration end', _displayDateOrDash(_tobaccoDurationEnd)),
              ],
            ),
        ],
      ],
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
        !_bundleReady &&
        _medical.isEmpty &&
        _surgical.isEmpty &&
        _drugs.isEmpty) {
      return const SizedBox.shrink();
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
                  _historyEmptyState(
                    icon: Icons.monitor_heart_outlined,
                    viewMessage: 'No chronic conditions recorded.',
                    addLabel: 'Add condition',
                    onAdd: _addMedicalDraft,
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
                    final isEditing = _sectionEditable &&
                        _isClinicalRowEditing(row.id, _editingChronicIds);
                    final choices = _conditionChoicesForRow(i);
                    final showCustomField = _isClinicalOtherSelection(
                      refId: row.conditionId,
                      customName: customNameCtl.text,
                    );
                    return _historyEntryCardShell(
                      key: ValueKey('chronic-${row.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyCardHeader(
                            title: row.displayConditionName,
                            isDraft: isDraft,
                            isEditing: isEditing,
                            showActions: _sectionEditable,
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
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: [
                                _historyMetaPill(
                                  label: 'Medication',
                                  value: row.isOnMedication
                                      ? 'On medication'
                                      : 'Not on medication',
                                  accent: row.isOnMedication
                                      ? AppColors.followAccentGreen
                                      : AppColors.textSecondary,
                                ),
                                _historyMetaPill(
                                  label: 'Duration',
                                  value: _formatOptionalMonths(
                                    row.durationInMonths,
                                    durCtl.text,
                                  ),
                                ),
                                _historyMetaPill(
                                  label: 'Compliance',
                                  value: row.complianceLevelName,
                                ),
                              ],
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
                  _historyEmptyState(
                    icon: Icons.local_hospital_outlined,
                    viewMessage: 'No surgical procedures recorded.',
                    addLabel: 'Add procedure',
                    onAdd: _addSurgicalDraft,
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
                    final isEditing = _sectionEditable &&
                        _isClinicalRowEditing(s.id, _editingSurgicalIds);
                    final procChoices = _procedureChoicesForRow(i);
                    final showCustomField = _isClinicalOtherSelection(
                      refId: s.procedureId,
                      customName: customNameCtl.text,
                    );
                    return _historyEntryCardShell(
                      key: ValueKey('surgical-${s.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyCardHeader(
                            title: s.displayProcedureName,
                            isDraft: isDraft,
                            isEditing: isEditing,
                            showActions: _sectionEditable,
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
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: [
                                _historyMetaPill(
                                  label: 'Approx. date',
                                  value: _formatSurgicalApproxDate(s),
                                ),
                                _historyMetaPill(
                                  label: 'Notes',
                                  value: s.notes,
                                ),
                              ],
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
                  _historyEmptyState(
                    icon: Icons.medication_liquid_outlined,
                    viewMessage: 'No drug history recorded.',
                    addLabel: 'Add category',
                    onAdd: _addDrugDraft,
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
                    final isEditing = _sectionEditable &&
                        _isClinicalRowEditing(d.id, _editingDrugIds);
                    final catChoices = _categoryChoicesForRow(i);
                    final showCustomField = _isClinicalOtherSelection(
                      refId: d.medicineCategoryId,
                      customName: customNameCtl.text,
                    );
                    return _historyEntryCardShell(
                      key: ValueKey('drug-${d.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyCardHeader(
                            title: d.displayCategoryName,
                            isDraft: isDraft,
                            isEditing: isEditing,
                            showActions: _sectionEditable,
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
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: [
                                _historyMetaPill(
                                  label: 'Adherence',
                                  value: d.adherenceLevelName,
                                ),
                                _historyMetaPill(
                                  label: 'Side effects',
                                  value: d.sideEffects,
                                ),
                              ],
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
            child: _tobaccoHistoryBody(),
          ),
        if (_medicalTab == _MedicalHistoryTab.tobacco && _sectionEditable)
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
        else if (_sectionEditable)
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
    if (_loadingDetail && !_bundleReady && !_baselineLoaded && !_lifestyleLoaded) {
      return const SizedBox.shrink();
    }

    final hasData = _baselineLoaded ||
        _lifestyleLoaded ||
        _tobaccoUse ||
        _lifestyleFormTouched;

    if (!_sectionEditable) {
      return PatientLifestyleView(
        data: hasData
            ? PatientLifestyleViewData(
                tobaccoUse: _tobaccoUse,
                tobaccoType: _tobaccoTypeController.text,
                tobaccoQuantityPerDay: _tobaccoQuantityController.text,
                tobaccoDurationStart: _tobaccoDurationStart != null
                    ? _displayDate(_tobaccoDurationStart)
                    : '',
                tobaccoDurationEnd: _tobaccoDurationEnd != null
                    ? _displayDate(_tobaccoDurationEnd)
                    : '',
                breakfast: _breakfastController.text,
                lunch: _lunchController.text,
                snacks: _snacksController.text,
                dinner: _dinnerController.text,
                nightSleepHours: _nightSleepController.text,
                daySleepHours: _daySleepController.text,
                exerciseLevelName: _displayExerciseLevelName(),
                highSaltDiet: _highSaltDiet,
                alcoholUse: _alcoholUse,
              )
            : null,
        onRecordTap: _toggleSectionReadOnly,
      );
    }

    return PatientLifestyleForm(
      tobaccoUse: _tobaccoUse,
      onTobaccoUseChanged: (v) => setState(() => _tobaccoUse = v),
      tobaccoTypeController: _tobaccoTypeController,
      tobaccoQuantityController: _tobaccoQuantityController,
      tobaccoDurationStart: _tobaccoDurationStart,
      tobaccoDurationEnd: _tobaccoDurationEnd,
      onPickTobaccoDate: _pickTobaccoDate,
      onClearTobaccoEnd: _tobaccoDurationEnd == null
          ? null
          : () => setState(() => _tobaccoDurationEnd = null),
      formatDate: _displayDateOrDash,
      breakfastController: _breakfastController,
      lunchController: _lunchController,
      snacksController: _snacksController,
      dinnerController: _dinnerController,
      nightSleepController: _nightSleepController,
      daySleepController: _daySleepController,
      exerciseLevels: _exerciseLevels,
      exerciseLevelId: _exerciseLevelId,
      highSaltDiet: _highSaltDiet,
      alcoholUse: _alcoholUse,
      saving: _savingBaseline || _savingLifestyle,
      onExerciseChanged: (v) => setState(() => _setExerciseLevel(v)),
      onHighSaltChanged: (v) => setState(() => _highSaltDiet = v),
      onAlcoholChanged: (v) => setState(() => _alcoholUse = v),
      onSave: () => unawaited(
            _saveBaselineLifestyle(
              successMessage: 'Baseline lifestyle saved.',
              includeLifestyle: true,
              validateTobacco: true,
              popOnSuccess: true,
            ),
          ),
      fieldDecoration: ({String? hint}) => _fieldDecoration(hint: hint),
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

    if (_loadingDetail && !_bundleReady && _visits.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_visits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _historyEmptyState(
            icon: Icons.event_note_rounded,
            viewMessage: 'No visits recorded yet.',
            addLabel: 'Log New Visit',
            onAdd: _openVisitAssessment,
          ),
          SizedBox(height: 16.h),
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
          _historyEmptyState(
            icon: Icons.event_note_rounded,
            viewMessage: switch (_visitHistorySegment) {
              _VisitHistorySegment.followUps =>
                'No follow-up visits in this filter.',
              _VisitHistorySegment.routine =>
                'No routine visits in this filter.',
              _VisitHistorySegment.all => 'No visits in this view.',
            },
            addLabel: 'Log New Visit',
            onAdd: _openVisitAssessment,
          )
        else
          ...shown.map(
            (v) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Material(
                color: AppColors.surface,
                elevation: 3,
                shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18.r),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: AppColors.registrationFieldBorder),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4.w,
                            color: AppColors.dashboardPrimary
                                .withValues(alpha: 0.7),
                          ),
                          Expanded(
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
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w900,
                                            color:
                                                AppColors.dashboardPrimaryDark,
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
                                          borderRadius:
                                              BorderRadius.circular(999),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                        ],
                      ),
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
    final familySection = api == null
        ? const SizedBox.shrink()
        : PatientFamilyHistorySection(
            key: ValueKey('family-history-${widget.summary.patientId}'),
            patientId: widget.summary.patientId,
            patientApi: api,
            medicalConditions: _medicalConditions,
            relationDegrees: _relationDegrees,
            readOnly: !_sectionEditable,
            allowAdd: true,
            initialRelatives: _cachedFamilyRelatives,
            onRelativesChanged: (relatives) {
              _cachedFamilyRelatives = relatives;
              _updateCacheFromState();
            },
          );

    return IndexedStack(
      index: PatientDetailSection.values.indexOf(_section),
      sizing: StackFit.loose,
      children: [
        (_section == PatientDetailSection.personalInfo && !_sectionEditable)
            ? _personalView()
            : _personalForm(),
        _medicalBody(),
        familySection,
        _baselineBody(),
        _visitsBody(),
      ],
    );
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
                  'Age ${s.age} • ${_summaryGenderLabel(s.gender)}',
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
          widget.fixedSection?.label ?? s.fullName,
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
          if (widget.fixedSection != null)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Center(
                child: Material(
                  color: _sectionReadOnly
                      ? AppColors.dashboardPrimary
                      : AppColors.dashboardChipBlueBg,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: _toggleSectionReadOnly,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sectionReadOnly
                                ? Icons.edit_outlined
                                : Icons.visibility_outlined,
                            size: 15.sp,
                            color: _sectionReadOnly
                                ? AppColors.surface
                                : AppColors.dashboardPrimary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            _sectionReadOnly ? 'Edit' : 'View',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: _sectionReadOnly
                                  ? AppColors.surface
                                  : AppColors.dashboardPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
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
      if (widget.showProfileBanner)
        SliverToBoxAdapter(child: _patientDetailHeroBanner(s)),
      if (widget.showSectionTabs)
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
      if (_initialLoading)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _PatientDetailLoadingView(
            label: widget.fixedSection?.label ?? 'Patient details',
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 24.h),
          sliver: SliverToBoxAdapter(
            child: _sectionBody(),
          ),
        ),
    ];

    final scroll = CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: slivers,
    );

    return Material(
      color: AppColors.registrationScreenBg,
      child: SafeArea(
        child: widget.fixedSection != null
            ? RefreshIndicator(
                color: AppColors.dashboardPrimary,
                onRefresh: () => _refreshFromNetwork(),
                child: scroll,
              )
            : scroll,
      ),
    );
  }
}

class _PatientDetailLoadingView extends StatelessWidget {
  const _PatientDetailLoadingView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Material(
          elevation: 3,
          shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24.r),
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44.r,
                  height: 44.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Loading $label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Please wait while we fetch patient records…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
