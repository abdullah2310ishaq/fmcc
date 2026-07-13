import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/core/theme/app_gradients.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
import 'package:doctor_app/src/features/doctor/screens/create_prescription_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_safe_area.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  const DoctorPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.visitId,
    required this.patientNumber,
    required this.fullName,
  });

  static const routePath = '/doctor/patient';

  final String patientId;
  final String visitId;
  final int patientNumber;
  final String fullName;

  @override
  State<DoctorPatientDetailScreen> createState() =>
      _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  bool _loading = true;
  String? _error;
  PatientProfileData? _profile;
  PatientCompleteHistoryData? _history;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Unauthorized. Please sign in again.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = PatientApi(session.apiClient);
      final profile = await api.getPatientProfile(
        patientId: widget.patientId,
        bearerToken: token,
      );
      PatientCompleteHistoryData? history;
      try {
        history = await api.getCompleteHistory(
          patientId: widget.patientId,
          bearerToken: token,
        );
      } catch (_) {
        history = null;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = session.apiClient.mapError(e).message;
      });
    }
  }

  String get _displayName {
    if (_profile != null) {
      final n = '${_profile!.firstName} ${_profile!.lastName}'.trim();
      if (n.isNotEmpty) return n;
    }
    return widget.fullName.trim().isNotEmpty ? widget.fullName : 'Patient';
  }

  Future<void> _openPrescription() async {
    final saved = await context.push<bool>(
      CreatePrescriptionScreen.routePath,
      extra: {
        'patientId': widget.patientId,
        'visitId': widget.visitId,
        'patientName': _displayName,
      },
    );
    if (saved == true && mounted) {
      await context.read<DoctorPrescriptionsController>().refreshFromSession(
            context.read<SessionController>().state,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const DoctorPageSafeArea(child: _DetailLoadingView())
                : _error != null
                    ? DoctorPageSafeArea(
                        child: _DetailErrorView(message: _error!, onRetry: _load),
                      )
                    : RefreshIndicator(
                        color: AppColors.dashboardPrimary,
                        onRefresh: _load,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _PatientHeroHeader(
                                name: _displayName,
                                firstName: _profile?.firstName ?? '',
                                lastName: _profile?.lastName ?? '',
                                patientNumber:
                                    _profile?.patientNumber ?? widget.patientNumber,
                                gender: _profile?.gender ?? '',
                                age: _ageFromDob(_profile?.dateOfBirth),
                                visitId: widget.visitId,
                                onBack: () => context.pop(),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  if (_profile != null) ...[
                                    _ContactCard(profile: _profile!),
                                    SizedBox(height: 12.h),
                                  ],
                                  if (_history?.baseline != null) ...[
                                    _BaselineCard(baseline: _history!.baseline!),
                                    SizedBox(height: 12.h),
                                  ],
                                  _HistoryCard(
                                    title: 'Medical history',
                                    icon: CupertinoIcons.heart_fill,
                                    accent: AppColors.danger,
                                    count: _history?.medical.length ?? 0,
                                    emptyMessage:
                                        'No medical conditions recorded.',
                                    items: [
                                      for (final row
                                          in _history?.medical ?? const [])
                                        _HistoryListItem(
                                          title: row.displayConditionName
                                                  .trim()
                                                  .isNotEmpty
                                              ? row.displayConditionName
                                              : 'Condition',
                                          subtitle: [
                                            if (row.isOnMedication)
                                              'On medication',
                                            if (row.complianceLevelName
                                                .trim()
                                                .isNotEmpty)
                                              row.complianceLevelName.trim(),
                                            if (row.durationInMonths != null)
                                              '${row.durationInMonths} mo',
                                          ].join(' · '),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  _HistoryCard(
                                    title: 'Surgical history',
                                    icon: CupertinoIcons.bandage_fill,
                                    accent: AppColors.dashboardWarning,
                                    count: _history?.surgical.length ?? 0,
                                    emptyMessage: 'No surgical procedures recorded.',
                                    items: [
                                      for (final row
                                          in _history?.surgical ?? const [])
                                        _HistoryListItem(
                                          title: row.displayProcedureName
                                                  .trim()
                                                  .isNotEmpty
                                              ? row.displayProcedureName
                                              : 'Procedure',
                                          subtitle: row.notes.trim(),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  _HistoryCard(
                                    title: 'Drug history',
                                    icon: CupertinoIcons.capsule_fill,
                                    accent: AppColors.followAccentPurple,
                                    count: _history?.drugs.length ?? 0,
                                    emptyMessage: 'No drug history recorded.',
                                    items: [
                                      for (final row
                                          in _history?.drugs ?? const [])
                                        _HistoryListItem(
                                          title: row.displayCategoryName
                                                  .trim()
                                                  .isNotEmpty
                                              ? row.displayCategoryName
                                              : 'Medication',
                                          subtitle: [
                                            if (row.adherenceLevelName
                                                .trim()
                                                .isNotEmpty)
                                              row.adherenceLevelName.trim(),
                                            if (row.sideEffects.trim().isNotEmpty)
                                              row.sideEffects.trim(),
                                          ].join(' · '),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          if (!_loading && _error == null)
            _WritePrescriptionBar(onPressed: _openPrescription),
        ],
      ),
    );
  }

  static int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}

class _PatientHeroHeader extends StatelessWidget {
  const _PatientHeroHeader({
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.patientNumber,
    required this.gender,
    required this.age,
    required this.visitId,
    required this.onBack,
  });

  final String name;
  final String firstName;
  final String lastName;
  final int patientNumber;
  final String gender;
  final int? age;
  final String visitId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final initials = NameInitials.fromFirstLast(firstName, lastName);
    final displayInitials =
        initials.isNotEmpty ? initials : NameInitials.fromFullName(name);
    final top = DoctorInsets.top(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        border: Border.all(color: AppColors.registrationFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.w, top + 4.h, 16.w, 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                CupertinoIcons.back,
                color: AppColors.dashboardPrimaryDark,
                size: 24.sp,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30.r,
                      backgroundColor: AppColors.patientAvatarBlue,
                      child: Text(
                        displayInitials.isNotEmpty ? displayInitials : '?',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.dashboardPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimaryDark,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Patient ID #$patientNumber',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (gender.trim().isNotEmpty ||
                age != null ||
                visitId.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    if (gender.trim().isNotEmpty)
                      _HeroChip(
                        icon: GenderLabel.isFemale(gender)
                            ? CupertinoIcons.person_crop_circle_fill
                            : CupertinoIcons.person_crop_circle,
                        label: GenderLabel.format(gender),
                      ),
                    if (age != null)
                      _HeroChip(
                        icon: CupertinoIcons.calendar,
                        label: '$age yrs',
                      ),
                    if (visitId.trim().isNotEmpty)
                      _HeroChip(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Active visit',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.dashboardPrimary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.profile});

  final PatientProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Contact & profile',
            icon: CupertinoIcons.person_crop_circle_fill,
            accent: AppColors.dashboardPrimary,
          ),
          SizedBox(height: 14.h),
          if (profile.cnic.trim().isNotEmpty)
            _InfoRow(
              icon: CupertinoIcons.creditcard,
              label: 'CNIC',
              value: profile.cnic,
            ),
          if (profile.contactNumber.trim().isNotEmpty)
            _InfoRow(
              icon: CupertinoIcons.phone_fill,
              label: 'Phone',
              value: profile.contactNumber,
            ),
          if (profile.address.trim().isNotEmpty)
            _InfoRow(
              icon: CupertinoIcons.location_solid,
              label: 'Address',
              value: profile.address,
            ),
        ],
      ),
    );
  }
}

class _BaselineCard extends StatelessWidget {
  const _BaselineCard({required this.baseline});

  final PatientBaselineLifestyle baseline;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Baseline & lifestyle',
            icon: CupertinoIcons.heart_circle_fill,
            accent: AppColors.success,
          ),
          SizedBox(height: 14.h),
          _InfoRow(
            icon: CupertinoIcons.person_2_fill,
            label: 'Family HTN / stroke',
            value: baseline.familyHistoryOfHtnOrStroke ? 'Yes' : 'No',
          ),
          _InfoRow(
            icon: CupertinoIcons.smoke_fill,
            label: 'Tobacco use',
            value: baseline.tobaccoUse ? 'Yes' : 'No',
          ),
          if (baseline.tobaccoUse && baseline.tobaccoType?.trim().isNotEmpty == true)
            _InfoRow(
              icon: CupertinoIcons.tag_fill,
              label: 'Tobacco type',
              value: baseline.tobaccoType!.trim(),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.count,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final int count;
  final String emptyMessage;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  title: title,
                  icon: icon,
                  accent: accent,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            )
          else
            ...items,
        ],
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  const _HistoryListItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.dashboardChipBlueBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 16.sp,
            color: AppColors.dashboardPrimary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16.sp, color: accent),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.dashboardPrimary),
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
                SizedBox(height: 2.h),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.35,
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

class _WritePrescriptionBar extends StatelessWidget {
  const _WritePrescriptionBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: DoctorBottomInset(
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dashboardPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: Icon(
              CupertinoIcons.pencil_ellipsis_rectangle,
              size: 20.sp,
            ),
            label: Text(
              'Write Prescription',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailLoadingView extends StatelessWidget {
  const _DetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(),
          SizedBox(height: 12.h),
          Text(
            'Loading patient history…',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.danger,
                size: 36.sp,
              ),
              SizedBox(height: 12.h),
              Text(
                'Could not load patient',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dashboardPrimaryDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dashboardPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: Icon(CupertinoIcons.arrow_clockwise, size: 18.sp),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
