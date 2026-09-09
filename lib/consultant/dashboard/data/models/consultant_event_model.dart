class ConsultantEvent {
  final String id;
  final String consultantUserId;
  final String? companyId;

  final String title;
  final String? description;

  final DateTime eventDate;

  final String? startTime;
  final String? endTime;

  final bool isAllDay;

  final String status;
  final String priority;

  final String? companyName;

  const ConsultantEvent({
    required this.id,
    required this.consultantUserId,
    this.companyId,
    required this.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    required this.isAllDay,
    required this.status,
    required this.priority,
    this.companyName,
  });

  factory ConsultantEvent.fromMap(Map<String, dynamic> map) {
    String? companyName;

    final company = map['companies'];

    if (company is Map) {
      companyName = company['name']?.toString();
    }

    return ConsultantEvent(
      id: map['id'].toString(),
      consultantUserId: map['consultant_user_id'].toString(),
      companyId: map['company_id']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      eventDate: DateTime.parse(map['event_date'].toString()),
      startTime: map['start_time']?.toString(),
      endTime: map['end_time']?.toString(),
      isAllDay: map['is_all_day'] == true,
      status: map['status']?.toString() ?? 'pending',
      priority: map['priority']?.toString() ?? 'normal',
      companyName: companyName,
    );
  }

  bool get isPending => status == 'pending';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get isHighPriority => priority == 'high';
}
