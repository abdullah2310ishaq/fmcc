import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/edit_prescription_screen.dart';

class DoctorPrescriptionsScreen extends StatelessWidget {
  const DoctorPrescriptionsScreen({super.key});

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final loc = d.toLocal();
    return '${loc.day}/${loc.month}/${loc.year}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorPrescriptionsController>();

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My prescriptions',
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
              child: controller.loading && controller.items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 120.h),
                        const Center(child: CupertinoActivityIndicator()),
                      ],
                    )
                  : controller.error != null && controller.items.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 80.h),
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
                      : controller.items.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: 100.h),
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 40.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No prescriptions yet',
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
                              itemCount: controller.items.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final item = controller.items[index];
                                return _PrescriptionCard(
                                  item: item,
                                  dateLabel: _fmtDate(item.prescriptionDate),
                                  onEdit: () async {
                                    final updated = await context.push<bool>(
                                      EditPrescriptionScreen.routePath,
                                      extra: {
                                        'prescriptionId': item.prescriptionId,
                                        'visitId': item.visitId,
                                        'patientId': '',
                                        'patientName': item.patientName,
                                        'initialNotes': item.doctorNotes,
                                        'medicinesString':
                                            item.prescribedMedicinesString,
                                      },
                                    );
                                    if (updated == true && context.mounted) {
                                      await controller.refreshFromSession(
                                        context.read<SessionController>().state,
                                      );
                                    }
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

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.item,
    required this.dateLabel,
    required this.onEdit,
  });

  final DoctorPrescriptionSummary item;
  final String dateLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.patientName.isEmpty ? 'Patient' : item.patientName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.dashboardPrimary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$dateLabel · #${item.patientNumber} · ${GenderLabel.format(item.patientGender)}',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          if (item.reasonForVisit.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              item.reasonForVisit,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
            ),
          ],
          if (item.prescribedMedicinesString.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.capsule,
                  size: 14.sp,
                  color: AppColors.dashboardPrimary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    item.prescribedMedicinesString,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (item.doctorNotes.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              item.doctorNotes,
              style: TextStyle(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
