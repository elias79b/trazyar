class ActivityLogModel {

  final String title;
  final String? description;
  final String icon;
  final DateTime createdAt;


  const ActivityLogModel({
    required this.title,
    this.description,
    required this.icon,
    required this.createdAt,
  });


  factory ActivityLogModel.fromMap(
      Map<String, dynamic> map) {

    return ActivityLogModel(

      title:
      map['title'] ?? '',

      description:
      map['description'],

      icon:
      map['icon'] ?? 'info',

      createdAt:
      DateTime.parse(
        map['created_at'],
      ),

    );
  }
}