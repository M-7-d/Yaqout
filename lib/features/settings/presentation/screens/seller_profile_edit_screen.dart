import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';

class SellerProfileEditScreen extends ConsumerStatefulWidget {
  const SellerProfileEditScreen({super.key});

  @override
  ConsumerState<SellerProfileEditScreen> createState() =>
      _SellerProfileEditScreenState();
}

class _SellerProfileEditScreenState
    extends ConsumerState<SellerProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _shopDescController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.fullName);
    _addressController = TextEditingController(text: user?.address);
    _shopDescController = TextEditingController(text: user?.shopDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _shopDescController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(UserEntity user) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            userId: user.id,
            fullName: _nameController.text.trim(),
            address: _addressController.text.trim(),
            shopDescription: _shopDescController.text.trim(),
          );
      if (!mounted) return;
      
      // Invalidate the seller profile provider to show fresh data
      ref.invalidate(userByIdProvider(user.id));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller profile updated successfully')),
      );
      
      // Navigate to the seller profile page explicitly
      context.go('/sellers/${user.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Seller Profile')),
        body: Center(child: Text(e.toString())),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Seller Profile')),
            body: const Center(
                child: Text('Please sign in to update your profile.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Seller Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Seller Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _shopDescController,
                  label: 'Shop Description',
                  icon: Icons.storefront_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified, color: AppColors.success),
                  title: const Text('Verified Seller'),
                  subtitle:
                      const Text('Verification is managed by the platform.'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Use this page to update your seller profile details. Your address and shop description will be visible on your public profile.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProfile(user),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
}
