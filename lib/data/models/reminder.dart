class Reminder {
  final int? id;
  final String title;
  final DateTime dueAt;
  final Duration leadTime; // alert before dueAt, e.g. 30 minutes
  final bool repeatDaily;

  const Reminder({
    this.id,
    required this.title,
    required this.dueAt,
    this.leadTime = const Duration(minutes: 30),
    this.repeatDaily = false,
  });

  DateTime get alertAt => dueAt.subtract(leadTime);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'leadMinutes': leadTime.inMinutes,
        'repeatDaily': repeatDaily ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, dynamic> m) => Reminder(
        id: m['id'] as int?,
        title: m['title'] as String,
        dueAt: DateTime.fromMillisecondsSinceEpoch(m['dueAt'] as int),
        leadTime: Duration(minutes: m['leadMinutes'] as int? ?? 30),
        repeatDaily: (m['repeatDaily'] as int? ?? 0) == 1,
      );
}
