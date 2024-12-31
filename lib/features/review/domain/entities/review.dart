class Review {
  final String id;
  final String packageId;
  final String userId;
  final String userName;
  final double rating;  // 1~5 별점
  final String content;
  final DateTime createdAt;
  final String? reservationId;  // 예약 검증용

  Review({
    required this.id,
    required this.packageId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.reservationId,
  });
}