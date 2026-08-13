enum StudentRecentActivityType {
  subtopicOpened,
  subtopicCompleted,
  topicCompleted,
}

class StudentRecentActivity {
  final StudentRecentActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  const StudentRecentActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  String get label {
    switch (type) {
      case StudentRecentActivityType.subtopicOpened:
        return 'STUDIED';
      case StudentRecentActivityType.subtopicCompleted:
        return 'COMPLETED';
      case StudentRecentActivityType.topicCompleted:
        return 'TOPIC COMPLETED';
    }
  }
}
