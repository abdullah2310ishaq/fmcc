import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:doctor_app/src/app.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/session/session_storage.dart';

bool _hasPersistedAuth(AppSession session) {
  return session.isSignedIn &&
      session.accessToken != null &&
      session.accessToken!.trim().isNotEmpty;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storage = SessionStorage();
  var initialState = await storage.read();

  // Cold start while signed out: always ask role again (not auth).
  if (!_hasPersistedAuth(initialState) &&
      initialState.role != UserRole.unknown) {
    initialState = initialState.copyWith(role: UserRole.unknown);
    await storage.write(initialState);
  }

  final sessionController = SessionController(
    initialState: initialState,
    storage: storage,
  );

  runApp(DoctorApp(sessionController: sessionController));
}
