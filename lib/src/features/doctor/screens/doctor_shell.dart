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
import 'package:doctor_app/src/features/doctor/screens/doctor_dashboard_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_prescriptions_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_queue_screen.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  static const routePath = '/doctor';

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    final api = DoctorApi(session.apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DoctorDashboardController(
            api: api,
            apiClient: session.apiClient,
          )..refreshFromSession(session.state),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorQueueController(
            api: api,
            apiClient: session.apiClient,
          )..refreshFromSession(session.state),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorPrescriptionsController(
            api: api,
            apiClient: session.apiClient,
          )..refreshFromSession(session.state),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _tabIndex,
          children: const [
            DoctorDashboardScreen(),
            DoctorQueueScreen(),
            DoctorPrescriptionsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.dashboardChipBlueBg,
          destinations: [
            NavigationDestination(
              icon: Icon(CupertinoIcons.square_grid_2x2, size: 22.sp),
              selectedIcon: Icon(
                CupertinoIcons.square_grid_2x2_fill,
                size: 22.sp,
              ),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.person_2, size: 22.sp),
              selectedIcon: Icon(CupertinoIcons.person_2_fill, size: 22.sp),
              label: 'Queue',
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
