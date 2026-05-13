import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:doctor_app/src/app.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/session/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storage = SessionStorage();
  final initialState = await storage.read();
  final sessionController = SessionController(
    initialState: initialState,
    storage: storage,
  );

  runApp(DoctorApp(sessionController: sessionController));
}
