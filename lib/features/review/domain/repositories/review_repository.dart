import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_on_final/features/review/domain/entities/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getPackageReviews(String packageId, {int? limit, DocumentSnapshot? lastDocument});
  Future<bool> canUserReview(String userId, String packageId);
  Future<void> addReview(Review review);
  Future<void> updateReview(Review review);
  Future<void> deleteReview(String reviewId);
}