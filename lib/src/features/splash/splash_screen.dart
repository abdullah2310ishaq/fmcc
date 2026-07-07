import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/app.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/';

  /// Total time on splash before navigating (3.5 s).
  static const Duration splashDuration = Duration(milliseconds: 3500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.85, curve: Curves.easeOutBack),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1, curve: Curves.easeOutCubic),
      ),
    );
    _navTimer = Timer(SplashScreen.splashDuration, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final session = context.read<SessionController>().state;
    context.go(sessionDestination(session));
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.dashboardChipBlueBg,
              AppColors.registrationScreenBg,
              AppColors.surface,
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24.r),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.dashboardPrimary
                                        .withValues(alpha: 0.2),
                                    blurRadius: 32,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.registrationFieldBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/medical_logo.svg',
                                width: 76.r,
                                height: 76.r,
                              ),
                            ),
                            SizedBox(height: 28.h),
                            Text(
                              'Careho Provider',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.dashboardPrimaryDark,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Community Health Worker Portal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 48.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BouncingDots(color: AppColors.dashboardPrimary),
                    SizedBox(height: 18.h),
                    Text(
                      'Loading…',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color:
                            AppColors.dashboardPrimary.withValues(alpha: 0.65),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots({required this.color});

  final Color color;

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = (_controller.value + i * 0.16) % 1.0;
            final lift = math.sin(progress * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Transform.translate(
                offset: Offset(0, -10.h * lift),
                child: Opacity(
                  opacity: 0.55 + 0.45 * lift,
                  child: Container(
                    width: 10.r,
                    height: 10.r,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
