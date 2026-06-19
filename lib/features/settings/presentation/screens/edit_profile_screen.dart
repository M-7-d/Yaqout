import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/products/presentation/providers/product_provider.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _shopDescriptionController;
  bool _isLoading = false;
  File? _avatarFile;

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      setState(() {
        _avatarFile = File(picked.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImagePickerSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.fullName);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.phone);
    _addressController = TextEditingController(text: user?.address);
    _shopDescriptionController = TextEditingController(text: user?.shopDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _shopDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImagePickerSourceSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryLight,
                      child: _avatarFile != null
                          ? ClipOval(
                              child: Image.file(
                                _avatarFile!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.avatarUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 60, color: AppColors.primary),
                                  ),
                                )
                              : const Icon(Icons.person, size: 60, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('BASIC INFO'),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            if (user?.isSeller == true) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Shop Address',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _shopDescriptionController,
                label: 'Shop Description',
                icon: Icons.storefront_outlined,
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 32),
            _buildSectionHeader('SECURITY'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                title: const Text('Change Password'),
                subtitle: const Text('Update your login credentials'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textHint,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.card,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: oldPasswordController,
              label: 'Old Password',
              icon: Icons.lock_open_rounded,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: newPasswordController,
              label: 'New Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecond)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              try {
                await ref.read(authNotifierProvider.notifier).updatePassword(newPasswordController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  Future<void> _saveProfile() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Upload Avatar if chosen
      String? uploadedUrl;
      if (_avatarFile != null) {
        uploadedUrl = await ref.read(authNotifierProvider.notifier).uploadAvatar(
              userId: user.id,
              file: _avatarFile!,
            );
      }

      // 2. Update Profile info
      await ref.read(authNotifierProvider.notifier).updateProfile(
            userId: user.id,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            avatarUrl: uploadedUrl,
            address: _addressController.text.trim(),
            shopDescription: _shopDescriptionController.text.trim(),
          );

      // Invalidate relevant providers to refresh widgets across other pages
      ref.invalidate(userByIdProvider(user.id));
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(userRoomsProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
