import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/profile/edit_profile_screen.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';

/// Full profile from API — bilingual headings (English + Urdu).
class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  static const routePath = '/profile';

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  HealthWorkerProfile? _profile;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p =
          await context.read<SessionController>().fetchHealthWorkerProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is SessionEndedFailure) {
        setState(() {
          _error = null;
          _loading = false;
        });
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.blueDark, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        title: _HeadingPair(en: 'Profile', ur: 'پروفائل'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Edit • ترمیم',
            onPressed: () => context.push(EditProfileScreen.routePath),
            icon: Icon(
              Icons.edit_rounded,
              size: 20.sp,
              color: AppColors.blueDark,
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blue,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 0.35.sh),
          const Center(child: CircularProgressIndicator(color: AppColors.blue)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          Icon(Icons.error_outline_rounded, size: 48.sp, color: AppColors.danger),
          SizedBox(height: 16.h),
          Text(
            _error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.35),
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry • دوبارہ کوشش'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
    final p = _profile;
    if (p == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 120.h),
          Text(
            'No profile data from server.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final fullName = '${p.firstName} ${p.lastName}'.trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
      children: [
        _HeroCard(profile: p, fullName: fullName.isEmpty ? '—' : fullName),
        SizedBox(height: 20.h),
        _SectionCard(
          titleEn: 'Personal',
          titleUr: 'ذاتی',
          children: [
            _FieldRow(en: 'First name', ur: 'پہلا نام', value: _val(p.firstName)),
            _FieldRow(en: 'Last name', ur: 'آخری نام', value: _val(p.lastName)),
            _FieldRow(en: 'Gender', ur: 'جنس', value: _genderLabel(p.gender)),
            _FieldRow(
              en: 'Date of birth',
              ur: 'تاریخ پیدائش',
              value: _dobLabel(p.dateOfBirth),
            ),
            _FieldRow(en: 'Age', ur: 'عمر', value: _ageLabel(p.ageYears)),
            _FieldRow(en: 'CNIC', ur: 'شناختی کارڈ', value: _val(p.cnic)),
          ],
        ),
        SizedBox(height: 14.h),
        _SectionCard(
          titleEn: 'Contact',
          titleUr: 'رابطہ',
          children: [
            _FieldRow(en: 'Email', ur: 'ای میل', value: _val(p.email)),
            _FieldRow(en: 'Phone', ur: 'فون', value: _val(p.phoneNumber)),
          ],
        ),
        SizedBox(height: 14.h),
        _SectionCard(
          titleEn: 'Professional',
          titleUr: 'پیشہ ورانہ',
          children: [
            _FieldRow(en: 'Health worker ID', ur: 'ہیلتھ ورکر آئی ڈی', value: _val(p.healthWorkerId)),
            _FieldRow(
              en: 'Education level',
              ur: 'تعلیمی معیار',
              value: _preferLabel(p.educationLevelLabel, p.educationLevelId),
            ),
            _FieldRow(
              en: 'LHW training certificate',
              ur: 'ایل ایچ ڈبلیو سرٹیفکیٹ',
              value: _val(p.lhwTrainingCertificate),
            ),
            _FieldRow(
              en: 'Verified',
              ur: 'تصدیق شدہ',
              value: p.isVerified ? 'Yes / ہاں' : 'No / نہیں',
            ),
            _FieldRow(en: 'Joined', ur: 'شمولیت', value: _joinedLabel(p.joinedDate)),
          ],
        ),
        SizedBox(height: 14.h),
        _SectionCard(
          titleEn: 'Location',
          titleUr: 'مقام',
          children: [
            _FieldRow(
              en: 'Province',
              ur: 'صوبہ',
              value: _preferLabel(p.provinceLabel, p.provinceId),
            ),
            _FieldRow(
              en: 'District',
              ur: 'ضلع',
              value: _preferLabel(p.districtLabel, p.districtId),
            ),
            _FieldRow(
              en: 'Tehsil',
              ur: 'تحصیل',
              value: _preferLabel(p.tehsilLabel, p.tehsilId),
            ),
            _FieldRow(en: 'Address', ur: 'پتہ', value: _val(p.address)),
          ],
        ),
        if (p.approxPatientsPerDay != null || p.salary != null) ...[
          SizedBox(height: 14.h),
          _SectionCard(
            titleEn: 'Additional',
            titleUr: 'اضافی',
            children: [
              if (p.approxPatientsPerDay != null)
                _FieldRow(
                  en: 'Patients per day (approx.)',
                  ur: 'روزانہ مریض (تقریباً)',
                  value: '${p.approxPatientsPerDay}',
                ),
              if (p.salary != null)
                _FieldRow(
                  en: 'Salary',
                  ur: 'تنخواہ',
                  value: _SalaryFmt.format(p.salary!),
                ),
            ],
          ),
        ],
        SizedBox(height: 12.h),
      ],
    );
  }

  static String _val(String? s) {
    if (s == null || s.trim().isEmpty) return '—';
    return s.trim();
  }

  static String _dobLabel(DateTime? d) {
    if (d == null) return '—';
    return formatIsoDateOnly(d);
  }

  static String _ageLabel(int? age) {
    if (age == null || age < 0) return '—';
    return '$age';
  }

  static String _genderLabel(String g) {
    final u = g.trim().toUpperCase();
    switch (u) {
      case 'M':
        return 'Male / مرد';
      case 'F':
        return 'Female / عورت';
      case '':
        return '—';
      default:
        return g.trim();
    }
  }

  static String _joinedLabel(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return '—';

    final dt = DateTime.tryParse(s);
    if (dt == null) return s; // fallback: show raw string

    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthShort(local.month);
    final year = local.year.toString();

    final hour12 = ((local.hour + 11) % 12) + 1;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    // Example: 08 May 2026 • 09:47 PM
    return '$day $month $year • ${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }

  static String _monthShort(int m) {
    switch (m) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  static String _preferLabel(String label, int id) {
    final l = label.trim();
    if (l.isNotEmpty) return l;
    if (id > 0) return 'ID $id';
    return '—';
  }
}

class _SalaryFmt {
  static String format(double s) {
    final t = s.truncateToDouble();
    if (t == s) return t.toInt().toString();
    return s.toStringAsFixed(2);
  }
}

class _HeadingPair extends StatelessWidget {
  const _HeadingPair({required this.en, required this.ur});

  final String en;
  final String ur;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          en,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text('·', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
        ),
        Text(
          ur,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.fullName});

  final HealthWorkerProfile profile;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final url = profile.profileImageUrl?.trim();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 38.r,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: CircleAvatar(
              radius: 34.r,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: url != null && url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url,
                        width: 68.r,
                        height: 68.r,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => SizedBox(
                          width: 68.r,
                          height: 68.r,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 36.sp,
                          color: AppColors.blue,
                        ),
                      )
                    : Icon(Icons.person_rounded, size: 36.sp, color: AppColors.blue),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.isVerified ? 'Verified account' : 'Pending verification',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                    Text(
                      profile.isVerified ? 'تصدیق شدہ اکاؤنٹ' : 'تصدیق زیر التواء',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.titleEn,
    required this.titleUr,
    required this.children,
  });

  final String titleEn;
  final String titleUr;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleEn,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Flexible(
                  child: Text(
                    titleUr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 22.h, color: AppColors.border),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.en,
    required this.ur,
    required this.value,
  });

  final String en;
  final String ur;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: Text(
                  en,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                flex: 1,
                child: Text(
                  ur,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
