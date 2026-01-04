import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/follow_service.dart';
import '../services/user_services.dart';
import '../utils/sheared_widgets.dart';
import 'Login.dart';
import 'edit_profie.dart';
import 'comment_screen.dart';

class AppColors {
  static const primaryPink = Color(0xFFec4899);
  static const secondaryViolet = Color(0xFF8b5cf6);
  static const indigo = Color(0xFF6366f1);
  static const green = Color(0xFF22c55e);
  static const blue = Color(0xFF3b82f6);
  static const red = Color(0xFFef4444);
  static const backgroundLight = Color(0xFFf3f4f6);
  static const surfaceLight = Color(0xFFffffff);
  static const borderLight = Color(0xFFe5e7eb);
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6b7280);
  static const backgroundDark = Color(0xFF0f111a);
  static const surfaceDark = Color(0xFF161822);
  static const surfaceDark2 = Color(0xFF1e2130);
  static const borderDark = Color(0xFF374151);
  static const textPrimaryDark = Color(0xFFf9fafb);
  static const textSecondaryDark = Color(0xFF9ca3af);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366f1), Color(0xFFec4899)],
  );

  static const avatarGradient = LinearGradient(
    colors: [Color(0xFFd946ef), Color(0xFF8b5cf6), Color(0xFF3b82f6)],
  );

  static const logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8b5cf6), Color(0xFFec4899)],
  );

  static const creatorGradient = LinearGradient(
    colors: [Color(0xFF8b5cf6), Color(0xFFec4899)],
  );

  static const consumerGradient = LinearGradient(
    colors: [Color(0xFF22c55e), Color(0xFF10b981)],
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _followService = FollowService();
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userPosts = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _userService.getCurrentUserProfile();
      if (userData != null) {
        final posts = await _userService.getUserPosts(userData['id']);
        final followCounts = await _followService.getFollowCounts(userData['id']);
        final stats = userData['role'] == 'creator'
            ? await _userService.getCreatorStats(userData['id'])
            : await _userService.getConsumerStats(userData['id']);

        setState(() {
          _userData = userData;
          _userPosts = posts;
          _stats = stats;
          _followersCount = followCounts['followers'] ?? 0;
          _followingCount = followCounts['following'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool get _isCreator => _userData?['role'] == 'creator';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPink.withOpacity(0.1),
                  AppColors.indigo.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryPink),
            ),
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _loadUserData,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ResponsiveLayout(
                    mobile: _buildMobileLayout(isDark),
                    tablet: _buildTabletLayout(isDark),
                    desktop: _buildDesktopLayout(isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: (isDark ? AppColors.surfaceDark : Colors.white).withOpacity(0.8),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _buildIconButton(
          Icons.arrow_back_ios_new,
          isDark,
              () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _userData?['username'] ?? 'Profile',
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildRoleBadge(),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildIconButton(
            Icons.settings_outlined,
            isDark,
            _navigateToEditProfile,
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, bool isDark, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: _isCreator ? AppColors.creatorGradient : AppColors.consumerGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCreator ? Icons.camera_alt_rounded : Icons.explore_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _isCreator ? 'Creator' : 'Consumer',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        _buildProfileHeader(isDark),
        const SizedBox(height: 16),
        _buildStatsCard(isDark),
        const SizedBox(height: 16),
        if (_stats != null) ...[
          _buildRoleStatsCard(isDark),
          const SizedBox(height: 16),
        ],
        _buildActionButtons(isDark),
        const SizedBox(height: 24),
        _buildPostsSection(isDark),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTabletLayout(bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildProfileHeader(isDark),
                  const SizedBox(height: 16),
                  _buildActionButtons(isDark),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildStatsCard(isDark),
                  if (_stats != null) ...[
                    const SizedBox(height: 16),
                    _buildRoleStatsCard(isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPostsSection(isDark),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _buildProfileHeader(isDark),
              const SizedBox(height: 16),
              _buildStatsCard(isDark),
              if (_stats != null) ...[
                const SizedBox(height: 16),
                _buildRoleStatsCard(isDark),
              ],
              const SizedBox(height: 16),
              _buildActionButtons(isDark),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _buildPostsSection(isDark),
        ),
      ],
    );
  }

  // ==================== PROFILE HEADER ====================

  Widget _buildProfileHeader(bool isDark) {
    final profilePic = _userData?['profile_pic'];
    final username = _userData?['username'] ?? 'Unknown';

    return _ModernCard(
      isDark: isDark,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.avatarGradient,
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  image: profilePic != null
                      ? DecorationImage(
                    image: NetworkImage(profilePic),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: profilePic == null
                    ? Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = AppColors.primaryGradient.createShader(
                          const Rect.fromLTWH(0, 0, 40, 40),
                        ),
                    ),
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: (_userData?['is_public'] ?? true)
                        ? const LinearGradient(
                      colors: [Color(0xFF22c55e), Color(0xFF10b981)],
                    )
                        : const LinearGradient(
                      colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    (_userData?['is_public'] ?? true) ? Icons.public : Icons.lock,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          if (_userData?['bio'] != null) ...[
            const SizedBox(height: 16),
            Text(
              _userData!['bio'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== STATS CARD ====================

  Widget _buildStatsCard(bool isDark) {
    return _ModernCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Posts',
            _userPosts.length,
            Icons.grid_on_rounded,
            AppColors.indigo,
            isDark,
          ),
          Container(
            width: 1,
            height: 60,
            color: isDark ? AppColors.borderDark.withOpacity(0.5) : AppColors.borderLight,
          ),
          _buildStatItem(
            'Followers',
            _followersCount,
            Icons.people_rounded,
            AppColors.primaryPink,
            isDark,
          ),
          Container(
            width: 1,
            height: 60,
            color: isDark ? AppColors.borderDark.withOpacity(0.5) : AppColors.borderLight,
          ),
          _buildStatItem(
            'Following',
            _followingCount,
            Icons.person_add_rounded,
            AppColors.secondaryViolet,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ==================== ROLE STATS CARD ====================

  Widget _buildRoleStatsCard(bool isDark) {
    return _ModernCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _isCreator ? AppColors.creatorGradient : AppColors.consumerGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isCreator ? Icons.analytics_rounded : Icons.explore_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isCreator ? 'Creator Analytics' : 'Activity Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isCreator) ...[
            _buildAnalyticRow(
              'Total Likes Received',
              _stats?['total_likes']?.toString() ?? '0',
              Icons.favorite_rounded,
              AppColors.red,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildAnalyticRow(
              'Total Comments',
              _stats?['total_comments']?.toString() ?? '0',
              Icons.chat_bubble_rounded,
              AppColors.blue,
              isDark,
            ),
          ] else ...[
            _buildAnalyticRow(
              'Likes Given',
              _stats?['total_likes_given']?.toString() ?? '0',
              Icons.favorite_rounded,
              AppColors.red,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildAnalyticRow(
              'Comments Made',
              _stats?['total_comments_given']?.toString() ?? '0',
              Icons.chat_bubble_rounded,
              AppColors.blue,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark.withOpacity(0.5) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _navigateToEditProfile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _signOut,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.red.withOpacity(0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppColors.red,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== POSTS SECTION ====================

  Widget _buildPostsSection(bool isDark) {
    return _ModernCard(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grid_on_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_userPosts.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_userPosts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      _isCreator ? Icons.add_photo_alternate_outlined : Icons.photo_library_outlined,
                      size: 56,
                      color: AppColors.primaryPink.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No posts yet',
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _userPosts.length,
              itemBuilder: (context, index) => _buildPhotoCard(
                _userPosts[index],
                isDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> post, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _PostDetailSheet(
            post: post,
            userData: _userData!,
            isDark: isDark,
            onPostUpdated: _loadUserData,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post['image_url'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['likes_count'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['comments_count'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _navigateToEditProfile() async {
    HapticFeedback.selectionClick();
    if (await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userData: _userData!),
      ),
    ) ==
        true) {
      _loadUserData();
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.selectionClick();
    if (await showDialog<bool>(
      context: context,
      builder: (_) => _ActionDialog(
        isDark: Theme.of(context).brightness == Brightness.dark,
        title: 'Sign Out',
        content: 'Are you sure you want to sign out?',
        confirmText: 'Sign Out',
        icon: Icons.logout_rounded,
      ),
    ) ==
        true) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
              (r) => false,
        );
      }
    }
  }
}

// ==================== MODERN CARD WIDGET ====================

class _ModernCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  const _ModernCard({
    required this.child,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark.withOpacity(0.5) : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

// ==================== ACTION DIALOG ====================

class _ActionDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  final String content;
  final String confirmText;
  final IconData icon;

  const _ActionDialog({
    required this.isDark,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== POST DETAIL SHEET ====================

class _PostDetailSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> userData;
  final bool isDark;
  final VoidCallback onPostUpdated;

  const _PostDetailSheet({
    required this.post,
    required this.userData,
    required this.isDark,
    required this.onPostUpdated,
  });

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _post;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _checkLikeStatus();
  }

  void _checkLikeStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final like = await _supabase
          .from('likes')
          .select()
          .eq('post_id', _post['id'])
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() => _isLiked = like != null);
      }
    }
  }

  void _toggleLike() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    HapticFeedback.selectionClick();
    setState(() {
      _isLiked = !_isLiked;
      _post['likes_count'] = (_post['likes_count'] ?? 0) + (_isLiked ? 1 : -1);
    });

    try {
      if (_isLiked) {
        await _supabase.from('likes').insert({
          'post_id': _post['id'],
          'user_id': userId,
        });
      } else {
        await _supabase
            .from('likes')
            .delete()
            .eq('post_id', _post['id'])
            .eq('user_id', userId);
      }
      widget.onPostUpdated();
    } catch (_) {}
  }

  void _deletePost() async {
    HapticFeedback.selectionClick();
    if (await showDialog<bool>(
      context: context,
      builder: (_) => _ActionDialog(
        isDark: widget.isDark,
        title: 'Delete Post',
        content: 'Are you sure? This cannot be undone.',
        confirmText: 'Delete',
        icon: Icons.delete_outline_rounded,
      ),
    ) ==
        true) {
      try {
        await _supabase.from('posts').delete().eq('id', _post['id']);
        if (mounted) {
          Navigator.pop(context);
          widget.onPostUpdated();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.userData['username'] ?? 'Unknown';
    final profilePic = widget.userData['profile_pic'];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isDark ? AppColors.borderDark.withOpacity(0.5) : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                            child: profilePic == null ? Text(username[0].toUpperCase()) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz,
                              color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            onSelected: (v) {
                              if (v == 'delete') {
                                _deletePost();
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: AppColors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete Post',
                                      style: TextStyle(color: AppColors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    if (_post['caption'] != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          _post['caption'],
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    if (_post['image_url'] != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            _post['image_url'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _actionBtn(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            '${_post['likes_count'] ?? 0}',
                            _toggleLike,
                            isActive: _isLiked,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 12),
                          _actionBtn(
                            Icons.chat_bubble_outline,
                            '${_post['comments_count'] ?? 0}',
                                () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommentsScreen(
                                  postId: _post['id'],
                                  postUsername: username,
                                  postImageUrl: _post['image_url'] ?? '',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_post['title'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _post['title'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap,
      {bool isActive = false, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (color ?? AppColors.primaryPink).withOpacity(0.1)
              : (widget.isDark ? AppColors.surfaceDark2 : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? (color ?? AppColors.primaryPink)
                  : (widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isActive
                    ? (color ?? AppColors.primaryPink)
                    : (widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}