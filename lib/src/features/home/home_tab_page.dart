import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/presentation/bp_reading_color.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/home/home_dashboard_controller.dart';
import 'package:doctor_app/src/features/patients/patient_directory_list_card.dart';
import 'package:doctor_app/src/features/profile/profile_view_screen.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({
    super.key,
    this.onViewAllPatients,
    this.onStartVisit,
  });

  final VoidCallback? onViewAllPatients;
  final ValueChanged<VisitPatientSeed>? onStartVisit;

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

  static String _shortDate(DateTime d) {
    final loc = d.toLocal();
    return '${loc.day} ${_month(loc)} ${loc.year}';
  }

  static String _time12h(DateTime d) {
    final loc = d.toLocal();
    var h = loc.hour;
    final m = loc.minute;
    final isPm = h >= 12;
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    final mm = m < 10 ? '0$m' : '$m';
    return '$h:$mm ${isPm ? 'PM' : 'AM'}';
  }

  static String _dueInEnglish(int days) {
    if (days <= 0) return 'Due today';
    if (days == 1) return 'Due in 1 day';
    return 'Due in $days days';
  }

  static int _calendarDaysBetween(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return bb.difference(aa).inDays;
  }

  static IconData _topicIcon(String condition) {
    final s = condition.toLowerCase();
    if (s.contains('diabet') || s.contains('glucose')) {
      return Icons.medical_services_outlined;
    }
    if (s.contains('antenatal') ||
        s.contains('pregnan') ||
        s.contains('prenatal')) {
      return Icons.pregnant_woman_rounded;
    }
    if (s.contains('post') && s.contains('op')) {
      return Icons.assignment_turned_in_outlined;
    }
    if (s.contains('hygiene') || s.contains('counsel')) {
      return Icons.health_and_safety_outlined;
    }
    if (s.contains('blood') || s.contains('bp') || s.contains('pressure')) {
      return Icons.monitor_heart_outlined;
    }
    return Icons.medical_information_outlined;
  }

  static Color _topicAccent(String condition) {
    final s = condition.toLowerCase();
    if (s.contains('diabet')) return AppColors.followAccentPurple;
    if (s.contains('antenatal') ||
        s.contains('pregnan') ||
        s.contains('prenatal')) {
      return AppColors.dashboardPrimary;
    }
    if (s.contains('post') && s.contains('op')) {
      return AppColors.followAccentGreen;
    }
    return AppColors.dashboardPrimary;
  }

  static String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static IconData _greetingIcon() {
    final h = DateTime.now().hour;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  static String _firstName(String fullName) {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    return parts.isEmpty ? '' : parts.first;
  }

  static Future<void> _showPatientDirectorySheet(
    BuildContext context, {
    VoidCallback? onViewAllPatients,
  }) {
    final dash = context.read<HomeDashboardController>();
    final patients = dash.patients;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (ctx, scroll) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 10.h),
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                    child: PatientDirectoryHeaderBanner(
                      totalCount: patients.length,
                      visibleCount: patients.length,
                    ),
                  ),
                  if (patients.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Text(
                        'No patients in directory yet.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scroll,
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (c, i) {
                          final p = patients[i];
                          return PatientDirectoryListCard(
                            patient: p,
                            onTap: () => Navigator.pop(ctx),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onViewAllPatients?.call();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dashboardPrimaryDark,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Open Patients tab',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
      child: Consumer<HomeDashboardController>(
        builder: (context, dash, _) {
          final isLhw = session.role == UserRole.ladyHealthWorker;
          final hasOverdue =
              isLhw && dash.followUps.any((f) => f.isOverdue);

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<HomeDashboardController>().refreshFromSession(
                    context.read<SessionController>().state,
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 28.h, bottom: 100.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _HomeWelcomeBanner(
                      fullName: fullName,
                      avatarLetters: avatarLetters,
                      now: now,
                      isLadyHealthWorker: isLhw,
                      onProfileTap: () =>
                          context.push(ProfileViewScreen.routePath),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  if (isLhw &&
                      dash.error != null &&
                      dash.error!.trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 16.w, 12.h),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Text(
                            dash.error!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 16.w, 0),
                    child: _StatsGrid(
                      isLadyHealthWorker: isLhw,
                      loading: dash.loading,
                      stats: dash.stats,
                      followUpsCount: dash.followUps.length,
                      onOpenDirectory: () => _showPatientDirectorySheet(
                        context,
                        onViewAllPatients: onViewAllPatients,
                      ),
                      onOpenPatientsTab: onViewAllPatients ?? () {},
                    ),
                  ),
                  SizedBox(height: 20.h),
                  const Divider(
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
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.dashboardChipBlueBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isLhw
                                    ? '${dash.followUps.length} listed'
                                    : '—',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dashboardPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        if (!isLhw)
                          Text(
                            'Follow-up queue is available for Lady Health Worker accounts.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          )
                        else if (dash.loading && dash.followUps.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            child: Center(
                              child: SizedBox(
                                width: 28.r,
                                height: 28.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.dashboardPrimary,
                                ),
                              ),
                            ),
                          )
                        else if (dash.followUps.isEmpty)
                          Text(
                            'No follow-up patients returned for your dashboard.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          )
                        else
                          ...dash.followUps.map(
                            (f) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _FollowUpCardApi(
                                data: f,
                                onStartVisit: onStartVisit,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: hasOverdue
                        ? AppColors.dashboardWarning.withValues(alpha: 0.55)
                        : AppColors.border,
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.isLadyHealthWorker,
    required this.loading,
    required this.stats,
    required this.followUpsCount,
    required this.onOpenDirectory,
    required this.onOpenPatientsTab,
  });

  final bool isLadyHealthWorker;
  final bool loading;
  final HwDashboardStats? stats;
  /// Length of [HomeDashboardController.followUps] — same queue as the list below.
  final int followUpsCount;
  final VoidCallback onOpenDirectory;
  final VoidCallback onOpenPatientsTab;

  String _num(int? v) {
    if (!isLadyHealthWorker) return '—';
    if (v != null) return '$v';
    if (loading) return '…';
    return '—';
  }

  Widget _tile(Widget child) {
    return Expanded(
      child: SizedBox(
        height: 144.h,
        child: child,
      ),
    );
  }

  Widget _footerText(String text, {Color? color, FontWeight? weight}) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? AppColors.textSecondary,
        height: 1.3,
      ),
    );
  }

  Widget _patientsTodayFooter() {
    if (!isLadyHealthWorker) {
      return _footerText('Health worker stats only');
    }
    if (stats == null && loading) {
      return SizedBox(
        width: 16.r,
        height: 16.r,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.dashboardPrimary,
        ),
      );
    }
    final diff = stats?.dailyDifference ?? 0;
    if (diff > 0) {
      return Row(
        children: [
          Icon(Icons.trending_up_rounded,
              size: 14.sp, color: AppColors.success),
          SizedBox(width: 4.w),
          Expanded(
            child: _footerText(
              '$diff more than yesterday',
              color: AppColors.success,
              weight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    if (diff < 0) {
      final down = -diff;
      return Row(
        children: [
          Icon(Icons.trending_down_rounded,
              size: 14.sp, color: AppColors.danger),
          SizedBox(width: 4.w),
          Expanded(
            child: _footerText(
              '$down fewer than yesterday',
              color: AppColors.danger,
              weight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return _footerText('Same as yesterday');
  }

  @override
  Widget build(BuildContext context) {
    // `stats.pendingFollowUps` can differ from the follow-ups API list length.
    // After load, use the list count so the stat card matches "N listed" and the cards.
    final int? pending = isLadyHealthWorker
        ? (!loading ? followUpsCount : stats?.pendingFollowUps)
        : null;
    final total = stats?.totalPatients;
    final visits = stats?.visitsThisMonth;
    final target = stats?.monthlyTarget;

    return Column(
      children: [
        Row(
          children: [
            _tile(
              _StatCard(
                title: 'Patients Today',
                value: _num(stats?.patientsToday),
                accent: AppColors.dashboardPrimary,
                icon: Icons.today_rounded,
                footer: _patientsTodayFooter(),
              ),
            ),
            SizedBox(width: 12.w),
            _tile(
              _StatCard(
                title: 'Pending Follow-ups',
                value: _num(pending),
                accent: AppColors.dashboardWarning,
                icon: Icons.pending_actions_rounded,
                footer: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14.sp, color: AppColors.dashboardWarning),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: _footerText(
                        isLadyHealthWorker ? 'Needs attention' : '—',
                        color: AppColors.dashboardWarning,
                        weight: FontWeight.w700,
                      ),
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
            _tile(
              _StatCard(
                title: 'Total Patients',
                value: _num(total),
                accent: AppColors.followAccentPurple,
                icon: Icons.groups_rounded,
                trailing: Material(
                  color: AppColors.followAccentPurple,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onOpenPatientsTab,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: EdgeInsets.all(7.r),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15.sp,
                      ),
                    ),
                  ),
                ),
                footer: _footerText(
                  'Tap card for directory',
                  color: AppColors.followAccentPurple,
                  weight: FontWeight.w700,
                ),
                onTap: isLadyHealthWorker ? onOpenDirectory : null,
              ),
            ),
            SizedBox(width: 12.w),
            _tile(
              _StatCard(
                title: 'This Month',
                value: _num(visits),
                accent: AppColors.followAccentGreen,
                icon: Icons.calendar_month_rounded,
                footer: _footerText(
                  isLadyHealthWorker && target != null && target > 0
                      ? 'of $target target'
                      : (isLadyHealthWorker ? 'Monthly visits' : '—'),
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
    required this.value,
    required this.accent,
    required this.icon,
    required this.footer,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;
  final Widget footer;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.r);
    final content = Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20.sp, color: accent),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const Spacer(),
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

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
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
        ],
      ),
    );
  }
}

class _FollowUpCardApi extends StatelessWidget {
  const _FollowUpCardApi({
    required this.data,
    required this.onStartVisit,
  });

  final HwFollowUpPatient data;
  final ValueChanged<VisitPatientSeed>? onStartVisit;

  _FollowVariant _variantFor() {
    if (data.isOverdue) return _FollowVariant.overdue;
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final next = data.nextVisitDate.toLocal();
    final nextDay = DateTime(next.year, next.month, next.day);
    if (nextDay == today) return _FollowVariant.today;
    return _FollowVariant.upcoming;
  }

  void _openVisit() {
    onStartVisit?.call(
      VisitPatientSeed(
        name: data.fullName,
        id: data.displayId,
        apiPatientId: data.patientId,
        age: data.age,
        gender: data.gender,
        lastVisit: HomeTabPage._shortDate(data.lastVisitDate),
        openedFromFollowUpList: true,
      ),
    );
  }

  Widget _lastVisitRichText() {
    final secondary = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.35,
    );
    final bold = secondary.copyWith(fontWeight: FontWeight.w800);
    final buf = StringBuffer(
      'Last visit: ${HomeTabPage._shortDate(data.lastVisitDate)} — ',
    );
    final reason = (data.lastVisitReason ?? '').trim();
    buf.write(reason.isNotEmpty ? reason : 'follow-up');
    final children = <InlineSpan>[
      TextSpan(text: buf.toString(), style: secondary),
    ];
    if (data.systolicBP1 != null && data.diastolicBP1 != null) {
      final c = BpReadingColor.forPair(data.systolicBP1!, data.diastolicBP1!);
      children.add(TextSpan(text: ', BP ', style: secondary));
      children.add(
        TextSpan(
          text: '${data.systolicBP1}/${data.diastolicBP1}',
          style: bold.copyWith(color: c),
        ),
      );
    }
    return Text.rich(TextSpan(children: children));
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variantFor();
    final overdue = variant == _FollowVariant.overdue;
    final today = variant == _FollowVariant.today;
    final upcoming = variant == _FollowVariant.upcoming;

    final topic = data.primaryCondition.trim().isEmpty
        ? 'Follow-up'
        : data.primaryCondition;
    final topicIcon = HomeTabPage._topicIcon(data.primaryCondition);
    final accent = HomeTabPage._topicAccent(data.primaryCondition);

    final now = DateTime.now().toLocal();
    final todayDay = DateTime(now.year, now.month, now.day);
    final next = data.nextVisitDate.toLocal();
    final nextDay = DateTime(next.year, next.month, next.day);
    final dueDays = HomeTabPage._calendarDaysBetween(todayDay, nextDay);

    final timeBadge = HomeTabPage._time12h(next);
    final scheduleNote = overdue ? 'Was: $timeBadge' : null;
    final dueInLabel =
        upcoming ? HomeTabPage._dueInEnglish(dueDays) : null;

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
      avatarBg = accent.withValues(alpha: 0.12);
      avatarFg = accent;
      chipFg = accent;
      chipBg = accent.withValues(alpha: 0.12);
    } else {
      bg = AppColors.followUpcomingBg;
      borderCol = AppColors.followUpcomingBorder;
      avatarBg = accent.withValues(alpha: 0.12);
      avatarFg = accent;
      chipFg = accent;
      chipBg = accent.withValues(alpha: 0.12);
    }

    final accentBar = overdue ? AppColors.dashboardWarning : accent;

    return Material(
      color: bg,
      elevation: overdue ? 1.5 : 3,
      shadowColor: accentBar.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderCol),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5.w, color: accentBar),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
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
                                padding: EdgeInsets.all(2.5.r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          avatarFg.withValues(alpha: 0.18),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 24.r,
                                  backgroundColor: avatarBg,
                                  child: Text(
                                    data.initials,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: avatarFg,
                                    ),
                                  ),
                                ),
                              ),
                              if (overdue)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 12.r,
                                    height: 12.r,
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.surface,
                                        width: 2,
                                      ),
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
                                Text(
                                  data.fullName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.dashboardPrimaryDark,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'Age ${data.age} • ${data.gender}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (overdue)
                            _statusBadge(
                              label: 'Overdue',
                              fg: AppColors.danger,
                              bg: AppColors.danger.withValues(alpha: 0.12),
                              icon: Icons.error_outline_rounded,
                            )
                          else if (today)
                            _statusBadge(
                              label: timeBadge,
                              fg: accent,
                              bg: accent.withValues(alpha: 0.12),
                              icon: Icons.schedule_rounded,
                            )
                          else if (upcoming && dueInLabel != null)
                            _statusBadge(
                              label: dueInLabel,
                              fg: accent,
                              bg: accent.withValues(alpha: 0.14),
                              icon: Icons.event_available_rounded,
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TopicChip(
                            label: topic,
                            icon: topicIcon,
                            foreground: chipFg,
                            background: chipBg,
                          ),
                          if (scheduleNote != null)
                            Text(
                              scheduleNote,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: borderCol.withValues(alpha: 0.7),
                          ),
                        ),
                        child: _lastVisitRichText(),
                      ),
                      if (overdue) ...[
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: FilledButton.icon(
                            onPressed: _openVisit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.dashboardActionRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            icon: Icon(Icons.play_arrow_rounded, size: 22.sp),
                            label: Text(
                              'Start Visit Now',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                              ),
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
                            onPressed: _openVisit,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
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
                            onPressed: _openVisit,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: BorderSide(
                                  color: accent.withValues(alpha: 0.65)),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String label,
    required Color fg,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: fg),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeWelcomeBanner extends StatelessWidget {
  const _HomeWelcomeBanner({
    required this.fullName,
    required this.avatarLetters,
    required this.now,
    required this.isLadyHealthWorker,
    required this.onProfileTap,
  });

  final String fullName;
  final String avatarLetters;
  final DateTime now;
  final bool isLadyHealthWorker;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final greeting = HomeTabPage._timeGreeting();
    final greetingIcon = HomeTabPage._greetingIcon();
    final displayName = fullName.trim().isEmpty
        ? 'Welcome back'
        : HomeTabPage._firstName(fullName);
    final dateLine = HomeTabPage._longDate(now);

    return Material(
      elevation: 3.5,
      shadowColor: AppColors.dashboardPrimary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(24.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onProfileTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 16.w, 18.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.dashboardChipBlueBg,
                AppColors.surface,
              ],
              stops: [0.0, 0.85],
            ),
            border: Border.all(color: AppColors.registrationFieldBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.dashboardPrimary
                                    .withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            greetingIcon,
                            size: 16.sp,
                            color: AppColors.dashboardPrimary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dashboardPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dashboardPrimaryDark,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.registrationFieldBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                dateLine,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLadyHealthWorker)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dashboardPrimary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.dashboardPrimary
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'LHW',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.dashboardPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
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
                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dashboardPrimary
                              .withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28.r,
                      backgroundColor: AppColors.dashboardPrimary,
                      child: avatarLetters.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              color: AppColors.surface,
                              size: 28.sp,
                            )
                          : Text(
                              avatarLetters,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.surface,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 2.w,
                    bottom: 2.h,
                    child: Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
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
