import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';

class BecomeSellerScreen extends ConsumerStatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _shopDescController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.fullName);
    _addressController = TextEditingController(text: user?.address);
    _shopDescController = TextEditingController(text: user?.shopDescription);
    _phoneController = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _shopDescController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _upgradeToSeller(UserEntity user) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            userId: user.id,
            fullName: _nameController.text.trim(),
            address: _addressController.text.trim(),
            shopDescription: _shopDescController.text.trim(),
            phone: _phoneController.text.trim(),
            role: 'seller', // Upgrade to seller
          );
      if (!mounted) return;
      
      // Invalidate the seller profile provider to show fresh data
      ref.invalidate(userByIdProvider(user.id));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Congratulations! You are now a seller.')),
      );
      
      // Navigate to home or settings
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgrade failed: ${e.toString()}')),
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
        appBar: AppBar(title: const Text('Become a Seller')),
        body: Center(child: Text(e.toString())),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Become a Seller')),
            body: const Center(
                child: Text('Please sign in to become a seller.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Become a Seller'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Start selling your products today! Fill in your store details below to upgrade your account.',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecond),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Shop Name *',
                    icon: Icons.person_outline,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address *',
                    icon: Icons.location_on_outlined,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _shopDescController,
                    label: 'Shop Description *',
                    icon: Icons.storefront_outlined,
                    maxLines: 4,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _upgradeToSeller(user),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Become a Seller',
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
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
