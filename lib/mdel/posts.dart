class Post {
  final String id;
  final String userId;
  final String username;
  final String? userProfilePic;
  final String title;
  final String caption;
  final String imageUrl;
  final List<String> taggedPeople;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfilePic,
    required this.title,
    required this.caption,
    required this.imageUrl,
    required this.taggedPeople,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isLiked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from joins
    final userData = json['users'];

    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: userData != null
          ? (userData['username'] as String? ?? 'Unknown')
          : (json['username'] as String? ?? 'Unknown'),
      userProfilePic: userData != null
          ? (userData['profile_pic'] as String?)
          : (json['profile_pic'] as String?),
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      taggedPeople: json['tagged_people'] != null
          ? List<String>.from(json['tagged_people'] as List)
          : [],
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'caption': caption,
      'image_url': imageUrl,
      'tagged_people': taggedPeople,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfilePic,
    String? title,
    String? caption,
    String? imageUrl,
    List<String>? taggedPeople,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      taggedPeople: taggedPeople ?? this.taggedPeople,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}