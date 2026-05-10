import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_theme.dart';
import 'package:doctor_app/src/features/approval/waiting_screen.dart';
import 'package:doctor_app/src/features/auth/auth_screen.dart';
import 'package:doctor_app/src/features/shell/home_shell.dart';
import 'package:doctor_app/src/features/profile/edit_profile_screen.dart';
import 'package:doctor_app/src/features/profile/profile_view_screen.dart';
import 'package:doctor_app/src/features/profile/registration_details_screen.dart';
import 'package:doctor_app/src/features/role/role_screen.dart';
import 'package:doctor_app/src/features/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Signed-in flag must agree with a stored bearer token, otherwise send user to auth.
bool _hasPersistedAuth(AppSession session) {
  return session.isSignedIn &&
      session.accessToken != null &&
      session.accessToken!.trim().isNotEmpty;
}

/// Normalized path for redirects (matches `context.push('/profile')`, etc.).
String _redirectPath(GoRouterState state) {
  var p = state.uri.path;
  if (p.isEmpty) return SplashScreen.routePath;
  if (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// Single destination for the current session (splash is only for unknown cold-start loading).
String _sessionDestination(AppSession session) {
  if (session.role == UserRole.unknown) {
    return RoleScreen.routePath;
  }
  if (!_hasPersistedAuth(session)) {
    return AuthScreen.routePath;
  }
  if (session.approvalStatus == ApprovalStatus.pending) {
    return WaitingScreen.routePath;
  }
  if (session.approvalStatus == ApprovalStatus.approved &&
      !session.hasCompletedRegistrationDetails) {
    return RegistrationDetailsScreen.routePath;
  }
  return HomeShell.routePath;
}

class DoctorApp extends StatefulWidget {
  const DoctorApp({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  State<DoctorApp> createState() => _DoctorAppState();
}

class _DoctorAppState extends State<DoctorApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(widget.sessionController);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionController>.value(
      value: widget.sessionController,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Doctor App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

GoRouter _buildRouter(SessionController sessionController) {
  final initial = _sessionDestination(sessionController.state);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initial,
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
        path: HomeShell.routePath,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: ProfileViewScreen.routePath,
        builder: (context, state) => const ProfileViewScreen(),
      ),
      GoRoute(
        path: EditProfileScreen.routePath,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final session = sessionController.state;
      final loc = _redirectPath(state);

      // If declined: force sign out and show auth with message (auth screen will display it).
      if (session.approvalStatus == ApprovalStatus.declined) {
        sessionController.handleDeclinedOnLaunch();
        return loc == AuthScreen.routePath ? null : AuthScreen.routePath;
      }

      final dest = _sessionDestination(session);

      // Allow `/profile` whenever user is allowed on home (avoid matchedLocation mismatch).
      if (dest == HomeShell.routePath &&
          (loc == ProfileViewScreen.routePath ||
              loc == EditProfileScreen.routePath)) {
        return null;
      }

      return loc == dest ? null : dest;
    },
  );
}

