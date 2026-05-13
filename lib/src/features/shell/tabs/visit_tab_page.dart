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

/// Shell index **2** — visit workflow (`POST /api/Patient/visit` + optional history `PUT` on `PatientController`).
///
/// **Visit history** (list of past visits for a patient) is `GET /api/Patient/visits/{patientId}`
/// and matches [`PatientVisitResponseModel`](MedicalApi/Models/Patient/PatientResponses/PatientVisitResponseModel.cs).
///
/// Optional **medical / surgical / drug** rows use `PUT /api/Patient/medicalhistory` (and siblings), same as patient detail.
class VisitTabPage extends StatefulWidget {
  const VisitTabPage({
    super.key,
    this.initialPatient,
    this.openRequestId = 0,
    this.onLeaveToHomeTab,
  });

  final VisitPatientSeed? initialPatient;
  final int openRequestId;
  /// System back from visit list (not assessment) → Home tab.
  final VoidCallback? onLeaveToHomeTab;

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
  }

  @override
  void didUpdateWidget(covariant VisitTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialPatient;
    if (next != null &&
        (next.apiPatientId != oldWidget.initialPatient?.apiPatientId ||
            widget.openRequestId != oldWidget.openRequestId)) {
      setState(() => _selectedPatient = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _selectedPatient;

    late final Widget page;
    if (patient != null) {
      page = _VisitAssessmentView(
        patient: patient,
        onBack: () => setState(() => _selectedPatient = null),
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
                                  onTap: () => setState(
                                    () => _selectedPatient = seed,
                                  ),
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
          setState(() => _selectedPatient = null);
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
  final _systolicController = TextEditingController(text: '120');
  final _diastolicController = TextEditingController(text: '80');
  final _pulseController = TextEditingController(text: '78');
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
  List<NamedReferenceItem> _medicalConditions = const [];
  List<NamedReferenceItem> _surgicalProcedures = const [];
  List<NamedReferenceItem> _medicineCategories = const [];
  List<NamedReferenceItem> _physicalLevels = const [];

  int? _visitTypeId;
  int? _visitStatusId;
  int? _visitActionId;
  int? _physicalActivityLevelId;
  int? _medicalConditionId;
  int? _surgicalProcedureId;

  final Set<int> _symptomIds = {};
  final Set<int> _medicineCategoryIds = {};

  bool _highSaltDiet = false;
  bool _alcoholUse = false;
  bool _isFollowUpVisit = false;
  DateTime? _nextVisitDate;

  bool _submitting = false;

  void _onBpControllersChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _isFollowUpVisit = widget.patient.openedFromFollowUpList;
    _systolicController.addListener(_onBpControllersChanged);
    _diastolicController.addListener(_onBpControllersChanged);
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
    _systolicController.removeListener(_onBpControllersChanged);
    _diastolicController.removeListener(_onBpControllersChanged);
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
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
        ref.getMedicalConditions(bearerToken: token),
        ref.getSurgicalProcedures(bearerToken: token),
        ref.getMedicineCategories(bearerToken: token),
        ref.getPhysicalActivityLevels(bearerToken: token),
      ]);

      if (!mounted) return;
      setState(() {
        _visitTypes = results[0];
        _visitStatuses = results[1];
        _visitActions = results[2];
        _symptoms = results[3];
        _medicalConditions = results[4];
        _surgicalProcedures = results[5];
        _medicineCategories = results[6];
        _physicalLevels = results[7];

        _visitTypeId = _firstPositiveId(_visitTypes);
        _visitStatusId = _firstPositiveId(_visitStatuses);
        _visitActionId = _firstPositiveId(_visitActions);
        _physicalActivityLevelId = _firstPositiveId(_physicalLevels);
        _medicalConditionId = _firstNonNoneId(_medicalConditions) ??
            _firstPositiveId(_medicalConditions);
        _surgicalProcedureId = _firstIdNamedNone(_surgicalProcedures) ??
            _firstPositiveId(_surgicalProcedures);
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

  static int? _firstNonNoneId(List<NamedReferenceItem> items) {
    for (final e in items) {
      if (e.id > 0 && !_isNoneName(e.name)) return e.id;
    }
    return null;
  }

  static int? _firstIdNamedNone(List<NamedReferenceItem> items) {
    for (final e in items) {
      if (_isNoneName(e.name)) return e.id;
    }
    return null;
  }

  static bool _isNoneName(String name) {
    final n = name.trim().toLowerCase();
    return n == 'none' || n == 'no' || n == 'n/a';
  }

  int? _parseIntCtl(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v;
  }

  Color _bpPairInputColor() {
    final sys = _parseIntCtl(_systolicController);
    final dia = _parseIntCtl(_diastolicController);
    if (sys == null || dia == null) return AppColors.textPrimary;
    return BpReadingColor.forPair(sys, dia);
  }

  Map<String, dynamic> _buildVisitBody({
    required String patientId,
    required String healthWorkerId,
  }) {
    final sys = _parseIntCtl(_systolicController);
    final dia = _parseIntCtl(_diastolicController);
    final pulse = _parseIntCtl(_pulseController);

    final map = <String, dynamic>{
      'patientId': patientId,
      'healthWorkerId': healthWorkerId,
      'visitTypeId': _visitTypeId ?? 0,
      'isFollowUpVisit': _isFollowUpVisit,
      'highSaltDiet': _highSaltDiet,
      'alcoholUse': _alcoholUse,
      'symptomIds': _symptomIds.toList(),
    };

    final reason = _reasonController.text.trim();
    if (reason.isNotEmpty) map['reasonForVisit'] = reason;

    if (sys != null) {
      map['systolicBP1'] = sys;
      map['avgSystolicBP'] = sys;
    }
    if (dia != null) {
      map['diastolicBP1'] = dia;
      map['avgDiastolicBP'] = dia;
    }
    if (pulse != null) map['pulse'] = pulse;

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
      map['nextVisitDate'] = _nextVisitDate!.toUtc().toIso8601String();
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

    final sys = _parseIntCtl(_systolicController);
    final dia = _parseIntCtl(_diastolicController);
    if (sys != null && (sys < 50 || sys > 300)) {
      _toast('Systolic BP must be between 50 and 300.');
      return;
    }
    if (dia != null && (dia < 50 || dia > 300)) {
      _toast('Diastolic BP must be between 50 and 300.');
      return;
    }
    final pulse = _parseIntCtl(_pulseController);
    if (pulse != null && (pulse < 20 || pulse > 300)) {
      _toast('Pulse must be between 20 and 300.');
      return;
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

      var historyFailures = 0;
      String? historyFirstError;
      Future<void> tryHistory(Future<void> Function() run) async {
        try {
          await run();
        } on Object catch (e) {
          historyFailures++;
          historyFirstError ??= session.apiClient.mapError(e).message;
        }
      }

      await tryHistory(() async {
        final medId = _medicalConditionId;
        if (medId != null && medId > 0) {
          final label = _labelForId(_medicalConditions, medId);
          if (!_isNoneName(label)) {
            await api.postMedicalHistory(
              bearerToken: token,
              body: {
                'patientId': pid,
                'conditionId': medId,
                'isOnMedication': false,
              },
            );
          }
        }
      });

      await tryHistory(() async {
        final surgId = _surgicalProcedureId;
        if (surgId != null && surgId > 0) {
          final label = _labelForId(_surgicalProcedures, surgId);
          if (!_isNoneName(label)) {
            await api.postSurgicalHistory(
              bearerToken: token,
              body: {
                'patientId': pid,
                'procedureId': surgId,
              },
            );
          }
        }
      });

      await tryHistory(() async {
        for (final catId in _medicineCategoryIds) {
          if (catId <= 0) continue;
          await api.postDrugHistory(
            bearerToken: token,
            body: {
              'patientId': pid,
              'medicineCategoryId': catId,
            },
          );
        }
      });

      if (!mounted) return;
      if (historyFailures > 0) {
        final hint = historyFirstError?.trim();
        _toast(
          'Visit saved for ${widget.patient.name}. '
          'Some history rows could not be saved'
          '${hint != null && hint.isNotEmpty ? ': $hint' : '.'}',
        );
      } else {
        _toast('Visit saved for ${widget.patient.name}.');
      }
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

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.dashboardPrimary.withValues(alpha: 0.08)
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
                      _sectionTitle('VISIT'),
                      if (_refsLoading)
                        Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.dashboardPrimary,
                            ),
                          ),
                        )
                      else ...[
                        _dropdownInt(
                          label: 'Visit type *',
                          value: _visitTypeId,
                          items: _visitTypes,
                          onChanged: (v) => setState(() => _visitTypeId = v),
                        ),
                        SizedBox(height: 12.h),
                        _dropdownInt(
                          label: 'Visit status',
                          value: _visitStatusId,
                          items: _visitStatuses,
                          onChanged: (v) => setState(() => _visitStatusId = v),
                        ),
                        SizedBox(height: 12.h),
                        _dropdownInt(
                          label: 'Visit action',
                          value: _visitActionId,
                          items: _visitActions,
                          onChanged: (v) => setState(() => _visitActionId = v),
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
                      _sectionTitle('VITALS (VISIT RECORD)'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _intField(
                              label: 'Systolic',
                              unit: 'mmHg',
                              controller: _systolicController,
                              valueColor: _bpPairInputColor(),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _intField(
                              label: 'Diastolic',
                              unit: 'mmHg',
                              controller: _diastolicController,
                              valueColor: _bpPairInputColor(),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _intField(
                              label: 'Pulse',
                              unit: 'bpm',
                              controller: _pulseController,
                            ),
                          ),
                        ],
                      ),
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
                      else
                        Wrap(
                          spacing: 9.w,
                          runSpacing: 9.h,
                          children: _symptoms.map((s) {
                            return _chip(
                              label: s.name,
                              selected: _symptomIds.contains(s.id),
                              onTap: () => setState(() {
                                if (!_symptomIds.add(s.id)) {
                                  _symptomIds.remove(s.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 22.h),
                      _sectionTitle(
                          'MEDICAL / SURGICAL / DRUG (optional, Patient API)'),
                      if (!_refsLoading) ...[
                        _dropdownInt(
                          label: 'Medical condition (optional row)',
                          value: _medicalConditionId,
                          items: _medicalConditions,
                          onChanged: (v) =>
                              setState(() => _medicalConditionId = v),
                        ),
                        SizedBox(height: 12.h),
                        _dropdownInt(
                          label: 'Surgical procedure (optional row)',
                          value: _surgicalProcedureId,
                          items: _surgicalProcedures,
                          onChanged: (v) =>
                              setState(() => _surgicalProcedureId = v),
                        ),
                        SizedBox(height: 12.h),
                        _label('Medicine categories (drug history rows)'),
                        if (_medicineCategories.isEmpty)
                          Text(
                            'No categories from API.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 9.w,
                            runSpacing: 9.h,
                            children: _medicineCategories.map((c) {
                              return _chip(
                                label: c.name,
                                selected: _medicineCategoryIds.contains(c.id),
                                onTap: () => setState(() {
                                  if (!_medicineCategoryIds.add(c.id)) {
                                    _medicineCategoryIds.remove(c.id);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
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
                      SizedBox(height: 12.h),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Next visit date',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _nextVisitDate == null
                              ? 'Not set'
                              : '${_nextVisitDate!.year}-${_nextVisitDate!.month.toString().padLeft(2, '0')}-${_nextVisitDate!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: _pickNextVisit,
                          icon: Icon(Icons.calendar_today_rounded, size: 20.sp),
                        ),
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
