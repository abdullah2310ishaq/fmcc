import 'package:flutter/services.dart';

/// Pakistani mobile: **11 digits**, typically `03XXXXXXXXX`.
///
/// Accepts pasted numbers starting with country code `92` (e.g. `923001234567`)
/// and normalizes to a leading `0`.
class PakistanPhoneInputFormatter extends TextInputFormatter {
  static const int maxDigits = 11;

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Strips non-digits, maps `92XXXXXXXXXXX` → `0XXXXXXXXXX` (first 11 digits).
  static String normalizeFromRaw(String raw) {
    var d = digitsOnly(raw);
    if (d.startsWith('92') && d.length >= 12) {
      d = '0${d.substring(2)}';
    }
    if (d.length > maxDigits) {
      d = d.substring(0, maxDigits);
    }
    return d;
  }

  static bool isValidPakistaniMobile(String raw) {
    final d = normalizeFromRaw(raw);
    return d.length == maxDigits && RegExp(r'^03\d{9}$').hasMatch(d);
  }

  static int _digitsBeforeCursor(String fullText, int cursor) {
    final end = cursor.clamp(0, fullText.length);
    return digitsOnly(fullText.substring(0, end)).length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsBefore =
        _digitsBeforeCursor(newValue.text, newValue.selection.baseOffset);

    final text = normalizeFromRaw(newValue.text);

    final offset = digitsBefore.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
