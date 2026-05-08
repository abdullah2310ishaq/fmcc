import 'package:doctor_app/src/core/session/app_session.dart';

class RoleIds {
  const RoleIds._();

  /// Confirmed from Postman request body: `"RoleId" : 2`
  static const int ladyHealthWorker = 2;

  /// Not present in the shared Postman collection.
  /// Keep it explicit so we can update once confirmed.
  static const int doctor = 1;

  static int fromRole(UserRole role) {
    switch (role) {
      case UserRole.ladyHealthWorker:
        return RoleIds.ladyHealthWorker;
      case UserRole.doctor:
        return RoleIds.doctor;
      case UserRole.unknown:
        return 0;
    }
  }
}

