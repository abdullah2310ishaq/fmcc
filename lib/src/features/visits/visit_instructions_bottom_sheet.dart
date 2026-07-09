import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/visits/visit_instruction_models.dart';

/// Returns `true` when the user checked "Don't show again".
Future<bool?> showVisitInstructionsBottomSheet(
  BuildContext context, {
  required List<VisitInstruction> instructions,
}) {
  if (instructions.isEmpty) return Future.value(false);

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) {
      return _VisitInstructionsSheet(instructions: instructions);
    },
  );
}

class _VisitInstructionsSheet extends StatefulWidget {
  const _VisitInstructionsSheet({required this.instructions});

  final List<VisitInstruction> instructions;

  @override
  State<_VisitInstructionsSheet> createState() =>
      _VisitInstructionsSheetState();
}

class _VisitInstructionsSheetState extends State<_VisitInstructionsSheet> {
  late final PageController _pageController;
  int _page = 0;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLast => _page >= widget.instructions.length - 1;

  void _onNext() {
    if (_isLast) {
      Navigator.of(context).pop(_dontShowAgain);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // Nearly full-screen sheet so instruction images read clearly.
    final height = screen.height * 0.94;

    return SafeArea(
      top: false,
      child: Container(
        height: height,
        margin: EdgeInsets.only(bottom: 6.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.dashboardChipBlueBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 20.sp,
                      color: AppColors.dashboardPrimary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit instructions',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dashboardPrimaryDark,
                          ),
                        ),
                        Text(
                          'Quick guide before logging this visit',
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
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.instructions.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final item = widget.instructions[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: ColoredBox(
                              color: AppColors.dashboardChipBlueBg
                                  .withValues(alpha: 0.35),
                              child: _InstructionImage(instruction: item),
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          item.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.instructions.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: active ? 18.w : 7.w,
                  height: 7.h,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.dashboardPrimary
                        : AppColors.dashboardPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    activeColor: AppColors.dashboardPrimary,
                    onChanged: (v) =>
                        setState(() => _dontShowAgain = v ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _dontShowAgain = !_dontShowAgain),
                      child: Text(
                        "Don't show these instructions next time",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: FilledButton(
                onPressed: _onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashboardPrimary,
                  foregroundColor: AppColors.surface,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  _isLast ? 'Got it — start visit' : 'Next',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionImage extends StatelessWidget {
  const _InstructionImage({required this.instruction});

  final VisitInstruction instruction;

  @override
  Widget build(BuildContext context) {
    final url = instruction.imageUrl;
    if (url == null) {
      return Center(
        child: Icon(
          Icons.health_and_safety_outlined,
          size: 72.sp,
          color: AppColors.dashboardPrimary.withValues(alpha: 0.55),
        ),
      );
    }

    final widthPx =
        (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context))
            .round();

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      memCacheWidth: widthPx,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => Center(
        child: SizedBox(
          width: 28.r,
          height: 28.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.dashboardPrimary,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 56.sp,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
