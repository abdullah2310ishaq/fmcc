import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/controllers/prescription_form_controller.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/screens/create_prescription_screen.dart';

class EditPrescriptionScreen extends StatefulWidget {
  const EditPrescriptionScreen({
    super.key,
    required this.prescriptionId,
    required this.visitId,
    required this.patientId,
    required this.patientName,
    this.initialTenureInDays = 0,
    this.initialNotes = '',
    this.continuedFromPrescriptionId,
    this.nextVisitDate,
    this.medicines = const [],
  });

  static const routePath = '/doctor/prescribe/edit';

  final String prescriptionId;
  final String visitId;
  final String patientId;
  final String patientName;
  final int initialTenureInDays;
  final String initialNotes;
  final String? continuedFromPrescriptionId;
  final DateTime? nextVisitDate;
  final List<PrescriptionMedicineInput> medicines;

  @override
  State<EditPrescriptionScreen> createState() => _EditPrescriptionScreenState();
}

class _EditPrescriptionScreenState extends State<EditPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();

    return ChangeNotifierProvider(
      create: (_) {
        final c = PrescriptionFormController(
          api: DoctorApi(session.apiClient),
          apiClient: session.apiClient,
        );
        c.loadForEdit(
          tenure: widget.initialTenureInDays,
          notes: widget.initialNotes,
          continuedFrom: widget.continuedFromPrescriptionId,
          nextVisit: widget.nextVisitDate,
          existingMedicines: widget.medicines,
        );
        return c;
      },
      child: Consumer<PrescriptionFormController>(
        builder: (context, form, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(CupertinoIcons.back, size: 22.sp),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Edit prescription',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
              ),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  Text(
                    widget.patientName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'ID: ${widget.prescriptionId}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  PrescriptionFormFields(form: form),
                  if (form.formError != null) ...[
                    SizedBox(height: 12.h),
                    Text(
                      form.formError!,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  SizedBox(
                    height: 48.h,
                    child: FilledButton(
                      onPressed: form.submitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final s = context.read<SessionController>().state;
                              final token = s.accessToken?.trim();
                              if (token == null || token.isEmpty) return;
                              try {
                                await form.submit(
                                  visitId: widget.visitId,
                                  patientId: widget.patientId,
                                  doctorId: s.doctorIdForApis,
                                  bearerToken: token,
                                  prescriptionId: widget.prescriptionId,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Prescription updated'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                context.pop(true);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dashboardPrimary,
                      ),
                      child: form.submitting
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text('Update prescription'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
