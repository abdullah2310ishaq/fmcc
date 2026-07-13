import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class DoctorMetricCard extends StatelessWidget {
  const DoctorMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accent = AppColors.dashboardPrimary,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22.sp),
              const Spacer(),
              if (onTap != null)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16.sp,
                  color: accent.withValues(alpha: 0.55),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: card,
      ),
    );
  }
}

class VisitActionBadge extends StatelessWidget {
  const VisitActionBadge({
    super.key,
    required this.visitActionId,
    this.compact = false,
  });

  final int visitActionId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isEmergency = visitActionId == 4;
    final isNormal = visitActionId == 3;
    final label = isEmergency
        ? 'Emergency'
        : isNormal
            ? 'Normal'
            : 'Visit';
    final bg = isEmergency
        ? const Color(0xFFFFEBEE)
        : isNormal
            ? const Color(0xFFE8F5E9)
            : AppColors.dashboardChipBlueBg;
    final fg = isEmergency
        ? AppColors.danger
        : isNormal
            ? AppColors.success
            : AppColors.dashboardPrimary;
    final border = isEmergency
        ? const Color(0xFFFFCDD2)
        : isNormal
            ? const Color(0xFFC8E6C9)
            : const Color(0xFFBBDEFB);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 10.w,
        vertical: compact ? 3.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmergency
                ? CupertinoIcons.exclamationmark_triangle_fill
                : isNormal
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.heart_fill,
            size: compact ? 11.sp : 12.sp,
            color: fg,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10.sp : 11.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary chip in the assigned-patients header.
class DoctorQueueStatChip extends StatelessWidget {
  const DoctorQueueStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16.sp, color: accent),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.dashboardPrimaryDark,
                height: 1,
              ),
            ),
            SizedBox(height: 2.h),
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
      ),
    );
  }
}

class DoctorAssignedPatientCard extends StatelessWidget {
  const DoctorAssignedPatientCard({
    super.key,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.patientNumber,
    required this.visitActionId,
    required this.onTap,
  });

  final String fullName;
  final String firstName;
  final String lastName;
  final int patientNumber;
  final int visitActionId;
  final VoidCallback onTap;

  bool get _isEmergency => visitActionId == 4;
  bool get _isNormal => visitActionId == 3;

  Color get _accent => _isEmergency
      ? AppColors.danger
      : _isNormal
          ? AppColors.success
          : AppColors.dashboardPrimary;

  Color get _accentBg => _isEmergency
      ? const Color(0xFFFFF5F5)
      : _isNormal
          ? const Color(0xFFF0FDF4)
          : AppColors.dashboardChipBlueBg;

  Color get _avatarBg => _isEmergency
      ? const Color(0xFFFFE4E6)
      : _isNormal
          ? AppColors.patientAvatarGreen
          : AppColors.patientAvatarBlue;

  @override
  Widget build(BuildContext context) {
    final initials = NameInitials.fromFirstLast(firstName, lastName);
    final displayInitials =
        initials.isNotEmpty ? initials : NameInitials.fromFullName(fullName);

    return Material(
      color: AppColors.surface,
      elevation: _isEmergency ? 4 : 2,
      shadowColor: _accent.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _accent.withValues(alpha: _isEmergency ? 0.35 : 0.2),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _accentBg.withValues(alpha: 0.55),
                AppColors.surface,
              ],
              stops: const [0.0, 0.45],
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _accent,
                        _accent.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 14.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.5.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 26.r,
                            backgroundColor: _avatarBg,
                            child: Text(
                              displayInitials.isNotEmpty ? displayInitials : '?',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                color: _accent,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.dashboardPrimaryDark,
                                      ),
                                    ),
                                  ),
                                  VisitActionBadge(
                                    visitActionId: visitActionId,
                                    compact: true,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 6.w,
                                runSpacing: 4.h,
                                children: [
                                  _MetaPill(
                                    icon: CupertinoIcons.number,
                                    label: 'ID #$patientNumber',
                                  ),
                                  _MetaPill(
                                    icon: _isEmergency
                                        ? CupertinoIcons.bolt_fill
                                        : CupertinoIcons.heart_fill,
                                    label: _isEmergency
                                        ? 'Priority visit'
                                        : 'Routine visit',
                                    tint: _accent,
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text_search,
                                    size: 13.sp,
                                    color: AppColors.dashboardPrimary,
                                  ),
                                  SizedBox(width: 5.w),
                                  Expanded(
                                    child: Text(
                                      'View history & prescribe',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.dashboardPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 18.sp,
                                    color: _accent.withValues(alpha: 0.55),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.tint,
  });

  final IconData icon;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (tint ?? AppColors.textSecondary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legacy tile — kept for any older references.
class DoctorQueueTile extends StatelessWidget {
  const DoctorQueueTile({
    super.key,
    required this.fullName,
    required this.patientNumber,
    required this.visitActionId,
    required this.onTap,
  });

  final String fullName;
  final int patientNumber;
  final int visitActionId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.last : '';

    return DoctorAssignedPatientCard(
      fullName: fullName,
      firstName: first,
      lastName: last,
      patientNumber: patientNumber,
      visitActionId: visitActionId,
      onTap: onTap,
    );
  }
}
