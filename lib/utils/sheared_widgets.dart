
import 'package:flutter/material.dart';
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
// Shared responsive utilities
class ResponsiveUtils {
static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

static double padding(BuildContext context) => isMobile(context) ? 16.0 : (isTablet(context) ? 20.0 : 24.0);
static double sidePadding(BuildContext context) => isMobile(context) ? 20.0 : (isTablet(context) ? 60.0 : 120.0);

static double value(BuildContext context, double mobile, double tablet, double desktop) {
if (isMobile(context)) return mobile;
if (isTablet(context)) return tablet;
return desktop;
}
}

// Shared responsive layout wrapper
class ResponsiveLayout extends StatelessWidget {
final Widget mobile;
final Widget tablet;
final Widget desktop;

const ResponsiveLayout({
super.key,
required this.mobile,
required this.tablet,
required this.desktop,
});

@override
Widget build(BuildContext context) {
return LayoutBuilder(
builder: (context, constraints) {
Widget child;
if (constraints.maxWidth < 600) {
child = mobile;
} else if (constraints.maxWidth < 1200) {
child = tablet;
} else {
child = desktop;
}
return Padding(
padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.sidePadding(context)),
child: child,
);
},
);
}
}

// Shared glass container
class GlassContainer extends StatelessWidget {
final Widget child;
final double maxWidth;

const GlassContainer({
super.key,
required this.child,
required this.maxWidth,
});

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

return Container(
constraints: BoxConstraints(maxWidth: maxWidth),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.7),
border: Border.all(
color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
width: 1,
),
boxShadow: [
BoxShadow(
color: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
blurRadius: 20,
spreadRadius: 2,
offset: const Offset(0, 4),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(16),
child: BackdropFilter(
filter: const ColorFilter.matrix([
1, 0, 0, 0, 0,
0, 1, 0, 0, 0,
0, 0, 1, 0, 0,
0, 0, 0, 18, -7,
]),
child: child,
),
),
);
}
}

// Shared input field
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final IconData? prefixIcon; // Add this
  final Widget? suffixIcon; // Add this (optional custom suffix)
  final bool enabled; // Add this
  final int? maxLines; // Add this

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.prefixIcon, // Add this
    this.suffixIcon, // Add this
    this.enabled = true, // Add this
    this.maxLines = 1, // Add this
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 42 : null, // Adjust height for multiline
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? obscureText : false,
            keyboardType: keyboardType,
            enabled: enabled,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: maxLines == 1 ? 0 : 12,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                prefixIcon,
                size: 18,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              )
                  : null,
              suffixIcon: _buildSuffixIcon(isDark),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool isDark) {
    if (suffixIcon != null) {
      return suffixIcon;
    }

    if (isPassword) {
      return IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          size: 18,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        onPressed: onToggleVisibility,
      );
    }

    return null;
  }
}
// Shared primary button
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Change to nullable
  final bool isFullWidth;
  final bool isLoading; // Add this
  final IconData? icon; // Add this

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.isLoading = false, // Add this
    this.icon, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _getButtonColor(context),
        boxShadow: _getButtonShadow(context),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: _buildButtonChild(),
      ),
    );
  }

  Color _getButtonColor(BuildContext context) {
    if (isLoading || onPressed == null) {
      return Colors.grey[400]!;
    }
    return Theme.of(context).colorScheme.primary.withOpacity(0.9);
  }

  List<BoxShadow>? _getButtonShadow(BuildContext context) {
    if (isLoading || onPressed == null) {
      return null;
    }
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildButtonChild() {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Loading...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
  }
}
// Shared navigation item
class NavItem extends StatelessWidget {
final IconData icon;
final String label;
final bool isSelected;
final VoidCallback onTap;
final bool filled;

const NavItem({
super.key,
required this.icon,
required this.label,
required this.isSelected,
required this.onTap,
this.filled = false,
});

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(8),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
decoration: BoxDecoration(
color: isSelected
? const Color(0xFF258cf4).withOpacity(0.2)
    : Colors.transparent,
borderRadius: BorderRadius.circular(8),
),
child: Row(
children: [
Icon(
icon,
size: 20,
color: isSelected
? const Color(0xFF258cf4)
    : isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D),
),
const SizedBox(width: 12),
Text(
label,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w500,
color: isSelected
? const Color(0xFF258cf4)
    : isDark ? Colors.white : const Color(0xFF212529),
),
),
],
),
),
),
);
}
}

