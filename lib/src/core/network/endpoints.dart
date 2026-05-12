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

