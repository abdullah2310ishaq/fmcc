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
import 'package:doctor_app/src/core/network/api_failure.dart';
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
        AppLogger.instance.w(
          '[AUTH] Declined message shown (showDeclinedMessageOnce was true)',
        );
        await controller.consumeDeclinedMessageFlag();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                24.w,
                0,
                24.w,
                16.h + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 200.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'Sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Sign in with your verified government Google\naccount to access the health worker portal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  _buildGoogleButton(
                    onPressed: _busy ? null : () => unawaited(_handleLogin()),
                    text: 'Continue with Google',
                    isLoading: _busy,
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
            if (_busy) const _SigningInOverlay(),
          ],
        ),
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
          elevation: 0,
          shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.dashboardPrimary,
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
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<String> _getGoogleIdToken() async {
    try {
      AppLogger.instance.i('[AUTH] GoogleSignIn.signIn() starting…');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        AppLogger.instance.w(
          '[AUTH] Google sign-in returned null account (user cancelled or dismissed)',
        );
        throw StateError('Sign-in cancelled • سائن اِن منسوخ کر دیا گیا');
      }
      AppLogger.instance.i(
        '[AUTH] Google account ok id=${account.id} email=${account.email} '
        'displayName=${account.displayName}',
      );
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.trim().isEmpty) {
        AppLogger.instance.e(
          '[AUTH] Google authentication.idToken is null/empty '
          '(serverClientId mis-configured is a common cause). '
          'accessTokenPresent=${auth.accessToken != null && auth.accessToken!.trim().isNotEmpty}',
        );
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
      } else {
        AppLogger.instance
            .w('[AUTH] Could not decode idToken payload (JWT shape?)');
      }

      AppLogger.instance.i(
        '[AUTH] Google idToken acquired len=${token.length} (value not logged)',
      );
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
    final session = context.read<SessionController>();
    final role = session.state.role;
    AppLogger.instance.i(
      '[AUTH] Login tap → role=$role isRegister=false '
      'webClientIdConfigured=${GoogleSignInConfig.webClientId.trim().isNotEmpty}',
    );
    setState(() => _busy = true);
    try {
      final idToken = await _getGoogleIdToken();
      if (!mounted) return;
      AppLogger.instance
          .i('[AUTH] Calling SessionController.signInWithGoogleIdToken…');
      await session.signInWithGoogleIdToken(
        idToken: idToken,
        isRegister: false,
      );
      AppLogger.instance.i(
          '[AUTH] Sign-in flow completed (session updated, leaving auth screen via router)');
    } catch (e, st) {
      if (!mounted) return;
      _logAuthScreenFailure(phase: 'sign_in_flow', error: e, stackTrace: st);

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

  /// Structured log so console shows failure kind (Google vs API vs mapped).
  static void _logAuthScreenFailure({
    required String phase,
    required Object error,
    required StackTrace? stackTrace,
  }) {
    final type = error.runtimeType.toString();
    if (error is ApiFailure) {
      AppLogger.instance.e(
        '[AUTH][$phase] ApiFailure subtype=$type message="${error.message}"',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    if (error is StateError) {
      AppLogger.instance.e(
        '[AUTH][$phase] StateError (often Google UI) message="${error.message}"',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    AppLogger.instance.e(
      '[AUTH][$phase] errorType=$type message=$error',
      error: error,
      stackTrace: stackTrace,
    );
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
                    color: AppColors.dashboardPrimary,
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
