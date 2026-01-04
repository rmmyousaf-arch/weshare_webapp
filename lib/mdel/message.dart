class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? senderUsername;
  final String? senderProfilePic;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.senderUsername,
    this.senderProfilePic,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    // Handle the joined users data
    final sender = map['users'];

    return Message(
      id: map['id'] ?? '',
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      senderUsername: sender?['username'],
      senderProfilePic: sender?['profile_pic'],
    );
  }
}

class Conversation {
  final String id;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final String otherUserId;
  final String otherUsername;
  final String? otherUserProfilePic;
  final int unreadCount;

  Conversation({
    required this.id,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    required this.otherUserId,
    required this.otherUsername,
    this.otherUserProfilePic,
    this.unreadCount = 0,
  });

  // Add factory constructor for RPC response
  factory Conversation.fromRpcResponse(Map<String, dynamic> map) {
    return Conversation(
      id: map['conversation_id'] ?? '',
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'])
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      otherUserId: map['other_user_id'] ?? '',
      otherUsername: map['other_username'] ?? 'Unknown',
      otherUserProfilePic: map['other_profile_pic'],
      unreadCount: (map['unread_count'] ?? 0) is int
          ? map['unread_count']
          : int.tryParse(map['unread_count'].toString()) ?? 0,
    );
  }
}