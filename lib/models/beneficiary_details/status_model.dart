class BeneficiaryStatus {
  final int id;
  final int beneficiaryId;
  final int statusTypeId;
  final DateTime startDate;
  final DateTime? endDate;
  final String? statusName;

  BeneficiaryStatus({
    required this.id,
    required this.beneficiaryId,
    required this.statusTypeId,
    required this.startDate,
    this.endDate,
    this.statusName,
  });

  factory BeneficiaryStatus.fromJson(Map<String, dynamic> json) {
    return BeneficiaryStatus(
      id: json['id'],
      beneficiaryId: json['beneficiary_id'],
      statusTypeId: json['beneficiary_status_type_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      statusName: json['status_name'],
    );
  }
}
