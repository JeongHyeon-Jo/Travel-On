import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../search/domain/entities/travel_package.dart';
import '../../../map/domain/entities/travel_point.dart';

class RecommendationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TravelPackage> _recommendedPackages = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<TravelPackage> get recommendedPackages => _recommendedPackages;

  Future<void> generateRecommendations(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 사용자 선호도 데이터 가져오기
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) throw Exception('사용자 데이터를 찾을 수 없습니다.');

      // 사용자의 좋아요 목록
      final likedPackages = List<String>.from(userData['likedPackages'] ?? []);

      // 사용자의 예약 이력 조회
      final bookingHistory = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved') // 승인된 예약만 고려
          .get();

      // 방문한 지역 집계
      final visitedRegions = <String, int>{};
      for (var booking in bookingHistory.docs) {
        final region = booking.data()['region'] as String;
        visitedRegions[region] = (visitedRegions[region] ?? 0) + 1;
      }

      // 모든 여행 패키지 가져오기
      final packagesSnapshot = await _firestore.collection('packages').get();
      final allPackages = packagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return TravelPackage(
          id: doc.id,
          title: data['title'] ?? '',
          titleEn: data['titleEn'] ?? '',
          titleJa: data['titleJa'] ?? '',
          titleZh: data['titleZh'] ?? '',
          description: data['description'] ?? '',
          descriptionEn: data['descriptionEn'] ?? '',
          descriptionJa: data['descriptionJa'] ?? '',
          descriptionZh: data['descriptionZh'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          region: data['region'] ?? '',
          mainImage: data['mainImage'],
          descriptionImages: List<String>.from(data['descriptionImages'] ?? []),
          guideName: data['guideName'] ?? '',
          guideId: data['guideId'] ?? '',
          minParticipants: (data['minParticipants'] as num?)?.toInt() ?? 4,
          maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 8,
          nights: (data['nights'] as num?)?.toInt() ?? 1,
          departureDays:
              List<int>.from(data['departureDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
          totalDays: (data['totalDays'] as num?)?.toInt() ?? 1,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          routePoints: (data['routePoints'] as List<dynamic>?)
                  ?.map((point) =>
                      TravelPoint.fromJson(point as Map<String, dynamic>))
                  .toList() ??
              [],
          likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
          likedBy: List<String>.from(data['likedBy'] ?? []),
        );
      }).toList();

      // 패키지 점수 계산
      final List<MapEntry<TravelPackage, double>> scoredPackages =
          allPackages.map((package) {
        double score = 0;

        // 1. 좋아요한 패키지와 같은 지역의 패키지 가중치
        if (likedPackages.contains(package.id)) {
          score += 2;
        }

        // 2. 자주 방문한 지역의 패키지 가중치
        final regionVisits = visitedRegions[package.region] ?? 0;
        score += regionVisits * 0.5;

        // 3. 인기도 반영
        score += package.likesCount * 0.1;

        // 4. 리뷰 평점 반영
        score += package.averageRating * 0.3;

        return MapEntry(package, score);
      }).toList();

      // 점수순으로 정렬
      scoredPackages.sort((a, b) => b.value.compareTo(a.value));

      // 상위 10개 패키지 선택
      _recommendedPackages =
          scoredPackages.take(10).map((entry) => entry.key).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>> calculateRegionPreferences(String userId) async {
    final visitedRegions = <String, double>{};

    // 1. 예약 이력 조회 (최근 1년)
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final bookingHistory = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed') // 완료된 예약만
        .where('travelDate', isGreaterThan: oneYearAgo)
        .get();

    // 2. 시간 기반 가중치 계산
    for (var booking in bookingHistory.docs) {
      final data = booking.data();
      final region = data['region'] as String;
      final travelDate = (data['travelDate'] as Timestamp).toDate();

      // 최근 방문일수록 높은 가중치
      final daysSinceVisit = DateTime.now().difference(travelDate).inDays;
      final timeWeight =
          1.0 - (daysSinceVisit / 365); // 1년 전 방문은 0점, 최근 방문은 1점에 가까움

      // 기존 가중치에 새로운 가중치 추가
      visitedRegions[region] = (visitedRegions[region] ?? 0) + timeWeight;
    }

    // 3. 리뷰 데이터로 보정
    final reviews = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .get();

    for (var review in reviews.docs) {
      final data = review.data();
      final region = data['region'] as String;
      final rating = (data['rating'] as num).toDouble();

      // 높은 평점을 준 지역에 추가 가중치
      if (rating >= 4.0) {
        visitedRegions[region] = (visitedRegions[region] ?? 0) + 0.5;
      }
    }

    return visitedRegions;
  }
}
