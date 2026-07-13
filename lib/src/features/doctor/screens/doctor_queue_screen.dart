import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_queue_controller.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';

class DoctorQueueScreen extends StatelessWidget {
  const DoctorQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorQueueController>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Patient queue',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.refreshFromSession(
                    context.read<SessionController>().state,
                  ),
                  icon: Icon(CupertinoIcons.refresh, size: 22.sp),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.refreshFromSession(
                context.read<SessionController>().state,
              ),
              child: controller.loading && controller.patients.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 120.h),
                        const Center(child: CupertinoActivityIndicator()),
                      ],
                    )
                  : controller.error != null && controller.patients.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 80.h),
                            Icon(
                              CupertinoIcons.exclamationmark_circle,
                              size: 36.sp,
                              color: AppColors.danger,
                            ),
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                controller.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        )
                      : controller.patients.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: 100.h),
                                Icon(
                                  CupertinoIcons.person_2,
                                  size: 40.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No patients in queue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                8.h,
                                16.w,
                                24.h,
                              ),
                              itemCount: controller.patients.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final p = controller.patients[index];
                                return DoctorQueueTile(
                                  fullName: p.fullName,
                                  patientNumber: p.patientNumber,
                                  visitActionId: p.visitActionId,
                                  onTap: () {
                                    context.push(
                                      DoctorPatientDetailScreen.routePath,
                                      extra: {
                                        'patientId': p.patientId,
                                        'visitId': p.visitId,
                                        'patientNumber': p.patientNumber,
                                        'fullName': p.fullName,
                                      },
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
