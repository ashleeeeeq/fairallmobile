class Guardian {
  final int id;
  final int beneficiaryId;
  final String guardianType; // 'father', 'mother', 'guardian'
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? civilStatus;
  final String? contactNumber;
  final String? highestEducation;
  final String? job;
  final String? estimatedSalary;
  final bool deceased;

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  Guardian({
    required this.id,
    required this.beneficiaryId,
    required this.guardianType,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.civilStatus,
    this.contactNumber,
    this.highestEducation,
    this.job,
    this.estimatedSalary,
    required this.deceased,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'],
      beneficiaryId: json['beneficiary_id'],
      guardianType: json['guardian_type'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      civilStatus: json['civil_status'],
      contactNumber: json['contact_number'],
      highestEducation: json['highest_education'],
      job: json['job'],
      estimatedSalary: json['estimated_salary'],
      deceased: json['deceased'] ?? false,
    );
  }
}