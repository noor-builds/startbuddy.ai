class StartupChat {
  final String id;
  final DateTime createdAt;
  final String authid;
  final int startupId;
  final String title;

  StartupChat({
    required this.id,
    required this.createdAt,
    required this.authid,
    required this.startupId,
    required this.title,
  });

  factory StartupChat.fromJson(Map<String, dynamic> json) {
    return StartupChat(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      authid: json['authid'] ?? '',
      startupId: json['startup_id'] ?? 0,
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'authid': authid,
      'startup_id': startupId,
      'title': title,
    };
  }
}

class ChatMessage {
  final String id;
  final DateTime createdAt;
  final String chatId;
  final String sender; // 'user', 'ai'
  final String content;

  ChatMessage({
    required this.id,
    required this.createdAt,
    required this.chatId,
    required this.sender,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      chatId: json['chat_id'] ?? '',
      sender: json['sender'] ?? 'user',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'chat_id': chatId,
      'sender': sender,
      'content': content,
    };
  }
}
