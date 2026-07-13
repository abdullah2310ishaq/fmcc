import 'package:equatable/equatable.dart';

enum UserRole { unknown, ladyHealthWorker, doctor }

enum ApprovalStatus { none, pending, approved, declined }

class RegistrationDetails extends Equatable {
  const RegistrationDetails({
    required this.fullName,
    required this.phone,
    this.email = '',
  });

  final String fullName;
  final String phone;
  final String email;

  bool get isComplete => fullName.trim().isNotEmpty && phone.trim().isNotEmpty;

  RegistrationDetails copyWith({
    String? fullName,
    String? phone,
    String? email,
  }) {
    return RegistrationDetails(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [fullName, phone, email];
}

class AppSession extends Equatable {
  static const Object _unset = Object();

  const AppSession({
    required this.role,
    required this.isSignedIn,
    required this.approvalStatus,
    required this.registrationDetails,
    required this.showDeclinedMessageOnce,
    required this.userId,
    this.healthWorkerId,
    this.doctorId,
    this.doctorSpeciality,
    this.pmdcNumber,
    this.hospitalName,
    this.hospitalConfirmed = false,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AppSession.initial() {
    return const AppSession(
      role: UserRole.unknown,
      isSignedIn: false,
      approvalStatus: ApprovalStatus.none,
      registrationDetails: RegistrationDetails(fullName: '', phone: '', email: ''),
      showDeclinedMessageOnce: false,
      userId: null,
      healthWorkerId: null,
      doctorId: null,
      doctorSpeciality: null,
      pmdcNumber: null,
      hospitalName: null,
      hospitalConfirmed: false,
      accessToken: null,
      refreshToken: null,
    );
  }

  final UserRole role;
  final bool isSignedIn;
  final ApprovalStatus approvalStatus;
  final RegistrationDetails registrationDetails;

  /// Used to show "declined" snackbar once after redirecting to auth screen.
  final bool showDeclinedMessageOnce;

  /// Backend user identifier (from JWT claim `name` in current API).
  final String? userId;

  /// LHW profile `healthWorkerId` (e.g. certificate code). Dashboard + patient assignment use this when set.
  final String? healthWorkerId;

  /// Doctor id for Doctor APIs (defaults to [userId] when unset).
  final String? doctorId;

  final String? doctorSpeciality;
  final String? pmdcNumber;
  final String? hospitalName;

  /// Doctor must confirm hospital before entering the doctor shell.
  final bool hospitalConfirmed;

  /// Bearer token for authorized API calls.
  final String? accessToken;

  /// Server refresh token (persisted securely).
  final String? refreshToken;

  bool get hasCompletedRegistrationDetails => registrationDetails.isComplete;

  String get doctorIdForApis {
    final d = doctorId?.trim();
    if (d != null && d.isNotEmpty) return d;
    return userId?.trim() ?? '';
  }

  /// Profile `healthWorkerId` only (e.g. `A171DE66`). Used for dashboard routes,
  /// `assignedHealthWorkerId` on patient create/update, and visit `healthWorkerId`.
  /// Never use JWT [userId] here — backend keys patients by LHW id.
  String? get healthWorkerIdForPatientApis {
    final h = healthWorkerId?.trim();
    if (h != null && h.isNotEmpty) return h;
    return null;
  }

  AppSession copyWith({
    UserRole? role,
    bool? isSignedIn,
    ApprovalStatus? approvalStatus,
    RegistrationDetails? registrationDetails,
    bool? showDeclinedMessageOnce,
    Object? userId = _unset,
    Object? healthWorkerId = _unset,
    Object? doctorId = _unset,
    Object? doctorSpeciality = _unset,
    Object? pmdcNumber = _unset,
    Object? hospitalName = _unset,
    bool? hospitalConfirmed,
    Object? accessToken = _unset,
    Object? refreshToken = _unset,
  }) {
    return AppSession(
      role: role ?? this.role,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      registrationDetails: registrationDetails ?? this.registrationDetails,
      showDeclinedMessageOnce:
          showDeclinedMessageOnce ?? this.showDeclinedMessageOnce,
      userId: userId == _unset ? this.userId : userId as String?,
      healthWorkerId: healthWorkerId == _unset
          ? this.healthWorkerId
          : healthWorkerId as String?,
      doctorId: doctorId == _unset ? this.doctorId : doctorId as String?,
      doctorSpeciality: doctorSpeciality == _unset
          ? this.doctorSpeciality
          : doctorSpeciality as String?,
      pmdcNumber: pmdcNumber == _unset ? this.pmdcNumber : pmdcNumber as String?,
      hospitalName:
          hospitalName == _unset ? this.hospitalName : hospitalName as String?,
      hospitalConfirmed: hospitalConfirmed ?? this.hospitalConfirmed,
      accessToken:
          accessToken == _unset ? this.accessToken : accessToken as String?,
      refreshToken:
          refreshToken == _unset ? this.refreshToken : refreshToken as String?,
    );
  }

  @override
  List<Object?> get props => [
        role,
        isSignedIn,
        approvalStatus,
        registrationDetails,
        showDeclinedMessageOnce,
        userId,
        healthWorkerId,
        doctorId,
        doctorSpeciality,
        pmdcNumber,
        hospitalName,
        hospitalConfirmed,
        accessToken,
        refreshToken,
      ];
}
