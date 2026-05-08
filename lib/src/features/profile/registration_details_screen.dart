import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/profile/health_worker_profile_models.dart';

class RegistrationDetailsScreen extends StatefulWidget {
  const RegistrationDetailsScreen({super.key});

  static const routePath = '/registration-details';

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController(text: 'M');
  final _ageController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _educationLevelIdController = TextEditingController();
  final _trainingCertificateController = TextEditingController();
  final _provinceIdController = TextEditingController();
  final _districtIdController = TextEditingController();
  final _tehsilIdController = TextEditingController();
  final _addressController = TextEditingController();

  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _educationLevelIdController.dispose();
    _trainingCertificateController.dispose();
    _provinceIdController.dispose();
    _districtIdController.dispose();
    _tehsilIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SessionController>();
    _tryPrefill(controller);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health worker profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Fill the details to complete registration.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'First name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Last name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _genderController.text.trim().isEmpty
                            ? 'M'
                            : _genderController.text.trim().toUpperCase(),
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _genderController.text = v;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Age'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Enter valid age';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cnicController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'CNIC'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter CNIC' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Phone number'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter phone number'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _educationLevelIdController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: 'Education level id'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Enter valid educationLevelId';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _trainingCertificateController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'LHW training certificate',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter training certificate'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _provinceIdController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Province id'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Enter valid provinceId';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _districtIdController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'District id'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Enter valid districtId';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tehsilIdController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Tehsil id'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Enter valid tehsilId';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Address'),
                        maxLines: 2,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter address' : null,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final ok = _formKey.currentState?.validate() ?? false;
                          if (!ok) return;
                          setState(() => _saving = true);
                          try {
                            final userId = controller.state.userId;
                            if (userId == null || userId.trim().isEmpty) {
                              throw StateError('Missing user id. Please login again.');
                            }

                            final profile = HealthWorkerProfileUpsert(
                              userId: userId,
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              gender: _genderController.text.trim().toUpperCase(),
                              age: int.parse(_ageController.text.trim()),
                              cnic: _cnicController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                              educationLevelId:
                                  int.parse(_educationLevelIdController.text.trim()),
                              lhwTrainingCertificate:
                                  _trainingCertificateController.text.trim(),
                              provinceId: int.parse(_provinceIdController.text.trim()),
                              districtId: int.parse(_districtIdController.text.trim()),
                              tehsilId: int.parse(_tehsilIdController.text.trim()),
                              address: _addressController.text.trim(),
                            );

                            await controller.completeRegistrationDetails(profile: profile);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: Text(_saving ? 'Saving...' : 'Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _tryPrefill(SessionController controller) {
    if (_prefilled) return;
    _prefilled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final existing = await controller.fetchHealthWorkerProfile();
        if (!mounted || existing == null) return;

        _firstNameController.text = existing.firstName;
        _lastNameController.text = existing.lastName;
        _genderController.text = existing.gender.isEmpty ? 'M' : existing.gender;
        _ageController.text = existing.age == 0 ? '' : existing.age.toString();
        _cnicController.text = existing.cnic;
        _phoneController.text = existing.phoneNumber;
        _educationLevelIdController.text =
            existing.educationLevelId == 0 ? '' : existing.educationLevelId.toString();
        _trainingCertificateController.text = existing.lhwTrainingCertificate;
        _provinceIdController.text =
            existing.provinceId == 0 ? '' : existing.provinceId.toString();
        _districtIdController.text =
            existing.districtId == 0 ? '' : existing.districtId.toString();
        _tehsilIdController.text =
            existing.tehsilId == 0 ? '' : existing.tehsilId.toString();
        _addressController.text = existing.address;
        setState(() {});
      } catch (_) {
        // Ignore prefill failures; user can still fill manually.
      }
    });
  }
}

