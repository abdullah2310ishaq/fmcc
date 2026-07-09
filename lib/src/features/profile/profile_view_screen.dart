import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/logout_flow.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/profile/edit_profile_screen.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';

/// Full profile from API — bilingual headings (English + Urdu).
class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key, this.showBackButton = true});

  /// When embedded in [HomeShell] (profile tab), hide the back arrow.
  final bool showBackButton;

  static const routePath = '/profile';

  /// Soft light-blue → white band used by the hero card.
  static const LinearGradient headerGradient = LinearGradient(
    colors: [AppColors.dashboardChipBlueBg, AppColors.surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  HealthWorkerProfile? _profile;
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
          await context.read<SessionController>().fetchHealthWorkerProfile();
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

  @override
  Widget build(BuildContext context) {
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
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.dashboardPrimaryDark,
                        size: 18.sp,
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
                child: _buildBody(),
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
                Icons.logout_rounded,
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

  Future<void> _openEditProfile() async {
    await context.push(EditProfileScreen.routePath);
    if (!mounted) return;
    await _load();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: EdgeInsets.all(14.w),
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Log out?',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'You will need to sign in again with your verified Google account.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 18.h),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.surface,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dashboardPrimaryDark,
                    side: const BorderSide(
                      color: AppColors.registrationFieldBorder,
                    ),
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout != true || !mounted) return;
    await LogoutFlow.run(context);
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 0.35.sh),
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.dashboardPrimary,
            ),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          Icon(Icons.error_outline_rounded,
              size: 48.sp, color: AppColors.danger),
          SizedBox(height: 16.h),
          Text(
            _error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.sp, color: AppColors.textSecondary, height: 1.35),
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry • دوبارہ کوشش'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dashboardPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
    final p = _profile;
    if (p == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 120.h),
          Text(
            'No profile data from server.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final fullName = '${p.firstName} ${p.lastName}'.trim();
    final session = context.watch<SessionController>();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 28.h),
      children: [
        _HeroCard(
          profile: p,
          fullName: fullName.isEmpty ? '—' : fullName,
          onEditPressed: () => unawaited(_openEditProfile()),
        ),
        SizedBox(height: 16.h),
        if (session.state.role == UserRole.ladyHealthWorker) ...[
          _lhwVisitsGuideCard(),
          SizedBox(height: 16.h),
        ],
        _SectionCard(
          icon: Icons.badge_outlined,
          title: 'Personal Details',
          rows: [
            (Icons.credit_card_rounded, 'CNIC', _val(p.cnic)),
            (Icons.phone_rounded, 'Phone', _val(p.phoneNumber)),
            (
              Icons.school_outlined,
              'Education',
              _preferLabel(p.educationLevelLabel, p.educationLevelId),
            ),
            (
              Icons.verified_outlined,
              'Certificate ID',
              _val(p.lhwTrainingCertificate),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _SectionCard(
          icon: Icons.location_on_outlined,
          title: 'Assigned Territory',
          rows: [
            (
              Icons.public_rounded,
              'Province',
              _preferLabel(p.provinceLabel, p.provinceId),
            ),
            (
              Icons.map_outlined,
              'District',
              _preferLabel(p.districtLabel, p.districtId),
            ),
            (
              Icons.place_outlined,
              'Tehsil',
              _preferLabel(p.tehsilLabel, p.tehsilId),
            ),
            (Icons.home_outlined, 'Address', _val(p.address)),
          ],
        ),
        SizedBox(height: 16.h),
        _SectionCard(
          icon: Icons.assignment_ind_outlined,
          title: 'Account Summary',
          rows: [
            (
              Icons.fingerprint_rounded,
              'Health Worker ID',
              _val(p.healthWorkerId),
            ),
            (Icons.wc_rounded, 'Gender', _genderLabel(p.gender)),
            (
              Icons.cake_outlined,
              'Date of Birth',
              _dobLabel(p.dateOfBirth),
            ),
            (Icons.calendar_today_rounded, 'Age', _ageLabel(p.ageYears)),
            (
              Icons.event_available_rounded,
              'Joined',
              _joinedLabel(p.joinedDate),
            ),
            if (p.approxPatientsPerDay != null)
              (
                Icons.groups_rounded,
                'Patients / Day',
                '${p.approxPatientsPerDay}',
              ),
            if (p.salary != null)
              (
                Icons.payments_outlined,
                'Salary',
                _SalaryFmt.format(p.salary!),
              ),
          ],
        ),
      ],
    );
  }

  static String _val(String? s) {
    if (s == null || s.trim().isEmpty) return '—';
    return s.trim();
  }

  static String _dobLabel(DateTime? d) {
    if (d == null) return '—';
    return formatIsoDateOnly(d);
  }

  static String _ageLabel(int? age) {
    if (age == null || age < 0) return '—';
    return '$age';
  }

  static String _genderLabel(String g) {
    final u = g.trim().toUpperCase();
    switch (u) {
      case 'M':
        return 'Male / مرد';
      case 'F':
        return 'Female / عورت';
      case '':
        return '—';
      default:
        return g.trim();
    }
  }

  static String _joinedLabel(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return '—';

    final dt = DateTime.tryParse(s);
    if (dt == null) return s; // fallback: show raw string

    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthShort(local.month);
    final year = local.year.toString();

    final hour12 = ((local.hour + 11) % 12) + 1;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    // Example: 08 May 2026 • 09:47 PM
    return '$day $month $year • ${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }

  static String _monthShort(int m) {
    switch (m) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  Widget _lhwVisitsGuideCard() {
    return Material(
      elevation: 2.5,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18.r),
      color: AppColors.surface,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 15.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.registrationFieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.health_and_safety_outlined,
                    size: 18.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Visits & history',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Home shows patients who need follow-up checks. On the Visit tab, pick Follow-ups for that queue or All patients for anyone in your directory.\n\n'
              'After you save a visit, open Patients, choose a person, then Visit History to see the list. Tap a row for full details.',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _preferLabel(String label, int id) {
    final l = label.trim();
    if (l.isNotEmpty) return l;
    if (id > 0) return 'ID $id';
    return '—';
  }
}

class _SalaryFmt {
  static String format(double s) {
    final t = s.truncateToDouble();
    if (t == s) return t.toInt().toString();
    return s.toStringAsFixed(2);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.fullName,
    required this.onEditPressed,
  });

  final HealthWorkerProfile profile;
  final String fullName;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final initials = NameInitials.fromFullName(fullName);
    final email = profile.email?.trim();
    final verified = profile.isVerified;
    return Material(
      elevation: 4,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(26.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.r),
          gradient: ProfileViewScreen.headerGradient,
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
              fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dashboardPrimaryDark,
                height: 1.1,
              ),
            ),
            if (email != null && email.isNotEmpty) ...[
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
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
                        ? Icons.verified_user_rounded
                        : Icons.pending_rounded,
                    size: 14.sp,
                    color: verified
                        ? AppColors.followAccentGreen
                        : AppColors.dashboardWarning,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    verified
                        ? 'Verified Health Worker'
                        : 'Pending Verification',
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
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEditPressed,
                icon: Icon(Icons.edit_rounded, size: 17.sp),
                label: Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashboardPrimary,
                  foregroundColor: AppColors.surface,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;

  /// (leadingIcon, label, value)
  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
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
              _FieldRow(
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
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: AppColors.dashboardPrimary.withValues(alpha: 0.7),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
