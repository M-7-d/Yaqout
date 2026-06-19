import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({this.productId, super.key});
  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final List<File> _newImages = [];
  /// Existing product image URLs while editing (user can remove before save).
  final List<String> _keptImageUrls = [];
  bool _isLoading = false;
  bool _isEdit    = false;
  bool _isOutOfStock = false;
  ProductEntity? _existing;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _stockListener() {
    final stockVal = int.tryParse(_stockCtrl.text) ?? 0;
    final isZero = stockVal == 0;
    if (_isOutOfStock != isZero) {
      setState(() => _isOutOfStock = isZero);
    }
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
    _stockCtrl.addListener(_stockListener);
  }

  int get _totalSelectedImages => _keptImageUrls.length + _newImages.length;

  Future<void> _pickImages() async {
    final remaining = 5 - _totalSelectedImages;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked.take(remaining)) {
        _newImages.add(File(x.path));
      }
    });
  }

  void _invalidateProductCaches({required String productId, required String sellerId}) {
    ref.invalidate(productDetailProvider(productId));
    ref.invalidate(sellerProductsProvider(sellerId));
    ref.invalidate(productsProvider);
    ref.invalidate(featuredProductsProvider);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix the fields marked in red.')),
        );
      }
      return;
    }

    UserEntity? signedInUser;
    if (_isEdit) {
      if (_existing == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product is still loading. Please wait a moment.')),
          );
        }
        return;
      }
    } else {
      signedInUser = ref.read(authNotifierProvider).valueOrNull;
      if (signedInUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be signed in to list a product.')),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      if (_isEdit) {
        final base = _existing!;
        final updated = base.copyWith(
          title:       _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price:       double.tryParse(_priceCtrl.text) ?? base.price,
          stock:       int.tryParse(_stockCtrl.text) ?? base.stock,
          images:      List<String>.from(_keptImageUrls),
        );
        await repo.updateProduct(updated, newImages: _newImages);
        _invalidateProductCaches(productId: base.id, sellerId: base.sellerId);
      } else {
        final product = ProductEntity(
          id:          '',
          sellerId:    signedInUser!.id,
          title:       _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price:       double.tryParse(_priceCtrl.text) ?? 0,
          stock:       int.tryParse(_stockCtrl.text) ?? 0,
          createdAt:   DateTime.now(),
        );
        await repo.createProduct(product, _newImages);
        ref.invalidate(productsProvider);
        ref.invalidate(featuredProductsProvider);
        ref.invalidate(sellerProductsProvider(signedInUser.id));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isEdit ? 'Product updated successfully!' : 'Product listed successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && widget.productId != null) {
      final detail = ref.watch(productDetailProvider(widget.productId!));
      if (detail.hasValue && _existing == null) {
        final p = detail.requireValue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _existing != null) return;
          setState(() {
            _existing = p;
            _keptImageUrls
              ..clear()
              ..addAll(p.images);
            _titleCtrl.text = p.title;
            _descCtrl.text = p.description ?? '';
            _priceCtrl.text = p.price.toString();
            _stockCtrl.text = p.stock.toString();
            _isOutOfStock = p.stock == 0;
          });
        });
      }
      if (detail.isLoading || (_existing == null && detail.hasValue)) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Product'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (detail.hasError) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Product'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(child: Text(detail.error.toString())),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'List Your Product'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Banner ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tell us what you\'re selling',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Adding clear photos and a detailed description helps you sell faster.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image Section ───────────────────────────────────────────────
                    _SectionTitle(title: 'Product Photos', subtitle: 'Upload up to 5 photos'),
                    const SizedBox(height: 16),
                    _AddPhotoSelector(
                      enabled: _totalSelectedImages < 5,
                      onTap: _pickImages,
                    ).animate().fadeIn(delay: 600.ms),
                    if (_totalSelectedImages > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Selected photos',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecond,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...List.generate(_keptImageUrls.length, (i) {
                            final idx = i;
                            return _RemovableImageTile(
                              onRemove: () => setState(() => _keptImageUrls.removeAt(idx)),
                              showMainBadge: idx == 0,
                              child: CachedNetworkImage(
                                imageUrl: _keptImageUrls[idx],
                                errorListener: (_) {},
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.shimmerBase,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            );
                          }),
                          ...List.generate(_newImages.length, (j) {
                            final idx = j;
                            return _RemovableImageTile(
                              onRemove: () => setState(() => _newImages.removeAt(idx)),
                              showMainBadge: _keptImageUrls.isEmpty && idx == 0,
                              child: Image.file(_newImages[idx], fit: BoxFit.cover),
                            );
                          }),
                        ],
                      ).animate().fadeIn(delay: 650.ms),
                    ],

                    const SizedBox(height: 32),

                    // ── Details Section ─────────────────────────────────────────────
                    _SectionTitle(title: 'Basic Information', subtitle: 'General details about your item'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Title',
                        hintText: 'e.g. Vintage Leather Watch',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
                    ).animate().fadeIn(delay: 700.ms),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What makes this product special?',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.description_outlined),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter a description' : null,
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 32),

                    // ── Inventory Section ──────────────────────────────────────────
                    _SectionTitle(title: 'Pricing & Stock', subtitle: 'Set your value and availability'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: '\$ ',
                              prefixIcon: Icon(Icons.attach_money_rounded),
                            ),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.errorLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.errorLight),
                      ),
                      child: SwitchListTile(
                        title: const Text('Mark as "Stock is empty"'),
                        subtitle: const Text('Tell buyers this product is finished'),
                        activeColor: AppColors.error,
                        value: _isOutOfStock,
                        onChanged: (val) {
                          if (val) {
                            _stockCtrl.text = '0';
                          } else {
                            _stockCtrl.text = '1';
                          }
                        },
                      ),
                    ).animate().fadeIn(delay: 950.ms),

                    const SizedBox(height: 48),

                    // ── Submit Button ───────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isEdit ? 'Update Product' : 'List Product Now',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.95, 0.95)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone. Are you sure you want to remove this product?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              context.pop();
              final repo = ref.read(productRepositoryProvider);
              await repo.deleteProduct(widget.productId!);
              if (mounted) context.go('/home');
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecond)),
      ],
    );
  }
}

class _AddPhotoSelector extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddPhotoSelector({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 112,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: enabled ? AppColors.primary.withOpacity(0.85) : AppColors.textHint,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                enabled ? 'Add photos' : 'Maximum 5 photos',
                style: TextStyle(
                  color: enabled ? AppColors.primary : AppColors.textHint,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemovableImageTile extends StatelessWidget {
  final VoidCallback onRemove;
  final bool showMainBadge;
  final Widget child;

  const _RemovableImageTile({
    required this.onRemove,
    this.showMainBadge = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: AppColors.shimmerBase,
                child: child,
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, color: Colors.red, size: 22),
                ),
              ),
            ),
          ),
          if (showMainBadge)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.92),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Text(
                  'MAIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
