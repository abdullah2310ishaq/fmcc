import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.blueDark,
                  size: 20.sp,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Update profile',
            onPressed: _openEditProfile,
            icon: Icon(
              Icons.edit_note_rounded,
              size: 20.sp,
              color: AppColors.blueDark,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _confirmLogout,
            icon: Icon(
              Icons.logout_rounded,
              size: 20.sp,
              color: AppColors.danger,
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blue,
        onRefresh: _load,
        child: _buildBody(),
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
                Container(
                  width: 46.r,
                  height: 46.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                    size: 25.sp,
                  ),
                ),
                SizedBox(height: 14.h),
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
    await context.read<SessionController>().logout(keepRole: true);
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 0.35.sh),
          const Center(child: CircularProgressIndicator(color: AppColors.blue)),
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
              backgroundColor: AppColors.blue,
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _HeroCard(profile: p, fullName: fullName.isEmpty ? '—' : fullName),
        Transform.translate(
          offset: Offset(0, -18.h),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
            decoration: BoxDecoration(
              color: AppColors.registrationScreenBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'PERSONAL DETAILS',
                  children: [
                    _FieldRow(label: 'CNIC', value: _val(p.cnic)),
                    _FieldRow(label: 'Phone', value: _val(p.phoneNumber)),
                    _FieldRow(
                      label: 'Education',
                      value: _preferLabel(
                        p.educationLevelLabel,
                        p.educationLevelId,
                      ),
                    ),
                    _FieldRow(
                      label: 'Certificate ID',
                      value: _val(p.lhwTrainingCertificate),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _SectionCard(
                  title: 'ASSIGNED TERRITORY',
                  children: [
                    _FieldRow(
                      label: 'Province',
                      value: _preferLabel(p.provinceLabel, p.provinceId),
                    ),
                    _FieldRow(
                      label: 'District',
                      value: _preferLabel(p.districtLabel, p.districtId),
                    ),
                    _FieldRow(
                      label: 'Tehsil',
                      value: _preferLabel(p.tehsilLabel, p.tehsilId),
                    ),
                    _FieldRow(label: 'Address', value: _val(p.address)),
                  ],
                ),
                SizedBox(height: 14.h),
                _SectionCard(
                  title: 'ACCOUNT SUMMARY',
                  children: [
                    _FieldRow(
                      label: 'Health Worker ID',
                      value: _val(p.healthWorkerId),
                    ),
                    _FieldRow(label: 'Gender', value: _genderLabel(p.gender)),
                    _FieldRow(
                      label: 'Date of Birth',
                      value: _dobLabel(p.dateOfBirth),
                    ),
                    _FieldRow(label: 'Age', value: _ageLabel(p.ageYears)),
                    _FieldRow(
                        label: 'Joined', value: _joinedLabel(p.joinedDate)),
                    if (p.approxPatientsPerDay != null)
                      _FieldRow(
                        label: 'Patients / Day',
                        value: '${p.approxPatientsPerDay}',
                      ),
                    if (p.salary != null)
                      _FieldRow(
                        label: 'Salary',
                        value: _SalaryFmt.format(p.salary!),
                      ),
                  ],
                ),
                SizedBox(height: 18.h),
                OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: Icon(Icons.logout_rounded, size: 20.sp),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.35),
                    ),
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  const _HeroCard({required this.profile, required this.fullName});

  final HealthWorkerProfile profile;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final initials = NameInitials.fromFullName(fullName);
    final email = profile.email?.trim();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F6FAB), Color(0xFF0E947E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 44.h),
      child: Column(
        children: [
          Container(
            width: 88.r,
            height: 88.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.5),
                width: 2.2,
              ),
            ),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 31.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.surface,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.surface,
              height: 1.1,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            email == null || email.isEmpty ? '—' : email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.surface.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  profile.isVerified
                      ? Icons.verified_user_rounded
                      : Icons.pending_rounded,
                  size: 14.sp,
                  color: AppColors.surface,
                ),
                SizedBox(width: 6.w),
                Text(
                  profile.isVerified
                      ? 'Verified Health Worker'
                      : 'Pending Verification',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => context.push(EditProfileScreen.routePath),
            icon: Icon(Icons.edit_rounded, size: 17.sp),
            label: Text(
              'Update Profile',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.surface,
              side: BorderSide(
                color: AppColors.surface.withValues(alpha: 0.65),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: AppColors.registrationSectionLabel,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.registrationFieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 18.h, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.dashboardPrimaryDark.withValues(alpha: 0.8),
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
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
