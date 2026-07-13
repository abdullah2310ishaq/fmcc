import 'package:google_sign_in/google_sign_in.dart';

import 'package:doctor_app/src/core/logging/app_logger.dart';

class GoogleSignInConfig {
  const GoogleSignInConfig._();

  /// Web OAuth client id used as audience by backend.
  static const webClientId =
      '256140774177-tcac5nlrs07bmon0fe3tv9amgmgnuba7.apps.googleusercontent.com';

  static GoogleSignIn createClient() => GoogleSignIn(
        serverClientId: webClientId,
        scopes: const ['email', 'profile', 'openid'],
      );

  /// Clears the cached Google account so the next [GoogleSignIn.signIn]
  /// always shows the account picker.
  static Future<void> signOutCachedAccount() async {
    try {
      await createClient().signOut();
    } on Object catch (e) {
      AppLogger.instance.w('[AUTH] Google cached signOut failed: $e');
    }
  }
}
