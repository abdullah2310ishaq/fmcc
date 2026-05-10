import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Small “?” after English copy; tap opens Urdu in a dialog (compact — avoids row overflow).
class UrduHelpSuffix extends StatelessWidget {
  const UrduHelpSuffix({
    super.key,
    required this.urduText,
    this.size,
    this.foregroundColor,
  });

  final String urduText;
  final double? size;

  /// On dark backgrounds (e.g. red button), pass a light [foregroundColor].
  final Color? foregroundColor;

  Future<void> _open(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: Text(
            urduText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dashboardPrimary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = size ?? 17.sp;
    final fg = foregroundColor ?? AppColors.dashboardPrimary;

    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Text(
              '?',
              style: TextStyle(
                fontSize: base * 0.92,
                fontWeight: FontWeight.w800,
                color: fg,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
