import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/patients/patient_detail_profile_banner.dart';
import 'package:doctor_app/src/features/patients/patient_detail_tab_view.dart';
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
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            primary: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 52.h,
            leading: IconButton(
              onPressed: onBack,
              splashRadius: 22.r,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19.sp,
                color: AppColors.dashboardPrimary,
              ),
            ),
            leadingWidth: 52.w,
            title: Text(
              'Patient profile',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [SizedBox(width: 46.w)],
          ),
          SliverToBoxAdapter(child: PatientDetailProfileBanner(summary: summary)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 28.h),
            sliver: SliverList.separated(
              itemCount: PatientDetailSection.values.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
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
    required this.section,
    required this.onTap,
  });

  final PatientDetailSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = section.accentColor;
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
                child: Icon(section.icon, size: 24.sp, color: accent),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      section.subtitle,
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
