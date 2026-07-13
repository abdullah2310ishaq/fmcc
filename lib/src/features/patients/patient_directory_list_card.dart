import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';

extension PatientDirectoryCardStyle on HwPatientSummary {
  bool _isAntenatalCondition() {
    final p = primaryCondition.toLowerCase();
    return p.contains('antenatal') || p.contains('pregnan');
  }

  ({Color fg, Color bg, Color avatarBg}) get directoryPalette {
    final p = primaryCondition.toLowerCase();
    if (_isAntenatalCondition()) {
      return (
        fg: AppColors.dashboardPrimary,
        bg: AppColors.dashboardChipBlueBg,
        avatarBg: AppColors.patientAvatarBlue,
      );
    }
    if (p.contains('diabet')) {
      return (
        fg: AppColors.followAccentPurple,
        bg: const Color(0xFFF3E8FF),
        avatarBg: AppColors.patientAvatarPurple,
      );
    }
    if (p.contains('post') || p.contains('surg')) {
      return (
        fg: AppColors.followAccentGreen,
        bg: AppColors.followUpcomingBg,
        avatarBg: AppColors.patientAvatarGreen,
      );
    }
    if (p.contains('hypertension') ||
        p.contains('pressure') ||
        p.contains('asthma')) {
      return (
        fg: AppColors.dashboardWarning,
        bg: AppColors.dashboardPeach,
        avatarBg: AppColors.patientAvatarOrange,
      );
    }
    return (
      fg: AppColors.dashboardPrimaryDark,
      bg: AppColors.dashboardChipBlueBg,
      avatarBg: AppColors.patientAvatarBlue,
    );
  }
}

String patientDirectoryGenderLabel(String gender) => GenderLabel.format(gender);

String patientDirectoryShortVisit(DateTime? d) {
  if (d == null) return '—';
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
  return '${d.day} ${months[d.month - 1]}';
}

/// Elevated patient row used on the directory tab and home sheet.
class PatientDirectoryListCard extends StatelessWidget {
  const PatientDirectoryListCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  final HwPatientSummary patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = patient;
    final initials = p.initials.trim().isNotEmpty
        ? p.initials
        : NameInitials.fromFullName(p.fullName);
    final pal = p.directoryPalette;

    return Material(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: pal.fg.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: pal.fg.withValues(alpha: 0.22),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4.w,
                  color: pal.fg.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 14.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.5.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: pal.fg.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 26.r,
                            backgroundColor: pal.avatarBg,
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                color: pal.fg,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dashboardPrimaryDark,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Wrap(
                                spacing: 6.w,
                                runSpacing: 4.h,
                                children: [
                                  _metaPill(
                                    icon: Icons.cake_outlined,
                                    label: '${p.age} yrs',
                                  ),
                                  _metaPill(
                                    icon: p.gender
                                            .trim()
                                            .toLowerCase()
                                            .startsWith('f')
                                        ? Icons.female_rounded
                                        : Icons.male_rounded,
                                    label: patientDirectoryGenderLabel(p.gender),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 9.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pal.bg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        p.primaryCondition.trim().isEmpty
                                            ? '—'
                                            : p.primaryCondition,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                          color: pal.fg,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Last: ${patientDirectoryShortVisit(p.lastVisitDate)}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: pal.fg.withValues(alpha: 0.55),
                          size: 24.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaPill({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.registrationFieldFill.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header banner for the patients directory tab.
class PatientDirectoryHeaderBanner extends StatelessWidget {
  const PatientDirectoryHeaderBanner({
    super.key,
    required this.totalCount,
    required this.visibleCount,
  });

  final int totalCount;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final showingFiltered = visibleCount != totalCount;

    return Material(
      elevation: 3.5,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.dashboardChipBlueBg,
              AppColors.surface,
            ],
            stops: [0.0, 0.9],
          ),
          border: Border.all(color: AppColors.registrationFieldBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dashboardPrimary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28.r,
                backgroundColor: AppColors.dashboardPrimary,
                child: Icon(
                  Icons.groups_rounded,
                  size: 28.sp,
                  color: AppColors.surface,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Patients',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    showingFiltered
                        ? 'Showing $visibleCount of $totalCount patients'
                        : '$totalCount patients in your directory',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.dashboardPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.dashboardPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '$visibleCount',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dashboardPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
