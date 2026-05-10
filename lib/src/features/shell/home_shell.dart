import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/patients/new_patient_registration_screen.dart';
import 'package:doctor_app/src/features/home/home_tab_page.dart';
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

  void _onFab() {
    context.push(NewPatientRegistrationScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pages = [
      HomeTabPage(
        onViewAllPatients: () =>
            setState(() => _tabIndex = HomeShellTab.patients.index),
      ),
      const PatientsTabPage(),
      const VisitTabPage(),
      const ProfileTabPage(),
    ];

    return Scaffold(
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
    );
  }
}
