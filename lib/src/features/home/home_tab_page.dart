import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/home/health_worker_dashboard_models.dart';
import 'package:doctor_app/src/features/home/home_dashboard_controller.dart';
import 'package:doctor_app/src/features/profile/profile_view_screen.dart';
import 'package:doctor_app/src/features/shell/tabs/visit_tab_page.dart';
import 'package:doctor_app/src/widgets/urdu_help_suffix.dart';

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

  static String _dueInUrdu(int days) {
    if (days <= 0) return 'آج یا گزر چکا۔';
    return '$days دن بعد مقررہ';
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

  static String _topicUrduHint(String condition) {
    final s = condition.toLowerCase();
    if (s.contains('diabet')) return 'ذیابیطس / شوگر متعلقہ۔';
    if (s.contains('antenatal') || s.contains('pregnan')) {
      return 'حمل کی دیکھ بھال۔';
    }
    if (s.contains('blood') || s.contains('bp')) {
      return 'بلڈ پریشر متعلقہ۔';
    }
    return 'کلینکل فالو اپ۔';
  }

  static String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
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
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                    child: Text(
                      'All patients (${patients.length})',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
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
                      child: ListView.builder(
                        controller: scroll,
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                        itemCount: patients.length,
                        itemBuilder: (c, i) {
                          final p = patients[i];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.dashboardPrimary.withValues(alpha: 0.12),
                              child: Text(
                                p.initials,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dashboardPrimary,
                                ),
                              ),
                            ),
                            title: Text(
                              p.fullName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${p.age} yrs • ${p.gender} • ${p.displayId}\n${p.primaryCondition}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            isThreeLine: true,
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
                                    : '${_timeGreeting()}, $fullName',
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
                                  border: Border.all(
                                      color: AppColors.surface, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  SizedBox(height: 20.h),
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
                                    isLhw
                                        ? '${dash.followUps.length} listed'
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dashboardPrimary,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  const UrduHelpSuffix(
                                    urduText:
                                        'فالو اپ فہرست میں موجود اندراجات کی تعداد۔',
                                  ),
                                ],
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
    required this.onOpenDirectory,
    required this.onOpenPatientsTab,
  });

  final bool isLadyHealthWorker;
  final bool loading;
  final HwDashboardStats? stats;
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

  Widget _patientsTodayFooter() {
    if (!isLadyHealthWorker) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Health worker stats only',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    if (stats == null && loading) {
      return Row(
        children: [
          SizedBox(
            width: 16.r,
            height: 16.r,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.dashboardPrimary,
            ),
          ),
        ],
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
            child: Text(
              '↑ $diff from yesterday',
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
            urduText: 'کل کے مقابلے میں آج زیادہ مریض۔',
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
            child: Text(
              '↓ $down from yesterday',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
          UrduHelpSuffix(
            urduText: 'کل کے مقابلے میں آج کم مریض۔',
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            'Same as yesterday',
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
          urduText: 'کل جتنے ہی آج۔',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = stats?.pendingFollowUps;
    final total = stats?.totalPatients;
    final visits = stats?.visitsThisMonth;
    final target = stats?.monthlyTarget;

    return Column(
      children: [
        Row(
          children: [
            _tile(
              _StatCard(
                title: 'PATIENTS TODAY',
                titleUrdu: 'آج کے مریض',
                value: _num(stats?.patientsToday),
                valueColor: AppColors.textPrimary,
                footer: _patientsTodayFooter(),
              ),
            ),
            SizedBox(width: 12.w),
            _tile(
              _StatCard(
                title: 'PENDING FOLLOW-UPS',
                titleUrdu: 'زیر التواء فالو اپ',
                value: _num(pending),
                valueColor: AppColors.dashboardWarning,
                footer: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14.sp, color: AppColors.dashboardWarning),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        isLadyHealthWorker ? 'Needs attention' : '—',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dashboardWarning,
                        ),
                      ),
                    ),
                    const UrduHelpSuffix(
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
            _tile(
              _StatCard(
                title: 'TOTAL PATIENTS',
                titleUrdu: 'کل مریض',
                value: _num(total),
                valueColor: AppColors.dashboardPrimary,
                border:
                    Border.all(color: AppColors.dashboardPrimary, width: 1.5),
                titleColor: AppColors.dashboardPrimary,
                trailing: Material(
                  color: AppColors.dashboardPrimaryDark,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onOpenPatientsTab,
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
                        'Tap card for directory',
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
                      urduText: 'فہرست دیکھنے کے لیے کارڈ تھپتھپائیں۔',
                    ),
                  ],
                ),
                onTap: isLadyHealthWorker ? onOpenDirectory : null,
              ),
            ),
            SizedBox(width: 12.w),
            _tile(
              _StatCard(
                title: 'THIS MONTH',
                titleUrdu: 'اس مہینے',
                value: _num(visits),
                valueColor: AppColors.textPrimary,
                footer: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLadyHealthWorker && target != null && target > 0
                            ? 'of $target target'
                            : (isLadyHealthWorker ? 'Monthly visits' : '—'),
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
                      urduText: isLadyHealthWorker && target != null && target > 0
                          ? 'ماہانہ ہدف کے مقابلے میں۔'
                          : 'ماہانہ وزٹس۔',
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: titleColor ?? AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
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

  String _lastVisitLine() {
    final buf = StringBuffer(
      'Last visit: ${HomeTabPage._shortDate(data.lastVisitDate)} — ',
    );
    final reason = (data.lastVisitReason ?? '').trim();
    if (reason.isNotEmpty) {
      buf.write(reason);
    } else {
      buf.write('follow-up');
    }
    if (data.systolicBP1 != null && data.diastolicBP1 != null) {
      buf.write(', BP ${data.systolicBP1}/${data.diastolicBP1}');
    }
    return buf.toString();
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
    final topicUrdu = HomeTabPage._topicUrduHint(data.primaryCondition);

    final now = DateTime.now().toLocal();
    final todayDay = DateTime(now.year, now.month, now.day);
    final next = data.nextVisitDate.toLocal();
    final nextDay = DateTime(next.year, next.month, next.day);
    final dueDays = HomeTabPage._calendarDaysBetween(todayDay, nextDay);

    final timeBadge = HomeTabPage._time12h(next);
    final scheduleNote = overdue ? 'Was: $timeBadge' : null;
    final scheduleUrdu = overdue ? 'مقررہ وقت۔' : null;
    final dueInLabel =
        upcoming ? HomeTabPage._dueInEnglish(dueDays) : null;
    final dueInUrdu =
        upcoming ? HomeTabPage._dueInUrdu(dueDays) : null;

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

    final subtitle =
        'Age ${data.age} • ${data.gender} • ID: ${data.displayId}';

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
                      data.initials,
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
                                data.fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const UrduHelpSuffix(urduText: 'مریض کا نام۔'),
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
                                const UrduHelpSuffix(
                                  urduText: 'وقت گزر چکا ہے۔',
                                ),
                              ],
                            ),
                          )
                        else if (today)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeBadge,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                                UrduHelpSuffix(
                                  urduText: 'آج کا مقررہ وقت۔',
                                ),
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
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dueInLabel,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                                UrduHelpSuffix(urduText: dueInUrdu),
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
                label: topic,
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
                      scheduleNote,
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
                  _lastVisitLine(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              const UrduHelpSuffix(urduText: 'پچھلا وزٹ (سرور ڈیٹا)۔'),
            ],
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
                  side: BorderSide(color: accent.withValues(alpha: 0.65)),
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
    );
  }
}
