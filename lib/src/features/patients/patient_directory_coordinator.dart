import 'package:flutter/foundation.dart';

/// App-wide signal to reload LHW dashboard data (stats, follow-ups, patient directory).
///
/// Used when a pushed route (e.g. new patient) cannot see [HomeDashboardController].
/// [HomeShell] listens and calls [HomeDashboardController.refreshFromSession].
class PatientDirectoryCoordinator extends ChangeNotifier {
  void requestDashboardReload() {
    notifyListeners();
  }
}
