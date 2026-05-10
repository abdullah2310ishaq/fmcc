import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
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

  @override
  Widget build(BuildContext context) {
    final session =
        context.select<SessionController, AppSession>((c) => c.state);
    final fullName = session.registrationDetails.fullName.trim();
    final avatarLetters = NameInitials.fromFullName(fullName);
    final now = DateTime.now();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 28.h, bottom: 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 0, 16.w, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty
                              ? '${_timeGreeting()} 👋'
                              : '${_timeGreeting()}, ${fullName}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dashboardPrimaryDark,
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _longDate(now),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: AppColors.dashboardPrimaryDark,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () =>
                              context.push(ProfileViewScreen.routePath),
                          child: SizedBox(
                            width: 52.r,
                            height: 52.r,
                            child: Center(
                              child: avatarLetters.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 26.sp,
                                    )
                                  : Text(
                                      avatarLetters,
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
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13.r,
                          height: 13.r,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 16.w, 0),
              child: _StatsGrid(onTotalPatientsTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All patients — API بعد میں',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20.h),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 10.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.dashboardChipBlueBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '5 Scheduled',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dashboardPrimary,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            const UrduHelpSuffix(
                              urduText: 'پانچ شیڈول / زیر التواء ملاقاتیں۔',
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
                  _FollowUpCard.today(
                    initials: 'SA',
                    name: 'Sajida Akhtar',
                    subtitle: 'Age 28 • Female • ID: LHW-2026-0038',
                    topicLabel: 'Antenatal Care',
                    topicUrdu: 'حمل کی دیکھ بھال (اینٹی نیٹل کیئر)',
                    topicIcon: Icons.pregnant_woman_rounded,
                    accentColor: AppColors.dashboardPrimary,
                    timeBadge: '10:30 AM',
                    timeBadgeUrdu: 'صبح ساڑھے دس بجے',
                    lastVisit:
                        'Last visit: 28 Apr 2026 — Week 28 checkup, weight 62kg, normal',
                    lastVisitUrdu:
                        'پچھلا وزٹ: ۲۸ اپریل ۲۰۲۶ — ہفتہ ۲۸ چیک، وزن ۶۲ کلو، عام۔',
                  ),
                  SizedBox(height: 12.h),
                  _FollowUpCard.today(
                    initials: 'MA',
                    name: 'Muhammad Arif',
                    subtitle: 'Age 52 • Male • ID: LHW-2026-0029',
                    topicLabel: 'Diabetes Follow-up',
                    topicUrdu: 'ذیابیطس فالو اپ',
                    topicIcon: Icons.medical_services_outlined,
                    accentColor: AppColors.followAccentPurple,
                    timeBadge: '12:00 PM',
                    timeBadgeUrdu: 'دوپہر بارہ بجے',
                    lastVisit:
                        'Last visit: 02 May 2026 — Fasting glucose 118 mg/dL, meds reviewed',
                    lastVisitUrdu:
                        'پچھلا وزٹ: ۲ مئی ۲۰۲۶ — فاسٹنگ گلوکوز ۱۱۸، ادویات کا جائزہ۔',
                  ),
                  SizedBox(height: 12.h),
                  _FollowUpCard.upcoming(
                    initials: 'RF',
                    name: 'Rubina Fatima',
                    subtitle: 'Age 41 • Female • ID: LHW-2026-0015',
                    topicLabel: 'Post-Op Check',
                    topicUrdu: 'آپریشن کے بعد معائنہ',
                    topicIcon: Icons.assignment_turned_in_outlined,
                    accentColor: AppColors.followAccentGreen,
                    dueInLabel: 'Due in 3 days',
                    dueInUrdu: '۳ دن بعد مقررہ',
                    lastVisit:
                        'Last visit: 05 May 2026 — Wound clean, vitals stable',
                    lastVisitUrdu:
                        'پچھلا وزٹ: ۵ مئی ۲۰۲۶ — زخم صاف، علامات مستحکم۔',
                  ),
                  SizedBox(height: 12.h),
                  _FollowUpCard.upcoming(
                    initials: 'AN',
                    name: 'Ayesha Noor',
                    subtitle: 'Age 29 • Female • ID: LHW-2026-0052',
                    topicLabel: 'Hygiene counselling',
                    topicUrdu: 'حفظانِ صحت کی رہنمائی',
                    topicIcon: Icons.health_and_safety_outlined,
                    accentColor: AppColors.followAccentGreen,
                    dueInLabel: 'Due in 2 days',
                    dueInUrdu: '۲ دن بعد مقررہ',
                    lastVisit: 'Last visit: 06 May 2026 — TB meds adherence OK',
                    lastVisitUrdu:
                        'پچھلا وزٹ: ۶ مئی ۲۰۲۶ — ٹی بی دوائیں باقاعدہ۔',
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Divider(
              height: 1,
              thickness: 1,
              // Demo includes an overdue card → warning stripe; use [AppColors.border] when none overdue.
              color: AppColors.dashboardWarning.withValues(alpha: 0.55),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 16.w, 0),
              child: Text(
                'Demo cards — patient follow-ups API بعد میں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
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
                    Expanded(
                      child: Text(
                        '↑ 3 from yesterday',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
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
                border:
                    Border.all(color: AppColors.dashboardPrimary, width: 1.5),
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
                    Expanded(
                      child: Text(
                        'Tap to view all →',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dashboardPrimary,
                        ),
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
                    Expanded(
                      child: Text(
                        'of 120 target',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
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
        border: border ??
            Border.all(color: AppColors.border.withValues(alpha: 0.6)),
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
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.w,
                  runSpacing: 4.h,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: titleColor ?? AppColors.textSecondary,
                        height: 1.2,
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

enum _FollowVariant { overdue, today, upcoming }

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
        topicIcon = Icons.monitor_heart_outlined,
        accentColor = AppColors.dashboardPrimary,
        timeBadge = null,
        timeBadgeUrdu = null,
        dueInLabel = null,
        dueInUrdu = null;

  const _FollowUpCard.today({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.topicLabel,
    required this.topicUrdu,
    required this.topicIcon,
    required this.accentColor,
    required this.timeBadge,
    required this.timeBadgeUrdu,
    required this.lastVisit,
    required this.lastVisitUrdu,
  })  : _variant = _FollowVariant.today,
        scheduleNote = null,
        scheduleUrdu = null,
        dueInLabel = null,
        dueInUrdu = null;

  const _FollowUpCard.upcoming({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.topicLabel,
    required this.topicUrdu,
    required this.topicIcon,
    required this.accentColor,
    required this.dueInLabel,
    required this.dueInUrdu,
    required this.lastVisit,
    required this.lastVisitUrdu,
  })  : _variant = _FollowVariant.upcoming,
        timeBadge = null,
        timeBadgeUrdu = null,
        scheduleNote = null,
        scheduleUrdu = null;

  final _FollowVariant _variant;
  final IconData topicIcon;
  final Color accentColor;
  final String initials;
  final String name;
  final String subtitle;
  final String topicLabel;
  final String topicUrdu;
  final String? scheduleNote;
  final String? scheduleUrdu;
  final String lastVisit;
  final String lastVisitUrdu;
  final String? timeBadge;
  final String? timeBadgeUrdu;
  final String? dueInLabel;
  final String? dueInUrdu;

  void _visitStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Visit flow — API بعد میں',
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _variant == _FollowVariant.overdue;
    final today = _variant == _FollowVariant.today;
    final upcoming = _variant == _FollowVariant.upcoming;

    late Color bg;
    late Color borderCol;
    late Color avatarBg;
    late Color avatarFg;
    late Color chipFg;
    late Color chipBg;

    if (overdue) {
      bg = AppColors.dashboardPeach;
      borderCol = AppColors.dashboardPeachBorder;
      avatarBg = AppColors.dashboardWarning.withValues(alpha: 0.15);
      avatarFg = AppColors.dashboardWarning;
      chipFg = AppColors.dashboardWarning;
      chipBg = AppColors.dashboardWarning.withValues(alpha: 0.12);
    } else if (today) {
      bg = AppColors.surface;
      borderCol = AppColors.border;
      avatarBg = accentColor.withValues(alpha: 0.12);
      avatarFg = accentColor;
      chipFg = accentColor;
      chipBg = accentColor.withValues(alpha: 0.12);
    } else {
      bg = AppColors.followUpcomingBg;
      borderCol = AppColors.followUpcomingBorder;
      avatarBg = accentColor.withValues(alpha: 0.12);
      avatarFg = accentColor;
      chipFg = accentColor;
      chipBg = accentColor.withValues(alpha: 0.12);
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderCol),
        boxShadow: [
          if (!overdue)
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
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: avatarFg,
                      ),
                    ),
                  ),
                  if (overdue)
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
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4.w,
                            runSpacing: 4.h,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              UrduHelpSuffix(urduText: 'مریض کا نام۔'),
                            ],
                          ),
                        ),
                        if (overdue)
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
                        else if (today && timeBadge != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
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
                                    color: accentColor,
                                  ),
                                ),
                                UrduHelpSuffix(urduText: timeBadgeUrdu!),
                              ],
                            ),
                          )
                        else if (upcoming &&
                            dueInLabel != null &&
                            dueInUrdu != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dueInLabel!,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                                UrduHelpSuffix(urduText: dueInUrdu!),
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
                icon: topicIcon,
                foreground: chipFg,
                background: chipBg,
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
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lastVisit,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              UrduHelpSuffix(urduText: lastVisitUrdu),
            ],
          ),
          if (overdue) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: FilledButton.icon(
                onPressed: () => _visitStub(context),
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
          if (today) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: FilledButton.icon(
                onPressed: () => _visitStub(context),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(Icons.play_arrow_rounded, size: 22.sp),
                label: Text(
                  'Start Visit',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          if (upcoming) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton.icon(
                onPressed: () => _visitStub(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.65)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(Icons.schedule_rounded, size: 22.sp),
                label: Text(
                  'Scheduled for Later',
                  style: TextStyle(
                    fontSize: 14.sp,
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

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.urdu,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String urdu;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 4.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 16.sp, color: foreground),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
          UrduHelpSuffix(urduText: urdu),
        ],
      ),
    );
  }
}
