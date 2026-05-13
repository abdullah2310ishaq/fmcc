import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_api.dart';
import 'package:doctor_app/src/features/home/home_dashboard_controller.dart';
import 'package:doctor_app/src/features/home/home_tab_page.dart';
import 'package:doctor_app/src/features/patients/new_patient_registration_screen.dart';
import 'package:doctor_app/src/features/patients/patient_directory_coordinator.dart';
import 'package:doctor_app/src/features/shell/home_shell_tab.dart';
import 'package:doctor_app/src/features/shell/shell_nav_item.dart';
import 'package:doctor_app/src/features/shell/tabs/patients_tab_page.dart';
import 'package:doctor_app/src/features/shell/tabs/profile_tab_page.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';

/// Main signed-in shell: four tabs + center FAB (`HomeShellTab.index` ↔ body).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const routePath = '/home';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  int _visitOpenRequestId = 0;
  VisitPatientSeed? _visitPatient;

  Future<void> _onFab() async {
    final created = await context.push<bool>(
      NewPatientRegistrationScreen.routePath,
    );
    if (!mounted) return;
    if (created == true) {
      setState(() => _tabIndex = HomeShellTab.patients.index);
      final session = context.read<SessionController>();
      await context.read<HomeDashboardController>().refreshFromSession(
            session.state,
          );
    }
  }

  void _openVisitAssessment(VisitPatientSeed patient) {
    setState(() {
      _visitPatient = patient;
      _visitOpenRequestId++;
      _tabIndex = HomeShellTab.visit.index;
    });
  }

  /// Bottom-nav tabs are not routes — system back should return here and clear
  /// any visit seed opened from Home so the Visit tab list stays consistent.
  void _goHomeTab() {
    setState(() {
      _tabIndex = HomeShellTab.home.index;
      _visitPatient = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pages = [
      HomeTabPage(
        onViewAllPatients: () =>
            setState(() => _tabIndex = HomeShellTab.patients.index),
        onStartVisit: _openVisitAssessment,
      ),
      PatientsTabPage(
        onStartVisit: _openVisitAssessment,
        onLeaveToHomeTab: _goHomeTab,
      ),
      VisitTabPage(
        initialPatient: _visitPatient,
        openRequestId: _visitOpenRequestId,
        onLeaveToHomeTab: _goHomeTab,
      ),
      ProfileTabPage(onLeaveToHomeTab: _goHomeTab),
    ];

    return ChangeNotifierProvider<HomeDashboardController>(
      key: ValueKey<String>(
        '${session.state.userId ?? ''}|${session.state.healthWorkerId ?? ''}',
      ),
      create: (context) {
        final s = context.read<SessionController>();
        final ctrl = HomeDashboardController(
          api: HealthWorkerDashboardApi(s.apiClient),
          apiClient: s.apiClient,
        );
        unawaited(
          Future.microtask(() async {
            await s.hydrateLhwHealthWorkerIdIfNeeded();
            await ctrl.refreshFromSession(s.state);
          }),
        );
        return ctrl;
      },
      child: _PatientDirectoryRefreshScope(
        child: Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          body: IndexedStack(
            index: _tabIndex,
            children: pages,
          ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onFab,
          backgroundColor: AppColors.dashboardPrimaryDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.note_add_rounded, color: Colors.white, size: 26.sp),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          padding: EdgeInsets.zero,
          height: 56.h + bottomInset,
          color: AppColors.surface,
          elevation: 12,
          shadowColor: Colors.black26,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: ShellNavItem(
                    tab: HomeShellTab.home,
                    selected: _tabIndex == HomeShellTab.home.index,
                    onTap: () =>
                        setState(() => _tabIndex = HomeShellTab.home.index),
                  ),
                ),
                Expanded(
                  child: ShellNavItem(
                    tab: HomeShellTab.patients,
                    selected: _tabIndex == HomeShellTab.patients.index,
                    onTap: () =>
                        setState(() => _tabIndex = HomeShellTab.patients.index),
                  ),
                ),
                SizedBox(width: 56.w),
                Expanded(
                  child: ShellNavItem(
                    tab: HomeShellTab.visit,
                    selected: _tabIndex == HomeShellTab.visit.index,
                    onTap: () =>
                        setState(() => _tabIndex = HomeShellTab.visit.index),
                  ),
                ),
                Expanded(
                  child: ShellNavItem(
                    tab: HomeShellTab.profile,
                    selected: _tabIndex == HomeShellTab.profile.index,
                    onTap: () =>
                        setState(() => _tabIndex = HomeShellTab.profile.index),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Reloads [HomeDashboardController] when [PatientDirectoryCoordinator] fires
/// (e.g. patient created from a pushed route that sits above this subtree).
class _PatientDirectoryRefreshScope extends StatefulWidget {
  const _PatientDirectoryRefreshScope({required this.child});

  final Widget child;

  @override
  State<_PatientDirectoryRefreshScope> createState() =>
      _PatientDirectoryRefreshScopeState();
}

class _PatientDirectoryRefreshScopeState
    extends State<_PatientDirectoryRefreshScope> {
  PatientDirectoryCoordinator? _coord;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<PatientDirectoryCoordinator>();
    if (!identical(_coord, next)) {
      _coord?.removeListener(_onReloadRequested);
      _coord = next..addListener(_onReloadRequested);
    }
  }

  void _onReloadRequested() {
    if (!mounted) return;
    final session = context.read<SessionController>();
    unawaited(
      context.read<HomeDashboardController>().refreshFromSession(session.state),
    );
  }

  @override
  void dispose() {
    _coord?.removeListener(_onReloadRequested);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
