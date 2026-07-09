import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/auth/google_sign_in_config.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/logout_flow.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  static const routePath = '/waiting';

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  bool _refreshing = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: GoogleSignInConfig.webClientId,
    scopes: const ['email', 'profile', 'openid'],
  );

  Future<void> _refreshStatus() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        throw StateError(
          'Session expired. Please sign in again. • سیشن ختم ہو گیا ہے، دوبارہ سائن اِن کریں۔',
        );
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw StateError(
          'Could not refresh token. Please sign in again. • ٹوکن ریفریش نہیں ہو سکا، دوبارہ سائن اِن کریں۔',
        );
      }

      if (!mounted) return;
      await context.read<SessionController>().signInWithGoogleIdToken(
            idToken: idToken,
            isRegister: false,
          );

      if (!mounted) return;
      final status = context.read<SessionController>().state.approvalStatus;
      if (status == ApprovalStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Still pending approval • ابھی منظوری زیرِ التواء ہے',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              bottom: 120.h,
            ),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.instance
          .e('[WAITING] Refresh failed: $e', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _logout() async {
    await LogoutFlow.run(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  const _WaitingHero(),
                  Positioned(
                    top: 4.h,
                    right: 8.w,
                    child: TextButton(
                      onPressed: () => unawaited(_logout()),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              AppColors.textPrimary.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: ColoredBox(
                color: AppColors.registrationScreenBg,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24.w,
                    24.h,
                    24.w,
                    16.h + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your access request is with the admin. '
                        'Pull to refresh after they approve you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'آپ کی رسائی کی درخواست ایڈمن کے پاس ہے۔ منظوری کے بعد ریفریش کریں۔',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.4,
                            fontFamily: 'NotoNastaliqUrdu',
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.registrationFieldBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dashboardPrimary
                                  .withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  color: AppColors.dashboardWarning
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(
                                  Icons.hourglass_top_rounded,
                                  color: AppColors.dashboardWarning,
                                  size: 26.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _refreshing
                                          ? 'Checking status…'
                                          : 'Status: Pending',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        _refreshing
                                            ? 'اسٹیٹس چیک ہو رہا ہے…'
                                            : 'اسٹیٹس: زیرِ التواء',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          height: 1.25,
                                          fontFamily: 'NotoNastaliqUrdu',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _refreshing
                            ? null
                            : () => unawaited(_refreshStatus()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.registrationSaveBlue,
                          foregroundColor: AppColors.surface,
                          disabledBackgroundColor: AppColors
                              .registrationSaveBlue
                              .withValues(alpha: 0.45),
                          minimumSize: Size(double.infinity, 52.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          _refreshing ? 'Refreshing…' : 'Refresh status',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Request sent • درخواست بھیج دی گئی',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.35,
                          fontFamily: 'NotoNastaliqUrdu',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingHero extends StatelessWidget {
  const _WaitingHero();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.registrationScreenBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76.r,
            height: 76.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: AppColors.registrationFieldBorder),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 38.sp,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Approval pending',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'We’ll move you on when you’re verified',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'منظوری کے بعد آپ کو خودکار طور پر آگے بھیج دیا جائے گا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