// Shared photo card
class PhotoCard extends StatelessWidget {
final String username;
final String location;
final String title;
final String views;
final String rating;
final String comments;
final VoidCallback? onTap;

const PhotoCard({
super.key,
required this.username,
required this.location,
required this.title,
required this.views,
required this.rating,
required this.comments,
this.onTap,
});

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(12),
child: Container(
decoration: BoxDecoration(
color: isDark ? const Color(0xFF16222E) : Colors.white,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: isDark ? const Color(0xFF283039) : const Color(0xFFE9ECEF),
width: 1,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 4,
offset: const Offset(0, 2),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// User Info
Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [
CircleAvatar(
radius: 18,
backgroundColor: const Color(0xFF258cf4).withOpacity(0.2),
child: Text(
username[0].toUpperCase(),
style: const TextStyle(
color: Color(0xFF258cf4),
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
username,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w500,
color: isDark ? Colors.white : const Color(0xFF212529),
),
),
Text(
location,
style: TextStyle(
fontSize: 11,
color: isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D),
),
),
],
),
),
],
),
),

// Photo
Expanded(
child: Container(
width: double.infinity,
decoration: BoxDecoration(
color: isDark ? const Color(0xFF283039) : const Color(0xFFE9ECEF),
),
child: Center(
child: Icon(
Icons.photo,
size: 48,
color: isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D),
),
),
),
),

// Photo Info
Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: isDark ? Colors.white : const Color(0xFF212529),
),
),
const SizedBox(height: 6),
Row(
children: [
Text(
views,
style: TextStyle(
fontSize: 11,
color: isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D),
),
),
const SizedBox(width: 12),
const Icon(Icons.star, size: 12, color: Color(0xFFfbbf24)),
const SizedBox(width: 2),
Text(
rating,
style: TextStyle(
fontSize: 11,
color: isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D),
),
),
const SizedBox(width: 12),
Text(
comments,
style: TextStyle(
fontSize: 11,
color: isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D),
),
),
],
),
],
),
),
],
),
),
);
}
}



// Different page widgets for navigation
class FeedPage extends StatefulWidget {
const FeedPage({super.key});

@override
State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
bool _isFollowingFeed = false;

final List<Map<String, dynamic>> _photoCards = [
{
'username': 'anseladams',
'location': 'California, USA',
'title': 'Alpine Sunrise',
'views': '1.2k views',
'rating': '4.8',
'comments': '102 comments',
},
{
'username': 'jane_doe_photo',
'location': 'Tokyo, Japan',
'title': 'City Lights',
'views': '2.5k views',
'rating': '4.9',
'comments': '230 comments',
},
{
'username': 'trail_tracker',
'location': 'British Columbia, Canada',
'title': 'Forest Path',
'views': '890 views',
'rating': '4.7',
'comments': '78 comments',
},
{
'username': 'marina_views',
'location': 'Sydney, Australia',
'title': 'Ocean Waves',
'views': '3.1k views',
'rating': '4.9',
'comments': '312 comments',
},
];

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

return SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 1200),
child: Column(
children: [
// Feed Toggle
Container(
height: 40,
width: 320,
padding: const EdgeInsets.all(4),
decoration: BoxDecoration(
color: isDark ? const Color(0xFF283039) : const Color(0xFFE9ECEF),
borderRadius: BorderRadius.circular(8),
),
child: Row(
children: [
Expanded(
child: _buildToggleButton('Following', !_isFollowingFeed, isDark),
),
Expanded(
child: _buildToggleButton('For You', _isFollowingFeed, isDark),
),
],
),
),
const SizedBox(height: 24),

// Photo Grid
LayoutBuilder(
builder: (context, constraints) {
int crossAxisCount = (constraints.maxWidth / 300).floor();
if (crossAxisCount < 1) crossAxisCount = 1;
if (crossAxisCount > 4) crossAxisCount = 4;

return GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: crossAxisCount,
crossAxisSpacing: 24,
mainAxisSpacing: 24,
childAspectRatio: 0.75,
),
itemCount: _photoCards.length,
itemBuilder: (context, index) {
final photo = _photoCards[index];
return PhotoCard(
username: photo['username'],
location: photo['location'],
title: photo['title'],
views: photo['views'],
rating: photo['rating'],
comments: photo['comments'],
);
},
);
},
),
],
),
),
),
);
}

Widget _buildToggleButton(String label, bool isSelected, bool isDark) {
return InkWell(
onTap: () => setState(() => _isFollowingFeed = !_isFollowingFeed),
borderRadius: BorderRadius.circular(6),
child: Container(
alignment: Alignment.center,
decoration: BoxDecoration(
color: isSelected
? (isDark ? const Color(0xFF16222E) : Colors.white)
    : Colors.transparent,
borderRadius: BorderRadius.circular(6),
boxShadow: isSelected ? [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 2,
offset: const Offset(0, 1),
),
] : null,
),
child: Text(
label,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w500,
color: isSelected
? (isDark ? Colors.white : const Color(0xFF212529))
    : (isDark ? const Color(0xFF9cabba) : const Color(0xFF6C757D)),
),
),
),
);
}
}



