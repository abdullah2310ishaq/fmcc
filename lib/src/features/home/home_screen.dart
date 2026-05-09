import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/profile/profile_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  static String _roleTitleEn(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.ladyHealthWorker:
        return 'Lady health worker';
      case UserRole.unknown:
        return 'Home';
    }
  }

  static String _roleTitleUr(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'ڈاکٹر';
      case UserRole.ladyHealthWorker:
        return 'لیڈی ہیلتھ ورکر';
      case UserRole.unknown:
        return 'ہوم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    final session = context.select<SessionController, AppSession>((c) => c.state);
    final name = session.registrationDetails.fullName.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _showLogoutConfirm(context, controller),
            child: Text(
              'Logout · لاگ آؤٹ',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.blueDark,
              ),
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  children: [
                    Text(
                      _roleTitleEn(session.role),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _roleTitleUr(session.role),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Text(
                            'خوش آمدید',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        name.isEmpty
                            ? 'You are signed in. Open your profile to view details.'
                            : name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: name.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          name.isEmpty
                              ? 'اپنے پروفائل سے تفصیلات دیکھیں۔'
                              : 'خوش آمدید — خوشی ہوئی کہ آپ یہاں ہیں۔',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  child: InkWell(
                    onTap: () => context.push(ProfileViewScreen.routePath),
                    borderRadius: BorderRadius.circular(16.r),
                    splashColor: AppColors.blue.withValues(alpha: 0.12),
                    highlightColor: AppColors.blue.withValues(alpha: 0.06),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.blue,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'پروفائل',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                            size: 26.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showLogoutConfirm(
    BuildContext context,
    SessionController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 32.sp,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Sign out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'لاگ آؤٹ کریں؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your session will end and you will need to sign in again with Google.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'آپ کا سیشن ختم ہو جائے گا؛ دوبارہ گوگل سے سائن ان کرنا ہو گا۔',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Stay · رہیں',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          backgroundColor: AppColors.blueDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Logout · لاگ آؤٹ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await controller.logout(keepRole: true);
    }
  }
}
