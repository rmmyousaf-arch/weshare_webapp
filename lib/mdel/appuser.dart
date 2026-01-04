class AppUser {
  final String id;
  final String username;
  final String email;
  final String? profilePic;
  final String? bio;
  final String role;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.profilePic,
    this.bio,
    required this.role,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePic: json['profile_pic'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String? ?? 'consumer',
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_pic': profilePic,
      'bio': bio,
      'role': role,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? username,
    String? email,
    String? profilePic,
    String? bio,
    String? role,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isCreator => role == 'creator';
  bool get isConsumer => role == 'consumer';

  String get displayRole => isCreator ? 'Creator' : 'Consumer';

  String get initial => username.isNotEmpty ? username[0].toUpperCase() : 'U';
}