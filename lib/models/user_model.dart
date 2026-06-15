import 'package:fairallmobile/config/app_config.dart';

class User {
  final int id;
  final String? loginId;
  final String email;
  final String? userType; // 'staff', 'beneficiary', 'donor'
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? avatarPath;

  // Relationships
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
    this.avatarPath,
    this.beneficiary,
    this.donor,
  });

  String get fullName {
    if (beneficiary != null) return beneficiary!.fullName;
    if (donor != null && donor!.fullName != null) return donor!.fullName!;
    return email.split('@').first;
  }

  String get displayName {
    String name = fullName;
    name = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isNotEmpty) {
      return name
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : word,
          )
          .join(' ');
    }
    return email;
  }

  bool get hasVerifiedEmail => emailVerifiedAt != null;

  String? getAvatarUrl() {
    if (avatarPath == null) return null;
    return '${AppConfig.baseUrl.replaceAll('/api', '')}/storage/$avatarPath';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Log the incoming JSON for debugging
    print('User.fromJson received:');
    print('   - Keys: ${json.keys}');
    print('   - Has beneficiary: ${json.containsKey('beneficiary')}');

    // Get beneficiary data - could be directly in json or nested
    Map<String, dynamic>? beneficiaryData;

    if (json['beneficiary'] != null) {
      beneficiaryData = json['beneficiary'];
      print('   - Beneficiary found directly');
    } else if (json['profile'] != null &&
        json['profile']['beneficiary'] != null) {
      beneficiaryData = json['profile']['beneficiary'];
      print('   - Beneficiary found in profile');
    } else if (json['data'] != null && json['data']['beneficiary'] != null) {
      beneficiaryData = json['data']['beneficiary'];
      print('   - Beneficiary found in data');
    }

    if (beneficiaryData != null) {
      print(
        '   - Beneficiary name: ${beneficiaryData['first_name']} ${beneficiaryData['last_name']}',
      );
    }

    return User(
      id: json['id'] ?? 0,
      loginId: json['login_id'],
      email: json['email'] ?? '',
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
      avatarPath: json['avatar_path'],
      beneficiary: beneficiaryData != null
          ? Beneficiary.fromJson(beneficiaryData)
          : null,
      donor: json['donor'] != null ? Donor.fromJson(json['donor']) : null,
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
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? gradeLevel;
  final String? formGiven;
  final String? withDisability;
  final String? address;
  final String? schoolName;
  final String? academicYear;
  final String? programDisplay;

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
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.gradeLevel,
    this.formGiven,
    this.withDisability,
    this.address,
    this.schoolName,
    this.academicYear,
    this.programDisplay,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      sex: json['sex'] as String,
      contactNumber: json['contact_number'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      gradeLevel: json['grade_level'] as String?,
      formGiven: _stringFromApiValue(json['form_given']),
      withDisability: _disabilityFromApiValue(json['with_disability']),
      address: json['full_address'] as String?,
      schoolName: json['school_name'] as String?,
      academicYear: json['academic_year'] as String?,
      programDisplay: json['program_display'] as String?,
    );
  }

  /// API may send booleans (Laravel casts) or strings from profile updates.
  static String? _stringFromApiValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  static String? _disabilityFromApiValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 'yes' : 'no';
    return value.toString().toLowerCase();
  }
}

// Donor Model
class Donor {
  final int id;
  final int userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? organizationName;
  final String? contactNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get fullName {
    final parts = [
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName,
      lastName,
    ];
    final name = parts.join(' ').trim();
    return name.isEmpty ? null : name;
  }

  Donor({
    required this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.organizationName,
    this.contactNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    // Prefer individual name fields; fall back to full_name
    String firstName, lastName;
    String? middleName;

    if (json['first_name'] != null) {
      firstName = json['first_name'] as String;
      middleName = json['middle_name'] as String?;
      lastName = json['last_name'] as String;
    } else if (json['full_name'] != null) {
      final parts = (json['full_name'] as String).split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.last : '';
      middleName = parts.length > 2
          ? parts.sublist(1, parts.length - 1).join(' ')
          : null;
    } else {
      firstName = json['display_name'] as String? ?? '';
      lastName = '';
    }

    return Donor(
      id: json['id'],
      userId: json['user_id'],
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      organizationName: json['organization_name'] ?? json['organization'],
      contactNumber: json['contact_number'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
