class CompanyModel {
  final String id;
  final String name;
  final String? city;
  final String? province;
  final bool isActive;

  const CompanyModel({
    required this.id,
    required this.name,
    this.city,
    this.province,
    required this.isActive,
  });

  factory CompanyModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      city: map['city'],
      province: map['province'],
      isActive: map['is_active'] ?? true,
    );
  }
}