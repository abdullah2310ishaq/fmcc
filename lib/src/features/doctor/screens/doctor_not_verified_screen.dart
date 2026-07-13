import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/auth/auth_api.dart';
import 'package:doctor_app/src/core/session/logout_flow.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';

/// Shown when doctor Google login returns null / unverified.
/// Explains the issue clearly, then OK signs out to the role screen.
class DoctorNotVerifiedScreen extends StatefulWidget {
  const DoctorNotVerifiedScreen({super.key});

  static const routePath = '/doctor/not-verified';

  @override
  State<DoctorNotVerifiedScreen> createState() =>
      _DoctorNotVerifiedScreenState();
}

class _DoctorNotVerifiedScreenState extends State<DoctorNotVerifiedScreen> {
  bool _busy = false;

  Future<void> _onOk() async {
    if (_busy) return;
    setState(() => _busy = true);
    await LogoutFlow.run(context);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        _onOk();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DoctorPageSafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 88.r,
                  height: 88.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardPeach.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dashboardPeachBorder),
                  ),
                  child: Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 42.sp,
                    color: AppColors.dashboardWarning,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Doctor not verified',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  AuthApi.doctorNotVerifiedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 10.h),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'آپ تصدیق شدہ نہیں ہیں۔ براہِ کرم ایڈمنسٹریشن سے رابطہ کریں۔',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.dashboardPrimary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'You cannot continue until an administrator verifies your doctor account and assigns a hospital.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                if (_busy)
                  const Center(child: CupertinoActivityIndicator())
                else
                  SizedBox(
                    height: 50.h,
                    child: FilledButton(
                      onPressed: _onOk,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dashboardPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 28.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
