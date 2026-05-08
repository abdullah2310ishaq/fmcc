class Endpoints {
  const Endpoints._();

  static const String googleLogin = '/api/Auth/google-login';

  // LHW profile endpoints from Postman
  static const String healthWorkerProfilePut = '/api/Profile/healthworker-profile';
  static String healthWorkerProfileGet(String userId) =>
      '/api/Profile/health-worker-profile/$userId';
}

