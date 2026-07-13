import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/gender_label.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/doctor_prescription_detail_screen.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_screen_header.dart';

class DoctorPrescriptionsScreen extends StatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  State<DoctorPrescriptionsScreen> createState() =>
      _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState extends State<DoctorPrescriptionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<DoctorPrescriptionsController>().refreshFromSession(
          context.read<SessionController>().state,
        );
  }

  List<DoctorPrescriptionSummary> _filtered(
    List<DoctorPrescriptionSummary> items,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final name = item.patientName.toLowerCase();
      final meds = item.prescribedMedicinesString.toLowerCase();
      final number = item.patientNumber.toString();
      return name.contains(q) || meds.contains(q) || number.contains(q);
    }).toList();
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final loc = d.toLocal();
    return '${loc.day}/${loc.month}/${loc.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = context.select<DoctorPrescriptionsController,
        List<DoctorPrescriptionSummary>>((c) => c.items);
    final loading =
        context.select<DoctorPrescriptionsController, bool>((c) => c.loading);
    final error =
        context.select<DoctorPrescriptionsController, String?>((c) => c.error);

    final filtered = _filtered(items);

    return ColoredBox(
      color: AppColors.dashboardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrescriptionsHeader(
            totalCount: items.length,
            loading: loading,
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
          Expanded(
            child: RefreshIndicator(
              color: AppColors.dashboardPrimary,
              onRefresh: _refresh,
              child: loading && items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 120.h),
                        const Center(child: CupertinoActivityIndicator()),
                      ],
                    )
                  : error != null && items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 80.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                error,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        )
                      : filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 80.h),
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 44.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _query.isEmpty
                                      ? 'No prescriptions yet'
                                      : 'No matches for your search',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                14.h,
                                16.w,
                                24.h,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 12.h),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return _PrescriptionListCard(
                                  item: item,
                                  dateLabel: _fmtDate(item.prescriptionDate),
                                  onTap: () async {
                                    final updated = await context.push<bool>(
                                      DoctorPrescriptionDetailScreen.routePath,
                                      extra: item,
                                    );
                                    if (updated == true && context.mounted) {
                                      await _refresh();
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

class _PrescriptionsHeader extends StatelessWidget {
  const _PrescriptionsHeader({
    required this.totalCount,
    required this.loading,
    required this.onRefresh,
  });

  final int totalCount;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return DoctorScreenHeader(
      title: 'My prescriptions',
      subtitle: 'All prescriptions you have written',
      trailing: DoctorHeaderRefreshButton(
        loading: loading,
        onPressed: onRefresh,
      ),
      bottom: DoctorHeaderCountBadge(
        icon: CupertinoIcons.doc_text_fill,
        label: '$totalCount total',
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Search patient or medicine…',
        hintStyle: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          CupertinoIcons.search,
          size: 18.sp,
          color: AppColors.dashboardPrimary,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 18.sp,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PrescriptionListCard extends StatelessWidget {
  const _PrescriptionListCard({
    required this.item,
    required this.dateLabel,
    required this.onTap,
  });

  final DoctorPrescriptionSummary item;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name =
        item.patientName.trim().isEmpty ? 'Patient' : item.patientName.trim();
    final meds = item.prescribedMedicinesString.trim();

    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.dashboardPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: AppColors.dashboardChipBlueBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.registrationFieldBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  NameInitials.fromFullName(name),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dashboardPrimary,
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
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$dateLabel · #${item.patientNumber} · ${GenderLabel.format(item.patientGender)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.reasonForVisit.trim().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        item.reasonForVisit,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (meds.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.capsule_fill,
                            size: 14.sp,
                            color: AppColors.dashboardPrimary,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              meds,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
