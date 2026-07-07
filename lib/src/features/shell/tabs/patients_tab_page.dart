import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/input_format/cnic_input_formatter.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/home_dashboard_controller.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/patients/new_patient_registration_screen.dart';
import 'package:doctor_app/src/features/patients/patient_directory_list_card.dart';
import 'package:doctor_app/src/features/patients/patient_detail_hub_page.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';

/// Shell index **1** — patient directory from dashboard API + detail + registration.
class PatientsTabPage extends StatefulWidget {
  const PatientsTabPage({
    super.key,
    this.onStartVisit,
    this.onLeaveToHomeTab,
  });

  final ValueChanged<VisitPatientSeed>? onStartVisit;
  /// System back / toolbar back from directory → Home tab (shell index 0).
  final VoidCallback? onLeaveToHomeTab;

  @override
  State<PatientsTabPage> createState() => _PatientsTabPageState();
}


@immutable
class PatientDirectoryFilter {
  const PatientDirectoryFilter._(this._key);

  final String _key;

  static const PatientDirectoryFilter all = PatientDirectoryFilter._('all');
  static const PatientDirectoryFilter male = PatientDirectoryFilter._('male');
  static const PatientDirectoryFilter female = PatientDirectoryFilter._('female');

  static const String _condPrefix = 'c\u0001';

  factory PatientDirectoryFilter.byPrimaryCondition(String label) {
    return PatientDirectoryFilter._('$_condPrefix${label.trim()}');
  }

  String? get _conditionLabel {
    if (!_key.startsWith(_condPrefix)) return null;
    return _key.substring(_condPrefix.length);
  }

  bool matches(HwPatientSummary p) {
    switch (_key) {
      case 'all':
        return true;
      case 'male':
        return p._genderIsMale();
      case 'female':
        return p._genderIsFemale();
      default:
        final want = _conditionLabel;
        if (want == null || want.isEmpty) return true;
        return p.primaryCondition.trim().toLowerCase() == want.toLowerCase();
    }
  }

  String chipLabel(int totalPatients, List<HwPatientSummary> patients) {
    switch (_key) {
      case 'all':
        return 'All ($totalPatients)';
      case 'male':
        final n = patients.where((x) => x._genderIsMale()).length;
        return n > 0 ? 'Male ($n)' : 'Male';
      case 'female':
        final n = patients.where((x) => x._genderIsFemale()).length;
        return n > 0 ? 'Female ($n)' : 'Female';
      default:
        final cond = _conditionLabel;
        if (cond == null || cond.isEmpty) return '—';
        final n = patients
            .where(
              (x) =>
                  x.primaryCondition.trim().toLowerCase() ==
                  cond.toLowerCase(),
            )
            .length;
        return n > 1 ? '$cond ($n)' : cond;
    }
  }

