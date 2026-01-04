import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID helper
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ==================== FOLLOW / UNFOLLOW ====================

  /// Follow a user
  Future<bool> followUser(String followedId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Prevent self-follow
    if (_currentUserId == followedId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      await _supabase.from('follows').insert({
        'follower_id': _currentUserId,
        'followed_id': followedId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } on PostgrestException catch (e) {
      // Handle duplicate follow (already following)
      if (e.code == '23505') {
        debugPrint('Already following this user');
        return false;
      }
      debugPrint('Error following user: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String followedId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', _currentUserId!)
          .eq('followed_id', followedId);
      return true;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Toggle follow status (follow if not following, unfollow if following)
  Future<bool> toggleFollow(String userId) async {
    final following = await isFollowing(userId);
    if (following) {
      await unfollowUser(userId);
      return false; // Now not following
    } else {
      await followUser(userId);
      return true; // Now following
    }
  }

  // ==================== CHECK FOLLOW STATUS ====================

  /// Check if current user is following a specific user
  Future<bool> isFollowing(String followedId) async {
    if (_currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', _currentUserId!)
          .eq('followed_id', followedId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Check if a user is following the current user
  Future<bool> isFollowedBy(String followerId) async {
    if (_currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('followed_id', _currentUserId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking followed by status: $e');
      return false;
    }
  }

  /// Check mutual follow (both users follow each other)
  Future<bool> isMutualFollow(String userId) async {
    if (_currentUserId == null) return false;

    try {
      final isFollowingThem = await isFollowing(userId);
      final isFollowedByThem = await isFollowedBy(userId);
      return isFollowingThem && isFollowedByThem;
    } catch (e) {
      debugPrint('Error checking mutual follow: $e');
      return false;
    }
  }

  // ==================== COUNT METHODS ====================

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select()
          .eq('followed_id', userId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('Error getting follower count: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  /// Get both follower and following counts at once
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final results = await Future.wait([
        getFollowerCount(userId),
        getFollowingCount(userId),
      ]);

      return {
        'followers': results[0],
        'following': results[1],
      };
    } catch (e) {
      debugPrint('Error getting follow counts: $e');
      return {
        'followers': 0,
        'following': 0,
      };
    }
  }

  // ==================== LIST METHODS ====================

  /// Get list of followers for a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            id,
            created_at,
            follower_id,
            users!follows_follower_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .eq('followed_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user == null) return null;

        return {
          'id': user['id'],
          'username': user['username'],
          'profile_pic': user['profile_pic'],
          'bio': user['bio'],
          'followed_at': item['created_at'],
        };
      }).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }

  /// Get list of users that a user is following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            id,
            created_at,
            followed_id,
            users!follows_followed_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user == null) return null;

        return {
          'id': user['id'],
          'username': user['username'],
          'profile_pic': user['profile_pic'],
          'bio': user['bio'],
          'followed_at': item['created_at'],
        };
      }).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error getting following: $e');
      return [];
    }
  }

  /// Get paginated followers list
  Future<List<Map<String, dynamic>>> getFollowersPaginated(
      String userId, {
        int page = 0,
        int limit = 20,
      }) async {
    try {
      final from = page * limit;
      final to = from + limit - 1;

      final response = await _supabase
          .from('follows')
          .select('''
            id,
            created_at,
            follower_id,
            users!follows_follower_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .eq('followed_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List).map((item) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user == null) return null;

        return {
          'id': user['id'],
          'username': user['username'],
          'profile_pic': user['profile_pic'],
          'bio': user['bio'],
          'followed_at': item['created_at'],
        };
      }).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error getting paginated followers: $e');
      return [];
    }
  }

  /// Get paginated following list
  Future<List<Map<String, dynamic>>> getFollowingPaginated(
      String userId, {
        int page = 0,
        int limit = 20,
      }) async {
    try {
      final from = page * limit;
      final to = from + limit - 1;

      final response = await _supabase
          .from('follows')
          .select('''
            id,
            created_at,
            followed_id,
            users!follows_followed_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List).map((item) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user == null) return null;

        return {
          'id': user['id'],
          'username': user['username'],
          'profile_pic': user['profile_pic'],
          'bio': user['bio'],
          'followed_at': item['created_at'],
        };
      }).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error getting paginated following: $e');
      return [];
    }
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get follow recommendations (users not yet followed)
  Future<List<Map<String, dynamic>>> getFollowRecommendations({
    int limit = 10,
  }) async {
    if (_currentUserId == null) return [];

    try {
      // Get users that current user is already following
      final followingResponse = await _supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', _currentUserId!);

      final followingIds = (followingResponse as List)
          .map((e) => e['followed_id'] as String)
          .toList();

      // Build exclude list (self + already following)
      final excludeIds = [_currentUserId!, ...followingIds];

      // Get users not in exclude list
      final response = await _supabase
          .from('users')
          .select('id, username, profile_pic, bio')
          .not('id', 'in', '(${excludeIds.join(',')})')
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get mutual friends (users followed by people you follow)
  Future<List<Map<String, dynamic>>> getMutualFriendRecommendations({
    int limit = 10,
  }) async {
    if (_currentUserId == null) return [];

    try {
      // Get users that current user follows
      final followingResponse = await _supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', _currentUserId!);

      final followingIds = (followingResponse as List)
          .map((e) => e['followed_id'] as String)
          .toList();

      if (followingIds.isEmpty) {
        return getFollowRecommendations(limit: limit);
      }

      // Get users followed by people you follow (but not yourself or already following)
      final excludeIds = [_currentUserId!, ...followingIds];

      final response = await _supabase
          .from('follows')
          .select('''
            followed_id,
            users!follows_followed_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .inFilter('follower_id', followingIds)
          .not('followed_id', 'in', '(${excludeIds.join(',')})')
          .limit(limit);

      // Remove duplicates and format
      final Map<String, Map<String, dynamic>> uniqueUsers = {};
      for (final item in response as List) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user != null && !uniqueUsers.containsKey(user['id'])) {
          uniqueUsers[user['id']] = {
            'id': user['id'],
            'username': user['username'],
            'profile_pic': user['profile_pic'],
            'bio': user['bio'],
          };
        }
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      debugPrint('Error getting mutual friend recommendations: $e');
      return [];
    }
  }

  // ==================== SEARCH ====================

  /// Search followers by username
  Future<List<Map<String, dynamic>>> searchFollowers(
      String userId,
      String query,
      ) async {
    if (query.isEmpty) return getFollowers(userId);

    try {
      final response = await _supabase
          .from('follows')
          .select('''
            id,
            created_at,
            follower_id,
            users!follows_follower_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .eq('followed_id', userId)
          .order('created_at', ascending: false);

      // Filter by username containing query
      return (response as List)
          .map((item) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user == null) return null;

        final username = (user['username'] as String?)?.toLowerCase() ?? '';
        if (!username.contains(query.toLowerCase())) return null;

        return {
          'id': user['id'],
          'username': user['username'],
          'profile_pic': user['profile_pic'],
          'bio': user['bio'],
          'followed_at': item['created_at'],
        };
      })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('Error searching followers: $e');
      return [];
    }
  }

  /// Search following by username
  Future<List<Map<String, dynamic>>> searchFollowing(
      String userId,
      String query,
      ) async {
    if (query.isEmpty) return getFollowing(userId);

    try {
      final response = await _supabase
          .from('follows')
          .select('''
            id,
            created_at,
            followed_id,
            users!follows_followed_id_fkey (
              id,
              username,
              profile_pic,
              bio
            )
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      // Filter by username containing query
      return (response as List)
          .map((item) {
        final user = item['users'] as Map<String, dynamic>?;
        if (user == null) return null;

        final username = (user['username'] as String?)?.toLowerCase() ?? '';
        if (!username.contains(query.toLowerCase())) return null;

        return {
          'id': user['id'],
          'username': user['username'],
          'profile_pic': user['profile_pic'],
          'bio': user['bio'],
          'followed_at': item['created_at'],
        };
      })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('Error searching following: $e');
      return [];
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Check follow status for multiple users at once
  Future<Map<String, bool>> getFollowStatusBatch(List<String> userIds) async {
    if (_currentUserId == null) {
      return {for (var id in userIds) id: false};
    }

    try {
      final response = await _supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', _currentUserId!)
          .inFilter('followed_id', userIds);

      final followedIds = (response as List)
          .map((e) => e['followed_id'] as String)
          .toSet();

      return {for (var id in userIds) id: followedIds.contains(id)};
    } catch (e) {
      debugPrint('Error getting batch follow status: $e');
      return {for (var id in userIds) id: false};
    }
  }

  /// Remove all followers (for account cleanup)
  Future<void> removeAllFollowers() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('followed_id', _currentUserId!);
    } catch (e) {
      debugPrint('Error removing all followers: $e');
      rethrow;
    }
  }

  /// Unfollow everyone (for account cleanup)
  Future<void> unfollowEveryone() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', _currentUserId!);
    } catch (e) {
      debugPrint('Error unfollowing everyone: $e');
      rethrow;
    }
  }
}