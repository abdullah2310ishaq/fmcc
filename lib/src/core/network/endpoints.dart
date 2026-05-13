/// HTTP paths used by the app.
///
/// **PatientController** (`/api/Patient/…`) — currently wired on the API (see
/// `MedicalApi/Controllers/PatientController.cs`):
/// - `GET /api/Patient/{patientId}` — profile
/// - `POST /api/Patient` — create patient
/// - `PUT /api/Patient` — update patient
/// - `GET /api/Patient/complete-history/{patientId}` — bundled history
/// - `PUT /api/Patient/medicalhistory` — update medical row (**needs `id`**)
/// - `PUT /api/Patient/surgicalhistory` — update surgical row (**needs `id`**)
/// - `PUT /api/Patient/drughistory` — update drug row (**needs `id`**)
/// - `PUT /api/Patient/baselinelifestyle` — update baseline lifestyle
/// - `GET /api/Patient/visits/{patientId}/` — visit list
/// - `POST /api/Patient/visit` — create visit
/// - `PUT /api/Patient/visit` — update visit
///
/// **Not** exposed on that controller right now (commented in API): POST for
/// medical/surgical/drug/baseline single-resource creates, GET per-resource history,
/// POST baseline create. Do not call those from the client until the backend restores them.
class Endpoints {
  const Endpoints._();

  static const String googleLogin = '/api/Auth/google-login';
  static const String refreshToken = '/api/Auth/refresh-token';

  // LHW profile endpoints from Postman
  static const String healthWorkerProfilePut = '/api/Profile/healthworker-profile';
  static String healthWorkerProfileGet(String userId) =>
      '/api/Profile/health-worker-profile/$userId';

  // Reference (dropdown) endpoints
  static const String educationLevels = '/api/Reference/education-levels';
  static const String provinces = '/api/Reference/provinces';
  static String districts(int provinceId) => '/api/Reference/districts/$provinceId';
  static String tehsils(int provinceId, int districtId) =>
      '/api/Reference/tehsils/$provinceId/$districtId';

  /// [healthWorkerId] = profile `healthWorkerId` (LHW code). Use [AppSession.healthWorkerIdForPatientApis].
  static String healthWorkerDashboardStats(String healthWorkerId) =>
      '/api/HealthWorkerDashboard/${Uri.encodeComponent(healthWorkerId)}/stats';

  static String healthWorkerDashboardFollowUps(String healthWorkerId) =>
      '/api/HealthWorkerDashboard/${Uri.encodeComponent(healthWorkerId)}/followups';

  static String healthWorkerDashboardPatients(String healthWorkerId) =>
      '/api/HealthWorkerDashboard/${Uri.encodeComponent(healthWorkerId)}/patients';

  static const String patientCreate = '/api/Patient';
  static const String patientUpdate = '/api/Patient';

  static String patientById(String patientId) =>
      '/api/Patient/${Uri.encodeComponent(patientId)}';

  static String patientCompleteHistory(String patientId) =>
      '/api/Patient/complete-history/${Uri.encodeComponent(patientId)}';

  static const String patientMedicalHistoryUpsert = '/api/Patient/medicalhistory';

  static const String patientSurgicalHistoryUpsert = '/api/Patient/surgicalhistory';

  static const String patientDrugHistoryUpsert = '/api/Patient/drughistory';

  static const String patientBaselineLifestyleUpsert = '/api/Patient/baselinelifestyle';

  static String patientVisits(String patientId) =>
      '/api/Patient/visits/${Uri.encodeComponent(patientId)}/';

  static const String maritalStatuses = '/api/Reference/marital-statuses';
  static const String medicalConditions = '/api/Reference/medical-conditions';
  static const String visitTypes = '/api/Reference/visit-types';
  static const String visitStatuses = '/api/Reference/visit-statuses';
  static const String visitActions = '/api/Reference/visit-actions';
  static const String symptoms = '/api/Reference/symptoms';
  static const String surgicalProcedures = '/api/Reference/surgical-procedures';
  static const String medicineCategories = '/api/Reference/medicine-categories';
  static const String physicalActivityLevels = '/api/Reference/physical-activity-levels';
  static const String adherenceLevels = '/api/Reference/adherence-levels';
  static const String complianceLevels = '/api/Reference/compliance-levels';

  static const String patientVisitCreate = '/api/Patient/visit';
  static const String patientVisitUpdate = '/api/Patient/visit';
}

