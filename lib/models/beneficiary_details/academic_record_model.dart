class AcademicRecord {
  final int id;
  final int beneficiaryId;
  final String schoolName;
  final String academicYear;
  final String term;
  final String gradeLevel;
  final double? gwa;
  final double? schoolAttendance;
  final List<SubjectGrade>? subjects;

  AcademicRecord({
    required this.id,
    required this.beneficiaryId,
    required this.schoolName,
    required this.academicYear,
    required this.term,
    required this.gradeLevel,
    this.gwa,
    this.schoolAttendance,
    this.subjects,
  });

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    return AcademicRecord(
      id: json['id'],
      beneficiaryId: json['beneficiary_id'],
      schoolName: json['school_name'] ?? 'N/A',
      academicYear: json['academic_year'] ?? 'N/A',
      term: json['term'] ?? 'N/A',
      gradeLevel: json['grade_level'] ?? 'N/A',
      gwa: json['gwa'] != null ? double.parse(json['gwa'].toString()) : null,
      schoolAttendance: json['school_attendance'] != null
          ? double.parse(json['school_attendance'].toString())
          : null,
      subjects: json['subjects'] != null
          ? (json['subjects'] as List)
                .map((s) => SubjectGrade.fromJson(s))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beneficiary_id': beneficiaryId,
      'school_name': schoolName,
      'academic_year': academicYear,
      'term': term,
      'grade_level': gradeLevel,
      'gwa': gwa,
      'school_attendance': schoolAttendance,
      'subjects': subjects?.map((s) => s.toJson()).toList(),
    };
  }
}

class SubjectGrade {
  final int id;
  final int academicRecordId;
  final String subjectName;
  final double grade;

  SubjectGrade({
    required this.id,
    required this.academicRecordId,
    required this.subjectName,
    required this.grade,
  });

  factory SubjectGrade.fromJson(Map<String, dynamic> json) {
    return SubjectGrade(
      id: json['id'],
      academicRecordId: json['academic_record_id'] ?? json['academicRecordId'],
      subjectName: json['subject_name'] ?? 'N/A',
      grade: json['grade'] != null
          ? double.parse(json['grade'].toString())
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academic_record_id': academicRecordId,
      'subject_name': subjectName,
      'grade': grade,
    };
  }
}
