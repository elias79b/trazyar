class CompanyModel {

  final String id;
  final String name;
  final String? city;
  final bool isActive;


  CompanyModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.city,
  });


  factory CompanyModel.fromMap(
      Map<String,dynamic> map){

    return CompanyModel(
      id: map['id'],
      name: map['name'] ?? '',
      city: map['city'],
      isActive:
      map['is_active'] ?? true,
    );

  }

}