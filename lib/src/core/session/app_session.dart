import 'package:equatable/equatable.dart';

enum UserRole { unknown, ladyHealthWorker, doctor }

enum ApprovalStatus { none, pending, approved, declined }

class RegistrationDetails extends Equatable {
  const RegistrationDetails({
    required this.fullName,
    required this.phone,
  });

  final String fullName;
  final String phone;

  bool get isComplete => fullName.trim().isNotEmpty && phone.trim().isNotEmpty;

  RegistrationDetails copyWith({String? fullName, String? phone}) {
    return RegistrationDetails(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [fullName, phone];
}

class AppSession extends Equatable {
  const AppSession({
    required this.role,
    required this.isSignedIn,
    required this.approvalStatus,
    required this.registrationDetails,
    required this.showDeclinedMessageOnce,
    required this.userId,
    required this.accessToken,
  });

  factory AppSession.initial() {
    return const AppSession(
      role: UserRole.unknown,
      isSignedIn: false,
      approvalStatus: ApprovalStatus.none,
      registrationDetails: RegistrationDetails(fullName: '', phone: ''),
      showDeclinedMessageOnce: false,
      userId: null,
      accessToken: null,
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

  /// Bearer token for authorized API calls.
  final String? accessToken;

  bool get hasCompletedRegistrationDetails => registrationDetails.isComplete;

  AppSession copyWith({
    UserRole? role,
    bool? isSignedIn,
    ApprovalStatus? approvalStatus,
    RegistrationDetails? registrationDetails,
    bool? showDeclinedMessageOnce,
    String? userId,
    String? accessToken,
  }) {
    return AppSession(
      role: role ?? this.role,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      registrationDetails: registrationDetails ?? this.registrationDetails,
      showDeclinedMessageOnce:
          showDeclinedMessageOnce ?? this.showDeclinedMessageOnce,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
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
        accessToken,
      ];
}

