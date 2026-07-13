import 'package:flutter/foundation.dart';

/// Bottom-nav tab index for [DoctorShell].
class DoctorShellTabController extends ChangeNotifier {
  static const dashboardTab = 0;
  static const patientsTab = 1;
  static const prescriptionsTab = 2;

  int _tabIndex = dashboardTab;

  int get tabIndex => _tabIndex;

  void selectTab(int index) {
    if (index < dashboardTab || index > prescriptionsTab) return;
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }
}
