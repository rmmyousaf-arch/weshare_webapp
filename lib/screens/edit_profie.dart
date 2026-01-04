import 'dart:typed_data';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_services.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final AnimationController _animController;

  late bool _isPublic;
  late String _selectedRole;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;
  bool _hasChanges = false;

  static const _primary = Color(0xFF6C5CE7);
  static const _secondary = Color(0xFFE84393);
  static const _success = Color(0xFF00B894);
  static const _error = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '')
      ..addListener(_checkChanges);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '')
      ..addListener(_checkChanges);
    _isPublic = widget.userData['is_public'] ?? true;
    _selectedRole = widget.userData['role'] ?? 'consumer';

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final changed = _usernameController.text != (widget.userData['username'] ?? '') ||
        _bioController.text != (widget.userData['bio'] ?? '') ||
        _isPublic != (widget.userData['is_public'] ?? true) ||
        _selectedRole != (widget.userData['role'] ?? 'consumer') ||
        _selectedImageBytes != null;

    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result?.files.firstOrNull?.bytes != null) {
        final file = result!.files.first;
        if (file.size > 5 * 1024 * 1024) {
          _showSnack('Image must be under 5MB', isError: true);
          return;
        }
        setState(() {
          _selectedImageBytes = file.bytes;
          _selectedImageName = file.name;
        });
        _checkChanges();
      }
    } catch (e) {
      _showSnack('Failed to pick image', isError: true);
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null) return null;

    final userId = _supabase.auth.currentUser!.id;
    final ext = _selectedImageName?.split('.').last ?? 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _supabase.storage.from('profile-pics').uploadBinary(
      path,
      _selectedImageBytes!,
      fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
    );

    return _supabase.storage.from('profile-pics').getPublicUrl(path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final profilePic = await _uploadImage() ?? widget.userData['profile_pic'];

      await _userService.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        isPublic: _isPublic,
        profilePic: profilePic,
        role: _selectedRole,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Update failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? _error : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Discard changes?',
        message: 'You have unsaved changes that will be lost.',
        confirmText: 'Discard',
        confirmColor: _error,
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F9FA);
    final card = isDark ? const Color(0xFF16161F) : Colors.white;
    final text1 = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final text2 = isDark ? Colors.white60 : Colors.black54;
    final border = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            _BackgroundOrbs(isDark: isDark),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(isDark, text1, card),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildAvatar(isDark, card, text1),
                          const SizedBox(height: 32),
                          _AnimatedCard(
                            animation: _animController,
                            delay: 0.0,
                            child: _buildRoleSelector(isDark, card, text1, text2, border),
                          ),
                          const SizedBox(height: 16),
                          _AnimatedCard(
                            animation: _animController,
                            delay: 0.1,
                            child: _buildInputSection(isDark, card, text1, text2, border),
                          ),
                          const SizedBox(height: 16),
                          _AnimatedCard(
                            animation: _animController,
                            delay: 0.2,
                            child: _buildPrivacyToggle(isDark, card, text1, text2, border),
                          ),
                          const SizedBox(height: 16),
                          _AnimatedCard(
                            animation: _animController,
                            delay: 0.3,
                            child: _buildAccountInfo(isDark, card, text1, text2, border),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomBar(isDark, card, border),
            if (_isLoading) _buildLoading(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, Color text1, Color card) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _GlassButton(
          onTap: () async {
            if (await _onWillPop()) Navigator.pop(context, false);
          },
          child: Icon(Icons.arrow_back_ios_new, size: 18, color: text1),
        ),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(color: text1, fontWeight: FontWeight.w700, fontSize: 20),
      ),
      centerTitle: true,
      actions: [
        if (_hasChanges)
          Padding(
            padding: const EdgeInsets.all(8),
            child: _GlassButton(
              onTap: _save,
              gradient: const LinearGradient(colors: [_primary, _secondary]),
              child: const Icon(Icons.check, size: 20, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(bool isDark, Color card, Color text1) {
    final url = widget.userData['profile_pic'];
    final name = widget.userData['username'] ?? '?';

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _animController,
        child: GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [_primary, _secondary, _primary.withOpacity(0.5), _secondary, _primary],
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: card,
                  image: _getImageProvider(url) != null
                      ? DecorationImage(image: _getImageProvider(url)!, fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImageBytes == null && url == null
                    ? Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(colors: [_primary, _secondary])
                            .createShader(const Rect.fromLTWH(0, 0, 48, 48)),
                    ),
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primary, _secondary]),
                    shape: BoxShape.circle,
                    border: Border.all(color: card, width: 3),
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
              if (_selectedImageBytes != null)
                Positioned(
                  top: 0,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _success,
                      shape: BoxShape.circle,
                      border: Border.all(color: card, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool isDark, Color card, Color text1, Color text2, Color border) {
    return _Card(
      color: card,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: Icons.person_outline, label: 'Account Type', color: text1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RoleChip(
                  role: 'consumer',
                  selected: _selectedRole == 'consumer',
                  onTap: () => setState(() {
                    _selectedRole = 'consumer';
                    _checkChanges();
                    HapticFeedback.selectionClick();
                  }),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleChip(
                  role: 'creator',
                  selected: _selectedRole == 'creator',
                  onTap: () => setState(() {
                    _selectedRole = 'creator';
                    _checkChanges();
                    HapticFeedback.selectionClick();
                  }),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark, Color card, Color text1, Color text2, Color border) {
    return _Card(
      color: card,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: Icons.edit_outlined, label: 'Profile Info', color: text1),
          const SizedBox(height: 16),
          _ModernInput(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email,
            isDark: isDark,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _ModernInput(
            controller: _bioController,
            label: 'Bio',
            icon: Icons.notes_rounded,
            isDark: isDark,
            maxLines: 3,
            hint: 'Tell us about yourself...',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(bool isDark, Color card, Color text1, Color text2, Color border) {
    return _Card(
      color: card,
      border: border,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _isPublic
                  ? const LinearGradient(colors: [_success, Color(0xFF00CEC9)])
                  : LinearGradient(colors: [Colors.grey, Colors.grey.shade600]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_isPublic ? Icons.public : Icons.lock_outline, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Public Profile' : 'Private Profile',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: text1),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPublic ? 'Anyone can see your content' : 'Only followers can see',
                  style: TextStyle(fontSize: 12, color: text2),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isPublic,
            onChanged: (v) {
              setState(() => _isPublic = v);
              _checkChanges();
              HapticFeedback.selectionClick();
            },
            activeColor: _success,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(bool isDark, Color card, Color text1, Color text2, Color border) {
    final email = widget.userData['email'] ?? 'No email';
    final createdAt = widget.userData['created_at'] != null
        ? DateTime.parse(widget.userData['created_at'])
        : DateTime.now();

    return _Card(
      color: card,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(icon: Icons.info_outline, label: 'Account Info', color: text1),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email, text1: text1, text2: text2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: border, height: 1),
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined',
            value: '${_months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}',
            text1: text1,
            text2: text2,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, Color card, Color border) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: card.withOpacity(0.8),
              border: Border(top: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Cancel',
                    onTap: () async {
                      if (await _onWillPop()) Navigator.pop(context, false);
                    },
                    outlined: true,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: 'Save Changes',
                    onTap: _hasChanges ? _save : null,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Container(
      color: Colors.black45,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161F) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(_primary)),
                ),
                const SizedBox(height: 20),
                Text('Saving...', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? url) {
    if (_selectedImageBytes != null) return MemoryImage(_selectedImageBytes!);
    if (url != null) return NetworkImage(url);
    return null;
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}

class _BackgroundOrbs extends StatelessWidget {
  final bool isDark;
  const _BackgroundOrbs({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -80, right: -80, child: _Orb(size: 250, color: const Color(0xFF6C5CE7).withOpacity(isDark ? 0.15 : 0.08))),
          Positioned(top: 300, left: -100, child: _Orb(size: 200, color: const Color(0xFFE84393).withOpacity(isDark ? 0.12 : 0.06))),
          Positioned(bottom: 100, right: -50, child: _Orb(size: 180, color: const Color(0xFF00B894).withOpacity(isDark ? 0.1 : 0.05))),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Gradient? gradient;

  const _GlassButton({required this.onTap, required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;

  const _AnimatedCard({required this.animation, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = Curves.easeOut.transform(((animation.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Transform.translate(offset: Offset(0, 30 * (1 - value)), child: Opacity(opacity: value, child: child));
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Color color;
  final Color border;
  final Widget child;

  const _Card({required this.color, required this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFE84393)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _RoleChip({required this.role, required this.selected, required this.onTap, required this.isDark});

  static const _primary = Color(0xFF6C5CE7);
  static const _secondary = Color(0xFFE84393);
  static const _success = Color(0xFF00B894);

  @override
  Widget build(BuildContext context) {
    final isCreator = role == 'creator';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: selected
              ? (isCreator ? const LinearGradient(colors: [_primary, _secondary]) : const LinearGradient(colors: [_success, Color(0xFF00CEC9)]))
              : null,
          color: selected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06))),
          boxShadow: selected ? [BoxShadow(color: (isCreator ? _primary : _success).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          children: [
            Icon(isCreator ? Icons.camera_alt_rounded : Icons.explore_rounded, size: 28, color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 8),
            Text(isCreator ? 'Creator' : 'Consumer', style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
            if (selected) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final String? hint;
  final String? Function(String?)? validator;

  const _ModernInput({required this.controller, required this.label, required this.icon, required this.isDark, this.maxLines = 1, this.hint, this.validator});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final border = isDark ? Colors.white12 : Colors.black.withOpacity(0.06);
    final text = isDark ? Colors.white : Colors.black87;
    final hint2 = isDark ? Colors.white38 : Colors.black38;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: text, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: hint2, fontSize: 14),
        hintStyle: TextStyle(color: hint2, fontSize: 14),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 12, top: maxLines > 1 ? 14 : 0),
          child: Icon(icon, size: 20, color: const Color(0xFF6C5CE7)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        filled: true,
        fillColor: bg,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: maxLines > 1 ? 16 : 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE74C3C))),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color text1;
  final Color text2;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.text1, required this.text2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: text2),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: text2)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: text1), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool isDark;

  const _ActionButton({required this.label, this.onTap, this.outlined = false, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: !outlined && enabled ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFE84393)]) : null,
          color: outlined ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100) : (!enabled ? Colors.grey.withOpacity(0.3) : null),
          borderRadius: BorderRadius.circular(16),
          border: outlined ? Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)) : null,
          boxShadow: !outlined && enabled ? [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: outlined ? (isDark ? Colors.white70 : Colors.black54) : (enabled ? Colors.white : Colors.white54)),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;

  const _ConfirmDialog({required this.title, required this.message, required this.confirmText, required this.confirmColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF16161F) : Colors.white;
    final text1 = isDark ? Colors.white : Colors.black87;
    final text2 = isDark ? Colors.white60 : Colors.black54;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: confirmColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: confirmColor, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: text1)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: text2)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: text2)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmText, style: const TextStyle(color: Colors.white)),
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