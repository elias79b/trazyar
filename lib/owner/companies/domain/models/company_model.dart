class CompanyModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? logo;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.logo,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      website: map['website']?.toString(),
      address: map['address']?.toString(),
      logo: map['logo']?.toString(),
      isActive: map['is_active'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address,
      'logo': logo,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? logo,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}