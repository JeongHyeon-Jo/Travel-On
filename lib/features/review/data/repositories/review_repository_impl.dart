import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:travel_on_final/features/review/domain/entities/review.dart';
import 'package:travel_on_final/features/review/domain/repositories/review_repository.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TravelProvider _travelProvider;  // 추가

  ReviewRepositoryImpl(this._travelProvider);  // 생성자 추가

  @override
  Future<List<Review>> getPackageReviews(String packageId, {int? limit, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('packageId', isEqualTo: packageId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => Review(
        id: doc.id,
        packageId: doc['packageId'],
        userId: doc['userId'],
        userName: doc['userName'],
        rating: (doc['rating'] as num).toDouble(),
        content: doc['content'],
        createdAt: (doc['createdAt'] as Timestamp).toDate(),
        reservationId: doc['reservationId'],
      )).toList();
    } catch (e) {
      print('Error getting package reviews: $e');
      rethrow;
    }
  }

  @override
  Future<bool> canUserReview(String userId, String packageId) async {
    try {
      final reservations = await _firestore
          .collection('reservations')
          .where('customerId', isEqualTo: userId)
          .where('packageId', isEqualTo: packageId)
          .where('status', isEqualTo: 'approved')
          .get();

      // print('Checking reservations for user $userId and package $packageId');
      for (var doc in reservations.docs) {
        // print('Reservation data: ${doc.data()}');
      }

      return reservations.docs.isNotEmpty;
    } catch (e) {
      // print('Error in canUserReview: $e');
      return false;
    }
  }

  @override
  Future<void> addReview(Review review) async {
    try {
      // 예약 확인
      if (!await canUserReview(review.userId, review.packageId)) {
        throw 'review.error.unauthorized'.tr();
      }

      // 리뷰 추가
      final reviewRef = await _firestore.collection('reviews').add({
        'packageId': review.packageId,
        'userId': review.userId,
        'userName': review.userName,
        'rating': review.rating,
        'content': review.content,
        'createdAt': FieldValue.serverTimestamp(),
        'reservationId': review.reservationId,
      });

      // 패키지 문서 가져오기
      final packageRef = _firestore.collection('packages').doc(review.packageId);

      // 현재 리뷰 수와 평균 별점 계산을 위한 모든 리뷰 가져오기
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('packageId', isEqualTo: review.packageId)
          .get();

      // 리뷰 개수와 총 별점 계산
      final reviewCount = reviewsSnapshot.docs.length;
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      // 평균 별점 계산
      final averageRating = totalRating / reviewCount;

      // 패키지 문서 업데이트
      await packageRef.update({
        'reviewCount': reviewCount,
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      });

      _travelProvider.refreshPackage(review.packageId);

    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  Future<void> _updatePackageRating(String packageId) async {
    final reviews = await getPackageReviews(packageId);
    if (reviews.isEmpty) return;

    final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    await _firestore.collection('packages').doc(packageId).update({
      'averageRating': averageRating,
      'reviewCount': reviews.length,
    });
  }

  @override
  Future<void> updateReview(Review review) async {
    await _firestore.collection('reviews').doc(review.id).update({
      'rating': review.rating,
      'content': review.content,
      // 필요한 다른 필드들...
    });

    // 패키지의 평균 별점 업데이트
    await _updatePackageRating(review.packageId);
  }


  @override
  Future<void> deleteReview(String reviewId) async {
    // 리뷰 문서 가져오기
    final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
    final packageId = reviewDoc.data()?['packageId'];

    // 리뷰 삭제
    await _firestore.collection('reviews').doc(reviewId).delete();

    // 패키지의 평균 별점 업데이트
    if (packageId != null) {
      await _updatePackageRating(packageId);
    }
  }
}