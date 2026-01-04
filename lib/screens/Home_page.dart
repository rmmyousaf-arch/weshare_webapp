import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mdel/appuser.dart';
import '../mdel/posts.dart';
import '../services/feed_service.dart';
import '../services/follow_service.dart';
import '../services/user_services.dart';
import '../utils/sheared_widgets.dart';
import 'Login.dart';
import 'comment_screen.dart';
import 'messagePage.dart';
import 'profile_page.dart';
import 'upload photo.dart';

// ==================== APP COLORS ====================
class AppColors {
  // Primary colors
  static const Color primaryPink = Color(0xFFec4899);
  static const Color secondaryViolet = Color(0xFF8b5cf6);
  static const Color indigo = Color(0xFF6366f1);
  static const Color green = Color(0xFF22c55e);
  static const Color yellow = Color(0xFFeab308);
  static const Color orange = Color(0xFFf97316);
  static const Color blue = Color(0xFF3b82f6);

  // Light theme
  static const Color backgroundLight = Color(0xFFf3f4f6);
  static const Color surfaceLight = Color(0xFFffffff);
  static const Color borderLight = Color(0xFFe5e7eb);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6b7280);

  // Dark theme
  static const Color backgroundDark = Color(0xFF0f111a);
  static const Color surfaceDark = Color(0xFF161822);
  static const Color surfaceDark2 = Color(0xFF1e2130);
  static const Color borderDark = Color(0xFF374151);
  static const Color textPrimaryDark = Color(0xFFf9fafb);
  static const Color textSecondaryDark = Color(0xFF9ca3af);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366f1), Color(0xFFec4899)],
  );

  static const LinearGradient avatarGradient = LinearGradient(
    colors: [Color(0xFFd946ef), Color(0xFF8b5cf6), Color(0xFF3b82f6)],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8b5cf6), Color(0xFFec4899)],
  );
}

