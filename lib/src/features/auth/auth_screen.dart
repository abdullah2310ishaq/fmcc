import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/auth/google_sign_in_config.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routePath = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthBodyCurveClipper extends CustomClipper<Path> {
  const _AuthBodyCurveClipper();

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

class _HealthWorkerIllustration extends StatelessWidget {
  const _HealthWorkerIllustration();

  @override
  Widget build(BuildContext context) {
    final mutedWhite = AppColors.surface.withValues(alpha: 0.22);
    final brightWhite = AppColors.surface.withValues(alpha: 0.34);

    return SizedBox(
      width: 190.w,
      height: 98.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 180.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 22.h,
            left: 66.w,
            child: Container(
              width: 50.w,
              height: 64.h,
              decoration: BoxDecoration(
                color: brightWhite,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Container(width: 18.w, height: 4.h, color: mutedWhite),
                  SizedBox(height: 5.h),
                  Container(width: 14.w, height: 4.h, color: mutedWhite),
                  SizedBox(height: 5.h),
                  Container(width: 18.w, height: 4.h, color: mutedWhite),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 82.h,
            left: 84.w,
            child: Container(
              width: 14.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: brightWhite,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 30.h,
            left: 28.w,
            child: Icon(
              Icons.person_rounded,
              size: 42.sp,
              color: mutedWhite,
            ),
          ),
          Positioned(
            bottom: 45.h,
            left: 36.w,
            child: CircleAvatar(
              radius: 7.r,
              backgroundColor: brightWhite,
            ),
          ),
          Positioned(
            bottom: 42.h,
            right: 24.w,
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: mutedWhite,
              child: Icon(
                Icons.monitor_heart_outlined,
                size: 24.sp,
                color: AppColors.surface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: GoogleSignInConfig.webClientId,
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
    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _buildBrandHeader()),
                Expanded(
                  flex: 4,
                  child: Transform.translate(
                    offset: Offset(0, -34.h),
                    child: ClipPath(
                      clipper: const _AuthBodyCurveClipper(),
                      child: Container(
                        color: AppColors.registrationScreenBg,
                        padding: EdgeInsets.fromLTRB(24.w, 82.h, 24.w, 24.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign in with your verified government Google\naccount to access the health worker portal.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.dashboardPrimaryDark
                                    .withValues(alpha: 0.82),
                                height: 1.45,
                              ),
                            ),
                            SizedBox(height: 28.h),
                            _buildGoogleButton(
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(_handleLogin()),
                              text: 'Continue with Google',
                              isLoading: _busy,
                            ),
                            SizedBox(height: 18.h),
                            Text(
                              'Only authorized and verified Health Workers can access\nthis system.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.registrationSectionLabel,
                                height: 1.4,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _footerLink('Privacy Policy'),
                                SizedBox(width: 28.w),
                                _footerLink('Help & Support'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_busy) const _SigningInOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F6FAB), Color(0xFF0E947E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.48),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 42.sp,
              color: AppColors.surface,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Careho Provider',
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.surface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Community Health Worker Portal',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.surface.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 44.h),
          const _HealthWorkerIllustration(),
        ],
      ),
    );
  }

  Widget _buildGoogleButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 54.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.registrationFieldBorder),
          elevation: 3,
          shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.r,
                height: 24.r,
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
                    width: 22.r,
                    height: 22.r,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _footerLink(String label) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.dashboardPrimary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<String> _getGoogleIdToken() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw StateError('Sign-in cancelled • سائن اِن منسوخ کر دیا گیا');
      }
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.trim().isEmpty) {
        throw StateError(
          'Failed to get Google token • گوگل ٹوکن حاصل نہیں ہو سکا',
        );
      }

      final claims = _tryDecodeJwtPayload(token);
      if (claims != null) {
        AppLogger.instance.i(
          '[AUTH] Google idToken claims '
          'iss=${claims['iss']} aud=${claims['aud']} azp=${claims['azp']} '
          'email=${claims['email']}',
        );
      }

      return token;
    } on PlatformException catch (e, st) {
      AppLogger.instance.e(
        '[AUTH] Google sign-in PlatformException '
        'code=${e.code} message=${e.message} details=${e.details}',
        error: e,
        stackTrace: st,
      );
      throw StateError(_friendlyGoogleSignInError(e));
    } catch (e, st) {
      AppLogger.instance.e(
        '[AUTH] Google sign-in failed: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
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
    } catch (e, st) {
      if (!mounted) return;
      AppLogger.instance
          .e('[AUTH] Sign-in failed: $e', error: e, stackTrace: st);

      final friendly = _friendlyBackendError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sign-in failed. Please try again.'),
              const SizedBox(height: 4),
              const Directionality(
                textDirection: TextDirection.rtl,
                child:
                    Text('سائن اِن ناکام ہو گیا۔ براہِ کرم دوبارہ کوشش کریں۔'),
              ),
              const SizedBox(height: 6),
              Text(
                friendly ?? e.toString(),
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

  static String? _friendlyBackendError(Object error) {
    final msg = error.toString();
    final m = msg.toLowerCase();

    // Backend DB constraint error when creating a new health worker row.
    if (m.contains('violation of unique key constraint') &&
        m.contains('healthworkers')) {
      return 'Server issue while creating profile. Please contact admin/support.\n'
          'سرور پر پروفائل بناتے وقت مسئلہ آیا ہے۔ براہِ کرم ایڈمن/سپورٹ سے رابطہ کریں۔';
    }

    return null;
  }

  static Map<String, dynamic>? _tryDecodeJwtPayload(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final obj = jsonDecode(decoded);
      return obj is Map<String, dynamic> ? obj : null;
    } catch (_) {
      return null;
    }
  }

  static String _friendlyGoogleSignInError(PlatformException e) {
    final code = e.code.trim();
    if (code == 'sign_in_canceled' || code == 'sign_in_cancelled') {
      return 'Sign-in cancelled • سائن اِن منسوخ کر دیا گیا';
    }
    if (code == 'network_error') {
      return 'Network error. Check internet • نیٹ ورک مسئلہ، انٹرنیٹ چیک کریں';
    }
    if (code == 'sign_in_failed') {
      return 'Google sign-in failed. Usually SHA-1/SHA-256 missing in Firebase '
          'or wrong google-services.json • '
          'اکثر Firebase میں SHA-1/SHA-256 نہ ہونے یا غلط google-services.json کی وجہ سے';
    }
    final msg = e.message?.trim();
    return 'Google sign-in failed ($code)${msg == null || msg.isEmpty ? '' : ': $msg'}';
  }
}

class _SigningInOverlay extends StatelessWidget {
  const _SigningInOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 22.w),
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signing in…',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'سائن اِن ہو رہا ہے…',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
