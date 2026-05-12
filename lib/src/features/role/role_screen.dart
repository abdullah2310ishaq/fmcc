import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/auth/auth_screen.dart';

/// Matches [AuthScreen] hero gradient and curved body for a consistent pre-auth flow.
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  static const routePath = '/role';

  static const List<Color> _heroGradientColors = [
    Color(0xFF1F6FAB),
    Color(0xFF0E947E),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _RoleHero(colors: _heroGradientColors)),
            Expanded(
              flex: 5,
              child: Transform.translate(
                offset: Offset(0, -34.h),
                child: ClipPath(
                  clipper: const _RoleBodyCurveClipper(),
                  child: ColoredBox(
                    color: AppColors.registrationScreenBg,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24.w,
                        72.h,
                        24.w,
                        16.h + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pick how you use Careho — one tap to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.dashboardPrimaryDark
                                  .withValues(alpha: 0.82),
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 22.h),
                          _RoleTile(
                            icon: Icons.health_and_safety_rounded,
                            iconTint: const Color(0xFF1565C0),
                            titleEn: 'Lady Health Worker',
                            titleUr: 'لیڈی ہیلتھ ورکر',
                            onTap: () => _selectRole(
                              context,
                              UserRole.ladyHealthWorker,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _RoleTile(
                            icon: Icons.medical_services_rounded,
                            iconTint: const Color(0xFF0E7668),
                            titleEn: 'Doctor',
                            titleUr: 'ڈاکٹر',
                            onTap: () => _selectRole(
                              context,
                              UserRole.doctor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'You can switch role later from profile settings.\n'
                            'پروفائل سیٹنگز سے بعد میں کردار تبدیل کر سکتے ہیں۔',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.registrationSectionLabel,
                              height: 1.4,
                              fontFamily: 'NotoNastaliqUrdu',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

class _RoleBodyCurveClipper extends CustomClipper<Path> {
  const _RoleBodyCurveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 34)
      ..cubicTo(
        size.width * 0.26,
        2,
        size.width * 0.74,
        2,
        size.width,
        34,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RoleHero extends StatelessWidget {
  const _RoleHero({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76.r,
            height: 76.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.badge_rounded,
              size: 40.sp,
              color: AppColors.surface,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Your role',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.surface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Choose one to sign in',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.surface.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'سائن اِن کے لیے ایک کردار منتخب کریں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface.withValues(alpha: 0.95),
                  height: 1.35,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
              ),
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.dashboardPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: iconTint.withValues(alpha: 0.12),
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
