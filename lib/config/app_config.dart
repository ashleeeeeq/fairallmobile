class AppConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String donorRegister = '/auth/donor/register';

  // Beneficiary Endpoints
  static const String beneficiaries = '/beneficiaries';
  static const String beneficiaryDetails = '/beneficiaries/{id}';
  static const String beneficiaryAcademicRecords = '/beneficiaries/{id}/academic-records';
  static const String beneficiaryGuardians = '/beneficiaries/{id}/guardians';
  static const String beneficiaryStatus = '/beneficiaries/{id}/status';
  static const String beneficiaryFFAAssessments = '/beneficiaries/{id}/ffa-assessments';
  static const String beneficiaryIntake = '/beneficiaries/{id}/intake';
  static const String beneficiaryInjuries = '/beneficiaries/{id}/injuries';

  // Forgot Password Endpoints
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resetPassword = '/auth/reset-password';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}