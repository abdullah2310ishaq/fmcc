import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/auth/auth_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  static const routePath = '/role';

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(
                titleEn: 'Choose your role',
                titleUr: 'اپنا کردار منتخب کریں',
                subtitleEn: 'Select one to continue',
                subtitleUr: 'جاری رکھنے کے لیے ایک انتخاب کریں',
              ),
              const SizedBox(height: 16),
              _RoleOptionCard(
                titleEn: 'Lady Health Worker',
                titleUr: 'لیڈی ہیلتھ ورکر',
                subtitleEn: 'Request access and continue',
                subtitleUr: 'رسائی کی درخواست کریں اور آگے بڑھیں',
                icon: Icons.health_and_safety_outlined,
                onTap: () async {
                  await controller.selectRole(UserRole.ladyHealthWorker);
                  if (!context.mounted) return;
                  context.go(AuthScreen.routePath);
                },
              ),
              const SizedBox(height: 12),
              _RoleOptionCard(
                titleEn: 'Doctor',
                titleUr: 'ڈاکٹر',
                subtitleEn: 'Request access and manage patients',
                subtitleUr: 'رسائی کی درخواست کریں اور مریضوں کو منظم کریں',
                icon: Icons.local_hospital_outlined,
                onTap: () async {
                  await controller.selectRole(UserRole.doctor);
                  if (!context.mounted) return;
                  context.go(AuthScreen.routePath);
                },
              ),
              const SizedBox(height: 18),
              const _FooterNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.titleEn,
    required this.titleUr,
    required this.subtitleEn,
    required this.subtitleUr,
  });

  final String titleEn;
  final String titleUr;
  final String subtitleEn;
  final String subtitleUr;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue.withValues(alpha: 0.10),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.blueDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titleEn,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                titleUr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitleEn,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                subtitleUr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.titleEn,
    required this.titleUr,
    required this.subtitleEn,
    required this.subtitleUr,
    required this.icon,
    required this.onTap,
  });

  final String titleEn;
  final String titleUr;
  final String subtitleEn;
  final String subtitleUr;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.blueDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleEn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        titleUr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'NotoNastaliqUrdu',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitleEn,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        subtitleUr,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.3,
                          fontFamily: 'NotoNastaliqUrdu',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.blueDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Tip: You can change your role later from settings.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'ٹِپ: آپ بعد میں سیٹنگز سے اپنا کردار تبدیل کر سکتے ہیں۔',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
