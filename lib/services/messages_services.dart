import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mdel/message.dart';

class MessageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from('users')
          .select('id, username, profile_pic')
          .neq('id', currentUserId ?? '')
          .ilike('username', '%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get or create conversation (always returns existing if available)
  Future<String?> getOrCreateConversation(String otherUserId) async {
    if (currentUserId == null) {
      debugPrint('Error: currentUserId is null');
      return null;
    }

    try {
      final response = await _supabase.rpc(
        'create_conversation_with_user',
        params: {'other_user_id': otherUserId},
      );

      debugPrint('Create conversation response: $response');

      if (response == null) {
        debugPrint('Error: RPC returned null');
        return null;
      }

      if (response['error'] != null) {
        debugPrint('Error from RPC: ${response['error']}');
        return null;
      }

      final conversationId = response['conversation_id'] as String;
      final isNew = response['is_new'] as bool;

      debugPrint('Conversation ID: $conversationId, Is New: $isNew');
      return conversationId;
    } catch (e, stackTrace) {
      debugPrint('Error in getOrCreateConversation: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get all conversations (unique users only)
  Future<List<Conversation>> getConversations() async {
    if (currentUserId == null) return [];

    try {
      final response = await _supabase.rpc('get_my_conversations');

      debugPrint('Get conversations response: $response');

      if (response == null) return [];

      final conversations = (response as List).map((conv) {
        return Conversation(
          id: conv['conversation_id'] ?? '',
          lastMessage: conv['last_message'],
          lastMessageAt: conv['last_message_at'] != null
              ? DateTime.parse(conv['last_message_at'])
              : DateTime.now(),
          createdAt: conv['created_at'] != null
              ? DateTime.parse(conv['created_at'])
              : DateTime.now(),
          otherUserId: conv['other_user_id'] ?? '',
          otherUsername: conv['other_username'] ?? 'Unknown',
          otherUserProfilePic: conv['other_profile_pic'],
          unreadCount: _parseUnreadCount(conv['unread_count']),
        );
      }).toList();

      // Sort by last message time (most recent first)
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      return conversations;
    } catch (e, stackTrace) {
      debugPrint('Error getting conversations: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  int _parseUnreadCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Get messages
  Future<List<Message>> getMessages(String conversationId,
      {int page = 0, int pageSize = 50}) async {
    try {
      final response = await _supabase.rpc(
        'get_messages',
        params: {
          'conv_id': conversationId,
          'page_number': page,
          'page_size': pageSize,
        },
      );

      debugPrint('Get messages response: $response');

      if (response == null) return [];

      return (response as List).map((m) {
        return Message(
          id: m['id'] ?? '',
          conversationId: m['conversation_id'] ?? '',
          senderId: m['sender_id'] ?? '',
          content: m['content'] ?? '',
          isRead: m['is_read'] ?? false,
          createdAt: m['created_at'] != null
              ? DateTime.parse(m['created_at'])
              : DateTime.now(),
          senderUsername: m['sender_username'],
          senderProfilePic: m['sender_profile_pic'],
        );
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('Error getting messages: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // Send message
  Future<Message?> sendMessage(String conversationId, String content) async {
    if (currentUserId == null || content.trim().isEmpty) return null;

    try {
      final response = await _supabase.rpc(
        'send_message',
        params: {
          'conv_id': conversationId,
          'message_content': content.trim(),
        },
      );

      debugPrint('Send message response: $response');

      if (response == null) {
        debugPrint('Error: RPC returned null');
        return null;
      }

      if (response['error'] != null) {
        debugPrint('Error from RPC: ${response['error']}');
        return null;
      }

      return Message(
        id: response['id'] ?? '',
        conversationId: response['conversation_id'] ?? '',
        senderId: response['sender_id'] ?? '',
        content: response['content'] ?? '',
        isRead: response['is_read'] ?? false,
        createdAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'])
            : DateTime.now(),
        senderUsername: response['sender_username'],
        senderProfilePic: response['sender_profile_pic'],
      );
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    try {
      final response = await _supabase.rpc(
        'mark_messages_read',
        params: {'conv_id': conversationId},
      );

      debugPrint('Mark as read response: $response');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Subscribe to new messages
  RealtimeChannel subscribeToMessages(
      String conversationId,
      void Function(Message) onNewMessage,
      ) {
    return _supabase
        .channel('messages_$conversationId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) async {
        try {
          debugPrint('New message received: ${payload.newRecord}');
          final messages =
          await getMessages(conversationId, page: 0, pageSize: 1);
          if (messages.isNotEmpty) {
            onNewMessage(messages.first);
          }
        } catch (e) {
          debugPrint('Error fetching new message: $e');
        }
      },
    )
        .subscribe();
  }

  // Subscribe to conversation updates
  RealtimeChannel subscribeToConversations(void Function() onUpdate) {
    return _supabase
        .channel('conversations_updates_${currentUserId ?? 'anon'}')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (_) => onUpdate(),
    )
        .subscribe();
  }
}