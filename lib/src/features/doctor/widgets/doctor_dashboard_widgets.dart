import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';

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

  static const _previewCount = 2;

  @override
  Widget build(BuildContext context) {
    final preview = patients.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Assigned patients',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dashboardPrimaryDark,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patients.length > _previewCount
                        ? 'View all (${patients.length})'
                        : 'View all',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right, size: 14.sp),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (loading && patients.isEmpty)
          Container(
            height: 120.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: const CupertinoActivityIndicator(),
          )
        else if (patients.isEmpty)
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.person_2,
                  size: 28.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No patients assigned yet',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
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
