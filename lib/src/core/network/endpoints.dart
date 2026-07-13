/// HTTP paths used by the app.
///
/// **PatientController** (`/api/Patient/…`) — currently wired on the API (see
/// `MedicalApi/Controllers/PatientController.cs`):
/// - `GET /api/Patient/{patientId}` — profile
/// - `POST /api/Patient` — create patient
/// - `PUT /api/Patient` — update patient
/// - `GET /api/Patient/complete-history/{patientId}` — bundled history
/// - `POST` / `PUT /api/Patient/medicalhistory` — create / update row (`PUT` needs `id`)
/// - `POST` / `PUT /api/Patient/surgicalhistory` — create / update (`PUT` needs `id`)
/// - `POST` / `PUT /api/Patient/drughistory` — create / update (`PUT` needs `id`)
/// - `POST` / `PUT /api/Patient/baselinelifestyle` — create / update baseline (incl. tobacco fields)
/// - `GET /api/Patient/visits/{patientId}/` — visit list
/// - `POST /api/Patient/visit` — create visit
/// - `PUT /api/Patient/visit` — update visit
/// - `DELETE /api/Patient/medicalhistory/{id}` — delete medical history row
/// - `DELETE /api/Patient/surgicalhistory/{id}` — delete surgical history row
/// - `DELETE /api/Patient/drughistory/{id}` — delete drug history row
class Endpoints {
  const Endpoints._();

  static const String googleLogin = '/api/Auth/google-login';
  static const String refreshToken = '/api/Auth/refresh-token';

  // LHW profile endpoints from Postman
  static const String healthWorkerProfilePut =
      '/api/Profile/healthworker-profile';
  static String healthWorkerProfileGet(String userId) =>
      '/api/Profile/health-worker-profile/$userId';

  static String doctorProfileGet(String userId) =>
      '/api/Profile/doctor-profile/${Uri.encodeComponent(userId)}';

  // Reference (dropdown) endpoints
  static const String educationLevels = '/api/Reference/education-levels';
  static const String provinces = '/api/Reference/provinces';
  static String districts(int provinceId) =>
      '/api/Reference/districts/$provinceId';
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

  static const String patientMedicalHistoryUpsert =
      '/api/Patient/medicalhistory';

  static String patientMedicalHistoryDelete(int id) =>
      '/api/Patient/medicalhistory/$id';

  static const String patientSurgicalHistoryUpsert =
      '/api/Patient/surgicalhistory';

  static String patientSurgicalHistoryDelete(int id) =>
      '/api/Patient/surgicalhistory/$id';

  static const String patientDrugHistoryUpsert = '/api/Patient/drughistory';

  static String patientDrugHistoryDelete(int id) =>
      '/api/Patient/drughistory/$id';

  static const String patientBaselineLifestyleUpsert =
      '/api/Patient/baselinelifestyle';

  /// Create/update meals, sleep, exercise, salt & alcohol.
  static const String patientLifestyleUpsert = '/api/Patient/lifestyle';

  static String patientLifestyle(String patientId) =>
      '/api/Patient/lifestyle/${Uri.encodeComponent(patientId)}';

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
  static const String physicalActivityLevels =
      '/api/Reference/physical-activity-levels';
  static const String exerciseLevels = '/api/Reference/exercise-levels';
  static const String adherenceLevels = '/api/Reference/adherence-levels';
  static const String complianceLevels = '/api/Reference/compliance-levels';
  static const String relationDegrees = '/api/Reference/relation-degrees';

  static const String patientFamilyRelativeCreate =
      '/api/Patient/familyhistory/relative';

  static String patientFamilyHistory(String patientId) =>
      '/api/Patient/familyhistory/${Uri.encodeComponent(patientId)}';

  static String patientFamilyRelativeConditions(int relativeId) =>
      '/api/Patient/familyhistory/relative/$relativeId/conditions';

  static String patientFamilyRelativeDelete(
    String patientId,
    int relativeId,
  ) =>
      '/api/Patient/familyhistory/relative/${Uri.encodeComponent(patientId)}/$relativeId';

  static String patientFamilyConditionDelete(
    String patientId,
    String relativeConditionId,
  ) =>
      '/api/Patient/familyhistory/condition/${Uri.encodeComponent(patientId)}/${Uri.encodeComponent(relativeConditionId)}';

  static const String patientVisitCreate = '/api/Patient/visit';
  static const String patientVisitUpdate = '/api/Patient/visit';
  static const String patientVisitInstructions = '/api/Patient/instructions';
  /// Text-only counselling list when visit BP is Controlled (GREEN).
  /// Not the pre-visit carousel (`patientVisitInstructions`).
  static const String patientCounsellingInstructions =
      '/api/Patient/counselling-instructison';

  // Doctor module (OpenAPI: MedicalApi.postman_collection.json)
  static String doctorUnassignHospital(String doctorId) =>
      '/api/Doctor/${Uri.encodeComponent(doctorId)}/unassign-hospital';

  static String doctorDashboard(String doctorId) =>
      '/api/Doctor/${Uri.encodeComponent(doctorId)}/dashboard';

  static String doctorEmergencyQueue(String doctorId) =>
      '/api/Patient/emergency-queue/${Uri.encodeComponent(doctorId)}';

  static const String doctorPrescription = '/api/Doctor/prescription';

  static String doctorPrescriptions(String doctorId) =>
      '/api/Doctor/${Uri.encodeComponent(doctorId)}/prescriptions';

  /// Full doctor record for profile screen.
  static String doctorById(String doctorId) =>
      '/api/Doctor/${Uri.encodeComponent(doctorId)}';

  static String patientPrescriptionHistory(String patientId) =>
      '/api/Patient/prescription-history/${Uri.encodeComponent(patientId)}';
}
