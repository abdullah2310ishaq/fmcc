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
    final controller = context.read<SessionController>();
    final role =
        context.select<SessionController, UserRole>((c) => c.state.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Center(
          child: TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await controller.logout(keepRole: false);
                  },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: Text(
              'Change role / کردار تبدیل کریں',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.blueDark,
                height: 1.15,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
                    text: 'Continue with Google',
                    isLoading: _busy,
                  ),

                  SizedBox(height: 32.h),

                  // Info note
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                'After continuing, your request goes to admin for approval.',
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
                                  'جاری رکھنے کے بعد آپ کی درخواست منظوری کے لیے ایڈمن کے پاس جائے گی۔',
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
            if (_busy) const _SigningInOverlay(),
          ],
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
                        const SizedBox(width: 10),
                        const Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'گوگل کے ساتھ جاری رکھیں',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
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