  /// Fixed chips plus up to [maxConditions] distinct `primaryCondition` values.
  static List<PatientDirectoryFilter> chipsFor(
    List<HwPatientSummary> patients, {
    int maxConditions = 10,
  }) {
    final counts = <String, int>{};
    for (final p in patients) {
      final c = p.primaryCondition.trim();
      if (c.isEmpty) continue;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return [
      all,
      male,
      female,
      ...sorted
          .take(maxConditions)
          .map((e) => PatientDirectoryFilter.byPrimaryCondition(e.key)),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is PatientDirectoryFilter && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

extension PatientsDirectoryUi on HwPatientSummary {
  bool _genderIsMale() {
    final g = gender.trim().toLowerCase();
    return g == 'male' || g == 'm';
  }

  bool _genderIsFemale() {
    final g = gender.trim().toLowerCase();
    return g == 'female' || g == 'f';
  }

  bool matchesSearch(String q) {
    final raw = q.trim();
    if (raw.isEmpty) return true;
    final qq = raw.toLowerCase();
    if (fullName.toLowerCase().contains(qq)) return true;
    if (patientId.toLowerCase().contains(qq)) return true;
    if (displayId.toLowerCase().contains(qq)) return true;

    final qDigits = CnicInputFormatter.digitsOnly(raw);
    if (qDigits.length >= 3) {
      bool digitsHit(String? s) {
        final d = CnicInputFormatter.digitsOnly(s ?? '');
        if (d.isEmpty) return false;
        return d.startsWith(qDigits) || d.contains(qDigits);
      }

      if (digitsHit(cnic)) return true;
      if (digitsHit(formattedPatientId)) return true;
      if (digitsHit(displayId)) return true;
    }
    return false;
  }
}

class _PatientsTabPageState extends State<PatientsTabPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _chipScrollController = ScrollController();

  PatientDirectoryFilter _selectedFilter = PatientDirectoryFilter.all;
  HwPatientSummary? _selectedPatient;

  bool get _searchChromeActive {
    return _searchFocusNode.hasFocus ||
        _searchController.text.trim().isNotEmpty;
  }

  void _onSearchChromeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchChromeChanged);
    _searchController.addListener(_onSearchChromeChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchChromeChanged);
    _searchController.removeListener(_onSearchChromeChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  Future<void> _onCreatePatient() async {
    final created = await context.push<bool>(
      NewPatientRegistrationScreen.routePath,
    );
    if (!mounted) return;
    if (created == true && _selectedPatient != null) {
      setState(() => _selectedPatient = null);
    }
  }

  void _onPatientTap(HwPatientSummary p) {
    setState(() => _selectedPatient = p);
  }

  List<HwPatientSummary> _visible(
    List<HwPatientSummary> all,
    PatientDirectoryFilter filter,
  ) {
    final q = _searchController.text;
    final out = all
        .where((p) => filter.matches(p))
        .where((p) => p.matchesSearch(q))
        .toList();
    out.sort((a, b) {
      final ca = a.primaryCondition.trim().toLowerCase();
      final cb = b.primaryCondition.trim().toLowerCase();
      if (ca.isEmpty != cb.isEmpty) {
        return ca.isEmpty ? 1 : -1;
      }
      final cCmp = ca.compareTo(cb);
      if (cCmp != 0) return cCmp;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final dash = context.watch<HomeDashboardController>();
    final selected = _selectedPatient;

    Widget body;
    if (selected != null) {
      // After PUT /api/Patient (or other flows) we reload the dashboard list.
      // `_selectedPatient` was captured from an older list instance, so the detail
      // screen would keep showing stale `fullName` / age / etc. until the user
      // re-tapped the row. Re-bind to the same `patientId` from the latest fetch.
      final dashPatients = dash.patients;
      HwPatientSummary? match;
      for (final p in dashPatients) {
        if (p.patientId == selected.patientId) {
          match = p;
          break;
        }
      }
      if (match != null && !identical(match, selected)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_selectedPatient?.patientId != selected.patientId) return;
          setState(() => _selectedPatient = match);
        });
      }

      body = SafeArea(
        bottom: false,
        child: PatientDetailHubPage(
          key: ValueKey(selected.patientId),
          summary: match ?? selected,
          onBack: () => setState(() => _selectedPatient = null),
          onStartVisit: widget.onStartVisit,
        ),
      );
    } else if (session.state.role != UserRole.ladyHealthWorker) {
      body = SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              'Patient directory is available for Lady Health Worker accounts.',
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
    final patients = dash.patients;
    final filters = PatientDirectoryFilter.chipsFor(patients);
    final selectedFilter = filters.contains(_selectedFilter)
        ? _selectedFilter
        : PatientDirectoryFilter.all;
    if (selectedFilter != _selectedFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedFilter = selectedFilter);
        }
      });
    }
    final visible = _visible(patients, selectedFilter);

    body = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    final h = widget.onLeaveToHomeTab;
                    if (h != null) {
                      h();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  splashRadius: 22.r,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 19.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                const Spacer(),
                if (!_searchChromeActive)
                  IconButton(
                    onPressed: _onCreatePatient,
                    splashRadius: 22.r,
                    icon: Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 24.sp,
                      color: AppColors.dashboardPrimary,
                    ),
                  )
                else
                  SizedBox(width: 48.w),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
            child: PatientDirectoryHeaderBanner(
              totalCount: patients.length,
              visibleCount: visible.length,
            ),
          ),
          if (dash.error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Material(
                color: AppColors.dashboardPeach,
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dash.error!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dashboardWarning,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: dash.loading
                            ? null
                            : () => dash.refreshFromSession(session.state),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by name, ID, or CNIC…',
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
                  final selectedChip = f == selectedFilter;
                  return ChoiceChip(
                    label: Text(
                      f.chipLabel(patients.length, patients),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: selectedChip
                            ? Colors.white
                            : AppColors.dashboardPrimary,
                      ),
                    ),
                    selected: selectedChip,
                    onSelected: (v) {
                      if (v) setState(() => _selectedFilter = f);
                    },
                    showCheckmark: false,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: selectedChip
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
            child: dash.loading && patients.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.dashboardPrimary,
                    ),
                  )
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          patients.isEmpty
                              ? 'No patients loaded yet. Pull to refresh from Home, or tap Retry.'
                              : 'No patients match — try another filter or search',
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
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: PatientDirectoryListCard(
                              patient: p,
                              onTap: () => _onPatientTap(p),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
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
      child: body,
    );
  }
}
