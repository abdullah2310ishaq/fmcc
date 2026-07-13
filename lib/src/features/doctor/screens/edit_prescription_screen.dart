import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/controllers/prescription_form_controller.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';
import 'package:doctor_app/src/features/doctor/widgets/prescription_form_widgets.dart';

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
            backgroundColor: AppColors.dashboardBackground,
            body: Column(
              children: [
                PrescriptionPatientBanner(
                  patientName: widget.patientName,
                  title: 'Edit prescription',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PrescriptionFormBody(
                      form: form,
                      errorText: form.formError,
                    ),
                  ),
                ),
                PrescriptionSaveBar(
                  label: 'Update prescription',
                  submitting: form.submitting,
                  onPressed: form.submitting
                      ? null
                      : () => _submit(context, form),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    PrescriptionFormController form,
  ) async {
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
      final message = e is ApiFailure
          ? e.message
          : (form.formError ?? 'Could not update prescription.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
