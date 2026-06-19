import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../../data/repositories/review_repository_impl.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.read(supabaseClientProvider));
});

final productReviewsProvider =
    FutureProvider.family<List<ReviewEntity>, String>((ref, productId) {
  return ref.read(reviewRepositoryProvider).getReviewsForProduct(productId);
});
