class AppConfig {
  //static const String baseUrl = 'http://10.0.2.2:8000/api';
  //static const String baseUrl = 'http://localhost:8000/api';
  static const String baseUrl = 'http://192.168.100.9:8000/api';
  //static const String baseUrl = 'https://fairall.site/api';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String donorRegister = '/auth/donor/register';
  static const String user = '/user';

  // Profile update endpoints
  static const String updateProfile = '/profile';
  static const String updateBeneficiary = '/profile/beneficiary';
  static const String updateDonor = '/profile/donor';

  // Avatar endpoints
  static const String uploadAvatar = '/profile/avatar';
  static const String deleteAvatar = '/profile/avatar';

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