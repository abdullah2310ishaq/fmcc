import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_queue_controller.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_patient_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_common_widgets.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_screen_header.dart';

class DoctorQueueScreen extends StatefulWidget {
  const DoctorQueueScreen({super.key});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<DoctorQueueController>().refreshFromSession(
          context.read<SessionController>().state,
        );
  }

  List<DoctorQueuePatient> _filtered(List<DoctorQueuePatient> patients) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return patients;
    return patients.where((p) {
      final name = p.fullName.toLowerCase();
      final number = p.patientNumber.toString();
      return name.contains(q) || number.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorQueueController>();
    final session = context.watch<SessionController>().state;
    final patients = _filtered(controller.patients);
    final totalCount = controller.patients.length;
    final emergencyCount = controller.emergencyCount;
    final normalCount = controller.normalCount;

    return ColoredBox(
      color: AppColors.dashboardBackground,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AssignedPatientsHeader(
              hospitalName: session.hospitalName,
              totalCount: totalCount,
              emergencyCount: emergencyCount,
              normalCount: normalCount,
              loading: controller.loading,
              onRefresh: _refresh,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: _SearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            if (controller.patients.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Row(
                  children: [
                    Text(
                      '${patients.length} patient${patients.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                    if (_query.trim().isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      Text(
                        '· filtered',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (emergencyCount > 0)
                      VisitActionBadge(visitActionId: 4, compact: true),
                  ],
                ),
              ),
            ],
            Expanded(
              child: RefreshIndicator(
                color: AppColors.dashboardPrimary,
                onRefresh: _refresh,
                child: _buildBody(
                  controller: controller,
                  patients: patients,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildBody({
    required DoctorQueueController controller,
    required List<DoctorQueuePatient> patients,
  }) {
    if (controller.loading && controller.patients.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 48.h),
          const Center(child: CupertinoActivityIndicator()),
          SizedBox(height: 12.h),
          Text(
            'Loading assigned patients…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (controller.error != null && controller.patients.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 40.h),
          _StateCard(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            iconColor: AppColors.danger,
            title: 'Could not load patients',
            message: controller.error!,
            actionLabel: 'Try again',
            onAction: _refresh,
          ),
        ],
      );
    }

    if (controller.patients.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 36.h),
          _StateCard(
            icon: CupertinoIcons.person_2_fill,
            iconColor: AppColors.dashboardPrimary,
            title: 'No assigned patients yet',
            message:
                'When a Lady Health Worker assigns a visit to you, the patient will appear here for review and prescription.',
          ),
        ],
      );
    }

    if (patients.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 36.h),
          _StateCard(
            icon: CupertinoIcons.search,
            iconColor: AppColors.dashboardPrimary,
            title: 'No matches found',
            message: 'Try a different name or patient ID.',
            actionLabel: 'Clear search',
            onAction: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      itemCount: patients.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final p = patients[index];
        return DoctorAssignedPatientCard(
          fullName: p.fullName,
          firstName: p.firstName,
          lastName: p.lastName,
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
    );
  }
}

class _AssignedPatientsHeader extends StatelessWidget {
  const _AssignedPatientsHeader({
    required this.hospitalName,
    required this.totalCount,
    required this.emergencyCount,
    required this.normalCount,
    required this.loading,
    required this.onRefresh,
  });

  final String? hospitalName;
  final int totalCount;
  final int emergencyCount;
  final int normalCount;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final hospital = hospitalName?.trim();

    return DoctorScreenHeader(
      title: 'Assigned Patients',
      subtitle: hospital != null && hospital.isNotEmpty
          ? hospital
          : 'Your clinical queue for today',
      trailing: DoctorHeaderRefreshButton(
        loading: loading,
        onPressed: onRefresh,
      ),
      bottom: Row(
        children: [
          DoctorQueueStatChip(
            label: 'Total',
            value: '$totalCount',
            icon: CupertinoIcons.person_2_fill,
            accent: AppColors.dashboardPrimary,
          ),
          SizedBox(width: 8.w),
          DoctorQueueStatChip(
            label: 'Emergency',
            value: '$emergencyCount',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            accent: AppColors.danger,
          ),
          SizedBox(width: 8.w),
          DoctorQueueStatChip(
            label: 'Normal',
            value: '$normalCount',
            icon: CupertinoIcons.checkmark_seal_fill,
            accent: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or patient ID',
          hintStyle: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.75),
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            size: 20.sp,
            color: AppColors.dashboardPrimary,
          ),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 20.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
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
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashboardPrimary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                icon: Icon(CupertinoIcons.arrow_clockwise, size: 18.sp),
                label: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
