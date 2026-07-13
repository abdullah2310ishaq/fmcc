import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/controllers/prescription_form_controller.dart';
import 'package:doctor_app/src/features/doctor/controllers/doctor_prescriptions_controller.dart';
import 'package:doctor_app/src/features/doctor/widgets/doctor_navigation_guard.dart';
import 'package:doctor_app/src/features/doctor/widgets/prescription_form_widgets.dart';

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
      create: (_) {
        final form = PrescriptionFormController(
          api: DoctorApi(session.apiClient),
          apiClient: session.apiClient,
        );
        final token = session.state.accessToken?.trim() ?? '';
        if (token.isNotEmpty) {
          form.loadActiveMedicines(token);
        }
        return form;
      },
      child: Consumer<PrescriptionFormController>(
        builder: (context, form, _) {
          Future<void> onBack() => DoctorNavigationGuard.popWithDiscardCheck(
                context,
                hasUnsavedChanges: form.hasUnsavedChanges,
              );

          return PopScope(
            canPop: !form.hasUnsavedChanges,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              await onBack();
            },
            child: Scaffold(
              backgroundColor: AppColors.dashboardBackground,
              body: Column(
                children: [
                  PrescriptionPatientBanner(
                    patientName: widget.patientName,
                    onBack: onBack,
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
                  label: 'Save prescription',
                  submitting: form.submitting,
                  onPressed: () => _submit(context, form),
                ),
              ],
            ),
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
      );
      if (!context.mounted) return;
      await context.read<DoctorPrescriptionsController>().refreshFromSession(s);
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
      final message = e is ApiFailure
          ? e.message
          : (form.formError ?? 'Could not save prescription.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
