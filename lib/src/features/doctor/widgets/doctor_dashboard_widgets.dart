import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';

BoxDecoration doctorPremiumCardDecoration({
  Color? color,
  Color? borderColor,
  Color? shadowColor,
  double radius = 18,
}) {
  return BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(radius.r),
    border: Border.all(
      color: borderColor ?? AppColors.dashboardPrimary.withValues(alpha: 0.14),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: (shadowColor ?? AppColors.dashboardPrimary)
            .withValues(alpha: 0.035),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class DoctorSectionHeader extends StatelessWidget {
  const DoctorSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: AppColors.dashboardPrimary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DoctorTimeGreeting {
  const DoctorTimeGreeting._({
    required this.label,
    required this.wish,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String wish;
  final IconData icon;
  final Color accent;

  static DoctorTimeGreeting now([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h >= 5 && h < 12) {
      return const DoctorTimeGreeting._(
        label: 'Good Morning',
        wish: 'Start strong — your patients are counting on you.',
        icon: Icons.wb_sunny_rounded,
        accent: Color(0xFFF59E0B),
      );
    }
    if (h >= 12 && h < 17) {
      return const DoctorTimeGreeting._(
        label: 'Good Afternoon',
        wish: 'Stay focused. Steady care makes the difference.',
        icon: Icons.wb_cloudy_rounded,
        accent: AppColors.dashboardPrimary,
      );
    }
    if (h >= 17 && h < 21) {
      return const DoctorTimeGreeting._(
        label: 'Good Evening',
        wish: 'Finish with clarity. Every note matters.',
        icon: Icons.nights_stay_rounded,
        accent: Color(0xFF5C6BC0),
      );
    }
    return const DoctorTimeGreeting._(
      label: 'Good Night',
      wish: 'Rest well. You made a real difference today.',
      icon: Icons.bedtime_rounded,
      accent: Color(0xFF64748B),
    );
  }
}

class DoctorHomeHeroCard extends StatelessWidget {
  const DoctorHomeHeroCard({
    super.key,
    required this.doctorName,
    required this.hospitalName,
    required this.specialty,
    required this.onProfileTap,
  });

  final String doctorName;
  final String hospitalName;
  final String specialty;
  final VoidCallback onProfileTap;

  static String _displayName(String fullName) {
    final t = fullName.trim();
    if (t.isEmpty || t == 'Doctor' || t == '—') return 'Doctor';
    return t;
  }

  static String _prettyDate(DateTime now) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = DoctorTimeGreeting.now();
    final now = DateTime.now();
    final name = _displayName(doctorName);
    final initials = NameInitials.fromFullName(name);
    final hospital = hospitalName.trim();
    final designation = specialty.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onProfileTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.dashboardPrimary.withValues(alpha: 0.18),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.dashboardPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54.r,
                    height: 54.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            AppColors.dashboardPrimary.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.dashboardChipBlueBg,
                      child: Text(
                        initials.isEmpty ? 'DR' : initials,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.dashboardPrimaryDark,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              greeting.icon,
                              size: 15.sp,
                              color: greeting.accent,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              greeting.label,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dashboardPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _prettyDate(now),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimaryDark,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          greeting.wish,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  if (designation.isNotEmpty)
                    _InfoChip(
                      icon: CupertinoIcons.star_fill,
                      label: designation,
                      color: AppColors.dashboardPrimary,
                    )
                  else
                    _InfoChip(
                      icon: CupertinoIcons.star_fill,
                      label: 'Doctor',
                      color: AppColors.dashboardPrimary,
                    ),
                  if (hospital.isNotEmpty)
                    _InfoChip(
                      icon: CupertinoIcons.building_2_fill,
                      label: hospital,
                      color: AppColors.followAccentGreen,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.dashboardPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Column(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Icon(icon, color: color, size: 17.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorDashboardQueuePreview extends StatelessWidget {
  const DoctorDashboardQueuePreview({
    super.key,
    required this.patients,
    required this.loading,
    required this.onViewAll,
  });

  final List<DoctorQueuePatient> patients;
  final bool loading;
  final VoidCallback onViewAll;

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final preview = patients.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoctorSectionHeader(
          title: 'Assigned patients',
          trailing: TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              patients.isEmpty ? 'View all' : 'View all (${patients.length})',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        if (loading && patients.isEmpty)
          Container(
            height: 100.h,
            alignment: Alignment.center,
            decoration: doctorPremiumCardDecoration(),
            child: const CupertinoActivityIndicator(),
          )
        else if (patients.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
            decoration: doctorPremiumCardDecoration(
              borderColor: AppColors.followAccentGreen.withValues(alpha: 0.22),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  size: 32.sp,
                  color: AppColors.followAccentGreen.withValues(alpha: 0.55),
                ),
                SizedBox(height: 10.h),
                Text(
                  'All caught up',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimaryDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'The LHW queue is currently clear.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...preview.map(
            (p) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: DoctorAssignedPatientCard(
                fullName: p.fullName,
                firstName: p.firstName,
                lastName: p.lastName,
                patientNumber: p.patientNumber,
                visitActionId: p.visitActionId,
                onTap: () => context.push(
                  DoctorPatientDetailScreen.routePath,
                  extra: {
                    'patientId': p.patientId,
                    'visitId': p.visitId,
                    'patientNumber': p.patientNumber,
                    'fullName': p.fullName,
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
