import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/src/core/auth/google_sign_in_config.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
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
      final status =
          context.read<SessionController>().state.approvalStatus;
      if (status == ApprovalStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Still pending approval • ابھی منظوری زیرِ التواء ہے',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.instance.e('[WAITING] Refresh failed: $e', error: e, stackTrace: st);
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

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval pending'),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.logout(keepRole: true);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.blueDark),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Request sent',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'درخواست بھیج دی گئی',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your request has been sent to the admin. Once approved, we’ll automatically move you forward.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'آپ کی درخواست ایڈمن کو بھیج دی گئی ہے۔ منظوری کے بعد آپ خودکار طور پر اگلے مرحلے میں چلے جائیں گے۔',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.hourglass_bottom_rounded,
                          color: AppColors.blueDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _refreshing ? 'Checking status…' : 'Status: Pending',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                _refreshing
                                    ? 'اسٹیٹس چیک ہو رہا ہے…'
                                    : 'اسٹیٹس: زیرِ التواء',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
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
                onPressed: _refreshing ? null : () => unawaited(_refreshStatus()),
                child: Text(_refreshing ? 'Refreshing…' : 'Refresh status'),
              ),
              const SizedBox(height: 8),
              const Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'اسٹیٹس ریفریش کریں',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

