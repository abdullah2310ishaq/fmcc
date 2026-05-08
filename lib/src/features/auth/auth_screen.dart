import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routePath = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<SessionController>();
    final showDeclined = controller.state.showDeclinedMessageOnce;
    if (showDeclined) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Your request was declined. Please contact admin.'),
                SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                      'آپ کی درخواست مسترد کر دی گئی ہے۔ براہِ کرم ایڈمن سے رابطہ کریں۔'),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
          ),
        );
        await controller.consumeDeclinedMessageFlag();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    final role =
        context.select<SessionController, UserRole>((c) => c.state.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'خوش آمدید',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await controller.logout(keepRole: false);
                  },
            child: Text(
              'Change role • کردار تبدیل کریں',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.blueDark,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero / Illustration area
              _buildHeaderIllustration(),
              SizedBox(height: 24.h),

              // Role card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.04),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              role == UserRole.doctor
                                  ? Icons.local_hospital_outlined
                                  : Icons.health_and_safety_outlined,
                              size: 28.sp,
                              color: AppColors.blueDark,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Role',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    'منتخب کردہ کردار',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  role == UserRole.doctor
                                      ? 'Doctor'
                                      : 'Lady Health Worker',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    role == UserRole.doctor
                                        ? 'ڈاکٹر'
                                        : 'لیڈی ہیلتھ ورکر',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              // Login button with Google icon
              _buildGoogleButton(
                onPressed: _busy ? null : () => unawaited(_handleLogin()),
                text: 'Login with Google',
                isLoading: _busy,
              ),

              SizedBox(height: 16.h),

              // Register button
              _buildGoogleButton(
                onPressed: _busy ? null : () => unawaited(_handleRegister()),
                text: 'Register with Google',
                isLoading: _busy,
                isOutlined: true,
              ),

              SizedBox(height: 32.h),

              // Info note
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 20.sp, color: AppColors.blueDark),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'After login/register, your request goes to admin for approval.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'لاگ اِن/رجسٹر کے بعد آپ کی درخواست منظوری کے لیے ایڈمن کے پاس جائے گی۔',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
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

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIllustration() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 40.sp,
              color: AppColors.blueDark,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Access Healthcare Portal',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'ہیلتھ کیئر پورٹل تک رسائی',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Sign in to continue',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'جاری رکھنے کے لیے سائن اِن کریں',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 54.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border, width: 1.5.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                backgroundColor: Colors.white,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.blueDark,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/google.svg',
                          width: 22.w,
                          height: 22.h,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/google.svg',
                          width: 22.w,
                          height: 22.h,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Future<String> _getGoogleIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Sign-in cancelled • سائن اِن منسوخ کر دیا گیا');
    }
    final auth = await account.authentication;
    final token = auth.idToken;
    if (token == null || token.trim().isEmpty) {
      throw StateError(
          'Failed to get Google token • گوگل ٹوکن حاصل نہیں ہو سکا');
    }
    return token;
  }

  Future<void> _handleLogin() async {
    setState(() => _busy = true);
    try {
      final idToken = await _getGoogleIdToken();
      if (!mounted) return;
      await context.read<SessionController>().signInWithGoogleIdToken(
            idToken: idToken,
            isRegister: false,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Login failed. Please try again.'),
              const SizedBox(height: 4),
              const Directionality(
                textDirection: TextDirection.rtl,
                child:
                    Text('لاگ اِن ناکام ہو گیا۔ براہِ کرم دوبارہ کوشش کریں۔'),
              ),
              const SizedBox(height: 6),
              Text(
                e.toString(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _busy = true);
    try {
      final idToken = await _getGoogleIdToken();
      if (!mounted) return;
      await context.read<SessionController>().signInWithGoogleIdToken(
            idToken: idToken,
            isRegister: true,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registration failed. Please try again.'),
              const SizedBox(height: 4),
              const Directionality(
                textDirection: TextDirection.rtl,
                child:
                    Text('رجسٹریشن ناکام ہو گئی۔ براہِ کرم دوبارہ کوشش کریں۔'),
              ),
              const SizedBox(height: 6),
              Text(
                e.toString(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
