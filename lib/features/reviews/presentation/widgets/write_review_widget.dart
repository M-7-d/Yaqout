import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../presentation/providers/review_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

class WriteReviewWidget extends ConsumerStatefulWidget {
  final String productId;
  final String sellerId;
  final String reviewerId;
  final VoidCallback onReviewSubmitted;

  const WriteReviewWidget({
    required this.productId,
    required this.sellerId,
    required this.reviewerId,
    required this.onReviewSubmitted,
    super.key,
  });

  @override
  ConsumerState<WriteReviewWidget> createState() => _WriteReviewWidgetState();
}

class _WriteReviewWidgetState extends ConsumerState<WriteReviewWidget> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      setState(() => _errorMessage = 'Please select a rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(reviewRepositoryProvider).createReview(
            productId: widget.productId,
            reviewerId: widget.reviewerId,
            rating: _rating,
            comment: _commentController.text.trim().isNotEmpty
                ? _commentController.text.trim()
                : null,
          );

      // Invalidate related providers to hot-reload across different views
      ref.invalidate(productReviewsProvider(widget.productId));
      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(sellerProductsProvider(widget.sellerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Your Rating: ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isSelected = starValue <= _rating;
                  return GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () => setState(() => _rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            enabled: !_isSubmitting,
            style: const TextStyle(color: AppColors.primaryDark),
            decoration: InputDecoration(
              hintText: 'Share your experience with this product (optional)...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
