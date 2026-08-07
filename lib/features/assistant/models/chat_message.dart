import '../../../core/utils/json_helpers.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String content;
  final DateTime createdAt;

  bool get isUser => sender == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: readString(json, 'id'),
      sender: readString(json, 'sender', fallback: 'assistant'),
      content: readString(json, 'content'),
      createdAt: parseDateTime(json['createdAt'], fallback: DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? content,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatMessage &&
            other.id == id &&
            other.sender == sender &&
            other.content == content &&
            other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, sender, content, createdAt);
}
