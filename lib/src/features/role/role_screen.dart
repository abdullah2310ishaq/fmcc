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

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();

    return Scaffold(
      backgroundColor: AppColors.background, // from colors.dart
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 24.h,
            bottom: MediaQuery.of(context).padding.bottom + 20.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(),
              SizedBox(height: 28.h),
              _RoleOptionCard(
                titleEn: 'Lady Health Worker',
                titleUr: 'لیڈی ہیلتھ ورکر',
                subtitleEn: 'Request access and continue',
                subtitleUr: 'رسائی کی درخواست کریں اور آگے بڑھیں',
                icon: Icons.health_and_safety_outlined,
                onTap: () async {
                  await controller.selectRole(UserRole.ladyHealthWorker);
                  if (!context.mounted) return;
                  context.go(AuthScreen.routePath);
                },
              ),
              SizedBox(height: 16.h),
              _RoleOptionCard(
                titleEn: 'Doctor',
                titleUr: 'ڈاکٹر',
                subtitleEn: 'Request access and manage patients',
                subtitleUr: 'رسائی کی درخواست کریں اور مریضوں کو منظم کریں',
                icon: Icons.local_hospital_outlined,
                onTap: () async {
                  await controller.selectRole(UserRole.doctor);
                  if (!context.mounted) return;
                  context.go(AuthScreen.routePath);
                },
              ),
              SizedBox(height: 24.h),
              const _FooterNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 28.sp,
                    color: AppColors.blueDark,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Choose your role',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'اپنا کردار منتخب کریں',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoNastaliqUrdu',
                  height: 1.4, // slight spacing, clean
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Select one to continue',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'جاری رکھنے کے لیے ایک انتخاب کریں',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.titleEn,
    required this.titleUr,
    required this.subtitleEn,
    required this.subtitleUr,
    required this.icon,
    required this.onTap,
  });

  final String titleEn;
  final String titleUr;
  final String subtitleEn;
  final String subtitleUr;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        splashColor: AppColors.blue.withValues(alpha: 0.08),
        highlightColor: AppColors.blue.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.04),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(18.w),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(icon, size: 30.sp, color: AppColors.blueDark),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleEn,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        titleUr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'NotoNastaliqUrdu',
                          height: 1.4, // clean, not too loose
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      subtitleEn,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        subtitleUr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'NotoNastaliqUrdu',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 34.w,
                height: 34.h,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20.sp,
                  color: AppColors.blueDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline,
                size: 20.sp, color: AppColors.blueDark),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip: You can change your role later from settings.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'ٹِپ: آپ بعد میں سیٹنگز سے اپنا کردار تبدیل کر سکتے ہیں۔',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'NotoNastaliqUrdu',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
