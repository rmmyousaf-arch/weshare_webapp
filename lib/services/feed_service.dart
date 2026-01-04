import 'package:supabase_flutter/supabase_flutter.dart';

import '../mdel/posts.dart';

class FeedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get feed posts with pagination
  Future<List<Post>> getFeedPosts({int page = 0, int pageSize = 10}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final start = page * pageSize;
    final end = start + pageSize - 1;

    try {
      // Option 1: Using OR condition (better for small lists)
      final response = await _supabase
          .from('posts')
          .select('''
          *,
          users!posts_user_id_fkey(username, profile_pic)
        ''')
          .or('user_id.eq.$currentUserId,user_id.in.(${await _getFollowedUserIdsString(currentUserId)})')
          .order('created_at', ascending: false)
          .range(start, end);

      return await _parsePosts(response as List, currentUserId);
    } catch (e) {
      print('Error getting feed: $e');
      return [];
    }
  }
// Helper method
  Future<String> _getFollowedUserIdsString(String currentUserId) async {
    final ids = await _getFollowedUserIds(currentUserId);
    return ids.join(',');
  }
  Future<List<String>> _getFollowedUserIds(String currentUserId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', currentUserId);

      return (response as List).map((e) => e['followed_id'] as String).toList();
    } catch (e) {
      print('Error getting followed users: $e');
      return [];
    }
  }

  Future<List<Post>> _parsePosts(List response, String currentUserId) async {
    if (response.isEmpty) return [];

    final posts = <Post>[];

    for (final postData in response) {
      try {
        final userData = postData['users'];
        final postId = postData['id'] as String;

        // Check if post is liked by current user
        final isLiked = await _isPostLiked(postId, currentUserId);

        posts.add(Post.fromJson({
          ...postData,
          'username': userData?['username'] ?? 'Unknown',
          'profile_pic': userData?['profile_pic'],
          'is_liked': isLiked,
        }));
      } catch (e) {
        print('Error parsing post: $e');
        continue;
      }
    }

    return posts;
  }

  Future<bool> _isPostLiked(String postId, String userId) async {
    try {
      final response = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Like a post
  Future<void> likePost(String postId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update likes count
      await _supabase.rpc('increment_likes_count', params: {'post_id': postId});
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUserId);

      // Update likes count
      await _supabase.rpc('decrement_likes_count', params: {'post_id': postId});
    } catch (e) {
      print('Error unliking post: $e');
      rethrow;
    }
  }

  // Get single post with details
  Future<Post?> getPost(String postId) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(username, profile_pic)
          ''')
          .eq('id', postId)
          .maybeSingle();

      if (response == null) return null;

      final userData = response['users'];
      final isLiked = currentUserId != null
          ? await _isPostLiked(postId, currentUserId)
          : false;

      return Post.fromJson({
        ...response,
        'username': userData?['username'] ?? 'Unknown',
        'profile_pic': userData?['profile_pic'],
        'is_liked': isLiked,
      });
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Get user's posts
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(username, profile_pic)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final currentUserId = _supabase.auth.currentUser?.id;
      return await _parsePosts(response as List, currentUserId ?? '');
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }

  // Add comment
  Future<void> addComment(String postId, String text) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'comment_text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get comments for post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            users!comments_user_id_fkey(username, profile_pic)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', currentUserId);
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }
}