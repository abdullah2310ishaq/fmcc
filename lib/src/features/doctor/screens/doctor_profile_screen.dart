import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/presentation/app_confirm_dialogs.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/logout_flow.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/core/theme/app_gradients.dart';
import 'package:doctor_app/src/features/profile/doctor_profile_models.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';

/// Doctor workspace profile — hospital, PMDC, specialty, and sign-out.
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, this.showBackButton = true});

  /// Hidden when embedded as a bottom-nav tab in [DoctorShell].
  final bool showBackButton;

  static const routePath = '/doctor/profile';

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  DoctorProfile? _profile;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p =
          await context.read<SessionController>().fetchDoctorProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) {
        setState(() {
          _error = null;
          _loading = false;
        });
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await AppConfirmDialogs.showLogout(context);
    if (shouldLogout != true || !mounted) return;
    await LogoutFlow.run(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;

    return Scaffold(
      backgroundColor: AppColors.registrationScreenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 8.h, 12.w, 6.h),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        CupertinoIcons.back,
                        color: AppColors.dashboardPrimaryDark,
                        size: 22.sp,
                      ),
                      onPressed: () => context.pop(),
                    )
                  else
                    SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                  ),
                  _logoutChip(),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.dashboardPrimary,
                onRefresh: _load,
                child: _buildBody(session),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutChip() {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _confirmLogout,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.square_arrow_right,
                size: 15.sp,
                color: AppColors.danger,
              ),
              SizedBox(width: 6.w),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppSession session) {
    final p = _profile;
    final name = _displayName(session, p);
    final email = _firstNonEmpty([
      p?.email,
      session.registrationDetails.email,
    ]);
    final phone = _firstNonEmpty([
      p?.phoneNumber,
      session.registrationDetails.phone,
    ]);
    final userId = _firstNonEmpty([p?.userId, session.userId]);
    final specialty = _firstNonEmpty([
      p?.specialtyName,
      session.doctorSpeciality,
    ]);
    final pmdc = _firstNonEmpty([p?.pmdcNumber, session.pmdcNumber]);
    final hospital = _firstNonEmpty([p?.hospitalName, session.hospitalName],
        fallback: 'Not assigned');
    final doctorId = _firstNonEmpty([p?.doctorId, session.doctorIdForApis]);
    final verified = p?.isVerified ?? session.hospitalConfirmed;
    final gender = p?.gender.trim() ?? '';
    final cnic = p?.cnic.trim() ?? '';
    final fee = p?.feePerPatient;
    final joined = p?.joinedDate;

    final accountRows = <(IconData, String, String)>[
      (CupertinoIcons.person_fill, 'Full Name', _val(name)),
      (CupertinoIcons.mail_solid, 'Email', _val(email)),
      (CupertinoIcons.phone_fill, 'Phone', _val(phone)),
      (CupertinoIcons.person_badge_plus_fill, 'User ID', _val(userId)),
    ];

    final professionalRows = <(IconData, String, String)>[
      (CupertinoIcons.number, 'Doctor ID', _val(doctorId)),
      (CupertinoIcons.doc_text, 'PMDC Number', _val(pmdc)),
      (CupertinoIcons.star_fill, 'Specialty', _val(specialty)),
      if (gender.isNotEmpty)
        (CupertinoIcons.person_2_fill, 'Gender', GenderLabel.format(gender)),
      if (cnic.isNotEmpty)
        (CupertinoIcons.creditcard_fill, 'CNIC', _val(cnic)),
      if (fee != null)
        (
          CupertinoIcons.money_dollar_circle_fill,
          'Fee per patient',
          'Rs ${fee.toStringAsFixed(fee.truncateToDouble() == fee ? 0 : 2)}',
        ),
      if (joined != null)
        (
          CupertinoIcons.calendar,
          'Joined',
          formatIsoDateOnly(joined),
        ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 28.h),
      children: [
        if (_loading)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: const CupertinoActivityIndicator(
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Refreshing profile…',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.dashboardPeach.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.dashboardPeachBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 18.sp,
                    color: AppColors.dashboardWarning,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Could not load full profile from server. Showing your signed-in details below.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dashboardWarning,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _heroCard(
          name: name,
          email: email,
          specialty: specialty,
          verified: verified,
        ),
        SizedBox(height: 16.h),
        _sectionCard(
          icon: CupertinoIcons.person_crop_circle,
          title: 'Account Details',
          rows: accountRows,
        ),
        SizedBox(height: 16.h),
        _sectionCard(
          icon: CupertinoIcons.briefcase_fill,
          title: 'Professional Details',
          rows: professionalRows,
        ),
        if (p?.tehsilName.trim().isNotEmpty == true ||
            p?.districtName.trim().isNotEmpty == true ||
            p?.provinceName.trim().isNotEmpty == true) ...[
          SizedBox(height: 16.h),
          _sectionCard(
            icon: CupertinoIcons.location_fill,
            title: 'Location',
            rows: [
              if (p?.provinceName.trim().isNotEmpty == true)
                (
                  CupertinoIcons.map_fill,
                  'Province',
                  _val(p!.provinceName),
                ),
              if (p?.districtName.trim().isNotEmpty == true)
                (
                  CupertinoIcons.placemark_fill,
                  'District',
                  _val(p!.districtName),
                ),
              if (p?.tehsilName.trim().isNotEmpty == true)
                (
                  CupertinoIcons.location,
                  'Tehsil',
                  _val(p!.tehsilName),
                ),
            ],
          ),
        ],
        SizedBox(height: 16.h),
        _sectionCard(
          icon: CupertinoIcons.building_2_fill,
          title: 'Hospital Assignment',
          rows: [
            (CupertinoIcons.house_fill, 'Hospital', _val(hospital)),
            (
              CupertinoIcons.checkmark_seal_fill,
              'Status',
              verified ? 'Verified doctor' : 'Pending verification',
            ),
          ],
        ),
        SizedBox(height: 20.h),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          icon: Icon(CupertinoIcons.square_arrow_right, size: 18.sp),
          label: Text(
            'Sign out of doctor workspace',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  static String _displayName(AppSession session, DoctorProfile? profile) {
    final apiName = profile?.fullName.trim() ?? '';
    if (apiName.isNotEmpty) return apiName;

    final fromSession = session.registrationDetails.fullName.trim();
    if (fromSession.isNotEmpty && fromSession != 'Doctor') {
      return fromSession;
    }
    final userId = session.userId?.trim();
    if (userId != null && userId.isNotEmpty) return userId;
    return 'Doctor';
  }

  static String _firstNonEmpty(
    List<String?> values, {
    String fallback = '',
  }) {
    for (final v in values) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty && t != '—' && t != '-') return t;
    }
    return fallback;
  }

  static String _val(String? s, {String fallback = '—'}) {
    if (s == null || s.trim().isEmpty) return fallback;
    return s.trim();
  }

  Widget _heroCard({
    required String name,
    required String email,
    required String specialty,
    required bool verified,
  }) {
    final initials = NameInitials.fromFullName(name);

    return Material(
      elevation: 4,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(26.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.r),
          gradient: AppGradients.header,
          border: Border.all(color: AppColors.registrationFieldBorder),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dashboardPrimary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 42.r,
                backgroundColor: AppColors.dashboardChipBlueBg,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dashboardPrimaryDark,
                height: 1.1,
              ),
            ),
            if (email.isNotEmpty) ...[
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.mail_solid,
                    size: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: Text(
                      email,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (specialty.isNotEmpty) ...[
              SizedBox(height: 5.h),
              Text(
                specialty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: verified
                    ? AppColors.followAccentGreen.withValues(alpha: 0.12)
                    : AppColors.dashboardPeach,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: verified
                      ? AppColors.followAccentGreen.withValues(alpha: 0.35)
                      : AppColors.dashboardPeachBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    verified
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.clock_fill,
                    size: 14.sp,
                    color: verified
                        ? AppColors.followAccentGreen
                        : AppColors.dashboardWarning,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    verified ? 'Verified Doctor' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: verified
                          ? AppColors.followAccentGreen
                          : AppColors.dashboardWarning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<(IconData, String, String)> rows,
  }) {
    return Material(
      elevation: 2.5,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18.r),
      color: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.registrationFieldBorder),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    icon,
                    size: 18.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            for (var i = 0; i < rows.length; i++) ...[
              _fieldRow(
                icon: rows[i].$1,
                label: rows[i].$2,
                value: rows[i].$3,
              ),
              if (i != rows.length - 1)
                Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17.sp, color: AppColors.textSecondary),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
