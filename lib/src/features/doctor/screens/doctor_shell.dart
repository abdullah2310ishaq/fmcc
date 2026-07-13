import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_dashboard_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_queue_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_shell_tab_controller.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_dashboard_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_prescriptions_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_queue_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';

class DoctorShell extends StatelessWidget {
  const DoctorShell({super.key});

  static const routePath = '/doctor';

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final api = DoctorApi(session.apiClient);

    return ChangeNotifierProvider(
      create: (_) => DoctorShellTabController(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => DoctorDashboardController(
              api: api,
              apiClient: session.apiClient,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => DoctorQueueController(
              api: api,
              apiClient: session.apiClient,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => DoctorPrescriptionsController(
              api: api,
              apiClient: session.apiClient,
            ),
          ),
        ],
        child: const _DoctorShellBody(),
      ),
    );
  }
}

class _DoctorShellBody extends StatefulWidget {
  const _DoctorShellBody();

  @override
  State<_DoctorShellBody> createState() => _DoctorShellBodyState();
}

class _DoctorShellBodyState extends State<_DoctorShellBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final session = context.read<SessionController>();
    await session.hydrateDoctorProfileIfNeeded();
    if (!mounted) return;

    final state = session.state;
    await Future.wait([
      context.read<DoctorDashboardController>().refreshFromSession(state),
      context.read<DoctorQueueController>().refreshFromSession(state),
      context.read<DoctorPrescriptionsController>().refreshFromSession(state),
    ]);
  }

  void _onTabSelected(int index) {
    context.read<DoctorShellTabController>().selectTab(index);

    if (index == DoctorShellTabController.patientsTab) {
      final session = context.read<SessionController>();
      unawaited(
        context.read<DoctorQueueController>().refreshFromSession(session.state),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = context.watch<DoctorShellTabController>().tabIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DoctorTabSafeArea(
        child: IndexedStack(
          index: tabIndex,
          children: const [
            DoctorDashboardScreen(),
            DoctorQueueScreen(),
            DoctorPrescriptionsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.dashboardChipBlueBg,
          destinations: [
            NavigationDestination(
              icon: Icon(CupertinoIcons.square_grid_2x2, size: 22.sp),
              selectedIcon: Icon(
                CupertinoIcons.square_grid_2x2_fill,
                size: 22.sp,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.person_2, size: 22.sp),
              selectedIcon: Icon(CupertinoIcons.person_2_fill, size: 22.sp),
              label: 'Patients',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.doc_text, size: 22.sp),
              selectedIcon: Icon(CupertinoIcons.doc_text_fill, size: 22.sp),
              label: 'Prescriptions',
            ),
          ],
        ),
      ),
    );
  }
}
