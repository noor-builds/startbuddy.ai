class StartupTask {
  final int id;
  final DateTime createdAt;
  final String authid;
  final int startupId;
  final String title;
  String status; // 'todo', 'in_progress', 'done'
  final String stage;  // 'idea', 'mvp', 'growth'
  final String priority; // 'low', 'medium', 'high'

  StartupTask({
    required this.id,
    required this.createdAt,
    required this.authid,
    required this.startupId,
    required this.title,
    required this.status,
    required this.stage,
    required this.priority,
  });

  factory StartupTask.fromJson(Map<String, dynamic> json) {
    return StartupTask(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      authid: json['authid'] ?? '',
      startupId: json['startup_id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? 'todo',
      stage: json['stage'] ?? 'idea',
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'authid': authid,
      'startup_id': startupId,
      'title': title,
      'status': status,
      'stage': stage,
      'priority': priority,
    };
  }
}
