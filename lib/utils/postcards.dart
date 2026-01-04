// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// import '../mdel/posts.dart'; // Add cached_network_image to pubspec.yaml
//
// class PostCard extends StatelessWidget {
//   final Post post;
//
//   const PostCard({super.key, required this.post});
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1A2634) : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           if (!isDark)
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   backgroundImage: post.userAvatarUrl != null
//                       ? NetworkImage(post.userAvatarUrl!)
//                       : null,
//                   backgroundColor: Colors.grey[300],
//                   child: post.userAvatarUrl == null
//                       ? Text(post.username[0].toUpperCase())
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   post.username,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
//           // Image
//           CachedNetworkImage(
//             imageUrl: post.imageUrl,
//             width: double.infinity,
//             height: 300,
//             fit: BoxFit.cover,
//             placeholder: (context, url) => Container(
//               height: 300,
//               color: Colors.grey[200],
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//             errorWidget: (context, url, error) => const Icon(Icons.error),
//           ),
//           // Actions & Caption
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.favorite_border, color: isDark ? Colors.white : Colors.black),
//                     const SizedBox(width: 4),
//                     Text('${post.likesCount}'),
//                     const SizedBox(width: 16),
//                     Icon(Icons.chat_bubble_outline, color: isDark ? Colors.white : Colors.black),
//                     const SizedBox(width: 4),
//                     Text('${post.commentsCount}'),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   post.title,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 if (post.caption != null) ...[
//                   const SizedBox(height: 4),
//                   Text(post.caption!),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }