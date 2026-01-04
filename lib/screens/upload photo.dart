import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../utils/sheared_widgets.dart';

class UploadPhotoPage extends StatefulWidget {
  const UploadPhotoPage({super.key});

  @override
  State<UploadPhotoPage> createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();

  Uint8List? _selectedImage;
  String? _selectedImageName;
  bool _isUploading = false;

  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            // Changed from 1200 to 700 so the vertical form doesn't look stretched on Desktop
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.borderDark.withOpacity(0.5) : AppColors.borderLight,
                ),
              ),
              // REMOVED: LayoutBuilder and Row logic
              // ADDED: Simple Column for Top-to-Bottom layout everywhere
              child: Column(
                children: [
                  _buildUploadArea(isDark),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  _buildForm(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildUploadArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: _selectedImage == null
          ? _buildEmptyState(isDark)
          : _buildImagePreview(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 64,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 24),
                Text(
                  'Click to upload your photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Supports JPG, PNG, WebP. Max 5MB',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryViolet.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Select Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImageName != null)
          Text(
            _selectedImageName!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: _pickImage,
                child: const Text(
                  'Change Photo',
                  style: TextStyle(
                    color: AppColors.indigo,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _selectedImageName = null;
                  });
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a New Post',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share your latest work with the community.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: 'Title *',
            hint: 'Add a catchy title',
            controller: _titleController,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'Caption',
            hint: 'Write a caption...',
            controller: _captionController,
            isDark: isDark,
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryViolet.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadPhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Upload Post',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isDark,
    int maxLines = 1,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            suffixIcon: suffixIcon != null
                ? Icon(
              suffixIcon,
              size: 18,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark2 : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.indigo,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check if bytes are available (crucial for web)
        if (file.bytes == null) {
          _showError('Failed to load image data');
          return;
        }

        // Validate file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
          _showError('Image size must be less than 5MB');
          return;
        }

        // Validate file type
        if (!_isValidImageType(file.extension)) {
          _showError('Please select a valid image (JPG, PNG, WebP)');
          return;
        }

        setState(() {
          _selectedImage = file.bytes!;
          _selectedImageName = file.name;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  bool _isValidImageType(String? extension) {
    if (extension == null) return false;
    final validTypes = ['jpg', 'jpeg', 'png', 'webp'];
    return validTypes.contains(extension.toLowerCase());
  }

  Future<void> _uploadPhoto() async {
    // Check if Supabase is initialized
    if (_supabase == null) {
      _showError('Supabase not initialized. Please restart the app.');
      return;
    }

    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }
    if (_titleController.text.isEmpty) {
      _showError('Please add a title');
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      final user = _supabase!.auth.currentUser;
      if (user == null) {
        _showError('Please login to upload photos');
        return;
      }
      final imageUrl = await _uploadImageToStorage(_selectedImage!, _selectedImageName!);
      await _insertPostData(imageUrl, user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post uploaded successfully!'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _clearForm();
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _showError('Authentication error: ${e.message}');
    } on StorageException catch (e) {
      _showError('Storage error: ${e.message}');
    } catch (e) {
      _showError('Failed to upload post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<String> _uploadImageToStorage(Uint8List imageBytes, String fileName) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(fileName)}';
      final String filePath = 'posts/$uniqueFileName';

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // default
      final extension = fileName.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      // Upload with proper file options for web using uploadBinary[citation:4]
      await _supabase!.storage.from('photos').uploadBinary(
        filePath,
        imageBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      // Get public URL
      final String publicUrl = _supabase!.storage
          .from('photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Storage upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
  }

  Future<void> _insertPostData(String imageUrl, String userId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final Map<String, dynamic> postData = {
        'user_id': userId,
        'title': _titleController.text.trim(),
        'caption': _captionController.text.trim(),
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase!
          .from('posts')
          .insert(postData);

    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to insert post data: $e');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _captionController.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageName = null;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }
}

