class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}

class ResetPasswordRequest {
  final String email;
  final String code;
  final String password;
  final String passwordConfirmation;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
    'password': password,
    'password_confirmation': passwordConfirmation,
  };
}

class ForgotPasswordResponse {
  final bool success;
  final String message;

  ForgotPasswordResponse({
    required this.success,
    required this.message,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}