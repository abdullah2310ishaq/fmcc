import 'package:flutter/material.dart';
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
          const SnackBar(
            content: Text('Your request is declined. Please contact admin.'),
            backgroundColor: AppColors.danger,
          ),
        );
        await controller.consumeDeclinedMessageFlag();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    final role = context.select<SessionController, UserRole>((c) => c.state.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Register'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await controller.logout(keepRole: false);
                  },
            child: const Text(
              'Change role',
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role == UserRole.doctor ? 'Doctor' : 'Lady Health Worker',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Google login only (for now).',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          final idToken = await _getGoogleIdToken();
                          if (!mounted) return;
                          await controller.signInWithGoogleIdToken(
                            idToken: idToken,
                            isRegister: false,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: Text(_busy ? 'Please wait...' : 'Login with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          final idToken = await _getGoogleIdToken();
                          if (!mounted) return;
                          await controller.signInWithGoogleIdToken(
                            idToken: idToken,
                            isRegister: true,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: const Text('Register with Google'),
              ),
              const Spacer(),
              const Text(
                'After login/register, your request goes to admin for approval.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getGoogleIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled.');
    }
    final auth = await account.authentication;
    final token = auth.idToken;
    if (token == null || token.trim().isEmpty) {
      throw StateError('Failed to get Google IdToken.');
    }
    return token;
  }
}

