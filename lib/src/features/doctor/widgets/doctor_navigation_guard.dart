import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:doctor_app/src/core/presentation/app_confirm_dialogs.dart';

abstract final class DoctorNavigationGuard {
  DoctorNavigationGuard._();

  static Future<void> popWithDiscardCheck(
    BuildContext context, {
    required bool hasUnsavedChanges,
  }) async {
    if (!hasUnsavedChanges) {
      context.pop();
      return;
    }
    final discard = await AppConfirmDialogs.showDiscardChanges(context);
    if (discard == true && context.mounted) {
      context.pop();
    }
  }

  static Future<void> popWithBackConfirm(
    BuildContext context, {
    String? message,
  }) async {
    final leave = await AppConfirmDialogs.showGoBack(context, message: message);
    if (leave == true && context.mounted) {
      context.pop();
    }
  }
}
