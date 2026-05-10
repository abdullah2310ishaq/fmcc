import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/profile/profile_view_screen.dart';
import 'package:doctor_app/src/widgets/urdu_help_suffix.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  static String _weekday(DateTime d) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[d.weekday - 1];
  }

  static String _month(DateTime d) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[d.month - 1];
  }

  static String _longDate(DateTime d) =>
      '${_weekday(d)}, ${d.day} ${_month(d)} ${d.year}';

  static String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.ladyHealthWorker:
        return 'Nurse';
      case UserRole.unknown:
        return '';
    }
  }

  static String _firstName(String fullName) {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.first;
  }

  static String _initials(String fullName) {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.single;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Future<void> _confirmLogout(
    BuildContext context,
    SessionController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 32.sp,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Sign out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your session will end and you will need to sign in again with Google.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Stay',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          backgroundColor: AppColors.blueDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await controller.logout(keepRole: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    final session = context.select<SessionController, AppSession>((c) => c.state);
    final fullName = session.registrationDetails.fullName.trim();
    final first = _firstName(fullName);
    final greetName =
        '${_roleLabel(session.role)}${first.isEmpty ? '' : ' $first'}'.trim();
    final headline = greetName.isEmpty
        ? '${_timeGreeting()} 👋'
        : '${_timeGreeting()}, $greetName! 👋';
    final now = DateTime.now();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              headline,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dashboardPrimaryDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                          UrduHelpSuffix(
                            urduText:
                                'سلام، یہ آپ کے لیے دن بھر کا مختصر خیرمقدمی پیغام ہے۔',
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Text(
                            _longDate(now),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          UrduHelpSuffix(
                            urduText: 'آج کی مکمل تاریخ۔',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: AppColors.dashboardPrimaryDark,
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        onTap: () => context.push(ProfileViewScreen.routePath),
                        borderRadius: BorderRadius.circular(12.r),
                        child: SizedBox(
                          width: 48.r,
                          height: 48.r,
                          child: Center(
                            child: Text(
                              _initials(fullName.isEmpty ? 'NA' : fullName),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 12.r,
                        height: 12.r,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 22.sp,
                  ),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _confirmLogout(context, controller);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _StatsGrid(onTotalPatientsTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All patients — API بعد میں',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              );
            }),
            SizedBox(height: 22.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Today's Follow-ups",
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const UrduHelpSuffix(
                  urduText: 'آج کے فالو اپ وزٹس کی فہرست۔',
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardChipBlueBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '4 Scheduled',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dashboardPrimary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      const UrduHelpSuffix(
                        urduText: 'چار شیڈول شدہ ملاقاتیں۔',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _FollowUpCard.overdue(
              initials: 'ZK',
              name: 'Zainab Khan',
              subtitle: 'Age 34 • Female • ID: LHW-2026-0041',
              topicLabel: 'BP Monitoring',
              topicUrdu: 'بلڈ پریشر کی نگرانی',
              scheduleNote: 'Was: 09:00 AM',
              scheduleUrdu: 'وقت صبح نو بجے تھا۔',
              lastVisit:
                  'Last visit: 03 May 2026 — Hypertension check, BP was 145/92',
              lastVisitUrdu:
                  'پچھلا وزٹ: ۳ مئی ۲۰۲۶ — بلڈ پریشر چیک، ریڈنگ ۱۴۵/۹۲ تھی۔',
            ),
            SizedBox(height: 12.h),
            _FollowUpCard.scheduled(
              initials: 'SA',
              name: 'Sajida Akhtar',
              subtitle: 'Age 28 • Female • ID: LHW-2026-0038',
              topicLabel: 'Antenatal Care',
              topicUrdu: 'حمل کی دیکھ بھال (اینٹی نیٹل کیئر)',
              timeBadge: '10:30 AM',
              timeBadgeUrdu: 'صبح ساڑھے دس بجے',
            ),
            SizedBox(height: 8.h),
            Text(
              'Demo cards — patient follow-ups API بعد میں',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.onTotalPatientsTap});

  final VoidCallback onTotalPatientsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'PATIENTS TODAY',
                titleUrdu: 'آج کے مریض',
                value: '12',
                valueColor: AppColors.textPrimary,
                footer: Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 14.sp, color: AppColors.success),
                    SizedBox(width: 4.w),
                    Text(
                      '↑ 3 from yesterday',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    UrduHelpSuffix(
                      urduText: 'کل کے مقابلے میں آج تین زیادہ مریض۔',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: 'PENDING FOLLOW-UPS',
                titleUrdu: 'زیر التواء فالو اپ',
                value: '4',
                valueColor: AppColors.dashboardWarning,
                footer: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14.sp, color: AppColors.dashboardWarning),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Needs attention',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dashboardWarning,
                        ),
                      ),
                    ),
                    UrduHelpSuffix(
                      urduText: 'فوری توجہ درکار ہے۔',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'TOTAL PATIENTS',
                titleUrdu: 'کل مریض',
                value: '247',
                valueColor: AppColors.dashboardPrimary,
                border: Border.all(color: AppColors.dashboardPrimary, width: 1.5),
                titleColor: AppColors.dashboardPrimary,
                trailing: Material(
                  color: AppColors.dashboardPrimaryDark,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onTotalPatientsTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
                footer: Row(
                  children: [
                    Text(
                      'Tap to view all →',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dashboardPrimary,
                      ),
                    ),
                    UrduHelpSuffix(
                      urduText: 'سب دیکھنے کے لیے تھپکی دیں۔',
                    ),
                  ],
                ),
                onTap: onTotalPatientsTap,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: 'THIS MONTH',
                titleUrdu: 'اس مہینے',
                value: '84',
                valueColor: AppColors.textPrimary,
                footer: Row(
                  children: [
                    Text(
                      'of 120 target',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    UrduHelpSuffix(
                      urduText: 'ہدف ۱۲۰ میں سے ۸۴۔',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 10.h),
          child: Text(
            'Stats above — demo placeholders; API بعد میں',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.titleUrdu,
    required this.value,
    required this.valueColor,
    required this.footer,
    this.border,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String titleUrdu;
  final String value;
  final Color valueColor;
  final Widget footer;
  final BoxBorder? border;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    final content = Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: border ?? Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: titleColor ?? AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    UrduHelpSuffix(urduText: titleUrdu),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          footer,
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }
    return content;
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard.overdue({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.topicLabel,
    required this.topicUrdu,
    required this.scheduleNote,
    required this.scheduleUrdu,
    required this.lastVisit,
    required this.lastVisitUrdu,
  })  : _variant = _FollowVariant.overdue,
        timeBadge = null,
        timeBadgeUrdu = null,
        showStartButton = true;

  const _FollowUpCard.scheduled({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.topicLabel,
    required this.topicUrdu,
    required this.timeBadge,
    required this.timeBadgeUrdu,
  })  : _variant = _FollowVariant.scheduled,
        scheduleNote = null,
        scheduleUrdu = null,
        lastVisit = null,
        lastVisitUrdu = null,
        showStartButton = false;

  final _FollowVariant _variant;
  final bool showStartButton;
  final String initials;
  final String name;
  final String subtitle;
  final String topicLabel;
  final String topicUrdu;
  final String? scheduleNote;
  final String? scheduleUrdu;
  final String? lastVisit;
  final String? lastVisitUrdu;
  final String? timeBadge;
  final String? timeBadgeUrdu;

  @override
  Widget build(BuildContext context) {
    final isOverdue = _variant == _FollowVariant.overdue;
    final bg = isOverdue ? AppColors.dashboardPeach : AppColors.surface;
    final borderColor =
        isOverdue ? AppColors.dashboardPeachBorder : AppColors.border;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isOverdue)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.dashboardWarning.withValues(alpha: 0.15)
                          : AppColors.dashboardChipBlueBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: isOverdue
                            ? AppColors.dashboardWarning
                            : AppColors.dashboardPrimary,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              UrduHelpSuffix(urduText: 'مریض کا نام۔'),
                            ],
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.danger,
                                  ),
                                ),
                                UrduHelpSuffix(
                                  urduText: 'وقت گزر چکا ہے۔',
                                ),
                              ],
                            ),
                          )
                        else if (timeBadge != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.dashboardChipBlueBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeBadge!,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dashboardPrimary,
                                  ),
                                ),
                                UrduHelpSuffix(urduText: timeBadgeUrdu!),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TopicChip(
                label: topicLabel,
                urdu: topicUrdu,
                icon: isOverdue
                    ? Icons.monitor_heart_outlined
                    : Icons.pregnant_woman_rounded,
                strongOrange: isOverdue,
              ),
              if (scheduleNote != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scheduleNote!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    UrduHelpSuffix(urduText: scheduleUrdu!),
                  ],
                ),
            ],
          ),
          if (lastVisit != null) ...[
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    lastVisit!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
                UrduHelpSuffix(urduText: lastVisitUrdu!),
              ],
            ),
          ],
          if (showStartButton) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Visit flow — API بعد میں',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashboardActionRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(Icons.play_arrow_rounded, size: 22.sp),
                label: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.w,
                  children: [
                    Text(
                      'Start Visit Now',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    UrduHelpSuffix(
                      urduText: 'اب وزٹ شروع کریں۔',
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _FollowVariant { overdue, scheduled }

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.urdu,
    required this.icon,
    required this.strongOrange,
  });

  final String label;
  final String urdu;
  final IconData icon;
  final bool strongOrange;

  @override
  Widget build(BuildContext context) {
    final fg =
        strongOrange ? AppColors.dashboardWarning : AppColors.dashboardPrimary;
    final bg = strongOrange
        ? AppColors.dashboardWarning.withValues(alpha: 0.12)
        : AppColors.dashboardChipBlueBg;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: fg),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          UrduHelpSuffix(urduText: urdu),
        ],
      ),
    );
  }
}
