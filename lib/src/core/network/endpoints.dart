class Endpoints {
  const Endpoints._();

  static const String googleLogin = '/api/Auth/google-login';

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
}

