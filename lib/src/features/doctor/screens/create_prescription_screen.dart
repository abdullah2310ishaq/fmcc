import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/controllers/prescription_form_controller.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({
    super.key,
    required this.patientId,
    required this.visitId,
    required this.patientName,
  });

  static const routePath = '/doctor/prescribe';

  final String patientId;
  final String visitId;
  final String patientName;

  @override
  State<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();

    return ChangeNotifierProvider(
      create: (_) => PrescriptionFormController(
        api: DoctorApi(session.apiClient),
        apiClient: session.apiClient,
      ),
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
                'Create prescription',
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
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Prescription saved'),
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
                          : const Text('Save prescription'),
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

/// Shared form fields for create & edit prescription screens.
class PrescriptionFormFields extends StatelessWidget {
  const PrescriptionFormFields({super.key, required this.form});

  final PrescriptionFormController form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: form.tenureInDays,
          keyboardType: TextInputType.number,
          decoration: _decoration('Tenure (days)', CupertinoIcons.calendar),
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            if (n == null || n <= 0) return 'Required';
            return null;
          },
          onChanged: (v) => form.tenureInDays = v,
        ),
        SizedBox(height: 12.h),
        TextFormField(
          initialValue: form.doctorNotes,
          maxLines: 3,
          decoration: _decoration('Doctor notes', CupertinoIcons.doc_text),
          onChanged: (v) => form.doctorNotes = v,
        ),
        SizedBox(height: 12.h),
        TextFormField(
          initialValue: form.continuedFromPrescriptionId,
          decoration: _decoration(
            'Continued from prescription ID (optional)',
            CupertinoIcons.link,
          ),
          onChanged: (v) => form.continuedFromPrescriptionId = v,
        ),
        SizedBox(height: 12.h),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            CupertinoIcons.calendar_today,
            color: AppColors.dashboardPrimary,
          ),
          title: Text(
            form.nextVisitDate == null
                ? 'Next visit date (optional)'
                : 'Next visit: ${form.nextVisitDate!.toLocal().toString().split(' ').first}',
            style: TextStyle(fontSize: 14.sp),
          ),
          trailing: form.nextVisitDate == null
              ? null
              : IconButton(
                  icon: Icon(CupertinoIcons.clear_circled, size: 20.sp),
                  onPressed: () => form.setNextVisitDate(null),
                ),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: form.nextVisitDate ?? now.add(const Duration(days: 7)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365 * 2)),
            );
            if (picked != null) form.setNextVisitDate(picked);
          },
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Text(
              'Medicines',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: form.addMedicine,
              icon: Icon(CupertinoIcons.plus_circle, size: 18.sp),
              label: const Text('Add'),
            ),
          ],
        ),
        for (var i = 0; i < form.medicines.length; i++) ...[
          SizedBox(height: 8.h),
          _MedicineCard(
            index: i,
            form: form,
            canRemove: form.medicines.length > 1,
          ),
        ],
      ],
    );
  }

  static InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.index,
    required this.form,
    required this.canRemove,
  });

  final int index;
  final PrescriptionFormController form;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final m = form.medicines[index];
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Medicine ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: () => form.removeMedicine(index),
                  icon: Icon(
                    CupertinoIcons.minus_circle,
                    color: AppColors.danger,
                    size: 20.sp,
                  ),
                ),
            ],
          ),
          TextFormField(
            initialValue: m.customMedicineName,
            decoration: const InputDecoration(labelText: 'Medicine name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) => m.customMedicineName = v,
          ),
          TextFormField(
            initialValue: m.dosageAmount,
            decoration: const InputDecoration(labelText: 'Dosage'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) => m.dosageAmount = v,
          ),
          TextFormField(
            initialValue: m.frequency,
            decoration: const InputDecoration(
              labelText: 'Frequency (e.g. 1-0-1)',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (v) => m.frequency = v,
          ),
          TextFormField(
            initialValue: m.durationInDays,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (days)'),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'Required';
              return null;
            },
            onChanged: (v) => m.durationInDays = v,
          ),
        ],
      ),
    );
  }
}
