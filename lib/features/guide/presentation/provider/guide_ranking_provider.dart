import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../guide/domain/entities/guide_ranking.dart';

class GuideRankingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  List<GuideRanking> _rankings = [];
  bool _isLoading = false;
  String? _error;

  GuideRankingProvider(this._firestore);

  List<GuideRanking> get rankings => _rankings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRankings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. 모든 가이드 정보 가져오기
      final guidesSnapshot = await _firestore
          .collection('users')
          .where('isGuide', isEqualTo: true)
          .get();

      List<GuideRanking> rankings = [];

      // 2. 각 가이드별로 예약 정보 집계
      for (var guideDoc in guidesSnapshot.docs) {
        // 가이드의 패키지 목록 가져오기
        final packagesSnapshot = await _firestore
            .collection('packages')
            .where('guideId', isEqualTo: guideDoc.id)
            .get();

        // 승인된 예약 수 집계
        int totalReservations = 0;
        double totalRating = 0;
        int reviewCount = 0;

        for (var packageDoc in packagesSnapshot.docs) {
          // 승인된 예약 수 계산
          final reservationsSnapshot = await _firestore
              .collection('reservations')
              .where('packageId', isEqualTo: packageDoc.id)
              .where('status', isEqualTo: 'approved')
              .get();

          totalReservations += reservationsSnapshot.docs.length;

          // 평균 평점 계산
          final reviewsSnapshot = await _firestore
              .collection('reviews')
              .where('packageId', isEqualTo: packageDoc.id)
              .get();

          if (reviewsSnapshot.docs.isNotEmpty) {
            for (var review in reviewsSnapshot.docs) {
              totalRating += review.data()['rating'] as double;
            }
            reviewCount += reviewsSnapshot.docs.length;
          }
        }

        // 가이드 랭킹 정보 생성
        rankings.add(GuideRanking(
          guideId: guideDoc.id,
          guideName: guideDoc.data()['name'],
          profileImageUrl: guideDoc.data()['profileImageUrl'],
          totalReservations: totalReservations,
          packageCount: packagesSnapshot.docs.length,
          rating: reviewCount > 0 ? totalRating / reviewCount : 0.0,
        ));
      }

      // 예약 수 기준으로 정렬
      rankings.sort((a, b) => b.totalReservations.compareTo(a.totalReservations));

      _rankings = rankings;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}