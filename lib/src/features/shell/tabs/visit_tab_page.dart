import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/presentation/bp_reading_color.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/reference/reference_api.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/home_dashboard_controller.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';

/// Visual severity tier for the auto-recommended visit action.
enum _RecommendedActionSeverity { controlled, uncontrolled, severe, emergency }

/// Shell index **2** — visit workflow: visit submit uses **`POST /api/Patient/visit`**.
///
/// Medical / surgical / drug history **create**/**update** live on separate
/// `POST`/`PUT …/medicalhistory` (and siblings) and are handled from the patient
/// detail **Medical History** tab after `GET …/complete-history/{id}` — not here.
class VisitTabPage extends StatefulWidget {
  const VisitTabPage({
    super.key,
    this.initialPatient,
    this.openRequestId = 0,
    this.onLeaveToHomeTab,
    this.onVisitAssessmentActiveChanged,
  });

  final VisitPatientSeed? initialPatient;
  final int openRequestId;
  /// System back from visit list (not assessment) → Home tab.
  final VoidCallback? onLeaveToHomeTab;
  /// `true` while the visit assessment form is on screen (hide shell center FAB).
  final ValueChanged<bool>? onVisitAssessmentActiveChanged;

  @override
  State<VisitTabPage> createState() => _VisitTabPageState();
}

/// [id] is the **display** patient id (e.g. formatted code). [apiPatientId] is the backend patient GUID.
class VisitPatientSeed {
  const VisitPatientSeed({
    required this.name,
    required this.id,
    required this.apiPatientId,
    required this.age,
    required this.gender,
    required this.lastVisit,
    this.openedFromFollowUpList = false,
  });

  final String name;
  final String id;
  final String apiPatientId;
  final int age;
  final String gender;
  final String lastVisit;

  /// True when the user picked this patient from the dashboard **follow-up** queue
  /// (Home or Visit tab). Pre-ticks "Follow-up visit" on the assessment form.
  final bool openedFromFollowUpList;
}

enum _VisitPatientListKind { followUps, directory }

