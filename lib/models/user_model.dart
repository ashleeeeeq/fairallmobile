class User {
  final int id;
  final String? loginId;
  final String email;
  final String? userType; // 'staff', 'beneficiary', 'donor'
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relationships
  final Staff? staff;
  final Beneficiary? beneficiary;
  final Donor? donor;

  User({
    required this.id,
    this.loginId,
    required this.email,
    this.userType,
    required this.isActive,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.staff,
    this.beneficiary,
    this.donor,
  });

  String get fullName {
    if (staff != null) return staff!.fullName;
    if (beneficiary != null) return beneficiary!.fullName;
    if (donor != null && donor!.fullName != null) return donor!.fullName!;
    return email.split('@').first;
  }

  String get displayName {
    String name = fullName; // Now this is non-nullable
    name = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isNotEmpty) {
      return name.split(' ').map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
      ).join(' ');
    }
    return email;
  }

  bool get hasVerifiedEmail => emailVerifiedAt != null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      loginId: json['login_id'],
      email: json['email'],
      userType: json['user_type'],
      isActive: json['is_active'] ?? true,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      staff: json['staff'] != null ? Staff.fromJson(json['staff']) : null,
      beneficiary: json['beneficiary'] != null ? Beneficiary.fromJson(json['beneficiary']) : null,
      donor: json['donor'] != null ? Donor.fromJson(json['donor']) : null,
    );
  }
}

// Staff Model
class Staff {
  final int id;
  final int userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final int departmentId;
  final int positionId;
  final String? contactNumber;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  Staff({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.departmentId,
    required this.positionId,
    this.contactNumber,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      departmentId: json['department_id'],
      positionId: json['position_id'],
      contactNumber: json['contact_number'],
      role: json['role'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

// Beneficiary Model
class Beneficiary {
  final int id;
  final int userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime birthDate;
  final String sex;
  final String? contactNumber;
  final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  final String? gradeLevel;
  final String? formGiven;
  final String? withDisability;

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Beneficiary({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthDate,
    required this.sex,
    this.contactNumber,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.gradeLevel,
    this.formGiven,
    this.withDisability,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      birthDate: DateTime.parse(json['birth_date']),
      sex: json['sex'],
      contactNumber: json['contact_number'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      gradeLevel: json['grade_level'],
      formGiven: json['form_given'],
      withDisability: json['with_disability'],
    );
  }
}

// Donor Model
class Donor {
  final int id;
  final int userId;
  final String? fullName;
  final String? organization;
  final String? contactNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Donor({
    required this.id,
    required this.userId,
    this.fullName,
    this.organization,
    this.contactNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      organization: json['organization'],
      contactNumber: json['contact_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}