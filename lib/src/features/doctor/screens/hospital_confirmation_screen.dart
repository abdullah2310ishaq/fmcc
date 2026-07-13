import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<SessionController>().pendingDoctorLogin;
    final hospital = pending?.hospitalName.trim().isNotEmpty == true
        ? pending!.hospitalName
        : 'your hospital';

    return Scaffold(
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
              Text(
                'Are you still working in "$hospital"?',
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
                  'If you select No, you will be signed out. Please contact the administration.',
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
    );
  }
}
