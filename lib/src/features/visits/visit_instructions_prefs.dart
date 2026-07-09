import 'package:shared_preferences/shared_preferences.dart';

/// Local flag: user opted out of the pre-visit instruction carousel.
class VisitInstructionsPrefs {
  VisitInstructionsPrefs._();

  static const _kSkip = 'visit.skipInstructions';

  static Future<bool> shouldSkip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSkip) ?? false;
  }

  static Future<void> setSkip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSkip, value);
  }
}
