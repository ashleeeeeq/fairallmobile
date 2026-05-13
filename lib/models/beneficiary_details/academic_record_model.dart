class AcademicRecord {
  final int id;
  final int beneficiaryId;
  final String schoolName;
  final String academicYear;
  final String term;
  final String gradeLevel;
  final double? gwa;
  final List<SubjectGrade>? subjects;

  AcademicRecord({
    required this.id,
    required this.beneficiaryId,
    required this.schoolName,
    required this.academicYear,
    required this.term,
    required this.gradeLevel,
    this.gwa,
    this.subjects,
  });

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    return AcademicRecord(
      id: json['id'],
      beneficiaryId: json['beneficiary_id'],
      schoolName: json['school_name'],
      academicYear: json['academic_year'],
      term: json['term'],
      gradeLevel: json['grade_level'],
      gwa: json['gwa'] != null ? double.parse(json['gwa'].toString()) : null,
      subjects: json['subjects'] != null
          ? (json['subjects'] as List).map((s) => SubjectGrade.fromJson(s)).toList()
          : null,
    );
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
      academicRecordId: json['academic_record_id'],
      subjectName: json['subject_name'],
      grade: double.parse(json['grade'].toString()),
    );
  }
}