// ==================== HOME PAGE ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;
  final FollowService _followService = FollowService();
  final UserService _userService = UserService();
  AppUser? _currentUser;
  bool _isLoadingUser = true;

  RealtimeChannel? _userSubscription;
  RealtimeChannel? _followsSubscription;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _setupUserRealtimeSubscription();
  }

  @override
  void dispose() {
    _userSubscription?.unsubscribe();
    _followsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    }
  }

  void _setupUserRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _userSubscription = _supabase
        .channel('user_profile_$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'users',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: (payload) async {
        if (!mounted) return;
        final user = await _userService.getCurrentUser();
        setState(() => _currentUser = user);
      },
    )
        .subscribe();

    _followsSubscription = _supabase
        .channel('follows_changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'follows',
      callback: (payload) {
        if (!mounted) return;
        setState(() {});
      },
    )
        .subscribe();
  }

  List<Widget> get _pages => [
    FeedPage(currentUser: _currentUser),
    const ExplorePage(),
    const MessagesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingUser) {
      return Scaffold(
        backgroundColor:
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(isDark),
        tablet: _buildTabletLayout(isDark),
        desktop: _buildDesktopLayout(isDark),
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        _buildGlassHeader(isDark),
        Expanded(child: _pages[_selectedNavIndex]),
        _buildModernBottomNav(isDark),
      ],
    );
  }

  Widget _buildGlassHeader(bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.logoGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PhotoStream',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),

              const SizedBox(width: 8),
              // Profile Avatar
              _buildGradientAvatar(
                imageUrl: _currentUser?.profilePic,
                initial: _currentUser?.initial ?? 'U',
                size: 38,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
  }) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientAvatar({
    String? imageUrl,
    required String initial,
    required double size,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          gradient: AppColors.avatarGradient,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: size / 2 - 2,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          backgroundColor: Colors.white,
          child: imageUrl == null
              ? Text(
            initial,
            style: TextStyle(
              color: AppColors.secondaryViolet,
              fontWeight: FontWeight.bold,
              fontSize: size / 3,
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildModernBottomNav(bool isDark) {
    final isCreator = _currentUser?.isCreator ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                isDark: isDark,
              ),
              _buildModernNavItem(
                index: 1,
                icon: Icons.explore_rounded,
                label: 'Explore',
                isDark: isDark,
              ),
              if (isCreator) _buildCreateButton(isDark),
              _buildModernNavItem(
                index: 2,
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                isDark: isDark,
              ),
              _buildModernNavItem(
                index: 3,
                icon: Icons.mail_outline_rounded,
                label: 'Messages',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark2 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryPink
                  : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UploadPhotoPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryViolet.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout(bool isDark) {
    return Column(
      children: [
        _buildDesktopHeader(isDark),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: _pages[_selectedNavIndex],
              ),
              _buildRightSidebar(isDark, 300),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(bool isDark) {
    return Column(
      children: [
        _buildDesktopHeader(isDark),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 8,
                      child: _pages[_selectedNavIndex],
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 380,
                      child: _buildRightSidebar(isDark, 380),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.logoGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPink.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PhotoStream',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Navigation pills
                    _buildDesktopNavigation(isDark),
                    const Spacer(),
                    // Right section
                    Row(
                      children: [
                        if (_currentUser?.isCreator ?? false)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildCreateButton(isDark),
                          ),
                        const SizedBox(width: 16),

                        const SizedBox(width: 16),
                        _buildGradientAvatar(
                          imageUrl: _currentUser?.profilePic,
                          initial: _currentUser?.initial ?? 'U',
                          size: 40,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNavigation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
        isDark ? AppColors.surfaceDark2.withOpacity(0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
          isDark ? AppColors.borderDark.withOpacity(0.5) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDesktopNavItem(0, Icons.home_rounded, 'Home', isDark),
          _buildDesktopNavItem(1, Icons.explore_rounded, 'Explore', isDark),
          _buildDesktopNavItem(2, Icons.mail_outline_rounded, 'Messages', isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(
      int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark2 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primaryPink
                  : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)
                    : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar(bool isDark, double width) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuggestionsSection(isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withOpacity(0.5)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggested for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getCreatorSuggestions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final creators = snapshot.data ?? [];
              if (creators.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No suggestions available',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: creators
                    .map((creator) => _buildSuggestionItem(creator, isDark))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> creator, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildGradientAvatar(
            imageUrl: creator['profile_pic'],
            initial: (creator['username'] as String? ?? 'U')[0].toUpperCase(),
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      creator['username'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (creator['verified'] == true) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Suggested for you',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          _ModernFollowButton(
            creatorId: creator['id'],
            followService: _followService,
            isDark: isDark,
          ),
        ],
      ),
    );
  }


  Widget _buildFooterLink(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.grey[600] : Colors.grey[500],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getCreatorSuggestions() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return [];

    try {
      final followingResponse = await _supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', currentUser.id);

      final followingIds =
      (followingResponse as List).map((e) => e['followed_id']).toSet();
      followingIds.add(currentUser.id);

      final response = await _supabase
          .from('users')
          .select('id, username, profile_pic, role')
          .eq('role', 'creator')
          .eq('is_public', true)
          .limit(50);

      List<Map<String, dynamic>> candidates =
      List<Map<String, dynamic>>.from(response);
      candidates.removeWhere((u) => followingIds.contains(u['id']));
      candidates.shuffle();

      return candidates.take(5).toList();
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    }
  }

  String _getPageTitle() {
    switch (_selectedNavIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Explore';
      case 2:
        return 'Messages';
      default:
        return 'PhotoStream';
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    }
  }
}

// ==================== MODERN FOLLOW BUTTON ====================
class _ModernFollowButton extends StatefulWidget {
  final String creatorId;
  final FollowService followService;
  final bool isDark;

  const _ModernFollowButton({
    required this.creatorId,
    required this.followService,
    required this.isDark,
  });

  @override
  State<_ModernFollowButton> createState() => _ModernFollowButtonState();
}

class _ModernFollowButtonState extends State<_ModernFollowButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final isFollowing =
    await widget.followService.isFollowing(widget.creatorId);
    if (mounted) {
      setState(() => _isFollowing = isFollowing);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);

    try {
      if (_isFollowing) {
        await widget.followService.unfollowUser(widget.creatorId);
      } else {
        await widget.followService.followUser(widget.creatorId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: _isFollowing ? null : AppColors.primaryGradient,
          color: _isFollowing
              ? (widget.isDark ? AppColors.surfaceDark2 : Colors.grey[100])
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isFollowing
              ? null
              : [
            BoxShadow(
              color: AppColors.indigo.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLoading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isFollowing
                ? (widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight)
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ==================== FEED PAGE ====================
class FeedPage extends StatefulWidget {
  final AppUser? currentUser;

  const FeedPage({super.key, this.currentUser});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FeedService _feedService = FeedService();
  final List<Post> _posts = [];
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 10;

  RealtimeChannel? _postsSubscription;
  RealtimeChannel? _likesSubscription;
  RealtimeChannel? _commentsSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _postsSubscription?.unsubscribe();
    _likesSubscription?.unsubscribe();
    _commentsSubscription?.unsubscribe();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    _postsSubscription = _supabase
        .channel('realtime_posts')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'posts',
      callback: (payload) => _handleNewPost(payload),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'posts',
      callback: (payload) => _handleUpdatedPost(payload),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'posts',
      callback: (payload) => _handleDeletedPost(payload),
    )
        .subscribe();

    _likesSubscription = _supabase
        .channel('realtime_likes')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'likes',
      callback: (payload) => _handleLikeChange(payload),
    )
        .subscribe();

    _commentsSubscription = _supabase
        .channel('realtime_comments')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'comments',
      callback: (payload) => _handleCommentChange(payload),
    )
        .subscribe();
  }

  Future<void> _handleNewPost(PostgresChangePayload payload) async {
    if (!mounted) return;

    try {
      final newPostId = payload.newRecord['id'];

      final response = await _supabase
          .from('posts')
          .select('*, users(*)')
          .eq('id', newPostId)
          .single();

      final userData = response['users'] ?? {};
      final currentUserId = _supabase.auth.currentUser?.id;

      bool shouldShow = false;
      if (currentUserId != null) {
        final followCheck = await _supabase
            .from('follows')
            .select()
            .eq('follower_id', currentUserId)
            .eq('followed_id', response['user_id'])
            .maybeSingle();

        shouldShow =
            followCheck != null || response['user_id'] == currentUserId;
      }

      if (shouldShow) {
        final newPost = Post(
          id: response['id'],
          userId: response['user_id'],
          username: userData['username'] ?? 'Unknown',
          userProfilePic: userData['profile_pic'],
          title: response['title'] ?? '',
          caption: response['caption'] ?? '',
          imageUrl: response['image_url'],
          taggedPeople: List<String>.from(response['tagged_people'] ?? []),
          likesCount: response['likes_count'] ?? 0,
          commentsCount: response['comments_count'] ?? 0,
          createdAt: DateTime.parse(response['created_at']),
          updatedAt: DateTime.parse(response['updated_at']),
          isLiked: false,
        );

        if (!_posts.any((p) => p.id == newPost.id)) {
          setState(() => _posts.insert(0, newPost));
        }
      }
    } catch (e) {
      debugPrint('Error handling new post: $e');
    }
  }

  void _handleUpdatedPost(PostgresChangePayload payload) {
    if (!mounted) return;

    final updatedId = payload.newRecord['id'];
    final index = _posts.indexWhere((p) => p.id == updatedId);

    if (index != -1) {
      setState(() {
        _posts[index] = _posts[index].copyWith(
          title: payload.newRecord['title'] ?? _posts[index].title,
          caption: payload.newRecord['caption'] ?? _posts[index].caption,
          likesCount:
          payload.newRecord['likes_count'] ?? _posts[index].likesCount,
          commentsCount:
          payload.newRecord['comments_count'] ?? _posts[index].commentsCount,
        );
      });
    }
  }

  void _handleDeletedPost(PostgresChangePayload payload) {
    if (!mounted) return;

    final deletedId = payload.oldRecord['id'];
    setState(() => _posts.removeWhere((p) => p.id == deletedId));
  }

  Future<void> _handleLikeChange(PostgresChangePayload payload) async {
    if (!mounted) return;

    String? postId;
    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      postId = payload.newRecord['post_id'];
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      postId = payload.oldRecord['post_id'];
    }

    if (postId == null) return;

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      try {
        final response = await _supabase
            .from('posts')
            .select('likes_count')
            .eq('id', postId)
            .single();

        final currentUserId = _supabase.auth.currentUser?.id;
        bool isLiked = false;

        if (currentUserId != null) {
          final likeCheck = await _supabase
              .from('likes')
              .select()
              .eq('post_id', postId)
              .eq('user_id', currentUserId)
              .maybeSingle();
          isLiked = likeCheck != null;
        }

        setState(() {
          _posts[index] = _posts[index].copyWith(
            likesCount: response['likes_count'],
            isLiked: isLiked,
          );
        });
      } catch (e) {
        debugPrint('Error updating like count: $e');
      }
    }
  }

  Future<void> _handleCommentChange(PostgresChangePayload payload) async {
    if (!mounted) return;

    String? postId;
    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      postId = payload.newRecord['post_id'];
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      postId = payload.oldRecord['post_id'];
    }

    if (postId == null) return;

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      try {
        final response = await _supabase
            .from('posts')
            .select('comments_count')
            .eq('id', postId)
            .single();

        setState(() {
          _posts[index] = _posts[index].copyWith(
            commentsCount: response['comments_count'],
          );
        });
      } catch (e) {
        debugPrint('Error updating comment count: $e');
      }
    }
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final posts =
      await _feedService.getFeedPosts(page: 0, pageSize: _pageSize);
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _hasMore = posts.length == _pageSize;
        _page = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading posts: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final posts =
      await _feedService.getFeedPosts(page: _page, pageSize: _pageSize);
      setState(() {
        _posts.addAll(posts);
        _hasMore = posts.length == _pageSize;
        _page++;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _handleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];

    setState(() {
      _posts[index] = post.copyWith(
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        isLiked: !post.isLiked,
      );
    });

    try {
      if (post.isLiked) {
        await _feedService.unlikePost(postId);
      } else {
        await _feedService.likePost(postId);
      }
    } catch (e) {
      setState(() => _posts[index] = post);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadInitialPosts,
      color: AppColors.primaryPink,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        // FIXED: Removed the +1 since we aren't showing the create post card anymore
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Logic for the loading indicator at the bottom
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // FIXED: Direct access to _posts[index] without offsetting
          return _ModernPostCard(
            post: _posts[index],
            isDark: isDark,
            onLike: () => _handleLike(_posts[index].id),
          );
        },
      ),
    );
  }


  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withOpacity(0.1),
                    AppColors.indigo.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: AppColors.primaryPink.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your feed is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow creators to see their photos in your feed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MODERN POST CARD ====================
class _ModernPostCard extends StatelessWidget {
  final Post post;
  final bool isDark;
  final VoidCallback onLike;

  const _ModernPostCard({
    required this.post,
    required this.isDark,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withOpacity(0.5)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    gradient: AppColors.avatarGradient,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: post.userProfilePic != null
                        ? NetworkImage(post.userProfilePic!)
                        : null,
                    backgroundColor: Colors.white,
                    child: post.userProfilePic == null
                        ? Text(
                      post.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.secondaryViolet,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _timeAgo(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.public,
                            size: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Caption before image
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                post.caption,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark.withOpacity(0.9)
                      : AppColors.textPrimaryLight.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),

          // Image
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    post.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color:
                        isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Like button
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(post.likesCount),
                  isActive: post.isLiked,
                  activeColor: AppColors.primaryPink,
                  onTap: onLike,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                // Comment button
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(post.commentsCount),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(
                        postId: post.id,
                        postUsername: post.username,
                        postImageUrl: post.imageUrl,
                      ),
                    ),
                  ),
                  isDark: isDark,
                ),

                const Spacer(),
                // Bookmark button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
    Color? activeColor,
    bool rotateIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? AppColors.primaryPink).withOpacity(0.1)
              : (isDark ? AppColors.surfaceDark2 : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Transform.rotate(
              angle: rotateIcon ? -0.4 : 0,
              child: Icon(
                icon,
                size: 22,
                color: isActive
                    ? (activeColor ?? AppColors.primaryPink)
                    : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isActive
                    ? (activeColor ?? AppColors.primaryPink)
                    : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}



// ==================== EXPLORE PAGE ====================
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Post> _posts = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final start = _page * _pageSize;
      final end = start + _pageSize - 1;

      final response = await _supabase
          .from('posts')
          .select('*, users!inner(id, username, profile_pic, is_public, role)')
          .eq('users.is_public', true)
          .eq('users.role', 'creator')
          .order('created_at', ascending: false)
          .range(start, end);

      final currentUserId = _supabase.auth.currentUser?.id ?? '';

      final List<Post> newPosts = [];
      for (var row in response as List) {
        final userData = row['users'];

        bool isLiked = false;
        if (currentUserId.isNotEmpty) {
          final like = await _supabase
              .from('likes')
              .select()
              .eq('post_id', row['id'])
              .eq('user_id', currentUserId)
              .maybeSingle();
          isLiked = like != null;
        }

        newPosts.add(Post(
          id: row['id'],
          userId: row['user_id'],
          username: userData['username'] ?? 'Unknown',
          userProfilePic: userData['profile_pic'],
          title: row['title'] ?? '',
          caption: row['caption'] ?? '',
          imageUrl: row['image_url'],
          taggedPeople: List<String>.from(row['tagged_people'] ?? []),
          likesCount: row['likes_count'] ?? 0,
          commentsCount: row['comments_count'] ?? 0,
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          isLiked: isLiked,
        ));
      }

      setState(() {
        _posts.addAll(newPosts);
        _hasMore = newPosts.length == _pageSize;
        _page++;
      });
    } catch (e) {
      debugPrint('Explore load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.indigo.withOpacity(0.1),
                    AppColors.primaryPink.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_off_rounded,
                size: 64,
                color: AppColors.indigo.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nothing to explore yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _posts.clear();
          _page = 0;
          _hasMore = true;
        });
        await _loadPosts();
      },
      color: AppColors.primaryPink,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = _posts[index];
          return _ModernExploreGridItem(
            post: post,
            isDark: isDark,
            onTap: () => _showPostDetail(post, isDark),
          );
        },
      ),
    );
  }

  void _showPostDetail(Post post, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ModernExplorePostDetail(post: post, isDark: isDark),
    );
  }
}

// ==================== MODERN EXPLORE GRID ITEM ====================
class _ModernExploreGridItem extends StatelessWidget {
  final Post post;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernExploreGridItem({
    required this.post,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: isDark ? AppColors.surfaceDark2 : Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (c, e, s) => Container(
                color: isDark ? AppColors.surfaceDark2 : Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MODERN EXPLORE POST DETAIL ====================
class _ModernExplorePostDetail extends StatelessWidget {
  final Post post;
  final bool isDark;

  const _ModernExplorePostDetail({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                gradient: AppColors.avatarGradient,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage: post.userProfilePic != null
                                    ? NetworkImage(post.userProfilePic!)
                                    : null,
                                child: post.userProfilePic == null
                                    ? Text(post.username[0].toUpperCase())
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: 12,
                                        color: AppColors.primaryPink,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Creator',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primaryPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Image.network(
                            post.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  post.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post.isLiked
                                      ? AppColors.primaryPink
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text('${post.likesCount} likes'),
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CommentsScreen(
                                          postId: post.id,
                                          postUsername: post.username,
                                          postImageUrl: post.imageUrl,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.chat_bubble_outline),
                                      const SizedBox(width: 8),
                                      Text('${post.commentsCount} comments'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (post.title.isNotEmpty ||
                                post.caption.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              if (post.title.isNotEmpty)
                                Text(
                                  post.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              if (post.caption.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    post.caption,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}