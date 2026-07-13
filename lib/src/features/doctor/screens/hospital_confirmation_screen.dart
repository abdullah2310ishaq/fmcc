import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/presentation/app_confirm_dialogs.dart';
import 'package:doctor_app/src/core/session/logout_flow.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';

/// Asks the doctor to confirm they still work at the assigned hospital.
class HospitalConfirmationScreen extends StatefulWidget {
  const HospitalConfirmationScreen({super.key});

  static const routePath = '/doctor/hospital-confirmation';

  @override
  State<HospitalConfirmationScreen> createState() =>
      _HospitalConfirmationScreenState();
}

class _HospitalConfirmationScreenState
    extends State<HospitalConfirmationScreen> {
  bool _busy = false;

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().confirmDoctorHospital();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() => _busy = false);
    }
  }

  Future<void> _onNo() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().declineDoctorHospital();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _showUnassignedBottomSheet();
  }

  Future<void> _showUnassignedBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.registrationFieldBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Icon(
                    CupertinoIcons.building_2_fill,
                    size: 40.sp,
                    color: AppColors.dashboardWarning,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'No hospital assigned',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'You are not assigned any hospital. Please ask your system administrator to assign you and add you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  SizedBox(
                    height: 48.h,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        await LogoutFlow.run(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dashboardPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _hospitalLabel(SessionController session) {
    final pending = session.pendingDoctorLogin;
    final fromPending = pending?.hospitalName.trim() ?? '';
    if (fromPending.isNotEmpty) return fromPending;
    final fromSession = session.state.hospitalName?.trim() ?? '';
    if (fromSession.isNotEmpty) return fromSession;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final pending = session.pendingDoctorLogin;
    final hospital = _hospitalLabel(session);
    final hasHospitalName = hospital.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _busy) return;
        final leave = await AppConfirmDialogs.showLogout(context);
        if (leave == true && context.mounted) {
          await LogoutFlow.run(context);
        }
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
                Icon(
                  CupertinoIcons.building_2_fill,
                  size: 56.sp,
                  color: AppColors.dashboardPrimary,
                ),
                SizedBox(height: 24.h),
                Text(
                  'Hospital confirmation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                if (hasHospitalName)
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Are you still working in '),
                        TextSpan(
                          text: hospital,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimaryDark,
                            fontSize: 17.sp,
                          ),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Are you still working at your hospital?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (pending != null &&
                    pending.doctorSpeciality.trim().isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    pending.doctorSpeciality,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dashboardPrimary,
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                if (_busy)
                  const Center(child: CupertinoActivityIndicator())
                else ...[
                  SizedBox(
                    height: 48.h,
                    child: FilledButton(
                      onPressed: _onYes,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dashboardPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 48.h,
                    child: OutlinedButton(
                      onPressed: _onNo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'If you select No, your hospital assignment will be cleared and you will be signed out.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
