import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';

/// Tiny tap target shown after English labels; opens Urdu text in a modal.
class UrduHelpSuffix extends StatelessWidget {
  const UrduHelpSuffix({
    super.key,
    required this.urduText,
    this.size,
    this.foregroundColor,
  });

  final String urduText;
  final double? size;

  /// When placed on a dark background (e.g. red button), pass a light color.
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
    final dim = size ?? 16.sp;
    return Padding(
      padding: EdgeInsets.only(left: 3.w),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
          child: Text(
            '?',
            style: TextStyle(
              fontSize: dim * 0.85,
              fontWeight: FontWeight.w800,
              color: foregroundColor ?? AppColors.dashboardPrimary,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
