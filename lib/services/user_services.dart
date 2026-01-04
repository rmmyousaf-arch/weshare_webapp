import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mdel/appuser.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user's full profile as Map
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Get current user as AppUser model
  Future<AppUser?> getCurrentUser() async {
    try {
      final profile = await getCurrentUserProfile();
      if (profile == null) return null;
      return AppUser.fromJson(profile);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching user by ID: $e');
      return null;
    }
  }

  // Get user's posts
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? username,
    String? bio,
    String? profilePic,
    bool? isPublic,
    String? role,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (profilePic != null) updates['profile_pic'] = profilePic;
      if (isPublic != null) updates['is_public'] = isPublic;
      if (role != null && (role == 'creator' || role == 'consumer')) {
        updates['role'] = role;
      }

      await _supabase.from('users').update(updates).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Get current user's role
  Future<String> getCurrentUserRole() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?['role'] ?? 'consumer';
    } catch (e) {
      return 'consumer';
    }
  }

  // Check if current user is creator
  Future<bool> isCreator() async {
    final role = await getCurrentUserRole();
    return role == 'creator';
  }

  // Get creator stats
  Future<Map<String, dynamic>?> getCreatorStats(String userId) async {
    try {
      final response = await _supabase
          .from('creator_stats')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching creator stats: $e');
      return null;
    }
  }

  // Get consumer stats
  Future<Map<String, dynamic>?> getConsumerStats(String userId) async {
    try {
      final response = await _supabase
          .from('consumer_stats')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching consumer stats: $e');
      return null;
    }
  }

  // Get all creators
  Future<List<Map<String, dynamic>>> getCreators({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'creator')
          .eq('is_public', true)
          .limit(limit)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching creators: $e');
      return [];
    }
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query, {String? roleFilter}) async {
    try {
      var queryBuilder = _supabase
          .from('users')
          .select()
          .ilike('username', '%$query%');

      if (roleFilter != null) {
        queryBuilder = queryBuilder.eq('role', roleFilter);
      }

      final response = await queryBuilder.limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }
}