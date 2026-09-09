class ConsultantNote {
  final String id;
  final String consultantUserId;

  final String title;
  final String content;

  final bool isPinned;
  final bool isArchived;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsultantNote({
    required this.id,
    required this.consultantUserId,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsultantNote.fromMap(Map<String, dynamic> map) {
    return ConsultantNote(
      id: map['id'].toString(),
      consultantUserId: map['consultant_user_id'].toString(),
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      isPinned: map['is_pinned'] == true,
      isArchived: map['is_archived'] == true,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }
}
