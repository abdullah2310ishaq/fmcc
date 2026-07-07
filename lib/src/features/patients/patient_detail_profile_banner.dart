import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/patients/patient_detail_tab_view.dart';

Color patientAvatarColorForCondition(String primary) {
  final p = primary.toLowerCase();
  if (p.contains('antenatal') || p.contains('pregnan')) {
    return AppColors.patientAvatarBlue;
  }
  if (p.contains('diabet')) return AppColors.patientAvatarPurple;
  if (p.contains('post') || p.contains('surg')) {
    return AppColors.patientAvatarGreen;
  }
  if (p.contains('hypertension') ||
      p.contains('pressure') ||
      p.contains('asthma')) {
    return AppColors.patientAvatarOrange;
  }
  return AppColors.patientAvatarBlue;
}

String patientGenderLabel(String gender) {
  final g = gender.trim().toLowerCase();
  if (g == 'male' || g == 'm') return 'Male';
  if (g == 'female' || g == 'f') return 'Female';
  return gender.trim().isNotEmpty ? gender.trim() : '—';
}

/// Gradient profile header shown on the patient detail hub only.
class PatientDetailProfileBanner extends StatelessWidget {
  const PatientDetailProfileBanner({super.key, required this.summary});

  final HwPatientSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final initials = s.initials.trim().isNotEmpty
        ? s.initials
        : NameInitials.fromFullName(s.fullName);
    final avatarBg = patientAvatarColorForCondition(s.primaryCondition);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: Material(
        elevation: 3,
        shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24.r),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.dashboardChipBlueBg,
                AppColors.surface,
              ],
            ),
            border: Border.all(
              color: AppColors.registrationFieldBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.dashboardPrimary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30.r,
                      backgroundColor: avatarBg.withValues(alpha: 0.45),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.dashboardPrimary,
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
                          s.fullName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimaryDark,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          children: [
                            _infoPill(
                              icon: Icons.cake_outlined,
                              label: '${s.age} yrs',
                            ),
                            _infoPill(
                              icon: s.gender.trim().toLowerCase().startsWith('f')
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              label: patientGenderLabel(s.gender),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.registrationFieldBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statBlock(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Condition',
                        value: s.primaryCondition.isNotEmpty
                            ? s.primaryCondition
                            : '—',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32.h,
                      color: AppColors.registrationFieldBorder,
                    ),
                    Expanded(
                      child: _statBlock(
                        icon: Icons.event_outlined,
                        label: 'Last visit',
                        value: patientDetailShortVisit(s.lastVisitDate),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.registrationFieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.dashboardPrimary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13.sp, color: AppColors.textSecondary),
            SizedBox(width: 4.w),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dashboardPrimaryDark,
          ),
        ),
      ],
    );
  }
}
