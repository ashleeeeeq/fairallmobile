class Address {
  final int? id;
  final String addressableType;
  final int addressableId;
  final String? street;
  final String? barangay;
  final String? city;
  final String? province;
  final String? zipCode;
  final String? country;

  Address({
    this.id,
    required this.addressableType,
    required this.addressableId,
    this.street,
    this.barangay,
    this.city,
    this.province,
    this.zipCode,
    this.country,
  });

  String get fullAddress {
    List<String> parts = [];
    if (street != null) parts.add(street!);
    if (barangay != null) parts.add(barangay!);
    if (city != null) parts.add(city!);
    if (province != null) parts.add(province!);
    if (zipCode != null) parts.add(zipCode!);
    if (country != null && country != 'Philippines') parts.add(country!);
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      addressableType: json['addressable_type'],
      addressableId: json['addressable_id'],
      street: json['street'],
      barangay: json['barangay'],
      city: json['city'],
      province: json['province'],
      zipCode: json['zip_code'],
      country: json['country'],
    );
  }
}