class _VisitTabPageState extends State<VisitTabPage> {
  VisitPatientSeed? _selectedPatient;
  _VisitPatientListKind _listKind = _VisitPatientListKind.directory;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
    if (_selectedPatient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVisitAssessmentActiveChanged?.call(true);
      });
    }
  }

  void _setSelectedPatient(VisitPatientSeed? patient) {
    if (_selectedPatient == patient) return;
    setState(() => _selectedPatient = patient);
    widget.onVisitAssessmentActiveChanged?.call(patient != null);
  }

  @override
  void dispose() {
    if (_selectedPatient != null) {
      widget.onVisitAssessmentActiveChanged?.call(false);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VisitTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialPatient;
    if (next != null &&
        (next.apiPatientId != oldWidget.initialPatient?.apiPatientId ||
            widget.openRequestId != oldWidget.openRequestId)) {
      setState(() => _selectedPatient = next);
      widget.onVisitAssessmentActiveChanged?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _selectedPatient;

    late final Widget page;
    if (patient != null) {
      page = _VisitAssessmentView(
        patient: patient,
        onBack: () => _setSelectedPatient(null),
      );
    } else {
      final session = context.watch<SessionController>();
      final dash = context.watch<HomeDashboardController>();

      if (session.state.role != UserRole.ladyHealthWorker) {
        page = SafeArea(
          bottom: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                'Visit workflow is available for Lady Health Worker accounts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      } else {
        final followUps = dash.followUps;
        final patients = dash.patients;
        final useFollowUps = _listKind == _VisitPatientListKind.followUps;
        final listEmpty = useFollowUps ? followUps.isEmpty : patients.isEmpty;
        final listLoading = dash.loading && listEmpty;

        page = SafeArea(
          bottom: false,
          child: ColoredBox(
            color: AppColors.registrationScreenBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 8.h),
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
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: SegmentedButton<_VisitPatientListKind>(
                    segments: [
                      ButtonSegment(
                        value: _VisitPatientListKind.followUps,
                        label: Text(
                          'Follow-ups',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: Icon(Icons.event_repeat_rounded, size: 18.sp),
                      ),
                      ButtonSegment(
                        value: _VisitPatientListKind.directory,
                        label: Text(
                          'All patients',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: Icon(Icons.people_outline_rounded, size: 18.sp),
                      ),
                    ],
                    selected: {_listKind},
                    onSelectionChanged: (next) {
                      setState(() => _listKind = next.single);
                    },
                  ),
                ),
                if (dash.error != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      dash.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dashboardWarning,
                      ),
                    ),
                  ),
                Expanded(
                  child: listLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.dashboardPrimary,
                          ),
                        )
                      : listEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Text(
                                  useFollowUps
                                      ? 'No pending follow-ups right now. Switch to All patients to log a visit for anyone in your directory.'
                                      : 'No patients in your directory yet. Open Home or Patients — data loads automatically.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
                              itemCount: useFollowUps
                                  ? followUps.length
                                  : patients.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final VisitPatientSeed seed;
                                if (useFollowUps) {
                                  final f = followUps[index];
                                  seed = VisitPatientSeed(
                                    name: f.fullName,
                                    id: f.displayId,
                                    apiPatientId: f.patientId,
                                    age: f.age,
                                    gender: f.gender,
                                    lastVisit: _shortVisit(f.lastVisitDate),
                                    openedFromFollowUpList: true,
                                  );
                                } else {
                                  final p = patients[index];
                                  seed = VisitPatientSeed(
                                    name: p.fullName,
                                    id: p.displayId,
                                    apiPatientId: p.patientId,
                                    age: p.age,
                                    gender: p.gender,
                                    lastVisit: _shortVisit(p.lastVisitDate),
                                  );
                                }
                                return _VisitPatientCard(
                                  patient: seed,
                                  onTap: () => _setSelectedPatient(seed),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedPatient != null) {
          _setSelectedPatient(null);
        } else {
          widget.onLeaveToHomeTab?.call();
        }
      },
      child: page,
    );
  }

  static String _shortVisit(DateTime? d) {
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
}

class _VisitPatientCard extends StatelessWidget {
  const _VisitPatientCard({
    required this.patient,
    required this.onTap,
  });

  final VisitPatientSeed patient;
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

class _VisitAssessmentView extends StatefulWidget {
  const _VisitAssessmentView({
    required this.patient,
    required this.onBack,
  });

  final VisitPatientSeed patient;
  final VoidCallback onBack;

  @override
  State<_VisitAssessmentView> createState() => _VisitAssessmentViewState();
}

class _VisitAssessmentViewState extends State<_VisitAssessmentView> {
  final _formKey = GlobalKey<FormState>();
  final _systolic1Controller = TextEditingController(text: '120');
  final _diastolic1Controller = TextEditingController(text: '80');
  final _systolic2Controller = TextEditingController(text: '120');
  final _diastolic2Controller = TextEditingController(text: '80');
  final _pulseController = TextEditingController(text: '78');
  final _temperatureController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _reasonController = TextEditingController();
  final _weightConcernsController = TextEditingController();
  final _adherenceNoteController = TextEditingController();

  ReferenceApi? _referenceApi;
  PatientApi? _patientApi;

  bool _refsLoading = true;
  String? _refsError;

  List<NamedReferenceItem> _visitTypes = const [];
  List<NamedReferenceItem> _visitStatuses = const [];
  List<NamedReferenceItem> _visitActions = const [];
  List<NamedReferenceItem> _symptoms = const [];
  List<NamedReferenceItem> _physicalLevels = const [];

  int? _visitTypeId;
  int? _visitStatusId;
  int? _visitActionId;
  int? _physicalActivityLevelId;

  final Map<int, bool> _symptomAnswers = {};

  bool _highSaltDiet = false;
  bool _alcoholUse = false;
  bool _isFollowUpVisit = false;
  bool _dangerSigns = false;
  DateTime? _nextVisitDate;

  bool _submitting = false;

  void _onBpControllersChanged() {
    if (!mounted) return;
    setState(() {
      _visitActionId = _recommendedActionId() ?? _visitActionId;
    });
  }

  int? _recommendedActionId() {
    if (_visitActions.isEmpty) return null;
    final avg = _averagedBpPair();
    if (avg == null) return _visitActionId;
    final sbp = avg.sbp;
    final dbp = avg.dbp;
    final bpHigh = sbp >= 140 || dbp >= 90;

    // Match against the action names returned from the reference API.
    // Keywords are picked so each tier maps to exactly one DB row:
    //   1 Normal · 2 Advised · 3 Referral · 4 Emergency Transfer ·
    //   5 Continue monitoring · 6 Refer and Follow-up · 7 Urgent referral
    if (_dangerSigns && bpHigh) {
      return _findVisitActionId(const ['emergency', 'transfer']);
    }
    if (sbp >= 180 || dbp >= 120) {
      return _findVisitActionId(const ['urgent']);
    }
    if (bpHigh) {
      return _findVisitActionId(const ['follow']);
    }
    return _findVisitActionId(const ['continue', 'monitor']);
  }

  int? _findVisitActionId(List<String> keywords) {
    for (final keyword in keywords) {
      for (final a in _visitActions) {
        if (a.id > 0 && a.name.toLowerCase().contains(keyword)) {
          return a.id;
        }
      }
    }
    return _firstPositiveId(_visitActions);
  }

  /// Severity tier (used only for tinting the recommended-action tile).
  _RecommendedActionSeverity _recommendedActionSeverity() {
    final avg = _averagedBpPair();
    if (avg == null) return _RecommendedActionSeverity.controlled;
    final sbp = avg.sbp;
    final dbp = avg.dbp;
    final bpHigh = sbp >= 140 || dbp >= 90;
    if (_dangerSigns && bpHigh) return _RecommendedActionSeverity.emergency;
    if (sbp >= 180 || dbp >= 120) return _RecommendedActionSeverity.severe;
    if (bpHigh) return _RecommendedActionSeverity.uncontrolled;
    return _RecommendedActionSeverity.controlled;
  }

  static int _roundedMean(int a, int b) => ((a + b) / 2).round();

  /// Both readings complete → average SBP/DBP for API + coloring.
  ({int sbp, int dbp})? _averagedBpPair() {
    final s1 = _parseIntCtl(_systolic1Controller);
    final d1 = _parseIntCtl(_diastolic1Controller);
    final s2 = _parseIntCtl(_systolic2Controller);
    final d2 = _parseIntCtl(_diastolic2Controller);
    if (s1 == null || d1 == null || s2 == null || d2 == null) return null;
    return (sbp: _roundedMean(s1, s2), dbp: _roundedMean(d1, d2));
  }

  Color _bpTintForReading(int? sys, int? dia) {
    if (sys == null || dia == null) return AppColors.textPrimary;
    return BpReadingColor.forPair(sys, dia);
  }

  String _bpCategoryLabel(int sbp, int dbp) {
    if (sbp >= 180 && dbp >= 120) return 'Severe HTN (urgent)';
    if (sbp >= 140 && dbp >= 90) return 'Uncontrolled HTN';
    if (sbp < 140 && dbp < 90) return 'Controlled';
    return 'Mixed / borderline';
  }

  @override
  void initState() {
    super.initState();
    _isFollowUpVisit = widget.patient.openedFromFollowUpList;
    _systolic1Controller.addListener(_onBpControllersChanged);
    _diastolic1Controller.addListener(_onBpControllersChanged);
    _systolic2Controller.addListener(_onBpControllersChanged);
    _diastolic2Controller.addListener(_onBpControllersChanged);
    _pulseController.addListener(_onBpControllersChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadReferencePayload());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = context.read<SessionController>().apiClient;
    _referenceApi ??= ReferenceApi(client);
    _patientApi ??= PatientApi(client);
  }

  @override
  void dispose() {
    _systolic1Controller.removeListener(_onBpControllersChanged);
    _diastolic1Controller.removeListener(_onBpControllersChanged);
    _systolic2Controller.removeListener(_onBpControllersChanged);
    _diastolic2Controller.removeListener(_onBpControllersChanged);
    _pulseController.removeListener(_onBpControllersChanged);
    _systolic1Controller.dispose();
    _diastolic1Controller.dispose();
    _systolic2Controller.dispose();
    _diastolic2Controller.dispose();
    _pulseController.dispose();
    _temperatureController.dispose();
    _respiratoryRateController.dispose();
    _reasonController.dispose();
    _weightConcernsController.dispose();
    _adherenceNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadReferencePayload() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _refsLoading = false;
          _refsError = 'Please sign in again.';
        });
      }
      return;
    }

    setState(() {
      _refsLoading = true;
      _refsError = null;
    });

    try {
      final ref = _referenceApi!;
      final results = await Future.wait<List<NamedReferenceItem>>([
        ref.getVisitTypes(bearerToken: token),
        ref.getVisitStatuses(bearerToken: token),
        ref.getVisitActions(bearerToken: token),
        ref.getSymptoms(bearerToken: token),
        ref.getPhysicalActivityLevels(bearerToken: token),
      ]);

      if (!mounted) return;
      setState(() {
        _visitTypes = results[0];
        _visitStatuses = results[1];
        _visitActions = results[2];
        _symptoms = results[3];
        _physicalLevels = results[4];

        _visitTypeId = _firstPositiveId(_visitTypes);
        _visitStatusId = _firstPositiveId(_visitStatuses);
        _physicalActivityLevelId = _firstPositiveId(_physicalLevels);
        _visitActionId =
            _recommendedActionId() ?? _firstPositiveId(_visitActions);
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      final msg =
          context.read<SessionController>().apiClient.mapError(e).message;

      setState(() => _refsError = msg);
    } finally {
      if (mounted) setState(() => _refsLoading = false);
    }
  }

  static int? _firstPositiveId(List<NamedReferenceItem> items) {
    for (final e in items) {
      if (e.id > 0) return e.id;
    }
    return null;
  }

  int? _parseIntCtl(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v;
  }

  Color _pulseInputColor() {
    final p = _parseIntCtl(_pulseController);
    if (p == null) return AppColors.textPrimary;
    return BpReadingColor.forPulse(p);
  }

  double? _parseDoubleCtl(TextEditingController c) {
    return double.tryParse(c.text.trim().replaceAll(',', '.'));
  }

  Map<String, dynamic> _buildVisitBody({
    required String patientId,
    required String healthWorkerId,
  }) {
    final s1 = _parseIntCtl(_systolic1Controller);
    final d1 = _parseIntCtl(_diastolic1Controller);
    final s2 = _parseIntCtl(_systolic2Controller);
    final d2 = _parseIntCtl(_diastolic2Controller);
    final pulse = _parseIntCtl(_pulseController);
    final temperature = _parseDoubleCtl(_temperatureController);
    final respiratoryRate = _parseIntCtl(_respiratoryRateController);

    final map = <String, dynamic>{
      'patientId': patientId,
      'healthWorkerId': healthWorkerId,
      'visitTypeId': _visitTypeId ?? 0,
      'isFollowUpVisit': _isFollowUpVisit,
      'highSaltDiet': _highSaltDiet,
      'alcoholUse': _alcoholUse,
      'dangerSigns': _dangerSigns,
      'symptomIds': _symptomAnswers.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      // Send local "now" without `.toUtc()` so the calendar date that the
      // user sees on their phone is what the backend stores.
      'visitDate': DateTime.now().toIso8601String(),
    };

    if (_symptomAnswers.isNotEmpty) {
      map['symptoms'] = _symptomAnswers.entries
          .map(
            (e) => <String, dynamic>{
              'symptomId': e.key,
              'isPresent': e.value,
            },
          )
          .toList();
    }

    final reason = _reasonController.text.trim();
    if (reason.isNotEmpty) map['reasonForVisit'] = reason;

    if (s1 != null) map['systolicBP1'] = s1;
    if (d1 != null) map['diastolicBP1'] = d1;
    if (s2 != null) map['systolicBP2'] = s2;
    if (d2 != null) map['diastolicBP2'] = d2;
    final avg = _averagedBpPair();
    if (avg != null) {
      map['avgSystolicBP'] = avg.sbp;
      map['avgDiastolicBP'] = avg.dbp;
    }
    if (pulse != null) map['pulse'] = pulse;
    if (temperature != null) map['temperature'] = temperature;
    if (respiratoryRate != null) map['respiratoryRate'] = respiratoryRate;

    if (_visitActionId != null && _visitActionId! > 0) {
      map['visitActionId'] = _visitActionId;
    }
    if (_visitStatusId != null && _visitStatusId! > 0) {
      map['visitStatusId'] = _visitStatusId;
    }
    if (_physicalActivityLevelId != null && _physicalActivityLevelId! > 0) {
      map['physicalActivityLevelId'] = _physicalActivityLevelId;
    }

    final w = _weightConcernsController.text.trim();
    if (w.isNotEmpty) map['weightConcerns'] = w;

    final ad = _adherenceNoteController.text.trim();
    if (ad.isNotEmpty) map['medicalAdherenceNote'] = ad;

    if (_nextVisitDate != null) {
      // Anchor at local noon so the calendar day never flips into the
      // previous day when the backend converts to UTC.
      final d = _nextVisitDate!;
      map['nextVisitDate'] =
          DateTime(d.year, d.month, d.day, 12).toIso8601String();
    }

    return map;
  }

  Future<void> _submitVisitRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_refsLoading || _visitTypeId == null || _visitTypeId! <= 0) {
      _toast('Still loading visit options, or select a visit type.');
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    final hwId = session.state.healthWorkerIdForPatientApis?.trim();
    if (token == null || token.isEmpty || hwId == null || hwId.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    int? bp(String label, TextEditingController c) {
      final v = _parseIntCtl(c);
      if (v == null) {
        _toast('$label is required.');
        return null;
      }
      if (v < 50 || v > 300) {
        _toast('$label must be between 50 and 300.');
        return null;
      }
      return v;
    }

    if (bp('Reading 1 systolic', _systolic1Controller) == null) return;
    if (bp('Reading 1 diastolic', _diastolic1Controller) == null) return;
    if (bp('Reading 2 systolic', _systolic2Controller) == null) return;
    if (bp('Reading 2 diastolic', _diastolic2Controller) == null) return;
    final pulse = _parseIntCtl(_pulseController);
    if (pulse != null && (pulse < 20 || pulse > 300)) {
      _toast('Pulse must be between 20 and 300.');
      return;
    }
    final tempRaw = _temperatureController.text.trim();
    if (tempRaw.isNotEmpty) {
      final temp = _parseDoubleCtl(_temperatureController);
      if (temp == null || temp < 30 || temp > 45) {
        _toast('Temperature must be between 30 and 45 °C.');
        return;
      }
    }
    final rrRaw = _respiratoryRateController.text.trim();
    if (rrRaw.isNotEmpty) {
      final rr = _parseIntCtl(_respiratoryRateController);
      if (rr == null || rr < 5 || rr > 80) {
        _toast('Respiratory rate must be between 5 and 80 per minute.');
        return;
      }
    }

    if (_symptoms.isNotEmpty) {
      for (final s in _symptoms) {
        if (s.id <= 0) continue;
        if (!_symptomAnswers.containsKey(s.id)) {
          _toast('Answer Yes or No for each symptom.');
          return;
        }
      }
    }

    final pid = widget.patient.apiPatientId.trim();
    if (pid.isEmpty) {
      _toast('Missing patient id for API.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = _patientApi!;
      final body = _buildVisitBody(patientId: pid, healthWorkerId: hwId);
      await api.createVisit(body: body, bearerToken: token);

      if (!mounted) return;
      _toast('Visit saved for ${widget.patient.name}.');
      try {
        await context.read<HomeDashboardController>().refreshFromSession(
              session.state,
            );
      } catch (_) {}
      if (!mounted) return;
      if (_visitWasFollowUpContext() &&
          _selectedVisitStatusIndicatesFollowUpDone()) {
        context.read<HomeDashboardController>().removeFollowUpForPatient(
              widget.patient.apiPatientId,
            );
      }
      widget.onBack();
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _labelForId(List<NamedReferenceItem> items, int id) {
    for (final e in items) {
      if (e.id == id) return e.name;
    }
    return '';
  }

  /// Visit status label suggests the follow-up work is finished (home queue).
  bool _selectedVisitStatusIndicatesFollowUpDone() {
    final id = _visitStatusId;
    if (id == null || id <= 0) return false;
    final n = _labelForId(_visitStatuses, id).trim().toLowerCase();
    if (n.isEmpty) return false;
    return n.contains('complete') ||
        n.contains('closed') ||
        n.contains('resolved') ||
        n == 'done' ||
        n == 'attended';
  }

  bool _visitWasFollowUpContext() {
    return widget.patient.openedFromFollowUpList || _isFollowUpVisit;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 14.sp))),
    );
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
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: AppColors.registrationSectionLabel,
        ),
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

  Widget _intField({
    required String label,
    required String unit,
    required TextEditingController controller,
    Color? valueColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w900,
        color: valueColor ?? AppColors.textPrimary,
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
        if (int.tryParse(value.trim()) == null) return 'Enter a number';
        return null;
      },
    );
  }

  Widget _optionalIntField({
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
    );
  }

  Widget _optionalDecimalField({
    required String label,
    required String unit,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    );
  }

  Widget _symptomYesNoRow(NamedReferenceItem symptom) {
    final answer = _symptomAnswers[symptom.id];
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.registrationFieldFill.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.registrationFieldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                symptom.name,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dashboardPrimaryDark,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            _yesNoChoice(
              label: 'Yes',
              selected: answer == true,
              onTap: () => setState(() => _symptomAnswers[symptom.id] = true),
            ),
            SizedBox(width: 6.w),
            _yesNoChoice(
              label: 'No',
              selected: answer == false,
              onTap: () => setState(() => _symptomAnswers[symptom.id] = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yesNoChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.dashboardPrimary
          : AppColors.surface,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: selected
                  ? AppColors.dashboardPrimary
                  : AppColors.registrationFieldBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownInt({
    required String label,
    required int? value,
    required List<NamedReferenceItem> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(label),
        DropdownButtonFormField<int>(
          value: value,
          decoration: _fieldDecoration(),
          items: items
              .where((e) => e.id > 0)
              .map(
                (e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(
                    e.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: _refsLoading ? null : onChanged,
        ),
      ],
    );
  }

  Widget _visitVitalsRecordCard() {
    final s1 = _parseIntCtl(_systolic1Controller);
    final d1 = _parseIntCtl(_diastolic1Controller);
    final s2 = _parseIntCtl(_systolic2Controller);
    final d2 = _parseIntCtl(_diastolic2Controller);
    final avg = _averagedBpPair();
    final avgColor = avg != null
        ? BpReadingColor.forPair(avg.sbp, avg.dbp)
        : AppColors.textSecondary;

    TextStyle readingLabelStyle() => TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.registrationSectionLabel,
          letterSpacing: 0.3,
        );

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimaryDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.dashboardPrimary,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Visit vitals (visit record)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'دو ریڈنگز کا اوسط • Controlled: SBP < 140 & DBP < 90 (green) · '
            'Uncontrolled: SBP ≥ 140 & DBP ≥ 90 (orange) · '
            'Severe: SBP ≥ 180 & DBP ≥ 120 (red)',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: 14.h),
          Text('Reading 1', style: readingLabelStyle()),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _intField(
                  label: 'Systolic',
                  unit: 'mmHg',
                  controller: _systolic1Controller,
                  valueColor: _bpTintForReading(s1, d1),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _intField(
                  label: 'Diastolic',
                  unit: 'mmHg',
                  controller: _diastolic1Controller,
                  valueColor: _bpTintForReading(s1, d1),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text('Reading 2', style: readingLabelStyle()),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _intField(
                  label: 'Systolic',
                  unit: 'mmHg',
                  controller: _systolic2Controller,
                  valueColor: _bpTintForReading(s2, d2),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _intField(
                  label: 'Diastolic',
                  unit: 'mmHg',
                  controller: _diastolic2Controller,
                  valueColor: _bpTintForReading(s2, d2),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (avg != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: avgColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: avgColor.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Average BP (mean of reading 1 & 2)',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${avg.sbp} / ${avg.dbp} mmHg',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: avgColor,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: avgColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _bpCategoryLabel(avg.sbp, avg.dbp),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: avgColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Text(
              'Enter all four BP values to show the average and category.',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          SizedBox(height: 14.h),
          _intField(
            label: 'Pulse',
            unit: 'bpm',
            controller: _pulseController,
            valueColor: _pulseInputColor(),
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _optionalDecimalField(
                  label: 'Temperature',
                  unit: '°C',
                  controller: _temperatureController,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _optionalIntField(
                  label: 'Respiratory rate',
                  unit: '/min',
                  controller: _respiratoryRateController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _severityColor(_RecommendedActionSeverity s) {
    switch (s) {
      case _RecommendedActionSeverity.controlled:
        return AppColors.followAccentGreen;
      case _RecommendedActionSeverity.uncontrolled:
        return AppColors.dashboardWarning;
      case _RecommendedActionSeverity.severe:
        return AppColors.danger;
      case _RecommendedActionSeverity.emergency:
        return AppColors.danger;
    }
  }

  String _severitySubtitle(_RecommendedActionSeverity s) {
    switch (s) {
      case _RecommendedActionSeverity.controlled:
        return 'Controlled — SBP < 140 and DBP < 90';
      case _RecommendedActionSeverity.uncontrolled:
        return 'Uncontrolled — SBP ≥ 140 or DBP ≥ 90';
      case _RecommendedActionSeverity.severe:
        return 'Severe — SBP ≥ 180 or DBP ≥ 120';
      case _RecommendedActionSeverity.emergency:
        return 'Emergency — high BP + danger signs';
    }
  }

  Widget _recommendedActionTile() {
    final id = _visitActionId;
    final label = (id != null && id > 0) ? _labelForId(_visitActions, id) : '';
    final severity = _recommendedActionSeverity();
    final color = _severityColor(severity);
    final avg = _averagedBpPair();
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.medical_information_outlined,
              size: 18.sp,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended action (auto)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.registrationSectionLabel,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label.isNotEmpty
                      ? label
                      : (avg == null
                          ? 'Enter all BP readings to compute.'
                          : 'No matching visit action in reference data.'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _severitySubtitle(severity),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.lock_outline_rounded,
            size: 16.sp,
            color: color.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _dangerSignsToggle() {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        'Danger signs present',
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Severe headache, chest pain, blurred vision, etc.',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      value: _dangerSigns,
      onChanged: (v) {
        setState(() {
          _dangerSigns = v ?? false;
          _visitActionId = _recommendedActionId() ?? _visitActionId;
        });
      },
    );
  }

  Widget _nextVisitDateTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Next visit date'),
        Material(
          color: AppColors.registrationFieldFill,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: _pickNextVisit,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.registrationFieldBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _nextVisitDate == null
                          ? 'Tap to pick the next visit date'
                          : '${_nextVisitDate!.year}-${_nextVisitDate!.month.toString().padLeft(2, '0')}-${_nextVisitDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: _nextVisitDate == null
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: _nextVisitDate == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_nextVisitDate != null)
                    IconButton(
                      onPressed: () => setState(() => _nextVisitDate = null),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18.sp,
                        color: AppColors.textSecondary,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickNextVisit() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() => _nextVisitDate = picked);
    }
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
            if (_refsError != null)
              Material(
                color: AppColors.dashboardPeach,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
               
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
                      _nextVisitDateTile(),
                      SizedBox(height: 18.h),
                      if (_refsLoading)
                        Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.dashboardPrimary,
                            ),
                          ),
                        )
                      else
                        _dropdownInt(
                          label: 'Visit status',
                          value: _visitStatusId,
                          items: _visitStatuses,
                          onChanged: (v) => setState(() => _visitStatusId = v),
                        ),
                      SizedBox(height: 18.h),
                      _visitVitalsRecordCard(),
                      SizedBox(height: 12.h),
                      _dangerSignsToggle(),
                      SizedBox(height: 8.h),
                      _recommendedActionTile(),
                      SizedBox(height: 20.h),
                      _sectionTitle('VISIT'),
                      if (!_refsLoading) ...[
                        _dropdownInt(
                          label: 'Visit type *',
                          value: _visitTypeId,
                          items: _visitTypes,
                          onChanged: (v) => setState(() => _visitTypeId = v),
                        ),
                        SizedBox(height: 12.h),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Follow-up visit',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: _isFollowUpVisit,
                          onChanged: _refsLoading
                              ? null
                              : (v) =>
                                  setState(() => _isFollowUpVisit = v ?? false),
                        ),
                        SizedBox(height: 8.h),
                        _label('Reason for visit'),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _fieldDecoration(),
                        ),
                      ],
                      SizedBox(height: 18.h),
                      _sectionTitle('SYMPTOMS'),
                      if (_symptoms.isEmpty)
                        Text(
                          'No symptoms from reference API.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else ...[
                        Text(
                          'Mark Yes or No for each symptom.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        ..._symptoms
                            .where((s) => s.id > 0)
                            .map(_symptomYesNoRow),
                      ],
                      SizedBox(height: 22.h),
                      _sectionTitle('LIFESTYLE (VISITUpsert)'),
                      if (!_refsLoading)
                        _dropdownInt(
                          label: 'Physical activity level',
                          value: _physicalActivityLevelId,
                          items: _physicalLevels,
                          onChanged: (v) =>
                              setState(() => _physicalActivityLevelId = v),
                        ),
                      SizedBox(height: 8.h),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'High salt diet',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _highSaltDiet,
                        onChanged: (v) =>
                            setState(() => _highSaltDiet = v ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Alcohol use',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _alcoholUse,
                        onChanged: (v) =>
                            setState(() => _alcoholUse = v ?? false),
                 
                      ),
                      SizedBox(height: 8.h),
                      _label('Weight concerns'),
                      TextFormField(
                        controller: _weightConcernsController,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _fieldDecoration(),
                      ),
                      SizedBox(height: 12.h),
                      _label('Medical adherence note'),
                      TextFormField(
                        controller: _adherenceNoteController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _fieldDecoration(),
                      ),
                      SizedBox(height: 24.h),
                      FilledButton.icon(
                        onPressed: (_submitting || _refsLoading)
                            ? null
                            : _submitVisitRecord,
                        icon: _submitting
                            ? SizedBox(
                                width: 22.sp,
                                height: 22.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.check_rounded, size: 22.sp),
                        label: Text(
                          _submitting ? 'Saving…' : 'Submit Visit Record',
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
