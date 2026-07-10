import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/auth/auth_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  static const routePath = '/role';

  static const _backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.dashboardChipBlueBg,
      AppColors.registrationScreenBg,
      AppColors.surface,
    ],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const _RoleHeader(),
                SizedBox(height: 36.h),
                _RoleTile(
                  icon: Icons.health_and_safety_rounded,
                  iconTint: AppColors.dashboardPrimary,
                  titleEn: 'Lady Health Worker',
                  titleUr: 'لیڈی ہیلتھ ورکر',
                  onTap: () => _selectRole(
                    context,
                    UserRole.ladyHealthWorker,
                  ),
                ),
                SizedBox(height: 14.h),
                _RoleTile(
                  icon: Icons.medical_services_rounded,
                  iconTint: AppColors.dashboardPrimaryDark,
                  titleEn: 'Doctor',
                  titleUr: 'ڈاکٹر',
                  onTap: () => _selectRole(
                    context,
                    UserRole.doctor,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _selectRole(
    BuildContext context,
    UserRole role,
  ) async {
    final controller = context.read<SessionController>();
    await controller.selectRole(role);
    if (!context.mounted) return;
    context.go(AuthScreen.routePath);
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your role',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.dashboardPrimaryDark,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Choose one to sign in',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'سائن اِن کے لیے ایک کردار منتخب کریں',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.dashboardPrimary,
              height: 1.35,
              fontFamily: 'NotoNastaliqUrdu',
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.iconTint,
    required this.titleEn,
    required this.titleUr,
    required this.onTap,
  });

  final IconData icon;
  final Color iconTint;
  final String titleEn;
  final String titleUr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.dashboardPrimary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, color: iconTint, size: 26.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleEn,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            titleUr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dashboardPrimaryDark,
                              height: 1.25,
                              fontFamily: 'NotoNastaliqUrdu',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: AppColors.registrationSectionLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
