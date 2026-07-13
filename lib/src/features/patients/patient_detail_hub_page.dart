import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/patients/patient_detail_profile_banner.dart';
import 'package:doctor_app/src/features/patients/patient_detail_tab_view.dart';
import 'package:doctor_app/src/features/patients/patient_prescription_history_page.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';

/// Patient overview — profile at top + one elevated card per history section.
class PatientDetailHubPage extends StatelessWidget {
  const PatientDetailHubPage({
    super.key,
    required this.summary,
    required this.onBack,
    this.onStartVisit,
  });

  final HwPatientSummary summary;
  final VoidCallback onBack;
  final ValueChanged<VisitPatientSeed>? onStartVisit;

  void _openSection(BuildContext context, PatientDetailSection section) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => PatientDetailTabView(
          key: ValueKey('${summary.patientId}-${section.name}'),
          summary: summary,
          onBack: () => Navigator.of(ctx).pop(),
          onStartVisit: onStartVisit,
          fixedSection: section,
          showProfileBanner: false,
          showSectionTabs: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.registrationScreenBg,
      child: Column(
        children: [
          // Static top bar — stays fixed while cards scroll.
          Material(
            color: AppColors.surface,
            elevation: 0.5,
            shadowColor: AppColors.dashboardPrimaryDark.withValues(alpha: 0.08),
            surfaceTintColor: Colors.transparent,
            child: SizedBox(
              height: 52.h,
              child: Row(
                children: [
                  SizedBox(width: 6.w),
                  IconButton(
                    onPressed: onBack,
                    splashRadius: 22.r,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19.sp,
                      color: AppColors.dashboardPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Patient profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 52.w),
                ],
              ),
            ),
          ),
          // Static profile area — does not scroll away.
          PatientDetailProfileBanner(summary: summary),
          // Only the section cards scroll.
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 28.h),
              itemCount: PatientDetailSection.values.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (index == PatientDetailSection.values.length) {
                  return _SectionHubCard(
                    sectionLabel: 'Prescription History',
                    sectionSubtitle:
                        'Read-only doctor prescriptions for this patient',
                    sectionIcon: Icons.medication_liquid_outlined,
                    sectionAccent: AppColors.dashboardActionRed,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (ctx) => PatientPrescriptionHistoryPage(
                            patientId: summary.patientId,
                            patientName: summary.fullName,
                          ),
                        ),
                      );
                    },
                  );
                }
                final section = PatientDetailSection.values[index];
                return _SectionHubCard(
                  section: section,
                  onTap: () => _openSection(context, section),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHubCard extends StatelessWidget {
  const _SectionHubCard({
    this.section,
    this.sectionLabel,
    this.sectionSubtitle,
    this.sectionIcon,
    this.sectionAccent,
    required this.onTap,
  }) : assert(
          section != null ||
              (sectionLabel != null &&
                  sectionSubtitle != null &&
                  sectionIcon != null &&
                  sectionAccent != null),
        );

  final PatientDetailSection? section;
  final String? sectionLabel;
  final String? sectionSubtitle;
  final IconData? sectionIcon;
  final Color? sectionAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = sectionAccent ?? section!.accentColor;
    final label = sectionLabel ?? section!.label;
    final subtitle = sectionSubtitle ?? section!.subtitle;
    final icon = sectionIcon ?? section!.icon;
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: accent.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24.sp, color: accent),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: accent.withValues(alpha: 0.75),
                    size: 22.sp,
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
