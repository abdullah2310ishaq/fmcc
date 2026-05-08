import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_theme.dart';
import 'package:doctor_app/src/features/approval/waiting_screen.dart';
import 'package:doctor_app/src/features/auth/auth_screen.dart';
import 'package:doctor_app/src/features/home/home_screen.dart';
import 'package:doctor_app/src/features/profile/registration_details_screen.dart';
import 'package:doctor_app/src/features/role/role_screen.dart';
import 'package:doctor_app/src/features/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionController>.value(
      value: sessionController,
      child: Builder(
        builder: (context) {
          final router = _buildRouter(context.read<SessionController>());
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'Doctor App',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                routerConfig: router,
              );
            },
          );
        },
      ),
    );
  }
}

GoRouter _buildRouter(SessionController sessionController) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.routePath,
    refreshListenable: sessionController,
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoleScreen.routePath,
        builder: (context, state) => const RoleScreen(),
      ),
      GoRoute(
        path: AuthScreen.routePath,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: WaitingScreen.routePath,
        builder: (context, state) => const WaitingScreen(),
      ),
      GoRoute(
        path: RegistrationDetailsScreen.routePath,
        builder: (context, state) => const RegistrationDetailsScreen(),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final session = sessionController.state;
      final loc = state.matchedLocation;

      // If declined: force sign out and show auth with message (auth screen will display it).
      if (session.approvalStatus == ApprovalStatus.declined) {
        sessionController.handleDeclinedOnLaunch();
        return AuthScreen.routePath;
      }

      if (session.role == UserRole.unknown) {
        return loc == RoleScreen.routePath ? null : RoleScreen.routePath;
      }

      if (!session.isSignedIn) {
        return loc == AuthScreen.routePath ? null : AuthScreen.routePath;
      }

      if (session.approvalStatus == ApprovalStatus.pending) {
        return loc == WaitingScreen.routePath ? null : WaitingScreen.routePath;
      }

      if (session.approvalStatus == ApprovalStatus.approved &&
          !session.hasCompletedRegistrationDetails) {
        return loc == RegistrationDetailsScreen.routePath
            ? null
            : RegistrationDetailsScreen.routePath;
      }

      return loc == HomeScreen.routePath ? null : HomeScreen.routePath;
    },
  );
}

