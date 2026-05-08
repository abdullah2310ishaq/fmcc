import 'package:flutter/services.dart';

/// Pakistani CNIC mask: `#####-#######-#` (13 digits → **15 characters** with dashes).
///
/// Backend validates exact length 15 including dashes.
class CnicInputFormatter extends TextInputFormatter {
  static const int maxDigits = 13;

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Masked value for API body (`cnic` field): **always send this**, not [digitsOnly].
  static String forApi(String fieldOrRaw) => formatFromRaw(fieldOrRaw);

  /// Builds masked text from any raw string (digits only are kept).
  static String formatFromRaw(String raw) {
    final d = digitsOnly(raw);
    if (d.isEmpty) return '';
    final clipped =
        d.length > maxDigits ? d.substring(0, maxDigits) : d;
    return _masked(clipped);
  }

  static String _masked(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) b.write('-');
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newDigits = digitsOnly(newValue.text);
    if (newDigits.length > maxDigits) {
      newDigits = newDigits.substring(0, maxDigits);
    }

    final formatted = _masked(newDigits);

    var selectionOffset = formatted.length;
    final sel = newValue.selection;
    if (sel.isValid) {
      final rawCursor = sel.baseOffset;
      final safeEnd = rawCursor.clamp(0, newValue.text.length);
      final digitsBefore =
          digitsOnly(newValue.text.substring(0, safeEnd)).length;
      selectionOffset = _offsetAfterNthDigit(formatted, digitsBefore);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  static int _offsetAfterNthDigit(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != '-') {
        seen++;
        if (seen == digitCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
