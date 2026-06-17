class StartupDocument {
  final int id;
  final DateTime createdAt;
  final String authid;
  final int startupId;
  final String title;
  final String type; // 'pitch_deck', 'business_plan', 'problem_solution', 'model_canvas', 'validation_report', 'user_persona', 'gtm_strategy', 'blueprint'
  final String? content; // markdown text
  final String? fileUrl; // URL to PDF

  StartupDocument({
    required this.id,
    required this.createdAt,
    required this.authid,
    required this.startupId,
    required this.title,
    required this.type,
    this.content,
    this.fileUrl,
  });

  factory StartupDocument.fromJson(Map<String, dynamic> json) {
    return StartupDocument(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      authid: json['authid'] ?? '',
      startupId: json['startup_id'] ?? json['startup_id'] ?? 0,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      content: json['content'],
      fileUrl: json['file_url'] ?? json['validation_report'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'authid': authid,
      'startup_id': startupId,
      'title': title,
      'type': type,
      'content': content,
      'file_url': fileUrl,
    };
  }
}
