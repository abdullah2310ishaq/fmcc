import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_theme.dart';
import 'package:doctor_app/src/features/approval/waiting_screen.dart';
import 'package:doctor_app/src/features/auth/auth_screen.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/create_prescription_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_shell.dart';
import 'package:doctor_app/src/features/doctor/screens/edit_prescription_screen.dart';
import 'package:doctor_app/src/features/doctor/screens/hospital_confirmation_screen.dart';
import 'package:doctor_app/src/features/shell/home_shell.dart';
import 'package:doctor_app/src/features/profile/edit_profile_screen.dart';
import 'package:doctor_app/src/features/profile/profile_view_screen.dart';
import 'package:doctor_app/src/features/patients/new_patient_registration_screen.dart';
import 'package:doctor_app/src/features/patients/patient_directory_coordinator.dart';
import 'package:doctor_app/src/features/patients/patient_detail_cache.dart';
import 'package:doctor_app/src/features/visits/visit_instructions_cache.dart';
import 'package:doctor_app/src/features/profile/registration_details_screen.dart';
import 'package:doctor_app/src/features/role/role_screen.dart';
import 'package:doctor_app/src/features/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

bool _hasPersistedAuth(AppSession session) {
  return session.isSignedIn &&
      session.accessToken != null &&
      session.accessToken!.trim().isNotEmpty;
}

String _redirectPath(GoRouterState state) {
  var p = state.uri.path;
  if (p.isEmpty) return SplashScreen.routePath;
  if (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

bool _isDoctorWorkspacePath(String loc) {
  return loc == DoctorShell.routePath ||
      loc == DoctorPatientDetailScreen.routePath ||
      loc == CreatePrescriptionScreen.routePath ||
      loc == EditPrescriptionScreen.routePath;
}

/// Resolves the correct landing route for the current [session].
/// Used by the splash screen (after its animation) and the router redirect.
String sessionDestination(
  AppSession session, {
  bool hasPendingDoctorHospitalConfirmation = false,
}) {
  if (hasPendingDoctorHospitalConfirmation) {
    return HospitalConfirmationScreen.routePath;
  }
  if (!_hasPersistedAuth(session)) {
    if (session.role == UserRole.unknown) {
      return RoleScreen.routePath;
    }
    return AuthScreen.routePath;
  }

  if (session.role == UserRole.doctor) {
    if (session.approvalStatus == ApprovalStatus.pending) {
      return WaitingScreen.routePath;
    }
    if (!session.hospitalConfirmed) {
      // Incomplete doctor session — force re-auth.
      return AuthScreen.routePath;
    }
    return DoctorShell.routePath;
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

class _DoctorAppState extends State<DoctorApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockPortraitOrientation();
    _router = _buildRouter(widget.sessionController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockPortraitOrientation();
    }
  }

  Future<void> _lockPortraitOrientation() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.sessionController),
        ChangeNotifierProvider(create: (_) => PatientDirectoryCoordinator()),
        ChangeNotifierProvider(create: (_) => PatientDetailCache()),
        ChangeNotifierProvider(create: (_) => VisitInstructionsCache()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: false,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'WHO-PEN Based Digital Health App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            routerConfig: _router,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: child ?? const SizedBox.shrink(),
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
        path: HomeShell.routePath,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: HospitalConfirmationScreen.routePath,
        builder: (context, state) => const HospitalConfirmationScreen(),
      ),
      GoRoute(
        path: DoctorShell.routePath,
        builder: (context, state) => const DoctorShell(),
      ),
      GoRoute(
        path: DoctorPatientDetailScreen.routePath,
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? Map<String, dynamic>.from(extra) : const {};
          return DoctorPatientDetailScreen(
            patientId: map['patientId']?.toString() ?? '',
            visitId: map['visitId']?.toString() ?? '',
            patientNumber: int.tryParse(map['patientNumber']?.toString() ?? '') ?? 0,
            fullName: map['fullName']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: CreatePrescriptionScreen.routePath,
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? Map<String, dynamic>.from(extra) : const {};
          return CreatePrescriptionScreen(
            patientId: map['patientId']?.toString() ?? '',
            visitId: map['visitId']?.toString() ?? '',
            patientName: map['patientName']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: EditPrescriptionScreen.routePath,
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? Map<String, dynamic>.from(extra) : const {};
          final medicinesRaw = map['medicines'];
          final medicines = <PrescriptionMedicineInput>[];
          if (medicinesRaw is List) {
            for (final item in medicinesRaw) {
              if (item is PrescriptionMedicineInput) {
                medicines.add(item);
              }
            }
          }
          return EditPrescriptionScreen(
            prescriptionId: map['prescriptionId']?.toString() ?? '',
            visitId: map['visitId']?.toString() ?? '',
            patientId: map['patientId']?.toString() ?? '',
            patientName: map['patientName']?.toString() ?? '',
            initialTenureInDays:
                int.tryParse(map['initialTenureInDays']?.toString() ?? '') ?? 0,
            initialNotes: map['initialNotes']?.toString() ?? '',
            continuedFromPrescriptionId:
                map['continuedFromPrescriptionId']?.toString(),
            nextVisitDate: map['nextVisitDate'] is DateTime
                ? map['nextVisitDate'] as DateTime
                : null,
            medicines: medicines,
          );
        },
      ),
      GoRoute(
        path: ProfileViewScreen.routePath,
        builder: (context, state) => const ProfileViewScreen(),
      ),
      GoRoute(
        path: EditProfileScreen.routePath,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: NewPatientRegistrationScreen.routePath,
        builder: (context, state) => const NewPatientRegistrationScreen(),
      ),
    ],
    redirect: (context, state) {
      final session = sessionController.state;
      final loc = _redirectPath(state);

      // Always let the splash screen show on launch; it self-navigates
      // to the resolved destination after its animation.
      if (loc == SplashScreen.routePath) return null;

      // If declined: force sign out and show auth with message (auth screen will display it).
      if (session.approvalStatus == ApprovalStatus.declined) {
        sessionController.handleDeclinedOnLaunch();
        return loc == AuthScreen.routePath ? null : AuthScreen.routePath;
      }

      // Incomplete doctor session (signed in without hospital confirmation).
      if (session.role == UserRole.doctor &&
          session.isSignedIn &&
          !session.hospitalConfirmed &&
          !sessionController.hasPendingDoctorHospitalConfirmation) {
        sessionController.logout(keepRole: true);
        return loc == AuthScreen.routePath ? null : AuthScreen.routePath;
      }

      final dest = sessionDestination(
        session,
        hasPendingDoctorHospitalConfirmation:
            sessionController.hasPendingDoctorHospitalConfirmation,
      );

      // Allow hospital confirmation only while pending.
      if (dest == HospitalConfirmationScreen.routePath) {
        return loc == HospitalConfirmationScreen.routePath ? null : dest;
      }

      // Allow doctor nested routes when doctor workspace is the destination.
      if (dest == DoctorShell.routePath && _isDoctorWorkspacePath(loc)) {
        return null;
      }

      // Allow `/profile` whenever user is allowed on home (avoid matchedLocation mismatch).
      if (dest == HomeShell.routePath &&
          (loc == ProfileViewScreen.routePath ||
              loc == EditProfileScreen.routePath ||
              loc == NewPatientRegistrationScreen.routePath)) {
        return null;
      }

      return loc == dest ? null : dest;
    },
  );
}
