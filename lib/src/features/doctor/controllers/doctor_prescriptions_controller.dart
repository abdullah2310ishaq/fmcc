import 'package:flutter/foundation.dart';

import 'package:doctor_app/src/core/network/api_client.dart';
import 'package:doctor_app/src/core/session/app_session.dart';
import 'package:doctor_app/src/features/doctor/api/doctor_api.dart';
import 'package:doctor_app/src/features/doctor/models/doctor_models.dart';

class DoctorPrescriptionsController extends ChangeNotifier {
  DoctorPrescriptionsController({
    required DoctorApi api,
    required ApiClient apiClient,
  })  : _api = api,
        _apiClient = apiClient;

  final DoctorApi _api;
  final ApiClient _apiClient;

  List<DoctorPrescriptionSummary> _items = const [];
  bool _loading = false;
  String? _error;

  List<DoctorPrescriptionSummary> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> refreshFromSession(AppSession session) async {
    if (session.role != UserRole.doctor) {
      _items = const [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final token = session.accessToken?.trim();
    final doctorId = session.doctorIdForApis;
    if (token == null || token.isEmpty || doctorId.isEmpty) {
      _items = const [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _api.getDoctorPrescriptions(
        doctorId: doctorId,
        bearerToken: token,
      );
    } catch (e) {
      _items = const [];
      _error = _apiClient.mapError(e).message;
    }

    _loading = false;
    notifyListeners();
  }
}
