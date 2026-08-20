class ConsultantCompany {
  final String id;
  final String name;
  final bool isActive;
  final String? city;

  const ConsultantCompany({
    required this.id,
    required this.name,
    required this.isActive,
    this.city,
  });

  factory ConsultantCompany.fromMap(Map<String, dynamic> map) {
    return ConsultantCompany(
      id: map['id'] as String,
      name: map['name'] ?? '',
      city: map['city'],
      isActive: map['is_active'] ?? true,
    );
  }
}